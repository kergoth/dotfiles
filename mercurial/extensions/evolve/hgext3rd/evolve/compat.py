# Copyright 2017 Octobus <contact@octobus.net>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""
Compatibility module
"""

import inspect

import functools

from mercurial import (
    copies,
    context,
    hg,
    mdiff,
    obsolete,
    revset,
    util,
    wireproto,
)
from mercurial.hgweb import hgweb_mod

# hg < 4.2 compat
try:
    from mercurial import vfs as vfsmod
    vfsmod.vfs
except ImportError:
    from mercurial import scmutil as vfsmod

try:
    from mercurial import obsutil
    obsutil.closestpredecessors
except ImportError:
    obsutil = None

# hg < 4.6 compat (c8e2d6ed1f9e)
try:
    from mercurial import logcmdutil
    changesetdisplayer = logcmdutil.changesetdisplayer
    changesetprinter = logcmdutil.changesetprinter
    displaygraph = logcmdutil.displaygraph
except (AttributeError, ImportError):
    from mercurial import cmdutil
    changesetdisplayer = cmdutil.show_changeset
    changesetprinter = cmdutil.changeset_printer
    displaygraph = cmdutil.displaygraph

from . import (
    exthelper,
)

eh = exthelper.exthelper()

# Wrap obsolete.creatmarkers and make it accept but ignore "operation" argument
# for hg < 4.3
originalcreatemarkers = obsolete.createmarkers
while isinstance(originalcreatemarkers, functools.partial):
    originalcreatemarkers = originalcreatemarkers.func
if originalcreatemarkers.__code__.co_argcount < 6:
    def createmarkers(repo, relations, flag=0, date=None, metadata=None,
                      operation=None):
        return obsolete.createmarkers(repo, relations, flag, date, metadata)
else:
    def createmarkers(*args, **kwargs):
        return obsolete.createmarkers(*args, **kwargs)

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
        precursorsmarkers = self.predecessors
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
# allprecursors  was renamed into allpredecessors in 4.4
def allprecursors(*args, **kwargs):
    func = getattr(obsutil, 'allpredecessors', None)
    if func is None:
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

def isobsnotesupported():
    # hack to know obsnote is supported. The patches for obsnote support was
    # pushed before the obsfateprinter patches, so this will serve as a good
    # check
    if not obsutil:
        return False
    return util.safehasattr(obsutil, 'obsfateprinter')

# Evolution renaming compat

TROUBLES = {}

if not util.safehasattr(context.basectx, 'orphan'):
    TROUBLES['ORPHAN'] = 'unstable'
    context.basectx.orphan = context.basectx.unstable
else:
    TROUBLES['ORPHAN'] = 'orphan'

if not util.safehasattr(context.basectx, 'contentdivergent'):
    TROUBLES['CONTENTDIVERGENT'] = 'divergent'
    context.basectx.contentdivergent = context.basectx.divergent
else:
    TROUBLES['CONTENTDIVERGENT'] = 'content-divergent'

if not util.safehasattr(context.basectx, 'phasedivergent'):
    TROUBLES['PHASEDIVERGENT'] = 'bumped'
    context.basectx.phasedivergent = context.basectx.bumped
else:
    TROUBLES['PHASEDIVERGENT'] = 'phase-divergent'

if not util.safehasattr(context.basectx, 'isunstable'):
    context.basectx.isunstable = context.basectx.troubled

if not util.safehasattr(revset, 'orphan'):
    @eh.revset('orphan')
    def oprhanrevset(*args, **kwargs):
        return revset.unstable(*args, **kwargs)

if not util.safehasattr(revset, 'contentdivergent'):
    @eh.revset('contentdivergent')
    def contentdivergentrevset(*args, **kwargs):
        return revset.divergent(*args, **kwargs)

if not util.safehasattr(revset, 'phasedivergent'):
    @eh.revset('phasedivergent')
    def phasedivergentrevset(*args, **kwargs):
        return revset.bumped(*args, **kwargs)

if not util.safehasattr(context.basectx, 'instabilities'):
    def instabilities(self):
        """return the list of instabilities affecting this changeset.

        Instabilities are returned as strings. possible values are:
         - orphan,
         - phase-divergent,
         - content-divergent.
         """
        instabilities = []
        if self.orphan():
            instabilities.append('orphan')
        if self.phasedivergent():
            instabilities.append('phase-divergent')
        if self.contentdivergent():
            instabilities.append('content-divergent')
        return instabilities

    context.basectx.instabilities = instabilities

# XXX: Better detection of property cache
if 'predecessors' not in dir(obsolete.obsstore):
    @property
    def predecessors(self):
        return self.precursors

    obsolete.obsstore.predecessors = predecessors

if not util.safehasattr(obsolete, '_computeorphanset'):
    obsolete._computeorphanset = obsolete.cachefor('orphan')(obsolete._computeunstableset)

if not util.safehasattr(obsolete, '_computecontentdivergentset'):
    obsolete._computecontentdivergentset = obsolete.cachefor('contentdivergent')(obsolete._computedivergentset)

if not util.safehasattr(obsolete, '_computephasedivergentset'):
    obsolete._computephasedivergentset = obsolete.cachefor('phasedivergent')(obsolete._computebumpedset)

def startpager(ui, cmd):
    """function to start a pager in case ui.pager() exists"""
    if util.safehasattr(ui, 'pager'):
        ui.pager(cmd)

def duplicatecopies(repo, wctx, rev, fromrev, skiprev=None):
    # cannot use anything else until 4.3 support is dropped.
    assert wctx.rev() is None
    if copies.duplicatecopies.__code__.co_argcount < 5:
        # pre 4.4 duplicatecopies compat
        copies.duplicatecopies(repo, rev, fromrev, skiprev=skiprev)
    else:
        copies.duplicatecopies(repo, wctx, rev, fromrev, skiprev=skiprev)

def memfilectx(repo, ctx, fctx, flags, copied, path):
    # XXX Would it be better at the module level?
    varnames = context.memfilectx.__init__.__code__.co_varnames
    ctxmandatory = varnames[2] == "changectx"

    if ctxmandatory:
        mctx = context.memfilectx(repo, ctx, fctx.path(), fctx.data(),
                                  islink='l' in flags,
                                  isexec='x' in flags,
                                  copied=copied.get(path))
    else:
        mctx = context.memfilectx(repo, fctx.path(), fctx.data(),
                                  islink='l' in flags,
                                  isexec='x' in flags,
                                  copied=copied.get(path))
    return mctx

def getcachevfs(repo):
    cachevfs = getattr(repo, 'cachevfs', None)
    if cachevfs is None:
        cachevfs = vfsmod.vfs(repo.vfs.join('cache'))
        cachevfs.createmode = repo.store.createmode
    return cachevfs

def strdiff(a, b, fn1, fn2):
    """ A version of mdiff.unidiff for comparing two strings
    """
    args = [a, '', b, '', fn1, fn2]

    # hg < 4.6 compat 8b6dd3922f70
    argspec = inspect.getargspec(mdiff.unidiff)

    if 'binary' in argspec.args:
        args.append(False)

    return mdiff.unidiff(*args)

# date related

try:
    import mercurial.utils.dateutil
    makedate = mercurial.utils.dateutil.makedate
    parsedate = mercurial.utils.dateutil.parsedate
except ImportError as e:
    import mercurial.util
    makedate = mercurial.util.makedate
    parsedate = mercurial.util.parsedate

def wireprotocommand(exthelper, name, args='', permission='pull'):
    if 3 <= len(wireproto.wireprotocommand.func_defaults):
        return wireproto.wireprotocommand(name, args, permission=permission)

    else:
        # <= hg-4.5 permission must be registered in dictionnary
        def decorator(func):
            @eh.extsetup
            def install(ui):
                hgweb_mod.perms[name] = permission
                wireproto.commands[name] = (func, args)
        return decorator
