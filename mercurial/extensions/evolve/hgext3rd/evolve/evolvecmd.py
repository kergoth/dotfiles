# Copyright 2011 Peter Arrenbrecht <peter.arrenbrecht@gmail.com>
#                Logilab SA        <contact@logilab.fr>
#                Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#                Patrick Mezard <patrick@mezard.eu>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

"""logic related to hg evolve command"""

import collections
import re

from mercurial import (
    bookmarks as bookmarksmod,
    cmdutil,
    commands,
    context,
    copies,
    error,
    hg,
    lock as lockmod,
    merge,
    node,
    obsolete,
    phases,
    scmutil,
    util,
)

from mercurial.i18n import _

from . import (
    cmdrewrite,
    compat,
    exthelper,
    rewriteutil,
    state,
    utility,
)

TROUBLES = compat.TROUBLES
shorttemplate = utility.shorttemplate
_bookmarksupdater = rewriteutil.bookmarksupdater
sha1re = re.compile(r'\b[0-9a-f]{6,40}\b')

eh = exthelper.exthelper()
_bookmarksupdater = rewriteutil.bookmarksupdater
mergetoolopts = commands.mergetoolopts

def _solveone(ui, repo, ctx, evolvestate, dryrun, confirm,
              progresscb, category):
    """Resolve the troubles affecting one revision

    returns a tuple (bool, newnode) where,
        bool: a boolean value indicating whether the instability was solved
        newnode: if bool is True, then the newnode of the resultant commit
                 formed. newnode can be node, when resolution led to no new
                 commit. If bool is False, this is ''.
    """
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction("evolve")
        if 'orphan' == category:
            result = _solveunstable(ui, repo, ctx, evolvestate,
                                    dryrun, confirm, progresscb)
        elif 'phasedivergent' == category:
            result = _solvebumped(ui, repo, ctx, evolvestate,
                                  dryrun, confirm, progresscb)
        elif 'contentdivergent' == category:
            result = _solvedivergent(ui, repo, ctx, evolvestate,
                                     dryrun, confirm, progresscb)
        else:
            assert False, "unknown trouble category: %s" % (category)
        tr.close()
        return result
    finally:
        lockmod.release(tr, lock, wlock)

def _solveunstable(ui, repo, orig, evolvestate, dryrun=False, confirm=False,
                   progresscb=None):
    """ Tries to stabilize the changeset orig which is orphan.

    returns a tuple (bool, newnode) where,
        bool: a boolean value indicating whether the instability was solved
        newnode: if bool is True, then the newnode of the resultant commit
                 formed. newnode can be node, when resolution led to no new
                 commit. If bool is False, this is ''.
    """
    pctx = orig.p1()
    keepbranch = orig.p1().branch() != orig.branch()
    if len(orig.parents()) == 2:
        p1obs = orig.p1().obsolete()
        p2obs = orig.p2().obsolete()
        if not p1obs and p2obs:
            pctx = orig.p2()  # second parent is obsolete ?
            keepbranch = orig.p2().branch() != orig.branch()
        elif not p2obs and p1obs:
            pass
        else:
            # store that we are resolving an orphan merge with both parents
            # obsolete and proceed with first parent
            evolvestate['orphanmerge'] = True
            # we should process the second parent first, so that in case of
            # no-conflicts the first parent is processed later and preserved as
            # first parent
            pctx = orig.p2()
            keepbranch = orig.p2().branch() != orig.branch()

    if not pctx.obsolete():
        ui.warn(_("cannot solve instability of %s, skipping\n") % orig)
        return (False, '')
    obs = pctx
    newer = compat.successorssets(repo, obs.node())
    # search of a parent which is not killed
    while not newer or newer == [()]:
        ui.debug("stabilize target %s is plain dead,"
                 " trying to stabilize on its parent\n" %
                 obs)
        obs = obs.parents()[0]
        newer = compat.successorssets(repo, obs.node())
    if len(newer) > 1:
        msg = _("skipping %s: divergent rewriting. can't choose "
                "destination\n") % obs
        ui.write_err(msg)
        return (False, '')
    targets = newer[0]
    assert targets
    if len(targets) > 1:
        # split target, figure out which one to pick, are they all in line?
        targetrevs = [repo[r].rev() for r in targets]
        roots = repo.revs('roots(%ld)', targetrevs)
        heads = repo.revs('heads(%ld)', targetrevs)
        if len(roots) > 1 or len(heads) > 1:
            cheader = _("ancestor '%s' split over multiple topological"
                        " branches.\nchoose an evolve destination:") % orig
            selectedrev = utility.revselectionprompt(ui, repo, list(heads),
                                                     cheader)
            if selectedrev is None:
                msg = _("could not solve instability, "
                        "ambiguous destination: "
                        "parent split across two branches\n")
                ui.write_err(msg)
                return (False, '')
            target = repo[selectedrev]
        else:
            target = repo[heads.first()]
    else:
        target = targets[0]
    displayer = compat.changesetdisplayer(ui, repo, {'template': shorttemplate})
    target = repo[target]
    if not ui.quiet or confirm:
        repo.ui.write(_('move:'), label='evolve.operation')
        displayer.show(orig)
        repo.ui.write(_('atop:'))
        displayer.show(target)
    if confirm and ui.prompt('perform evolve? [Ny]', 'n') != 'y':
            raise error.Abort(_('evolve aborted by user'))
    if progresscb:
        progresscb()
    todo = 'hg rebase -r %s -d %s\n' % (orig, target)
    if dryrun:
        repo.ui.write(todo)
        return (False, '')
    else:
        repo.ui.note(todo)
        if progresscb:
            progresscb()
        try:
            newid = relocate(repo, orig, target, pctx, keepbranch)
            return (True, newid)
        except MergeFailure:
            ops = {'current': orig.node()}
            evolvestate.addopts(ops)
            evolvestate.save()
            repo.ui.write_err(_('evolve failed!\n'))
            repo.ui.write_err(
                _("fix conflict and run 'hg evolve --continue'"
                  " or use 'hg update -C .' to abort\n"))
            raise

