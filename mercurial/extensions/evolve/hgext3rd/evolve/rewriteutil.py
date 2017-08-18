# Module dedicated to host utility code dedicated to changeset rewrite
#
# Copyright 2017 Octobus <contact@octobus.net>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

# Status: Stabilization of the API in progress
#
#   The content of this module should move into core incrementally once we are
#   happy one piece of it (and hopefully, able to reuse it in other core
#   commands).

from mercurial import (
    cmdutil,
    commands,
    context,
    copies,
    error,
    hg,
    lock as lockmod,
    node,
    obsolete,
    phases,
    repair,
    revset,
    util,
)

from mercurial.i18n import _

from . import (
    compat,
)

def _formatrevs(repo, revs, maxrevs=4):
    """return a string summarising revision in a descent size

    If there is few enough revision, we list them otherwise we display a
    summary in the form:

        1ea73414a91b and 5 others
    """
    tonode = repo.changelog.node
    numrevs = len(revs)
    if numrevs < maxrevs:
        shorts = [node.short(tonode(r)) for r in revs]
        summary = ', '.join(shorts)
    else:
        if util.safehasattr(revs, 'first'):
            first = revs.first()
        else:
            first = revs[0]
        summary = _('%s and %d others')
        summary %= (node.short(tonode(first)), numrevs - 1)
    return summary

def precheck(repo, revs, action='rewrite'):
    """check if <revs> can be rewritten

    <action> can be used to control the commit message.
    """
    if node.nullrev in revs:
        msg = _("cannot %s the null revision") % (action)
        hint = _("no changeset checked out")
        raise error.Abort(msg, hint=hint)
    publicrevs = repo.revs('%ld and public()', revs)
    if publicrevs:
        summary = _formatrevs(repo, publicrevs)
        msg = _("cannot %s public changesets: %s") % (action, summary)
        hint = _("see 'hg help phases' for details")
        raise error.Abort(msg, hint=hint)
    newunstable = disallowednewunstable(repo, revs)
    if newunstable:
        msg = _("%s will orphan %i descendants")
        msg %= (action, len(newunstable))
        hint = _("see 'hg help evolution.instability'")
        raise error.Abort(msg, hint=hint)

def bookmarksupdater(repo, oldid, tr):
    """Return a callable update(newid) updating the current bookmark
    and bookmarks bound to oldid to newid.
    """
    def updatebookmarks(newid):
        oldbookmarks = repo.nodebookmarks(oldid)
        bmchanges = [(b, newid) for b in oldbookmarks]
        if bmchanges:
            compat.bookmarkapplychanges(repo, tr, bmchanges)
    return updatebookmarks

def disallowednewunstable(repo, revs):
    """Check that editing <revs> will not create disallowed unstable

    (unstable creation is controled by some special config).
    """
    allowunstable = obsolete.isenabled(repo, obsolete.allowunstableopt)
    if allowunstable:
        return revset.baseset()
    return repo.revs("(%ld::) - %ld", revs, revs)

def foldcheck(repo, revs):
    """check that <revs> can be folded"""
    precheck(repo, revs, action='fold')
    roots = repo.revs('roots(%ld)', revs)
    if len(roots) > 1:
        raise error.Abort(_("cannot fold non-linear revisions "
                            "(multiple roots given)"))
    root = repo[roots.first()]
    if root.phase() <= phases.public:
        raise error.Abort(_("cannot fold public revisions"))
    heads = repo.revs('heads(%ld)', revs)
    if len(heads) > 1:
        raise error.Abort(_("cannot fold non-linear revisions "
                            "(multiple heads given)"))
    head = repo[heads.first()]
    return root, head

def deletebookmark(repo, repomarks, bookmarks):
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction('prune')
        bmchanges = []
        for bookmark in bookmarks:
            bmchanges.append((bookmark, None))
        compat.bookmarkapplychanges(repo, tr, bmchanges)
        tr.close()
        for bookmark in sorted(bookmarks):
            repo.ui.write(_("bookmark '%s' deleted\n") % bookmark)
    finally:
        lockmod.release(tr, lock, wlock)

