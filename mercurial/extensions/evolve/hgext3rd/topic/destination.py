from __future__ import absolute_import

from mercurial.i18n import _
from mercurial import (
    bookmarks,
    destutil,
    error,
    extensions,
)
from . import topicmap
from .evolvebits import builddependencies

def _destmergebranch(orig, repo, action='merge', sourceset=None,
                     onheadcheck=True, destspace=None):
    # XXX: take destspace into account
    if sourceset is None:
        p1 = repo['.']
    else:
        # XXX: using only the max here is flacky. That code should eventually
        # be updated to take care of the whole sourceset.
        p1 = repo[max(sourceset)]
    top = p1.topic()
    if top:
        revs = repo.revs('topic(%s) - obsolete()', top)
        deps, rdeps = builddependencies(repo, revs)
        heads = [r for r in revs if not rdeps[r]]
        if onheadcheck and p1.rev() not in heads:
            raise error.Abort(_("not at topic head, update or explicit"))

        # prune heads above the source
        otherheads = set(heads)
        pool = set([p1.rev()])
        while pool:
            current = pool.pop()
            otherheads.discard(current)
            pool.update(rdeps[current])
        if not otherheads:
            # nothing to do at the topic level
            bhead = ngtip(repo, p1.branch(), all=True)
            if not bhead:
                raise error.NoMergeDestAbort(_("nothing to merge"))
            elif 1 == len(bhead):
                return bhead[0]
            else:
                msg = _("branch '%s' has %d heads "
                        "- please merge with an explicit rev")
                hint = _("run 'hg heads .' to see heads")
                raise error.ManyMergeDestAbort(msg % (p1.branch(), len(bhead)),
                                               hint=hint)
        elif len(otherheads) == 1:
            return otherheads.pop()
        else:
            msg = _("topic '%s' has %d heads "
                    "- please merge with an explicit rev") % (top, len(heads))
            raise error.ManyMergeDestAbort(msg)
    return orig(repo, action, sourceset, onheadcheck, destspace=destspace)

def _destupdatetopic(repo, clean, check=None):
    """decide on an update destination from current topic"""
    movemark = node = None
    topic = repo.currenttopic
    revs = repo.revs('.::topic("%s")' % topic)
    if not revs:
        return None, None, None
    node = revs.last()
    if bookmarks.isactivewdirparent(repo):
        movemark = repo['.'].node()
    return node, movemark, None

def desthistedit(orig, ui, repo):
    if not (ui.config('histedit', 'defaultrev', None) is None
            and repo.currenttopic):
        return orig(ui, repo)
    revs = repo.revs('::. and stack()')
    if revs:
        return revs.min()
    return None

def ngtip(repo, branch, all=False):
    """tip new generation"""
    ## search for untopiced heads of branch
    # could be heads((::branch(x) - topic()))
    # but that is expensive
    #
    # we should write plain code instead

    tmap = topicmap.gettopicrepo(repo).branchmap()
    if branch not in tmap:
        return []
    elif all:
        return tmap.branchheads(branch)
    else:
        return [tmap.branchtip(branch)]

def modsetup(ui):
    """run a uisetup time to install all destinations wrapping"""
    extensions.wrapfunction(destutil, '_destmergebranch', _destmergebranch)
    bridx = destutil.destupdatesteps.index('branch')
    destutil.destupdatesteps.insert(bridx, 'topic')
    destutil.destupdatestepmap['topic'] = _destupdatetopic
    extensions.wrapfunction(destutil, 'desthistedit', desthistedit)