def _solvebumped(ui, repo, bumped, evolvestate, dryrun=False, confirm=False,
                 progresscb=None):
    """Stabilize a bumped changeset

    returns a tuple (bool, newnode) where,
        bool: a boolean value indicating whether the instability was solved
        newnode: if bool is True, then the newnode of the resultant commit
                 formed. newnode can be node, when resolution led to no new
                 commit. If bool is False, this is ''.
    """
    repo = repo.unfiltered()
    bumped = repo[bumped.rev()]
    # For now we deny bumped merge
    if len(bumped.parents()) > 1:
        msg = _('skipping %s : we do not handle merge yet\n') % bumped
        ui.write_err(msg)
        return (False, '')
    prec = repo.set('last(allprecursors(%d) and public())', bumped.rev()).next()
    # For now we deny target merge
    if len(prec.parents()) > 1:
        msg = _('skipping: %s: public version is a merge, '
                'this is not handled yet\n') % prec
        ui.write_err(msg)
        return (False, '')

    displayer = compat.changesetdisplayer(ui, repo, {'template': shorttemplate})
    if not ui.quiet or confirm:
        repo.ui.write(_('recreate:'), label='evolve.operation')
        displayer.show(bumped)
        repo.ui.write(_('atop:'))
        displayer.show(prec)
    if confirm and ui.prompt('perform evolve? [Ny]', 'n') != 'y':
        raise error.Abort(_('evolve aborted by user'))
    if dryrun:
        todo = 'hg rebase --rev %s --dest %s;\n' % (bumped, prec.p1())
        repo.ui.write(todo)
        repo.ui.write(('hg update %s;\n' % prec))
        repo.ui.write(('hg revert --all --rev %s;\n' % bumped))
        repo.ui.write(('hg commit --msg "%s update to %s"\n' %
                       (TROUBLES['PHASEDIVERGENT'], bumped)))
        return (False, '')
    if progresscb:
        progresscb()
    newid = tmpctx = None
    tmpctx = bumped
    # Basic check for common parent. Far too complicated and fragile
    tr = repo.currenttransaction()
    assert tr is not None
    bmupdate = _bookmarksupdater(repo, bumped.node(), tr)
    if not list(repo.set('parents(%d) and parents(%d)', bumped.rev(), prec.rev())):
        # Need to rebase the changeset at the right place
        repo.ui.status(
            _('rebasing to destination parent: %s\n') % prec.p1())
        try:
            tmpid = relocate(repo, bumped, prec.p1())
            if tmpid is not None:
                tmpctx = repo[tmpid]
                compat.createmarkers(repo, [(bumped, (tmpctx,))],
                                     operation='evolve')
        except MergeFailure:
            repo.vfs.write('graftstate', bumped.hex() + '\n')
            repo.ui.write_err(_('evolution failed!\n'))
            msg = _("fix conflict and run 'hg evolve --continue'\n")
            repo.ui.write_err(msg)
            raise
    # Create the new commit context
    repo.ui.status(_('computing new diff\n'))
    files = set()
    copied = copies.pathcopies(prec, bumped)
    precmanifest = prec.manifest().copy()
    # 3.3.2 needs a list.
    # future 3.4 don't detect the size change during iteration
    # this is fishy
    for key, val in list(bumped.manifest().iteritems()):
        precvalue = precmanifest.get(key, None)
        if precvalue is not None:
            del precmanifest[key]
        if precvalue != val:
            files.add(key)
    files.update(precmanifest)  # add missing files
    # commit it
    if files: # something to commit!
        def filectxfn(repo, ctx, path):
            if path in bumped:
                fctx = bumped[path]
                flags = fctx.flags()
                mctx = compat.memfilectx(repo, ctx, fctx, flags, copied, path)
                return mctx
            return None
        text = '%s update to %s:\n\n' % (TROUBLES['PHASEDIVERGENT'], prec)
        text += bumped.description()

        new = context.memctx(repo,
                             parents=[prec.node(), node.nullid],
                             text=text,
                             files=files,
                             filectxfn=filectxfn,
                             user=bumped.user(),
                             date=bumped.date(),
                             extra=bumped.extra())

        newid = repo.commitctx(new)
    if newid is None:
        compat.createmarkers(repo, [(tmpctx, ())], operation='evolve')
        newid = prec.node()
    else:
        phases.retractboundary(repo, tr, bumped.phase(), [newid])
        compat.createmarkers(repo, [(tmpctx, (repo[newid],))],
                             flag=obsolete.bumpedfix, operation='evolve')
    bmupdate(newid)
    repo.ui.status(_('committed as %s\n') % node.short(newid))
    # reroute the working copy parent to the new changeset
    with repo.dirstate.parentchange():
        repo.dirstate.setparents(newid, node.nullid)
    return (True, newid)