def presplitupdate(repo, ui, prev, ctx):
    """prepare the working directory for a split (for topic hooking)
    """
    hg.update(repo, prev)
    commands.revert(ui, repo, rev=ctx.rev(), all=True)

def reachablefrombookmark(repo, revs, bookmarks):
    """filter revisions and bookmarks reachable from the given bookmark
    yoinked from mq.py
    """
    repomarks = repo._bookmarks
    if not bookmarks.issubset(repomarks):
        raise error.Abort(_("bookmark '%s' not found") %
                          ','.join(sorted(bookmarks - set(repomarks.keys()))))

    # If the requested bookmark is not the only one pointing to a
    # a revision we have to only delete the bookmark and not strip
    # anything. revsets cannot detect that case.
    nodetobookmarks = {}
    for mark, bnode in repomarks.iteritems():
        nodetobookmarks.setdefault(bnode, []).append(mark)
    for marks in nodetobookmarks.values():
        if bookmarks.issuperset(marks):
            rsrevs = repair.stripbmrevset(repo, marks[0])
            revs = set(revs)
            revs.update(set(rsrevs))
            revs = sorted(revs)
    return repomarks, revs

def rewrite(repo, old, updates, head, newbases, commitopts):
    """Return (nodeid, created) where nodeid is the identifier of the
    changeset generated by the rewrite process, and created is True if
    nodeid was actually created. If created is False, nodeid
    references a changeset existing before the rewrite call.
    """
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction('rewrite')
        if len(old.parents()) > 1: # XXX remove this unnecessary limitation.
            raise error.Abort(_('cannot amend merge changesets'))
        base = old.p1()
        updatebookmarks = bookmarksupdater(repo, old.node(), tr)

        # commit a new version of the old changeset, including the update
        # collect all files which might be affected
        files = set(old.files())
        for u in updates:
            files.update(u.files())

        # Recompute copies (avoid recording a -> b -> a)
        copied = copies.pathcopies(base, head)

        # prune files which were reverted by the updates
        def samefile(f):
            if f in head.manifest():
                a = head.filectx(f)
                if f in base.manifest():
                    b = base.filectx(f)
                    return (a.data() == b.data()
                            and a.flags() == b.flags())
                else:
                    return False
            else:
                return f not in base.manifest()
        files = [f for f in files if not samefile(f)]
        # commit version of these files as defined by head
        headmf = head.manifest()

        def filectxfn(repo, ctx, path):
            if path in headmf:
                fctx = head[path]
                flags = fctx.flags()
                mctx = context.memfilectx(repo, fctx.path(), fctx.data(),
                                          islink='l' in flags,
                                          isexec='x' in flags,
                                          copied=copied.get(path))
                return mctx
            return None

        message = cmdutil.logmessage(repo.ui, commitopts)
        if not message:
            message = old.description()

        user = commitopts.get('user') or old.user()
        # TODO: In case not date is given, we should take the old commit date
        # if we are working one one changeset or mimic the fold behavior about
        # date
        date = commitopts.get('date') or None
        extra = dict(commitopts.get('extra', old.extra()))
        extra['branch'] = head.branch()

        new = context.memctx(repo,
                             parents=newbases,
                             text=message,
                             files=files,
                             filectxfn=filectxfn,
                             user=user,
                             date=date,
                             extra=extra)

        if commitopts.get('edit'):
            new._text = cmdutil.commitforceeditor(repo, new, [])
        revcount = len(repo)
        newid = repo.commitctx(new)
        new = repo[newid]
        created = len(repo) != revcount
        updatebookmarks(newid)

        tr.close()
        return newid, created
    finally:
        lockmod.release(tr, lock, wlock)
