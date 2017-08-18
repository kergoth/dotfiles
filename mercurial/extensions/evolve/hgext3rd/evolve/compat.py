# Copyright 2017 Octobus <contact@octobus.net>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""
Compatibility module
"""

from mercurial import (
    hg,
    obsolete,
    util,
)

try:
    from mercurial import obsutil
    obsutil.closestpredecessors
except ImportError:
    obsutil = None

from . import (
    exthelper,
)

eh = exthelper.exthelper()

if not util.safehasattr(hg, '_copycache'):
    # exact copy of relevantmarkers as in Mercurial-176d1a0ce385
    # this fixes relevant markers computation for version < hg-4.3
    @eh.wrapfunction(obsolete.obsstore, 'relevantmarkers')
    def relevantmarkers(orig, self, nodes):
        """return a set of all obsolescence markers relevant to a set of nodes.

        "relevant" to a set of nodes mean:

        - marker that use this changeset as successor
        - prune marker of direct children on this changeset
        - recursive application of the two rules on precursors of these markers

        It is a set so you cannot rely on order.

        Backport of mercurial changeset 176d1a0ce385 for version < 4.3
        """

        pendingnodes = set(nodes)
        seenmarkers = set()
        seennodes = set(pendingnodes)
        precursorsmarkers = self.precursors
        succsmarkers = self.successors
        children = self.children
        while pendingnodes:
            direct = set()
            for current in pendingnodes:
                direct.update(precursorsmarkers.get(current, ()))
                pruned = [m for m in children.get(current, ()) if not m[1]]
                direct.update(pruned)
                pruned = [m for m in succsmarkers.get(current, ()) if not m[1]]
                direct.update(pruned)
            direct -= seenmarkers
            pendingnodes = set([m[0] for m in direct])
            seenmarkers |= direct
            pendingnodes -= seennodes
            seennodes |= pendingnodes
        return seenmarkers

# successors set move from mercurial.obsolete to mercurial.obsutil in 4.3
def successorssets(*args, **kwargs):
    func = getattr(obsutil, 'successorssets', None)
    if func is None:
        func = obsolete.successorssets
    return func(*args, **kwargs)

# allprecursors set move from mercurial.obsolete to mercurial.obsutil in 4.3
def allprecursors(*args, **kwargs):
    func = getattr(obsutil, 'allprecursors', None)
    if func is None:
        func = obsolete.allprecursors
    return func(*args, **kwargs)

# compatibility layer for mercurial < 4.3
def bookmarkapplychanges(repo, tr, changes):
    """Apply a list of changes to bookmarks
    """
    bookmarks = repo._bookmarks
    if util.safehasattr(bookmarks, 'applychanges'):
        return bookmarks.applychanges(repo, tr, changes)
    for name, node in changes:
        if node is None:
            del bookmarks[name]
        else:
            bookmarks[name] = node
    bookmarks.recordchange(tr)