def _solvedivergent(ui, repo, divergent, evolvestate, dryrun=False,
                    confirm=False, progresscb=None):
    """tries to solve content-divergence of a changeset

    returns a tuple (bool, newnode) where,
        bool: a boolean value indicating whether the instability was solved
        newnode: if bool is True, then the newnode of the resultant commit
                 formed. newnode can be node, when resolution led to no new
                 commit. If bool is False, this is ''.
    """
    repo = repo.unfiltered()
    divergent = repo[divergent.rev()]
    base, others = divergentdata(divergent)
    if len(others) > 1:
        othersstr = "[%s]" % (','.join([str(i) for i in others]))
        msg = _("skipping %d:%s with a changeset that got split"
                " into multiple ones:\n"
                "|[%s]\n"
                "| This is not handled by automatic evolution yet\n"
                "| You have to fallback to manual handling with commands "
                "such as:\n"
                "| - hg touch -D\n"
                "| - hg prune\n"
                "| \n"
                "| You should contact your local evolution Guru for help.\n"
                ) % (divergent, TROUBLES['CONTENTDIVERGENT'], othersstr)
        ui.write_err(msg)
        return (False, '')
    other = others[0]
    if len(other.parents()) > 1:
        msg = _("skipping %s: %s changeset can't be "
                "a merge (yet)\n") % (divergent, TROUBLES['CONTENTDIVERGENT'])
        ui.write_err(msg)
        hint = _("You have to fallback to solving this by hand...\n"
                 "| This probably means redoing the merge and using \n"
                 "| `hg prune` to kill older version.\n")
        ui.write_err(hint)
        return (False, '')
    if other.p1() not in divergent.parents():
        msg = _("skipping %s: have a different parent than %s "
                "(not handled yet)\n") % (divergent, other)
        hint = _("| %(d)s, %(o)s are not based on the same changeset.\n"
                 "| With the current state of its implementation, \n"
                 "| evolve does not work in that case.\n"
                 "| rebase one of them next to the other and run \n"
                 "| this command again.\n"
                 "| - either: hg rebase --dest 'p1(%(d)s)' -r %(o)s\n"
                 "| - or:     hg rebase --dest 'p1(%(o)s)' -r %(d)s\n"
                 ) % {'d': divergent, 'o': other}
        ui.write_err(msg)
        ui.write_err(hint)
        return (False, '')

    displayer = compat.changesetdisplayer(ui, repo, {'template': shorttemplate})
    if not ui.quiet or confirm:
        ui.write(_('merge:'), label='evolve.operation')
        displayer.show(divergent)
        ui.write(_('with: '))
        displayer.show(other)
        ui.write(_('base: '))
        displayer.show(base)
    if confirm and ui.prompt(_('perform evolve? [Ny]'), 'n') != 'y':
        raise error.Abort(_('evolve aborted by user'))
    if dryrun:
        ui.write(('hg update -c %s &&\n' % divergent))
        ui.write(('hg merge %s &&\n' % other))
        ui.write(('hg commit -m "auto merge resolving conflict between '
                 '%s and %s"&&\n' % (divergent, other)))
        ui.write(('hg up -C %s &&\n' % base))
        ui.write(('hg revert --all --rev tip &&\n'))
        ui.write(('hg commit -m "`hg log -r %s --template={desc}`";\n'
                 % divergent))
        return (False, '')
    if divergent not in repo[None].parents():
        repo.ui.status(_('updating to "local" conflict\n'))
        hg.update(repo, divergent.rev())
    repo.ui.note(_('merging %s changeset\n') % TROUBLES['CONTENTDIVERGENT'])
    if progresscb:
        progresscb()
    stats = merge.update(repo,
                         other.node(),
                         branchmerge=True,
                         force=False,
                         ancestor=base.node(),
                         mergeancestor=True)
    hg._showstats(repo, stats)
    if stats[3]:
        repo.ui.status(_("use 'hg resolve' to retry unresolved file merges "
                         "or 'hg update -C .' to abort\n"))
    if stats[3] > 0:
        raise error.Abort('merge conflict between several amendments '
                          '(this is not automated yet)',
                          hint="""/!\ You can try:
/!\ * manual merge + resolve => new cset X
/!\ * hg up to the parent of the amended changeset (which are named W and Z)
/!\ * hg revert --all -r X
/!\ * hg ci -m "same message as the amended changeset" => new cset Y
/!\ * hg prune -n Y W Z
""")
    if progresscb:
        progresscb()
    emtpycommitallowed = repo.ui.backupconfig('ui', 'allowemptycommit')
    tr = repo.currenttransaction()
    assert tr is not None
    try:
        repo.ui.setconfig('ui', 'allowemptycommit', True, 'evolve')
        with repo.dirstate.parentchange():
            repo.dirstate.setparents(divergent.node(), node.nullid)
        oldlen = len(repo)
        cmdrewrite.amend(ui, repo, message='', logfile='')
        if oldlen == len(repo):
            new = divergent
            # no changes
        else:
            new = repo['.']
        compat.createmarkers(repo, [(other, (new,))], operation='evolve')
        phases.retractboundary(repo, tr, other.phase(), [new.node()])
        return (True, new.node())
    finally:
        repo.ui.restoreconfig(emtpycommitallowed)

class MergeFailure(error.Abort):
    pass

def _orderrevs(repo, revs):
    """Compute an ordering to solve instability for the given revs

    revs is a list of unstable revisions.

    Returns the same revisions ordered to solve their instability from the
    bottom to the top of the stack that the stabilization process will produce
    eventually.

    This ensures the minimal number of stabilizations, as we can stabilize each
    revision on its final stabilized destination.
    """
    # Step 1: Build the dependency graph
    dependencies, rdependencies = utility.builddependencies(repo, revs)
    # Step 2: Build the ordering
    # Remove the revisions with no dependency(A) and add them to the ordering.
    # Removing these revisions leads to new revisions with no dependency (the
    # one depending on A) that we can remove from the dependency graph and add
    # to the ordering. We progress in a similar fashion until the ordering is
    # built
    solvablerevs = collections.deque([r for r in sorted(dependencies.keys())
                                      if not dependencies[r]])
    ordering = []
    while solvablerevs:
        rev = solvablerevs.popleft()
        for dependent in rdependencies[rev]:
            dependencies[dependent].remove(rev)
            if not dependencies[dependent]:
                solvablerevs.append(dependent)
        del dependencies[rev]
        ordering.append(rev)

    ordering.extend(sorted(dependencies))
    return ordering

def relocate(repo, orig, dest, pctx=None, keepbranch=False):
    """rewrites the orig rev on dest rev

    returns the node of new commit which is formed
    """
    if orig.rev() == dest.rev():
        raise error.Abort(_('tried to relocate a node on top of itself'),
                          hint=_("This shouldn't happen. If you still "
                                 "need to move changesets, please do so "
                                 "manually with nothing to rebase - working "
                                 "directory parent is also destination"))

    if pctx is None:
        if len(orig.parents()) == 2:
            raise error.Abort(_("tried to relocate a merge commit without "
                                "specifying which parent should be moved"),
                              hint=_("Specify the parent by passing in pctx"))
        pctx = orig.p1()

    commitmsg = orig.description()

    cache = {}
    sha1s = re.findall(sha1re, commitmsg)
    unfi = repo.unfiltered()
    for sha1 in sha1s:
        ctx = None
        try:
            ctx = unfi[sha1]
        except error.RepoLookupError:
            continue

        if not ctx.obsolete():
            continue

        successors = compat.successorssets(repo, ctx.node(), cache)

        # We can't make any assumptions about how to update the hash if the
        # cset in question was split or diverged.
        if len(successors) == 1 and len(successors[0]) == 1:
            newsha1 = node.hex(successors[0][0])
            commitmsg = commitmsg.replace(sha1, newsha1[:len(sha1)])
        else:
            repo.ui.note(_('The stale commit message reference to %s could '
                           'not be updated\n') % sha1)

    tr = repo.currenttransaction()
    assert tr is not None
    try:
        r = _evolvemerge(repo, orig, dest, pctx, keepbranch)
        if r[-1]: # some conflict
            raise error.Abort(_('unresolved merge conflicts '
                                '(see hg help resolve)'))
        nodenew = _relocatecommit(repo, orig, commitmsg)
    except error.Abort as exc:
        with repo.dirstate.parentchange():
            repo.setparents(repo['.'].node(), node.nullid)
            repo.dirstate.write(tr)
            # fix up dirstate for copies and renames
            compat.duplicatecopies(repo, repo[None], dest.rev(), orig.p1().rev())

        class LocalMergeFailure(MergeFailure, exc.__class__):
            pass
        exc.__class__ = LocalMergeFailure
        tr.close() # to keep changes in this transaction (e.g. dirstate)
        raise
    _finalizerelocate(repo, orig, dest, nodenew, tr)
    return nodenew

def _relocatecommit(repo, orig, commitmsg):
    if commitmsg is None:
        commitmsg = orig.description()
    extra = dict(orig.extra())
    if 'branch' in extra:
        del extra['branch']
    extra['rebase_source'] = orig.hex()

    backup = repo.ui.backupconfig('phases', 'new-commit')
    try:
        targetphase = max(orig.phase(), phases.draft)
        repo.ui.setconfig('phases', 'new-commit', targetphase, 'evolve')
        # Commit might fail if unresolved files exist
        nodenew = repo.commit(text=commitmsg, user=orig.user(),
                              date=orig.date(), extra=extra)
    finally:
        repo.ui.restoreconfig(backup)
    return nodenew

def _finalizerelocate(repo, orig, dest, nodenew, tr):
    destbookmarks = repo.nodebookmarks(dest.node())
    nodesrc = orig.node()
    oldbookmarks = repo.nodebookmarks(nodesrc)
    bmchanges = []

    if nodenew is not None:
        compat.createmarkers(repo, [(repo[nodesrc], (repo[nodenew],))],
                             operation='evolve')
        for book in oldbookmarks:
            bmchanges.append((book, nodenew))
    else:
        compat.createmarkers(repo, [(repo[nodesrc], ())], operation='evolve')
        # Behave like rebase, move bookmarks to dest
        for book in oldbookmarks:
            bmchanges.append((book, dest.node()))
    for book in destbookmarks: # restore bookmark that rebase move
        bmchanges.append((book, dest.node()))
    if bmchanges:
        compat.bookmarkapplychanges(repo, tr, bmchanges)

def _evolvemerge(repo, orig, dest, pctx, keepbranch):
    """Used by the evolve function to merge dest on top of pctx.
    return the same tuple as merge.graft"""
    if repo['.'].rev() != dest.rev():
        merge.update(repo,
                     dest,
                     branchmerge=False,
                     force=True)
    if repo._activebookmark:
        repo.ui.status(_("(leaving bookmark %s)\n") % repo._activebookmark)
    bookmarksmod.deactivate(repo)
    if keepbranch:
        repo.dirstate.setbranch(orig.branch())
    if util.safehasattr(repo, 'currenttopic'):
        # uurrgs
        # there no other topic setter yet
        if not orig.topic() and repo.vfs.exists('topic'):
                repo.vfs.unlink('topic')
        else:
            with repo.vfs.open('topic', 'w') as f:
                f.write(orig.topic())

    return merge.graft(repo, orig, pctx, ['destination', 'evolving'], True)

instabilities_map = {
    'contentdivergent': "content-divergent",
    'phasedivergent': "phase-divergent"
}

def _selectrevs(repo, allopt, revopt, anyopt, targetcat):
    """select troubles in repo matching according to given options"""
    revs = set()
    if allopt or revopt:
        revs = repo.revs("%s()" % targetcat)
        if revopt:
            revs = scmutil.revrange(repo, revopt) & revs
        elif not anyopt:
            topic = getattr(repo, 'currenttopic', '')
            if topic:
                revs = repo.revs('topic(%s)', topic) & revs
            elif targetcat == 'orphan':
                revs = _aspiringdescendant(repo,
                                           repo.revs('(.::) - obsolete()::'))
                revs = set(revs)
        if targetcat == 'contentdivergent':
            # Pick one divergent per group of divergents
            revs = _dedupedivergents(repo, revs)
    elif anyopt:
        revs = repo.revs('first(%s())' % (targetcat))
    elif targetcat == 'orphan':
        revs = set(_aspiringchildren(repo, repo.revs('(.::) - obsolete()::')))
        if 1 < len(revs):
            msg = "multiple evolve candidates"
            hint = (_("select one of %s with --rev")
                    % ', '.join([str(repo[r]) for r in sorted(revs)]))
            raise error.Abort(msg, hint=hint)
    elif instabilities_map.get(targetcat, targetcat) in repo['.'].instabilities():
        revs = set([repo['.'].rev()])
    return revs

def _dedupedivergents(repo, revs):
    """Dedupe the divergents revs in revs to get one from each group with the
    lowest revision numbers
    """
    repo = repo.unfiltered()
    res = set()
    # To not reevaluate divergents of the same group once one is encountered
    discarded = set()
    for rev in revs:
        if rev in discarded:
            continue
        divergent = repo[rev]
        base, others = divergentdata(divergent)
        othersrevs = [o.rev() for o in others]
        res.add(min([divergent.rev()] + othersrevs))
        discarded.update(othersrevs)
    return res

def divergentdata(ctx):
    """return base, other part of a conflict

    This only return the first one.

    XXX this woobly function won't survive XXX
    """
    repo = ctx._repo.unfiltered()
    for base in repo.set('reverse(allprecursors(%d))', ctx.rev()):
        newer = compat.successorssets(ctx._repo, base.node())
        # drop filter and solution including the original ctx
        newer = [n for n in newer if n and ctx.node() not in n]
        if newer:
            return base, tuple(ctx._repo[o] for o in newer[0])
    raise error.Abort(_("base of divergent changeset %s not found") % ctx,
                      hint=_('this case is not yet handled'))

def _aspiringdescendant(repo, revs):
    """Return a list of changectx which can be stabilized on top of pctx or
    one of its descendants recursively. Empty list if none can be found."""
    target = set(revs)
    result = set(target)
    paths = collections.defaultdict(set)
    for r in repo.revs('orphan() - %ld', revs):
        for d in _possibledestination(repo, r):
            paths[d].add(r)

    result = set(target)
    tovisit = list(revs)
    while tovisit:
        base = tovisit.pop()
        for unstable in paths[base]:
            if unstable not in result:
                tovisit.append(unstable)
                result.add(unstable)
    return sorted(result - target)

def _aspiringchildren(repo, revs):
    """Return a list of changectx which can be stabilized on top of pctx or
    one of its descendants. Empty list if none can be found."""
    target = set(revs)
    result = []
    for r in repo.revs('orphan() - %ld', revs):
        dest = _possibledestination(repo, r)
        if target & dest:
            result.append(r)
    return result

def _possibledestination(repo, rev):
    """return all changesets that may be a new parent for REV"""
    tonode = repo.changelog.node
    parents = repo.changelog.parentrevs
    torev = repo.changelog.rev
    dest = set()
    tovisit = list(parents(rev))
    while tovisit:
        r = tovisit.pop()
        succsets = compat.successorssets(repo, tonode(r))
        if not succsets:
            tovisit.extend(parents(r))
        else:
            # We should probably pick only one destination from split
            # (case where '1 < len(ss)'), This could be the currently tipmost
            # but logic is less clear when result of the split are now on
            # multiple branches.
            for ss in succsets:
                for n in ss:
                    dest.add(torev(n))
    return dest

def _handlenotrouble(ui, repo, allopt, revopt, anyopt, targetcat):
    """Used by the evolve function to display an error message when
    no troubles can be resolved"""
    troublecategories = ['phasedivergent', 'contentdivergent', 'orphan']
    unselectedcategories = [c for c in troublecategories if c != targetcat]
    msg = None
    hint = None

    troubled = {
        "orphan": repo.revs("orphan()"),
        "contentdivergent": repo.revs("contentdivergent()"),
        "phasedivergent": repo.revs("phasedivergent()"),
        "all": repo.revs("troubled()"),
    }

    hintmap = {
        'phasedivergent': _("do you want to use --phase-divergent"),
        'phasedivergent+contentdivergent': _("do you want to use "
                                             "--phase-divergent or"
                                             " --content-divergent"),
        'phasedivergent+orphan': _("do you want to use --phase-divergent"
                                   " or --orphan"),
        'contentdivergent': _("do you want to use --content-divergent"),
        'contentdivergent+orphan': _("do you want to use --content-divergent"
                                     " or --orphan"),
        'orphan': _("do you want to use --orphan"),
        'any+phasedivergent': _("do you want to use --any (or --rev) and"
                                " --phase-divergent"),
        'any+phasedivergent+contentdivergent': _("do you want to use --any"
                                                 " (or --rev) and"
                                                 " --phase-divergent or"
                                                 " --content-divergent"),
        'any+phasedivergent+orphan': _("do you want to use --any (or --rev)"
                                       " and --phase-divergent or --orphan"),
        'any+contentdivergent': _("do you want to use --any (or --rev) and"
                                  " --content-divergent"),
        'any+contentdivergent+orphan': _("do you want to use --any (or --rev)"
                                         " and --content-divergent or "
                                         "--orphan"),
        'any+orphan': _("do you want to use --any (or --rev)"
                        "and --orphan"),
    }

    if revopt:
        revs = scmutil.revrange(repo, revopt)
        if not revs:
            msg = _("set of specified revisions is empty")
        else:
            msg = _("no %s changesets in specified revisions") % targetcat
            othertroubles = []
            for cat in unselectedcategories:
                if revs & troubled[cat]:
                    othertroubles.append(cat)
            if othertroubles:
                hint = hintmap['+'.join(othertroubles)]

    elif anyopt:
        msg = _("no %s changesets to evolve") % targetcat
        othertroubles = []
        for cat in unselectedcategories:
            if troubled[cat]:
                othertroubles.append(cat)
        if othertroubles:
            hint = hintmap['+'.join(othertroubles)]

    else:
        # evolve without any option = relative to the current wdir
        if targetcat == 'orphan':
            msg = _("nothing to evolve on current working copy parent")
        else:
            msg = _("current working copy parent is not %s") % targetcat

        p1 = repo['.'].rev()
        othertroubles = []
        for cat in unselectedcategories:
            if p1 in troubled[cat]:
                othertroubles.append(cat)
        if othertroubles:
            hint = hintmap['+'.join(othertroubles)]
        else:
            length = len(troubled[targetcat])
            if length:
                hint = _("%d other %s in the repository, do you want --any "
                         "or --rev") % (length, targetcat)
            else:
                othertroubles = []
                for cat in unselectedcategories:
                    if troubled[cat]:
                        othertroubles.append(cat)
                if othertroubles:
                    hint = hintmap['any+' + ('+'.join(othertroubles))]
                else:
                    msg = _("no troubled changesets")

    assert msg is not None
    ui.write_err("%s\n" % msg)
    if hint:
        ui.write_err("(%s)\n" % hint)
        return 2
    else:
        return 1

def _preparelistctxs(items, condition):
    return [item.hex() for item in items if condition(item)]

def _formatctx(fm, ctx):
    fm.data(node=ctx.hex())
    fm.data(desc=ctx.description())
    fm.data(date=ctx.date())
    fm.data(user=ctx.user())

def listtroubles(ui, repo, troublecategories, **opts):
    """Print all the troubles for the repo (or given revset)"""
    troublecategories = troublecategories or ['contentdivergent', 'orphan', 'phasedivergent']
    showunstable = 'orphan' in troublecategories
    showbumped = 'phasedivergent' in troublecategories
    showdivergent = 'contentdivergent' in troublecategories

    revs = repo.revs('+'.join("%s()" % t for t in troublecategories))
    if opts.get('rev'):
        revs = scmutil.revrange(repo, opts.get('rev'))

    fm = ui.formatter('evolvelist', opts)
    for rev in revs:
        ctx = repo[rev]
        unpars = _preparelistctxs(ctx.parents(), lambda p: p.orphan())
        obspars = _preparelistctxs(ctx.parents(), lambda p: p.obsolete())
        imprecs = _preparelistctxs(repo.set("allprecursors(%n)", ctx.node()),
                                   lambda p: not p.mutable())
        dsets = divergentsets(repo, ctx)

        fm.startitem()
        # plain formatter section
        hashlen, desclen = 12, 60
        desc = ctx.description()
        if desc:
            desc = desc.splitlines()[0]
        desc = (desc[:desclen] + '...') if len(desc) > desclen else desc
        fm.plain('%s: ' % ctx.hex()[:hashlen])
        fm.plain('%s\n' % desc)
        fm.data(node=ctx.hex(), rev=ctx.rev(), desc=desc, phase=ctx.phasestr())

        for unpar in unpars if showunstable else []:
            fm.plain('  %s: %s (%s parent)\n' % (TROUBLES['ORPHAN'],
                                                 unpar[:hashlen],
                                                 TROUBLES['ORPHAN']))
        for obspar in obspars if showunstable else []:
            fm.plain('  %s: %s (obsolete parent)\n' % (TROUBLES['ORPHAN'],
                                                       obspar[:hashlen]))
        for imprec in imprecs if showbumped else []:
            fm.plain('  %s: %s (immutable precursor)\n' %
                     (TROUBLES['PHASEDIVERGENT'], imprec[:hashlen]))

        if dsets and showdivergent:
            for dset in dsets:
                fm.plain('  %s: ' % TROUBLES['CONTENTDIVERGENT'])
                first = True
                for n in dset['divergentnodes']:
                    t = "%s (%s)" if first else " %s (%s)"
                    first = False
                    fm.plain(t % (node.hex(n)[:hashlen], repo[n].phasestr()))
                comprec = node.hex(dset['commonprecursor'])[:hashlen]
                fm.plain(" (precursor %s)\n" % comprec)
        fm.plain("\n")

        # templater-friendly section
        _formatctx(fm, ctx)
        troubles = []
        for unpar in unpars:
            troubles.append({'troubletype': TROUBLES['ORPHAN'],
                             'sourcenode': unpar, 'sourcetype': 'orphanparent'})
        for obspar in obspars:
            troubles.append({'troubletype': TROUBLES['ORPHAN'],
                             'sourcenode': obspar,
                             'sourcetype': 'obsoleteparent'})
        for imprec in imprecs:
            troubles.append({'troubletype': TROUBLES['PHASEDIVERGENT'],
                             'sourcenode': imprec,
                             'sourcetype': 'immutableprecursor'})
        for dset in dsets:
            divnodes = [{'node': node.hex(n),
                         'phase': repo[n].phasestr(),
                        } for n in dset['divergentnodes']]
            troubles.append({'troubletype': TROUBLES['CONTENTDIVERGENT'],
                             'commonprecursor': node.hex(dset['commonprecursor']),
                             'divergentnodes': divnodes})
        fm.data(troubles=troubles)

    fm.end()

def _checkevolveopts(repo, opts):
    """ check the options passed to `hg evolve` and warn for deprecation warning
    if any """

    if opts['continue']:
        if opts['any']:
            raise error.Abort(_('cannot specify both "--any" and "--continue"'))
        if opts['all']:
            raise error.Abort(_('cannot specify both "--all" and "--continue"'))
        if opts['rev']:
            raise error.Abort(_('cannot specify both "--rev" and "--continue"'))
        if opts['stop']:
            raise error.Abort(_('cannot specify both "--stop" and'
                                ' "--continue"'))

    if opts['stop']:
        if opts['any']:
            raise error.Abort(_('cannot specify both "--any" and "--stop"'))
        if opts['all']:
            raise error.Abort(_('cannot specify both "--all" and "--stop"'))
        if opts['rev']:
            raise error.Abort(_('cannot specify both "--rev" and "--stop"'))

    if opts['rev']:
        if opts['any']:
            raise error.Abort(_('cannot specify both "--rev" and "--any"'))
        if opts['all']:
            raise error.Abort(_('cannot specify both "--rev" and "--all"'))

    # Backward compatibility
    if opts['unstable']:
        msg = ("'evolve --unstable' is deprecated, "
               "use 'evolve --orphan'")
        repo.ui.deprecwarn(msg, '4.4')

        opts['orphan'] = opts['divergent']

    if opts['divergent']:
        msg = ("'evolve --divergent' is deprecated, "
               "use 'evolve --content-divergent'")
        repo.ui.deprecwarn(msg, '4.4')

        opts['content_divergent'] = opts['divergent']

    if opts['bumped']:
        msg = ("'evolve --bumped' is deprecated, "
               "use 'evolve --phase-divergent'")
        repo.ui.deprecwarn(msg, '4.4')

        opts['phase_divergent'] = opts['bumped']

    return opts

def _cleanup(ui, repo, startnode, showprogress):
    if showprogress:
        ui.progress(_('evolve'), None)
    if repo['.'] != startnode:
        ui.status(_('working directory is now at %s\n') % repo['.'])

def divergentsets(repo, ctx):
    """Compute sets of commits divergent with a given one"""
    cache = {}
    base = {}
    for n in compat.allprecursors(repo.obsstore, [ctx.node()]):
        if n == ctx.node():
            # a node can't be a base for divergence with itself
            continue
        nsuccsets = compat.successorssets(repo, n, cache)
        for nsuccset in nsuccsets:
            if ctx.node() in nsuccset:
                # we are only interested in *other* successor sets
                continue
            if tuple(nsuccset) in base:
                # we already know the latest base for this divergency
                continue
            base[tuple(nsuccset)] = n
    divergence = []
    for divset, b in base.iteritems():
        divergence.append({
            'divergentnodes': divset,
            'commonprecursor': b
        })

    return divergence

@eh.command(
    '^evolve|stabilize|solve',
    [('n', 'dry-run', False,
      _('do not perform actions, just print what would be done')),
     ('', 'confirm', False,
      _('ask for confirmation before performing the action')),
     ('A', 'any', False,
      _('also consider troubled changesets unrelated to current working '
        'directory')),
     ('r', 'rev', [], _('solves troubles of these revisions')),
     ('', 'bumped', False, _('solves only bumped changesets')),
     ('', 'phase-divergent', False, _('solves only phase-divergent changesets')),
     ('', 'divergent', False, _('solves only divergent changesets')),
     ('', 'content-divergent', False, _('solves only content-divergent changesets')),
     ('', 'unstable', False, _('solves only unstable changesets')),
     ('', 'orphan', False, _('solves only orphan changesets (default)')),
     ('a', 'all', False, _('evolve all troubled changesets related to the '
                           'current  working directory and its descendants')),
     ('c', 'continue', False, _('continue an interrupted evolution')),
     ('', 'stop', False, _('stop the interrupted evolution')),
     ('l', 'list', False, 'provide details on troubled changesets in the repo'),
    ] + mergetoolopts,
    _('[OPTIONS]...')
)
def evolve(ui, repo, **opts):
    """solve troubled changesets in your repository

    Modifying history can lead to various types of troubled changesets:
    unstable, bumped, or divergent. The evolve command resolves your troubles
    by executing one of the following actions:

    - update working copy to a successor
    - rebase an unstable changeset
    - extract the desired changes from a bumped changeset
    - fuse divergent changesets back together

    If you pass no arguments, evolve works in automatic mode: it will execute a
    single action to reduce instability related to your working copy. There are
    two cases for this action. First, if the parent of your working copy is
    obsolete, evolve updates to the parent's successor. Second, if the working
    copy parent is not obsolete but has obsolete predecessors, then evolve
    determines if there is an unstable changeset that can be rebased onto the
    working copy parent in order to reduce instability.
    If so, evolve rebases that changeset. If not, evolve refuses to guess your
    intention, and gives a hint about what you might want to do next.

    Any time evolve creates a changeset, it updates the working copy to the new
    changeset. (Currently, every successful evolve operation involves an update
    as well; this may change in future.)

    Automatic mode only handles common use cases. For example, it avoids taking
    action in the case of ambiguity, and it ignores unstable changesets that
    are not related to your working copy.
    It also refuses to solve bumped or divergent changesets unless you
    explicitly request such behavior (see below).

    Eliminating all instability around your working copy may require multiple
    invocations of :hg:`evolve`. Alternately, use ``--all`` to recursively
    select and evolve all unstable changesets that can be rebased onto the
    working copy parent.
    This is more powerful than successive invocations, since ``--all`` handles
    ambiguous cases (e.g. unstable changesets with multiple children) by
    evolving all branches.

    When your repository cannot be handled by automatic mode, you might need to
    use ``--rev`` to specify a changeset to evolve. For example, if you have
    an unstable changeset that is not related to the working copy parent,
    you could use ``--rev`` to evolve it. Or, if some changeset has multiple
    unstable children, evolve in automatic mode refuses to guess which one to
    evolve; you have to use ``--rev`` in that case.

    Alternately, ``--any`` makes evolve search for the next evolvable changeset
    regardless of whether it is related to the working copy parent.

    You can supply multiple revisions to evolve multiple troubled changesets
    in a single invocation. In revset terms, ``--any`` is equivalent to ``--rev
    first(unstable())``. ``--rev`` and ``--all`` are mutually exclusive, as are
    ``--rev`` and ``--any``.

    ``hg evolve --any --all`` is useful for cleaning up instability across all
    branches, letting evolve figure out the appropriate order and destination.

    When you have troubled changesets that are not unstable, :hg:`evolve`
    refuses to consider them unless you specify the category of trouble you
    wish to resolve, with ``--bumped`` or ``--divergent``. These options are
    currently mutually exclusive with each other and with ``--unstable``
    (the default). You can combine ``--bumped`` or ``--divergent`` with
    ``--rev``, ``--all``, or ``--any``.

    You can also use the evolve command to list the troubles affecting your
    repository by using the --list flag. You can choose to display only some
    categories of troubles with the --unstable, --divergent or --bumped flags.
    """

    opts = _checkevolveopts(repo, opts)
    # Options
    contopt = opts['continue']
    anyopt = opts['any']
    allopt = opts['all']
    startnode = repo['.']
    dryrunopt = opts['dry_run']
    confirmopt = opts['confirm']
    revopt = opts['rev']
    stopopt = opts['stop']

    troublecategories = ['phase_divergent', 'content_divergent', 'orphan']
    specifiedcategories = [t.replace('_', '')
                           for t in troublecategories
                           if opts[t]]
    if opts['list']:
        compat.startpager(ui, 'evolve')
        listtroubles(ui, repo, specifiedcategories, **opts)
        return

    targetcat = 'orphan'
    if 1 < len(specifiedcategories):
        msg = _('cannot specify more than one trouble category to solve (yet)')
        raise error.Abort(msg)
    elif len(specifiedcategories) == 1:
        targetcat = specifiedcategories[0]
    elif repo['.'].obsolete():
        displayer = compat.changesetdisplayer(ui, repo,
                                              {'template': shorttemplate})
        # no args and parent is obsolete, update to successors
        try:
            ctx = repo[utility._singlesuccessor(repo, repo['.'])]
        except utility.MultipleSuccessorsError as exc:
            repo.ui.write_err(_('parent is obsolete with multiple'
                                ' successors:\n'))
            for ln in exc.successorssets:
                for n in ln:
                    displayer.show(repo[n])
            return 2

        ui.status(_('update:'))
        if not ui.quiet:
            displayer.show(ctx)

        if dryrunopt:
            return 0
        res = hg.update(repo, ctx.rev())
        if ctx != startnode:
            ui.status(_('working directory is now at %s\n') % ctx)
        return res

    ui.setconfig('ui', 'forcemerge', opts.get('tool', ''), 'evolve')
    troubled = set(repo.revs('troubled()'))

    # Progress handling
    seen = 1
    count = allopt and len(troubled) or 1
    showprogress = allopt

    def progresscb():
        if revopt or allopt:
            ui.progress(_('evolve'), seen, unit=_('changesets'), total=count)

    evolvestate = state.cmdstate(repo)
    # Continuation handling
    if contopt:
        if not evolvestate:
            raise error.Abort(_('no interrupted evolve to continue'))
        evolvestate.load()
        continueevolve(ui, repo, evolvestate, progresscb)
        if evolvestate['command'] != 'evolve':
            evolvestate.delete()
            return
        startnode = repo.unfiltered()[evolvestate['startnode']]
        evolvestate.delete()
    elif stopopt:
        if not evolvestate:
            raise error.Abort(_('no interrupted evolve to stop'))
        evolvestate.load()
        pctx = repo['.']
        hg.updaterepo(repo, pctx.node(), True)
        ui.status(_('stopped the interrupted evolve\n'))
        ui.status(_('working directory is now at %s\n') % pctx)
        evolvestate.delete()
        return
    else:
        cmdutil.bailifchanged(repo)

        revs = _selectrevs(repo, allopt, revopt, anyopt, targetcat)

        if not revs:
            return _handlenotrouble(ui, repo, allopt, revopt, anyopt, targetcat)

        # For the progress bar to show
        count = len(revs)
        # Order the revisions
        if targetcat == 'orphan':
            revs = _orderrevs(repo, revs)

        # cbor does not know how to serialize sets, using list for skippedrevs
        stateopts = {'category': targetcat, 'replacements': {}, 'revs': revs,
                     'confirm': confirmopt, 'startnode': startnode.node(),
                     'skippedrevs': [], 'command': 'evolve', 'orphanmerge': False}
        evolvestate.addopts(stateopts)
        for rev in revs:
            curctx = repo[rev]
            progresscb()
            ret = _solveone(ui, repo, curctx, evolvestate, dryrunopt, confirmopt,
                            progresscb, targetcat)
            seen += 1
            if ret[0]:
                evolvestate['replacements'][curctx.node()] = [ret[1]]
            else:
                evolvestate['skippedrevs'].append(curctx.node())

            if evolvestate['orphanmerge']:
                # we were processing an orphan merge with both parents obsolete,
                # stabilized for second parent, re-stabilize for the first parent
                ret = _solveone(ui, repo, repo[ret[1]], evolvestate, dryrunopt,
                                confirmopt, progresscb, targetcat)
                if ret[0]:
                    evolvestate['replacements'][curctx.node()] = [ret[1]]
                else:
                    evolvestate['skippedrevs'].append(curctx.node())

                evolvestate['orphanmerge'] = False

    progresscb()
    _cleanup(ui, repo, startnode, showprogress)

def continueevolve(ui, repo, evolvestate, progresscb):
    """logic for handling of `hg evolve --continue`"""
    orig = repo[evolvestate['current']]
    with repo.wlock(), repo.lock():
        ctx = orig
        source = ctx.extra().get('source')
        extra = {}
        if source:
            extra['source'] = source
            extra['intermediate-source'] = ctx.hex()
        else:
            extra['source'] = ctx.hex()
        user = ctx.user()
        date = ctx.date()
        message = ctx.description()
        ui.status(_('evolving %d:%s "%s"\n') % (ctx.rev(), ctx,
                                                message.split('\n', 1)[0]))
        targetphase = max(ctx.phase(), phases.draft)
        overrides = {('phases', 'new-commit'): targetphase}

        ctxparents = orig.parents()
        if len(ctxparents) == 2:
            currentp1 = repo.dirstate.parents()[0]
            p1obs = ctxparents[0].obsolete()
            p2obs = ctxparents[1].obsolete()
            # asumming that the parent of current wdir is successor of one
            # of p1 or p2 of the original changeset
            if p1obs and not p2obs:
                # p1 is obsolete and p2 is not obsolete, current working
                # directory parent should be successor of p1, so we should
                # set dirstate parents to (succ of p1, p2)
                with repo.dirstate.parentchange():
                    repo.dirstate.setparents(currentp1,
                                             ctxparents[1].node())
            elif p2obs and not p1obs:
                # p2 is obsolete and p1 is not obsolete, current working
                # directory parent should be successor of p2, so we should
                # set dirstate parents to (succ of p2, p1)
                with repo.dirstate.parentchange():
                    repo.dirstate.setparents(ctxparents[0].node(),
                                             currentp1)

            else:
                # both the parents were obsoleted, if orphanmerge is set, we
                # are processing the second parent first (to keep parent order)
                if evolvestate.get('orphanmerge'):
                    with repo.dirstate.parentchange():
                        repo.dirstate.setparents(ctxparents[0].node(),
                                                 currentp1)
                pass

        with repo.ui.configoverride(overrides, 'evolve-continue'):
            node = repo.commit(text=message, user=user,
                               date=date, extra=extra)

        # resolving conflicts can lead to empty wdir and node can be None in
        # those cases
        newctx = repo[node] if node is not None else repo['.']
        compat.createmarkers(repo, [(ctx, (newctx,))], operation='evolve')

        # make sure we are continuing evolve and not `hg next --evolve`
        if evolvestate['command'] == 'evolve':
            evolvestate['replacements'][ctx.node()] = node
            category = evolvestate['category']
            confirm = evolvestate['confirm']
            unfi = repo.unfiltered()
            if evolvestate['orphanmerge']:
                # processing a merge changeset with both parents obsoleted,
                # stabilized on second parent, insert in front of list to
                # re-process to stabilize on first parent
                evolvestate['revs'].insert(0, repo[node].rev())
                evolvestate['orphanmerge'] = False
            for rev in evolvestate['revs']:
                # XXX: prevent this lookup by storing nodes instead of revnums
                curctx = unfi[rev]
                if (curctx.node() not in evolvestate['replacements'] and
                    curctx.node() not in evolvestate['skippedrevs']):
                    newnode = _solveone(ui, repo, curctx, evolvestate, False,
                                        confirm, progresscb, category)
                    if newnode[0]:
                        evolvestate['replacements'][curctx.node()] = newnode[1]
                    else:
                        evolvestate['skippedrevs'].append(curctx.node())
        return
