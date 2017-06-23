# Copyright 2011 Peter Arrenbrecht <peter.arrenbrecht@gmail.com>
#                Logilab SA        <contact@logilab.fr>
#                Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#                Patrick Mezard <patrick@mezard.eu>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""extends Mercurial feature related to Changeset Evolution

This extension:

- provides several commands to mutate history and deal with resulting issues,
- enable the changeset-evolution feature for Mercurial,
- improves some aspect of the early implementation in Mercurial core,

Note that a version dedicated to server usage only (no local working copy) is
available as 'evolve.serveronly'.

While many feature related to changeset evolution are directly handled by core
this extensions contains significant additions recommended to any user of
changeset evolution.

With the extensions various evolution events will display warning (new unstable
changesets, obsolete working copy parent, improved error when accessing hidden
revision, etc).

In addition, the extension contains better discovery protocol for obsolescence
markers. This means less obs-markers will have to be pushed and pulled around,
speeding up such operation.

Some improvement and bug fixes available in newer version of Mercurial are also
backported to older version of Mercurial by this extension. Some older
experimental protocol are also supported for a longer time in the extensions to
help people transitioning. (The extensions is currently compatible down to
Mercurial version 3.8).

New Config:

    [experimental]
    # Set to control the behavior when pushing draft changesets to a publishing
    # repository. Possible value:
    # * ignore: current core behavior (default)
    # * warn: proceed with the push, but issue a warning
    # * abort: abort the push
    auto-publish = ignore

    # For some large repository with few markers, the current  for obsolescence
    # markers discovery can get in the way. You can disable it with the
    # configuration option below. This means all pushes and pulls will
    # re-exchange all markers every time.
    evolution.obsdiscovery = yes

Obsolescence Markers Discovery Experiment
=========================================

We are experimenting with a new protocol to discover common markers between
local and remote repositories. This experiment is still at an early stage but
is already raising better results than the previous version (when usable).

"Large" repositories (hundreds of thousand) are currently unsupported. Some key
algorithm has a naive implementation with too agressive caching, creating
memory consumption issue (this will get fixed).

Medium sized repositories works fine, but be prepared for a noticable initial
cache filling. for the Mercurial repository, this is around 20 seconds

The following config control the experiment::

  [experimental]

  # enable new discovery protocol
  # (needed on both client and server)
  obshashrange = yes

  # avoid cache warming after transaction
  # (recommended 'off' for developer repositories)
  # (recommended 'yes' for server (default))
  obshashrange.warm-cache = no

It is recommended to enable the blackbox extension. It gather useful data about
the experiment. It is shipped with Mercurial so no extra install are needed.

    [extensions]
    blackbox =

Finally some extra options are available to help tame the experimental
implementation of some of the algorithms:

    [experimental]
    # restrict cache size to reduce memory consumption
    obshashrange.lru-size = 2000 # default is 2000

    # automatically disable obshashrange related computation and capabilities
    # if the repository has more than N revisions.  This is meant to help large
    # server deployement to enable the feature on smaller repositories while
    # ensuring no large repository will get affected.
    obshashrange.max-revs = 100000 # default is None

Effect Flag Experiment
======================

We are experimenting with a way to register what changed between a precursor
and its successors (content, description, parent, etc...). For example, having
this information is helpful to show what changed between an obsolete changeset
and its tipmost successors. This experiment is active by default

The following config control the experiment::

  [experimental]
  # deactivate the registration of effect flags in obs markers
  evolution.effect-flags = false

The effect flags are shown in the obglog command output without particular
configuration if you want to inspect them.

Templates
=========

Evolve ship several templates that you can use to have a better visibility
about your obs history:

  - precursors, for each obsolete changeset show the closest visible
    precursors.
  - successors, for each obsolete changeset show the closets visible
    successors. It is useful when your working directory is obsolete to see
    what are its successors. This informations can also be retrieved with the
    obslog command and the --all option.
  - obsfate, for each obsolete changeset display a line summarizing what
    changed between the changeset and its successors. Dependending on the
    verbosity level (-q and -v) it display the changeset successors, the users
    that created the obsmarkers and the date range of theses changes.

    The template itself is not complex, the data are basically a list of
    successortset. Each successorset is a dict with these fields:

      - "verb", how did the revision changed, pruned or rewritten for the moment
      - "users" a sorted list of users that have create obs marker between current
        changeset and one of its successor
      - "min_date" the tiniest date of the first obs marker between current
        changeset and one of its successor
      - "max_date" the biggest date between current changeset and one of its
        successor
      - "successors" a sorted list of locally know successors node ids
      - "markers" the raw list of changesets.
"""

evolutionhelptext = """
Obsolescence markers make it possible to mark changesets that have been
deleted or superset in a new version of the changeset.

Unlike the previous way of handling such changes, by stripping the old
changesets from the repository, obsolescence markers can be propagated
between repositories. This allows for a safe and simple way of exchanging
mutable history and altering it after the fact. Changeset phases are
respected, such that only draft and secret changesets can be altered (see
:hg:`help phases` for details).

Obsolescence is tracked using "obsolete markers", a piece of metadata
tracking which changesets have been made obsolete, potential successors for
a given changeset, the moment the changeset was marked as obsolete, and the
user who performed the rewriting operation. The markers are stored
separately from standard changeset data can be exchanged without any of the
precursor changesets, preventing unnecessary exchange of obsolescence data.

The complete set of obsolescence markers describes a history of changeset
modifications that is orthogonal to the repository history of file
modifications. This changeset history allows for detection and automatic
resolution of edge cases arising from multiple users rewriting the same part
of history concurrently.

Current feature status
======================

This feature is still in development.  If you see this help, you have enabled an
extension that turned this feature on.

Obsolescence markers will be exchanged between repositories that explicitly
assert support for the obsolescence feature (this can currently only be done
via an extension).""".strip()


import os
import sys
import random
import re
import collections
import errno
import struct

try:
    import StringIO as io
    StringIO = io.StringIO
except ImportError:
    import io
    StringIO = io.StringIO


try:
    from mercurial import registrar
    registrar.templatekeyword # new in hg-3.8
except ImportError:
    from . import metadata
    raise ImportError('evolve needs version %s or above' %
                      min(metadata.testedwith.split()))

import mercurial
from mercurial import util
from mercurial import repair

from mercurial import obsolete
if not obsolete._enabled:
    obsolete._enabled = True

from mercurial import (
    bookmarks as bookmarksmod,
    cmdutil,
    commands,
    context,
    copies,
    dirstate,
    error,
    extensions,
    help,
    hg,
    lock as lockmod,
    merge,
    node,
    obsolete,
    patch,
    phases,
    revset,
    scmutil,
)

from mercurial.commands import walkopts, commitopts, commitopts2, mergetoolopts
from mercurial.i18n import _
from mercurial.node import nullid

from . import (
    checkheads,
    compat,
    debugcmd,
    exthelper,
    metadata,
    obscache,
    obsexchange,
    obshistory,
    safeguard,
    templatekw,
    utility,
)

__version__ = metadata.__version__
testedwith = metadata.testedwith
minimumhgversion = metadata.minimumhgversion
buglink = metadata.buglink

sha1re = re.compile(r'\b[0-9a-f]{6,40}\b')

# Flags for enabling optional parts of evolve
commandopt = 'allnewcommands'

obsexcmsg = utility.obsexcmsg

colortable = {'evolve.node': 'yellow',
              'evolve.user': 'green',
              'evolve.rev': 'blue',
              'evolve.short_description': '',
              'evolve.date': 'cyan',
              'evolve.current_rev': 'bold',
              'evolve.verb': '',
              }

_pack = struct.pack
_unpack = struct.unpack

aliases, entry = cmdutil.findcmd('commit', commands.table)
interactiveopt = [['i', 'interactive', None, _('use interactive mode')]]
# This extension contains the following code
#
# - Extension Helper code
# - Obsolescence cache
# - ...
# - Older format compat

eh = exthelper.exthelper()
eh.merge(debugcmd.eh)
eh.merge(obsexchange.eh)
eh.merge(checkheads.eh)
eh.merge(safeguard.eh)
eh.merge(obscache.eh)
eh.merge(obshistory.eh)
eh.merge(templatekw.eh)
eh.merge(compat.eh)
uisetup = eh.final_uisetup
extsetup = eh.final_extsetup
reposetup = eh.final_reposetup
cmdtable = eh.cmdtable

# pre hg 4.0 compat

if not util.safehasattr(dirstate.dirstate, 'parentchange'):
    import contextlib

    @contextlib.contextmanager
    def parentchange(self):
        '''Context manager for handling dirstate parents.

        If an exception occurs in the scope of the context manager,
        the incoherent dirstate won't be written when wlock is
        released.
        '''
        self._parentwriters += 1
        yield
        # Typically we want the "undo" step of a context manager in a
        # finally block so it happens even when an exception
        # occurs. In this case, however, we only want to decrement
        # parentwriters if the code in the with statement exits
        # normally, so we don't have a try/finally here on purpose.
        self._parentwriters -= 1
    dirstate.dirstate.parentchange = parentchange

#####################################################################
### Option configuration                                          ###
#####################################################################

@eh.reposetup # must be the first of its kin.
def _configureoptions(ui, repo):
    # If no capabilities are specified, enable everything.
    # This is so existing evolve users don't need to change their config.
    evolveopts = ui.configlist('experimental', 'evolution')
    if not evolveopts:
        evolveopts = ['all']
        ui.setconfig('experimental', 'evolution', evolveopts, 'evolve')

@eh.uisetup
def _configurecmdoptions(ui):
    # Unregister evolve commands if the command capability is not specified.
    #
    # This must be in the same function as the option configuration above to
    # guarantee it happens after the above configuration, but before the
    # extsetup functions.
    evolvecommands = ui.configlist('experimental', 'evolutioncommands')
    evolveopts = ui.configlist('experimental', 'evolution')
    if evolveopts and (commandopt not in evolveopts and
                       'all' not in evolveopts):
        # We build whitelist containing the commands we want to enable
        whitelist = set()
        for cmd in evolvecommands:
            matchingevolvecommands = [e for e in cmdtable.keys() if cmd in e]
            if not matchingevolvecommands:
                raise error.Abort(_('unknown command: %s') % cmd)
            elif len(matchingevolvecommands) > 1:
                msg = _('ambiguous command specification: "%s" matches %r')
                raise error.Abort(msg % (cmd, matchingevolvecommands))
            else:
                whitelist.add(matchingevolvecommands[0])
        for disabledcmd in set(cmdtable) - whitelist:
            del cmdtable[disabledcmd]

#####################################################################
### experimental behavior                                         ###
#####################################################################

commitopts3 = [
    ('D', 'current-date', None,
     _('record the current date as commit date')),
    ('U', 'current-user', None,
     _('record the current user as committer')),
]

def _resolveoptions(ui, opts):
    """modify commit options dict to handle related options

    For now, all it does is figure out the commit date: respect -D unless
    -d was supplied.
    """
    # N.B. this is extremely similar to setupheaderopts() in mq.py
    if not opts.get('date') and opts.get('current_date'):
        opts['date'] = '%d %d' % util.makedate()
    if not opts.get('user') and opts.get('current_user'):
        opts['user'] = ui.username()

getrevs = obsolete.getrevs

#####################################################################
### Additional Utilities                                          ###
#####################################################################

# This section contains a lot of small utility function and method

# - Function to create markers
# - useful alias pstatus and pdiff (should probably go in evolve)
# - "troubles" method on changectx
# - function to travel through the obsolescence graph
# - function to find useful changeset to stabilize


### Useful alias

@eh.uisetup
def _installalias(ui):
    if ui.config('alias', 'pstatus', None) is None:
        ui.setconfig('alias', 'pstatus', 'status --rev .^', 'evolve')
    if ui.config('alias', 'pdiff', None) is None:
        ui.setconfig('alias', 'pdiff', 'diff --rev .^', 'evolve')
    if ui.config('alias', 'odiff', None) is None:
        ui.setconfig('alias', 'odiff',
                     "diff --hidden --rev 'limit(precursors(.),1)' --rev .",
                     'evolve')
    if ui.config('alias', 'grab', None) is None:
        if os.name == 'nt':
            ui.setconfig('alias', 'grab',
                         "! " + util.hgexecutable()
                         + " rebase --dest . --rev $@ && "
                         + util.hgexecutable() + " up tip",
                         'evolve')
        else:
            ui.setconfig('alias', 'grab',
                         "! $HG rebase --dest . --rev $@ && $HG up tip",
                         'evolve')


### Troubled revset symbol

@eh.revset('troubled')
def revsettroubled(repo, subset, x):
    """``troubled()``
    Changesets with troubles.
    """
    revset.getargs(x, 0, 0, 'troubled takes no arguments')
    troubled = set()
    troubled.update(getrevs(repo, 'unstable'))
    troubled.update(getrevs(repo, 'bumped'))
    troubled.update(getrevs(repo, 'divergent'))
    troubled = revset.baseset(troubled)
    troubled.sort() # set is non-ordered, enforce order
    return subset & troubled

### Obsolescence graph

# XXX SOME MAJOR CLEAN UP TO DO HERE XXX

def _precursors(repo, s):
    """Precursor of a changeset"""
    cs = set()
    nm = repo.changelog.nodemap
    markerbysubj = repo.obsstore.precursors
    node = repo.changelog.node
    for r in s:
        for p in markerbysubj.get(node(r), ()):
            pr = nm.get(p[0])
            if pr is not None:
                cs.add(pr)
    cs -= repo.changelog.filteredrevs # nodemap has no filtering
    return cs

def _allprecursors(repo, s):  # XXX we need a better naming
    """transitive precursors of a subset"""
    node = repo.changelog.node
    toproceed = [node(r) for r in s]
    seen = set()
    allsubjects = repo.obsstore.precursors
    while toproceed:
        nc = toproceed.pop()
        for mark in allsubjects.get(nc, ()):
            np = mark[0]
            if np not in seen:
                seen.add(np)
                toproceed.append(np)
    nm = repo.changelog.nodemap
    cs = set()
    for p in seen:
        pr = nm.get(p)
        if pr is not None:
            cs.add(pr)
    cs -= repo.changelog.filteredrevs # nodemap has no filtering
    return cs

def _successors(repo, s):
    """Successors of a changeset"""
    cs = set()
    node = repo.changelog.node
    nm = repo.changelog.nodemap
    markerbyobj = repo.obsstore.successors
    for r in s:
        for p in markerbyobj.get(node(r), ()):
            for sub in p[1]:
                sr = nm.get(sub)
                if sr is not None:
                    cs.add(sr)
    cs -= repo.changelog.filteredrevs # nodemap has no filtering
    return cs

def _allsuccessors(repo, s, haltonflags=0):  # XXX we need a better naming
    """transitive successors of a subset

    haltonflags allows to provide flags which prevent the evaluation of a
    marker.  """
    node = repo.changelog.node
    toproceed = [node(r) for r in s]
    seen = set()
    allobjects = repo.obsstore.successors
    while toproceed:
        nc = toproceed.pop()
        for mark in allobjects.get(nc, ()):
            if mark[2] & haltonflags:
                continue
            for sub in mark[1]:
                if sub == nullid:
                    continue # should not be here!
                if sub not in seen:
                    seen.add(sub)
                    toproceed.append(sub)
    nm = repo.changelog.nodemap
    cs = set()
    for s in seen:
        sr = nm.get(s)
        if sr is not None:
            cs.add(sr)
    cs -= repo.changelog.filteredrevs # nodemap has no filtering
    return cs

#####################################################################
### Extending revset and template                                 ###
#####################################################################

# this section add several useful revset symbol not yet in core.
# they are subject to changes


### XXX I'm not sure this revset is useful
@eh.revset('suspended')
def revsetsuspended(repo, subset, x):
    """``suspended()``
    Obsolete changesets with non-obsolete descendants.
    """
    revset.getargs(x, 0, 0, 'suspended takes no arguments')
    suspended = revset.baseset(getrevs(repo, 'suspended'))
    suspended.sort()
    return subset & suspended


@eh.revset('precursors')
def revsetprecursors(repo, subset, x):
    """``precursors(set)``
    Immediate precursors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_precursors(repo, s))
    s.sort()
    return subset & s


@eh.revset('allprecursors')
def revsetallprecursors(repo, subset, x):
    """``allprecursors(set)``
    Transitive precursors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_allprecursors(repo, s))
    s.sort()
    return subset & s


@eh.revset('successors')
def revsetsuccessors(repo, subset, x):
    """``successors(set)``
    Immediate successors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_successors(repo, s))
    s.sort()
    return subset & s

@eh.revset('allsuccessors')
def revsetallsuccessors(repo, subset, x):
    """``allsuccessors(set)``
    Transitive successors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_allsuccessors(repo, s))
    s.sort()
    return subset & s


#####################################################################
### Various trouble warning                                       ###
#####################################################################

# This section take care of issue warning to the user when troubles appear

def _warnobsoletewc(ui, repo):
    rev = repo['.']

    if not rev.obsolete():
        return

    msg = _("working directory parent is obsolete! (%s)\n")
    shortnode = node.short(rev.node())

    ui.warn(msg % shortnode)

    # Check that evolve is activated for performance reasons
    if ui.quiet or not obsolete.isenabled(repo, commandopt):
        return

    # Show a warning for helping the user to solve the issue
    reason, successors = obshistory._getobsfateandsuccs(repo, rev.node())

    if reason == 'pruned':
        solvemsg = _("use 'hg evolve' to update to its parent successor")
    elif reason == 'diverged':
        debugcommand = "hg evolve --list --divergent"
        basemsg = _("%s has diverged, use '%s' to resolve the issue")
        solvemsg = basemsg % (shortnode, debugcommand)
    elif reason == 'superseed':
        msg = _("use 'hg evolve' to update to its successor: %s")
        solvemsg = msg % successors[0]
    elif reason == 'superseed_split':
        msg = _("use 'hg evolve' to update to its tipmost successor: %s")

        if len(successors) <= 2:
            solvemsg = msg % ", ".join(successors)
        else:
            firstsuccessors = ", ".join(successors[:2])
            remainingnumber = len(successors) - 2
            successorsmsg = _("%s and %d more") % (firstsuccessors, remainingnumber)
            solvemsg = msg % successorsmsg
    else:
        raise ValueError(reason)

    ui.warn("(%s)\n" % solvemsg)

if util.safehasattr(context, '_filterederror'):
    # if < hg-4.2 we do not update the message
    @eh.wrapfunction(context, '_filterederror')
    def evolve_filtererror(original, repo, changeid):
        """build an exception to be raised about a filtered changeid

        This is extracted in a function to help extensions (eg: evolve) to
        experiment with various message variants."""
        if repo.filtername.startswith('visible'):

            unfilteredrepo = repo.unfiltered()
            rev = unfilteredrepo[changeid]
            reason, successors = obshistory._getobsfateandsuccs(unfilteredrepo, rev.node())

            # Be more precise in cqse the revision is superseed
            if reason == 'superseed':
                reason = _("successor: %s") % successors[0]
            elif reason == 'superseed_split':
                if len(successors) <= 2:
                    reason = _("successors: %s") % ", ".join(successors)
                else:
                    firstsuccessors = ", ".join(successors[:2])
                    remainingnumber = len(successors) - 2
                    successorsmsg = _("%s and %d more") % (firstsuccessors, remainingnumber)
                    reason = _("successors: %s") % successorsmsg

            msg = _("hidden revision '%s'") % changeid
            hint = _('use --hidden to access hidden revisions; %s') % reason
            return error.FilteredRepoLookupError(msg, hint=hint)
        msg = _("filtered revision '%s' (not in '%s' subset)")
        msg %= (changeid, repo.filtername)
        return error.FilteredRepoLookupError(msg)

@eh.wrapcommand("update")
@eh.wrapcommand("pull")
def wrapmayobsoletewc(origfn, ui, repo, *args, **opts):
    """Warn that the working directory parent is an obsolete changeset"""
    def warnobsolete():
        _warnobsoletewc(ui, repo)
    wlock = None
    try:
        wlock = repo.wlock()
        repo._afterlock(warnobsolete)
        res = origfn(ui, repo, *args, **opts)
    finally:
        lockmod.release(wlock)
    return res

@eh.wrapcommand("parents")
def wrapparents(origfn, ui, repo, *args, **opts):
    res = origfn(ui, repo, *args, **opts)
    _warnobsoletewc(ui, repo)
    return res

# XXX this could wrap transaction code
# XXX (but this is a bit a layer violation)
@eh.wrapcommand("commit")
@eh.wrapcommand("import")
@eh.wrapcommand("push")
@eh.wrapcommand("pull")
@eh.wrapcommand("graft")
@eh.wrapcommand("phase")
@eh.wrapcommand("unbundle")
def warnobserrors(orig, ui, repo, *args, **kwargs):
    """display warning is the command resulted in more instable changeset"""
    # part of the troubled stuff may be filtered (stash ?)
    # This needs a better implementation but will probably wait for core.
    filtered = repo.changelog.filteredrevs
    priorunstables = len(set(getrevs(repo, 'unstable')) - filtered)
    priorbumpeds = len(set(getrevs(repo, 'bumped')) - filtered)
    priordivergents = len(set(getrevs(repo, 'divergent')) - filtered)
    ret = orig(ui, repo, *args, **kwargs)
    filtered = repo.changelog.filteredrevs
    newunstables = \
        len(set(getrevs(repo, 'unstable')) - filtered) - priorunstables
    newbumpeds = \
        len(set(getrevs(repo, 'bumped')) - filtered) - priorbumpeds
    newdivergents = \
        len(set(getrevs(repo, 'divergent')) - filtered) - priordivergents
    if newunstables > 0:
        ui.warn(_('%i new unstable changesets\n') % newunstables)
    if newbumpeds > 0:
        ui.warn(_('%i new bumped changesets\n') % newbumpeds)
    if newdivergents > 0:
        ui.warn(_('%i new divergent changesets\n') % newdivergents)
    return ret

@eh.wrapfunction(mercurial.exchange, 'push')
def push(orig, repo, *args, **opts):
    """Add a hint for "hg evolve" when troubles make push fails
    """
    try:
        return orig(repo, *args, **opts)
    except error.Abort as ex:
        hint = _("use 'hg evolve' to get a stable history "
                 "or --force to ignore warnings")
        if (len(ex.args) >= 1
            and ex.args[0].startswith('push includes ')
            and ex.hint is None):
            ex.hint = hint
        raise

def summaryhook(ui, repo):
    def write(fmt, count):
        s = fmt % count
        if count:
            ui.write(s)
        else:
            ui.note(s)

    state = _evolvestateread(repo)
    if state is not None:
        # i18n: column positioning for "hg summary"
        ui.write(_('evolve: (evolve --continue)\n'))

@eh.extsetup
def obssummarysetup(ui):
    cmdutil.summaryhooks.add('evolve', summaryhook)


#####################################################################
### Core Other extension compat                                   ###
#####################################################################


@eh.extsetup
def _rebasewrapping(ui):
    # warning about more obsolete
    try:
        rebase = extensions.find('rebase')
        if rebase:
            extensions.wrapcommand(rebase.cmdtable, 'rebase', warnobserrors)
    except KeyError:
        pass # rebase not found
    try:
        histedit = extensions.find('histedit')
        if histedit:
            extensions.wrapcommand(histedit.cmdtable, 'histedit', warnobserrors)
    except KeyError:
        pass # histedit not found

#####################################################################
### Old Evolve extension content                                  ###
#####################################################################

# XXX need clean up and proper sorting in other section

### changeset rewriting logic
#############################

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
        updatebookmarks = _bookmarksupdater(repo, old.node(), tr)

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

class MergeFailure(error.Abort):
    pass

def relocate(repo, orig, dest, pctx=None, keepbranch=False):
    """rewrite <rev> on dest"""
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

        successors = obsolete.successorssets(repo, ctx.node(), cache)

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
            repo.setparents(repo['.'].node(), nullid)
            repo.dirstate.write(tr)
            # fix up dirstate for copies and renames
            copies.duplicatecopies(repo, dest.rev(), orig.p1().rev())

        class LocalMergeFailure(MergeFailure, exc.__class__):
            pass
        exc.__class__ = LocalMergeFailure
        tr.close() # to keep changes in this transaction (e.g. dirstate)
        raise
    _finalizerelocate(repo, orig, dest, nodenew, tr)
    return nodenew

def _bookmarksupdater(repo, oldid, tr):
    """Return a callable update(newid) updating the current bookmark
    and bookmarks bound to oldid to newid.
    """
    def updatebookmarks(newid):
        dirty = False
        oldbookmarks = repo.nodebookmarks(oldid)
        if oldbookmarks:
            for b in oldbookmarks:
                repo._bookmarks[b] = newid
            dirty = True
        if dirty:
            repo._bookmarks.recordchange(tr)
    return updatebookmarks

### new command
#############################
metadataopts = [
    ('d', 'date', '',
     _('record the specified date in metadata'), _('DATE')),
    ('u', 'user', '',
     _('record the specified user in metadata'), _('USER')),
]

@eh.uisetup
def _installimportobsolete(ui):
    entry = cmdutil.findcmd('import', commands.table)[1]
    entry[1].append(('', 'obsolete', False,
                    _('mark the old node as obsoleted by '
                      'the created commit')))

@eh.wrapfunction(mercurial.cmdutil, 'tryimportone')
def tryimportone(orig, ui, repo, hunk, parents, opts, *args, **kwargs):
    extracted = patch.extract(ui, hunk)
    expected = extracted.get('nodeid')
    if expected is not None:
        expected = node.bin(expected)
    oldextract = patch.extract
    try:
        patch.extract = lambda ui, hunk: extracted
        ret = orig(ui, repo, hunk, parents, opts, *args, **kwargs)
    finally:
        patch.extract = oldextract
    created = ret[1]
    if (opts['obsolete'] and None not in (created, expected)
        and created != expected):
            tr = repo.transaction('import-obs')
            try:
                metadata = {'user': ui.username()}
                repo.obsstore.create(tr, expected, (created,),
                                     metadata=metadata)
                tr.close()
            finally:
                tr.release()
    return ret


def _deprecatealias(oldalias, newalias):
    '''Deprecates an alias for a command in favour of another

    Creates a new entry in the command table for the old alias. It creates a
    wrapper that has its synopsis set to show that is has been deprecated.
    The documentation will be replace with a pointer to the new alias.
    If a user invokes the command a deprecation warning will be printed and
    the command of the *new* alias will be invoked.

    This function is loosely based on the extensions.wrapcommand function.
    '''
    try:
        aliases, entry = cmdutil.findcmd(newalias, cmdtable)
    except error.UnknownCommand:
        # Commands may be disabled
        return
    for alias, e in cmdtable.items():
        if e is entry:
            break

    synopsis = '(DEPRECATED)'
    if len(entry) > 2:
        fn, opts, _syn = entry
    else:
        fn, opts, = entry
    deprecationwarning = _('%s have been deprecated in favor of %s\n') % (
        oldalias, newalias)

    def newfn(*args, **kwargs):
        ui = args[0]
        ui.warn(deprecationwarning)
        util.checksignature(fn)(*args, **kwargs)
    newfn.__doc__ = deprecationwarning
    cmdwrapper = eh.command(oldalias, opts, synopsis)
    cmdwrapper(newfn)

@eh.extsetup
def deprecatealiases(ui):
    _deprecatealias('gup', 'next')
    _deprecatealias('gdown', 'previous')

def _solveone(ui, repo, ctx, dryrun, confirm, progresscb, category):
    """Resolve the troubles affecting one revision"""
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction("evolve")
        if 'unstable' == category:
            result = _solveunstable(ui, repo, ctx, dryrun, confirm, progresscb)
        elif 'bumped' == category:
            result = _solvebumped(ui, repo, ctx, dryrun, confirm, progresscb)
        elif 'divergent' == category:
            result = _solvedivergent(ui, repo, ctx, dryrun, confirm,
                                     progresscb)
        else:
            assert False, "unknown trouble category: %s" % (category)
        tr.close()
        return result
    finally:
        lockmod.release(tr, lock, wlock)

def _handlenotrouble(ui, repo, allopt, revopt, anyopt, targetcat):
    """Used by the evolve function to display an error message when
    no troubles can be resolved"""
    troublecategories = ['bumped', 'divergent', 'unstable']
    unselectedcategories = [c for c in troublecategories if c != targetcat]
    msg = None
    hint = None

    troubled = {
        "unstable": repo.revs("unstable()"),
        "divergent": repo.revs("divergent()"),
        "bumped": repo.revs("bumped()"),
        "all": repo.revs("troubled()"),
    }

    hintmap = {
        'bumped': _("do you want to use --bumped"),
        'bumped+divergent': _("do you want to use --bumped or --divergent"),
        'bumped+unstable': _("do you want to use --bumped or --unstable"),
        'divergent': _("do you want to use --divergent"),
        'divergent+unstable': _("do you want to use --divergent"
                                " or --unstable"),
        'unstable': _("do you want to use --unstable"),
        'any+bumped': _("do you want to use --any (or --rev) and --bumped"),
        'any+bumped+divergent': _("do you want to use --any (or --rev) and"
                                  " --bumped or --divergent"),
        'any+bumped+unstable': _("do you want to use --any (or --rev) and"
                                 "--bumped or --unstable"),
        'any+divergent': _("do you want to use --any (or --rev) and"
                           " --divergent"),
        'any+divergent+unstable': _("do you want to use --any (or --rev)"
                                    " and --divergent or --unstable"),
        'any+unstable': _("do you want to use --any (or --rev)"
                          "and --unstable"),
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
        if targetcat == 'unstable':
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
            l = len(troubled[targetcat])
            if l:
                hint = _("%d other %s in the repository, do you want --any "
                         "or --rev") % (l, targetcat)
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

def _cleanup(ui, repo, startnode, showprogress):
    if showprogress:
        ui.progress(_('evolve'), None)
    if repo['.'] != startnode:
        ui.status(_('working directory is now at %s\n') % repo['.'])

class MultipleSuccessorsError(RuntimeError):
    """Exception raised by _singlesuccessor when multiple successor sets exists

    The object contains the list of successorssets in its 'successorssets'
    attribute to call to easily recover.
    """

    def __init__(self, successorssets):
        self.successorssets = successorssets

def _singlesuccessor(repo, p):
    """returns p (as rev) if not obsolete or its unique latest successors

    fail if there are no such successor"""

    if not p.obsolete():
        return p.rev()
    obs = repo[p]
    ui = repo.ui
    newer = obsolete.successorssets(repo, obs.node())
    # search of a parent which is not killed
    while not newer:
        ui.debug("stabilize target %s is plain dead,"
                 " trying to stabilize on its parent\n" %
                 obs)
        obs = obs.parents()[0]
        newer = obsolete.successorssets(repo, obs.node())
    if len(newer) > 1 or len(newer[0]) > 1:
        raise MultipleSuccessorsError(newer)

    return repo[newer[0][0]].rev()

def builddependencies(repo, revs):
    """returns dependency graphs giving an order to solve instability of revs
    (see _orderrevs for more information on usage)"""

    # For each troubled revision we keep track of what instability if any should
    # be resolved in order to resolve it. Example:
    # dependencies = {3: [6], 6:[]}
    # Means that: 6 has no dependency, 3 depends on 6 to be solved
    dependencies = {}
    # rdependencies is the inverted dict of dependencies
    rdependencies = collections.defaultdict(set)

    for r in revs:
        dependencies[r] = set()
        for p in repo[r].parents():
            try:
                succ = _singlesuccessor(repo, p)
            except MultipleSuccessorsError as exc:
                dependencies[r] = exc.successorssets
                continue
            if succ in revs:
                dependencies[r].add(succ)
                rdependencies[succ].add(r)
    return dependencies, rdependencies

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
            elif targetcat == 'unstable':
                revs = _aspiringdescendant(repo,
                                           repo.revs('(.::) - obsolete()::'))
                revs = set(revs)
        if targetcat == 'divergent':
            # Pick one divergent per group of divergents
            revs = _dedupedivergents(repo, revs)
    elif anyopt:
        revs = repo.revs('first(%s())' % (targetcat))
    elif targetcat == 'unstable':
        revs = set(_aspiringchildren(repo, repo.revs('(.::) - obsolete()::')))
        if 1 < len(revs):
            msg = "multiple evolve candidates"
            hint = (_("select one of %s with --rev")
                    % ', '.join([str(repo[r]) for r in sorted(revs)]))
            raise error.Abort(msg, hint=hint)
    elif targetcat in repo['.'].troubles():
        revs = set([repo['.'].rev()])
    return revs


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
    dependencies, rdependencies = builddependencies(repo, revs)
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

def divergentsets(repo, ctx):
    """Compute sets of commits divergent with a given one"""
    cache = {}
    base = {}
    for n in obsolete.allprecursors(repo.obsstore, [ctx.node()]):
        if n == ctx.node():
            # a node can't be a base for divergence with itself
            continue
        nsuccsets = obsolete.successorssets(repo, n, cache)
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

def _preparelistctxs(items, condition):
    return [item.hex() for item in items if condition(item)]

def _formatctx(fm, ctx):
    fm.data(node=ctx.hex())
    fm.data(desc=ctx.description())
    fm.data(date=ctx.date())
    fm.data(user=ctx.user())

def listtroubles(ui, repo, troublecategories, **opts):
    """Print all the troubles for the repo (or given revset)"""
    troublecategories = troublecategories or ['divergent', 'unstable', 'bumped']
    showunstable = 'unstable' in troublecategories
    showbumped = 'bumped' in troublecategories
    showdivergent = 'divergent' in troublecategories

    revs = repo.revs('+'.join("%s()" % t for t in troublecategories))
    if opts.get('rev'):
        revs = scmutil.revrange(repo, opts.get('rev'))

    fm = ui.formatter('evolvelist', opts)
    for rev in revs:
        ctx = repo[rev]
        unpars = _preparelistctxs(ctx.parents(), lambda p: p.unstable())
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
            fm.plain('  unstable: %s (unstable parent)\n' % unpar[:hashlen])
        for obspar in obspars if showunstable else []:
            fm.plain('  unstable: %s (obsolete parent)\n' % obspar[:hashlen])
        for imprec in imprecs if showbumped else []:
            fm.plain('  bumped: %s (immutable precursor)\n' % imprec[:hashlen])

        if dsets and showdivergent:
            for dset in dsets:
                fm.plain('  divergent: ')
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
            troubles.append({'troubletype': 'unstable', 'sourcenode': unpar,
                             'sourcetype': 'unstableparent'})
        for obspar in obspars:
            troubles.append({'troubletype': 'unstable', 'sourcenode': obspar,
                             'sourcetype': 'obsoleteparent'})
        for imprec in imprecs:
            troubles.append({'troubletype': 'bumped', 'sourcenode': imprec,
                             'sourcetype': 'immutableprecursor'})
        for dset in dsets:
            divnodes = [{'node': node.hex(n),
                         'phase': repo[n].phasestr(),
                        } for n in dset['divergentnodes']]
            troubles.append({'troubletype': 'divergent',
                             'commonprecursor': node.hex(dset['commonprecursor']),
                             'divergentnodes': divnodes})
        fm.data(troubles=troubles)

    fm.end()

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
     ('', 'divergent', False, _('solves only divergent changesets')),
     ('', 'unstable', False, _('solves only unstable changesets (default)')),
     ('a', 'all', False, _('evolve all troubled changesets related to the '
                           'current  working directory and its descendants')),
     ('c', 'continue', False, _('continue an interrupted evolution')),
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
    It also refuses to solve bumped or divergent changesets unless you explicity
    request such behavior (see below).

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

    # Options
    listopt = opts['list']
    contopt = opts['continue']
    anyopt = opts['any']
    allopt = opts['all']
    startnode = repo['.']
    dryrunopt = opts['dry_run']
    confirmopt = opts['confirm']
    revopt = opts['rev']
    troublecategories = ['bumped', 'divergent', 'unstable']
    specifiedcategories = [t for t in troublecategories if opts[t]]
    if listopt:
        listtroubles(ui, repo, specifiedcategories, **opts)
        return

    targetcat = 'unstable'
    if 1 < len(specifiedcategories):
        msg = _('cannot specify more than one trouble category to solve (yet)')
        raise error.Abort(msg)
    elif len(specifiedcategories) == 1:
        targetcat = specifiedcategories[0]
    elif repo['.'].obsolete():
        displayer = cmdutil.show_changeset(ui, repo,
                                           {'template': shorttemplate})
        # no args and parent is obsolete, update to successors
        try:
            ctx = repo[_singlesuccessor(repo, repo['.'])]
        except MultipleSuccessorsError as exc:
            repo.ui.write_err('parent is obsolete with multiple successors:\n')
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

    # Continuation handling
    if contopt:
        if anyopt:
            raise error.Abort('cannot specify both "--any" and "--continue"')
        if allopt:
            raise error.Abort('cannot specify both "--all" and "--continue"')
        state = _evolvestateread(repo)
        if state is None:
            raise error.Abort('no evolve to continue')
        orig = repo[state['current']]
        # XXX This is a terrible terrible hack, please get rid of it.
        lock = repo.wlock()
        try:
            repo.vfs.write('graftstate', orig.hex() + '\n')
            try:
                graftcmd = commands.table['graft'][0]
                ret = graftcmd(ui, repo, old_obsolete=True, **{'continue': True})
                _evolvestatedelete(repo)
                return ret
            finally:
                util.unlinkpath(repo.vfs.join('graftstate'), ignoremissing=True)
        finally:
            lock.release()
    cmdutil.bailifchanged(repo)

    if revopt and allopt:
        raise error.Abort('cannot specify both "--rev" and "--all"')
    if revopt and anyopt:
        raise error.Abort('cannot specify both "--rev" and "--any"')

    revs = _selectrevs(repo, allopt, revopt, anyopt, targetcat)

    if not revs:
        return _handlenotrouble(ui, repo, allopt, revopt, anyopt, targetcat)

    # For the progress bar to show
    count = len(revs)
    # Order the revisions
    if targetcat == 'unstable':
        revs = _orderrevs(repo, revs)
    for rev in revs:
        progresscb()
        _solveone(ui, repo, repo[rev], dryrunopt, confirmopt,
                  progresscb, targetcat)
        seen += 1
    progresscb()
    _cleanup(ui, repo, startnode, showprogress)

def _possibledestination(repo, rev):
    """return all changesets that may be a new parent for REV"""
    tonode = repo.changelog.node
    parents = repo.changelog.parentrevs
    torev = repo.changelog.rev
    dest = set()
    tovisit = list(parents(rev))
    while tovisit:
        r = tovisit.pop()
        succsets = obsolete.successorssets(repo, tonode(r))
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

def _aspiringchildren(repo, revs):
    """Return a list of changectx which can be stabilized on top of pctx or
    one of its descendants. Empty list if none can be found."""
    target = set(revs)
    result = []
    for r in repo.revs('unstable() - %ld', revs):
        dest = _possibledestination(repo, r)
        if target & dest:
            result.append(r)
    return result

def _aspiringdescendant(repo, revs):
    """Return a list of changectx which can be stabilized on top of pctx or
    one of its descendants recursively. Empty list if none can be found."""
    target = set(revs)
    result = set(target)
    paths = collections.defaultdict(set)
    for r in repo.revs('unstable() - %ld', revs):
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

def _solveunstable(ui, repo, orig, dryrun=False, confirm=False,
                   progresscb=None):
    """Stabilize an unstable changeset"""
    pctx = orig.p1()
    if len(orig.parents()) == 2:
        if not pctx.obsolete():
            pctx = orig.p2()  # second parent is obsolete ?
        elif orig.p2().obsolete():
            hint = _("Redo the merge (%s) and use `hg prune <old> "
                     "--succ <new>` to obsolete the old one") % orig.hex()[:12]
            ui.warn(_("warning: no support for evolving merge changesets "
                      "with two obsolete parents yet\n") +
                    _("(%s)\n") % hint)
            return False

    if not pctx.obsolete():
        ui.warn(_("cannot solve instability of %s, skipping\n") % orig)
        return False
    obs = pctx
    newer = obsolete.successorssets(repo, obs.node())
    # search of a parent which is not killed
    while not newer or newer == [()]:
        ui.debug("stabilize target %s is plain dead,"
                 " trying to stabilize on its parent\n" %
                 obs)
        obs = obs.parents()[0]
        newer = obsolete.successorssets(repo, obs.node())
    if len(newer) > 1:
        msg = _("skipping %s: divergent rewriting. can't choose "
                "destination\n") % obs
        ui.write_err(msg)
        return 2
    targets = newer[0]
    assert targets
    if len(targets) > 1:
        # split target, figure out which one to pick, are they all in line?
        targetrevs = [repo[r].rev() for r in targets]
        roots = repo.revs('roots(%ld)', targetrevs)
        heads = repo.revs('heads(%ld)', targetrevs)
        if len(roots) > 1 or len(heads) > 1:
            msg = "cannot solve split accross two branches\n"
            ui.write_err(msg)
            return 2
        target = repo[heads.first()]
    else:
        target = targets[0]
    displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
    target = repo[target]
    if not ui.quiet or confirm:
        repo.ui.write(_('move:'))
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
    else:
        repo.ui.note(todo)
        if progresscb:
            progresscb()
        keepbranch = orig.p1().branch() != orig.branch()
        try:
            relocate(repo, orig, target, pctx, keepbranch)
        except MergeFailure:
            _evolvestatewrite(repo, {'current': orig.node()})
            repo.ui.write_err(_('evolve failed!\n'))
            repo.ui.write_err(
                _("fix conflict and run 'hg evolve --continue'"
                  " or use 'hg update -C .' to abort\n"))
            raise

def _solvebumped(ui, repo, bumped, dryrun=False, confirm=False,
                 progresscb=None):
    """Stabilize a bumped changeset"""
    repo = repo.unfiltered()
    bumped = repo[bumped.rev()]
    # For now we deny bumped merge
    if len(bumped.parents()) > 1:
        msg = _('skipping %s : we do not handle merge yet\n') % bumped
        ui.write_err(msg)
        return 2
    prec = repo.set('last(allprecursors(%d) and public())', bumped).next()
    # For now we deny target merge
    if len(prec.parents()) > 1:
        msg = _('skipping: %s: public version is a merge, '
                'this is not handled yet\n') % prec
        ui.write_err(msg)
        return 2

    displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
    if not ui.quiet or confirm:
        repo.ui.write(_('recreate:'))
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
        repo.ui.write(('hg commit --msg "bumped update to %s"'))
        return 0
    if progresscb:
        progresscb()
    newid = tmpctx = None
    tmpctx = bumped
    # Basic check for common parent. Far too complicated and fragile
    tr = repo.currenttransaction()
    assert tr is not None
    bmupdate = _bookmarksupdater(repo, bumped.node(), tr)
    if not list(repo.set('parents(%d) and parents(%d)', bumped, prec)):
        # Need to rebase the changeset at the right place
        repo.ui.status(
            _('rebasing to destination parent: %s\n') % prec.p1())
        try:
            tmpid = relocate(repo, bumped, prec.p1())
            if tmpid is not None:
                tmpctx = repo[tmpid]
                obsolete.createmarkers(repo, [(bumped, (tmpctx,))])
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
                mctx = context.memfilectx(repo, fctx.path(), fctx.data(),
                                          islink='l' in flags,
                                          isexec='x' in flags,
                                          copied=copied.get(path))
                return mctx
            return None
        text = 'bumped update to %s:\n\n' % prec
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
        obsolete.createmarkers(repo, [(tmpctx, ())])
        newid = prec.node()
    else:
        phases.retractboundary(repo, tr, bumped.phase(), [newid])
        obsolete.createmarkers(repo, [(tmpctx, (repo[newid],))],
                               flag=obsolete.bumpedfix)
    bmupdate(newid)
    repo.ui.status(_('committed as %s\n') % node.short(newid))
    # reroute the working copy parent to the new changeset
    with repo.dirstate.parentchange():
        repo.dirstate.setparents(newid, node.nullid)

def _solvedivergent(ui, repo, divergent, dryrun=False, confirm=False,
                    progresscb=None):
    repo = repo.unfiltered()
    divergent = repo[divergent.rev()]
    base, others = divergentdata(divergent)
    if len(others) > 1:
        othersstr = "[%s]" % (','.join([str(i) for i in others]))
        msg = _("skipping %d:divergent with a changeset that got splitted"
                " into multiple ones:\n"
                "|[%s]\n"
                "| This is not handled by automatic evolution yet\n"
                "| You have to fallback to manual handling with commands "
                "such as:\n"
                "| - hg touch -D\n"
                "| - hg prune\n"
                "| \n"
                "| You should contact your local evolution Guru for help.\n"
                ) % (divergent, othersstr)
        ui.write_err(msg)
        return 2
    other = others[0]
    if len(other.parents()) > 1:
        msg = _("skipping %s: divergent changeset can't be "
                "a merge (yet)\n") % divergent
        ui.write_err(msg)
        hint = _("You have to fallback to solving this by hand...\n"
                 "| This probably means redoing the merge and using \n"
                 "| `hg prune` to kill older version.\n")
        ui.write_err(hint)
        return 2
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
        return 2

    displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
    if not ui.quiet or confirm:
        ui.write(_('merge:'))
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
        return
    if divergent not in repo[None].parents():
        repo.ui.status(_('updating to "local" conflict\n'))
        hg.update(repo, divergent.rev())
    repo.ui.note(_('merging divergent changeset\n'))
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
        amend(ui, repo, message='', logfile='')
        if oldlen == len(repo):
            new = divergent
            # no changes
        else:
            new = repo['.']
        obsolete.createmarkers(repo, [(other, (new,))])
        phases.retractboundary(repo, tr, other.phase(), [new.node()])
    finally:
        repo.ui.restoreconfig(emtpycommitallowed)

def divergentdata(ctx):
    """return base, other part of a conflict

    This only return the first one.

    XXX this woobly function won't survive XXX
    """
    repo = ctx._repo.unfiltered()
    for base in repo.set('reverse(allprecursors(%d))', ctx):
        newer = obsolete.successorssets(ctx._repo, base.node())
        # drop filter and solution including the original ctx
        newer = [n for n in newer if n and ctx.node() not in n]
        if newer:
            return base, tuple(ctx._repo[o] for o in newer[0])
    raise error.Abort("base of divergent changeset %s not found" % ctx,
                      hint='this case is not yet handled')

shorttemplate = "[{label('evolve.rev', rev)}] {desc|firstline}\n"

@eh.command(
    '^previous',
    [('B', 'move-bookmark', False,
        _('move active bookmark after update')),
     ('', 'merge', False, _('bring uncommitted change along')),
     ('', 'no-topic', False, _('ignore topic and move topologically')),
     ('n', 'dry-run', False,
        _('do not perform actions, just print what would be done'))],
    '[OPTION]...')
def cmdprevious(ui, repo, **opts):
    """update to parent revision

    Displays the summary line of the destination for clarity."""
    wlock = None
    dryrunopt = opts['dry_run']
    if not dryrunopt:
        wlock = repo.wlock()
    try:
        wkctx = repo[None]
        wparents = wkctx.parents()
        if len(wparents) != 1:
            raise error.Abort('merge in progress')
        if not opts['merge']:
            try:
                cmdutil.bailifchanged(repo)
            except error.Abort as exc:
                exc.hint = _('do you want --merge?')
                raise

        parents = wparents[0].parents()
        topic = getattr(repo, 'currenttopic', '')
        if topic and not opts.get("no_topic", False):
            parents = [ctx for ctx in parents if ctx.topic() == topic]
        displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
        if not parents:
            ui.warn(_('no parent in topic "%s"\n') % topic)
            ui.warn(_('(do you want --no-topic)\n'))
        elif len(parents) == 1:
            p = parents[0]
            bm = repo._activebookmark
            shouldmove = opts.get('move_bookmark') and bm is not None
            if dryrunopt:
                ui.write(('hg update %s;\n' % p.rev()))
                if shouldmove:
                    ui.write(('hg bookmark %s -r %s;\n' % (bm, p.rev())))
            else:
                ret = hg.update(repo, p.rev())
                if not ret:
                    tr = lock = None
                    try:
                        lock = repo.lock()
                        tr = repo.transaction('previous')
                        if shouldmove:
                            repo._bookmarks[bm] = p.node()
                            repo._bookmarks.recordchange(tr)
                        else:
                            bookmarksmod.deactivate(repo)
                        tr.close()
                    finally:
                        lockmod.release(tr, lock)

            displayer.show(p)
            return 0
        else:
            for p in parents:
                displayer.show(p)
            ui.warn(_('multiple parents, explicitly update to one\n'))
            return 1
    finally:
        lockmod.release(wlock)

@eh.command(
    '^next',
    [('B', 'move-bookmark', False,
        _('move active bookmark after update')),
     ('', 'merge', False, _('bring uncommitted change along')),
     ('', 'evolve', False, _('evolve the next changeset if necessary')),
     ('', 'no-topic', False, _('ignore topic and move topologically')),
     ('n', 'dry-run', False,
      _('do not perform actions, just print what would be done'))],
    '[OPTION]...')
def cmdnext(ui, repo, **opts):
    """update to next child revision

    Use the ``--evolve`` flag to evolve unstable children on demand.

    Displays the summary line of the destination for clarity.
    """
    wlock = None
    dryrunopt = opts['dry_run']
    if not dryrunopt:
        wlock = repo.wlock()
    try:
        wkctx = repo[None]
        wparents = wkctx.parents()
        if len(wparents) != 1:
            raise error.Abort('merge in progress')
        if not opts['merge']:
            try:
                cmdutil.bailifchanged(repo)
            except error.Abort as exc:
                exc.hint = _('do you want --merge?')
                raise

        children = [ctx for ctx in wparents[0].children() if not ctx.obsolete()]
        topic = getattr(repo, 'currenttopic', '')
        filtered = []
        if topic and not opts.get("no_topic", False):
            filtered = [ctx for ctx in children if ctx.topic() != topic]
            # XXX N-square membership on children
            children = [ctx for ctx in children if ctx not in filtered]
        displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
        if len(children) == 1:
            c = children[0]
            bm = repo._activebookmark
            shouldmove = opts.get('move_bookmark') and bm is not None
            if dryrunopt:
                ui.write(('hg update %s;\n' % c.rev()))
                if shouldmove:
                    ui.write(('hg bookmark %s -r %s;\n' % (bm, c.rev())))
            else:
                ret = hg.update(repo, c.rev())
                if not ret:
                    lock = tr = None
                    try:
                        lock = repo.lock()
                        tr = repo.transaction('next')
                        if shouldmove:
                            repo._bookmarks[bm] = c.node()
                            repo._bookmarks.recordchange(tr)
                        else:
                            bookmarksmod.deactivate(repo)
                        tr.close()
                    finally:
                        lockmod.release(tr, lock)
            displayer.show(c)
            result = 0
        elif children:
            ui.warn(_("ambigious next changeset:\n"))
            for c in children:
                displayer.show(c)
            ui.warn(_('explicitly update to one of them\n'))
            result = 1
        else:
            aspchildren = _aspiringchildren(repo, [repo['.'].rev()])
            if topic:
                filtered.extend(repo[c] for c in children
                                if repo[c].topic() != topic)
                # XXX N-square membership on children
                aspchildren = [ctx for ctx in aspchildren if ctx not in filtered]
            if not opts['evolve'] or not aspchildren:
                if filtered:
                    ui.warn(_('no children on topic "%s"\n') % topic)
                    ui.warn(_('do you want --no-topic\n'))
                else:
                    ui.warn(_('no children\n'))
                if aspchildren:
                    msg = _('(%i unstable changesets to be evolved here, '
                            'do you want --evolve?)\n')
                    ui.warn(msg % len(aspchildren))
                result = 1
            elif 1 < len(aspchildren):
                ui.warn(_("ambigious next (unstable) changeset:\n"))
                for c in aspchildren:
                    displayer.show(repo[c])
                ui.warn(_("(run 'hg evolve --rev REV' on one of them)\n"))
                return 1
            else:
                cmdutil.bailifchanged(repo)
                result = _solveone(ui, repo, repo[aspchildren[0]], dryrunopt,
                                   False, lambda: None, category='unstable')
                if not result:
                    ui.status(_('working directory now at %s\n')
                              % ui.label(str(repo['.']), 'evolve.node'))
                return result
            return 1
        return result
    finally:
        lockmod.release(wlock)

def _reachablefrombookmark(repo, revs, bookmarks):
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

def _deletebookmark(repo, repomarks, bookmarks):
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction('prune')
        for bookmark in bookmarks:
            del repomarks[bookmark]
        repomarks.recordchange(tr)
        tr.close()
        for bookmark in sorted(bookmarks):
            repo.ui.write(_("bookmark '%s' deleted\n") % bookmark)
    finally:
        lockmod.release(tr, lock, wlock)

def _getmetadata(**opts):
    metadata = {}
    date = opts.get('date')
    user = opts.get('user')
    if date:
        metadata['date'] = '%i %i' % util.parsedate(date)
    if user:
        metadata['user'] = user
    return metadata

@eh.command(
    '^prune|obsolete',
    [('n', 'new', [], _("successor changeset (DEPRECATED)")),
     ('s', 'succ', [], _("successor changeset")),
     ('r', 'rev', [], _("revisions to prune")),
     ('k', 'keep', None, _("does not modify working copy during prune")),
     ('', 'biject', False, _("do a 1-1 map between rev and successor ranges")),
     ('', 'fold', False,
      _("record a fold (multiple precursors, one successors)")),
     ('', 'split', False,
      _("record a split (on precursor, multiple successors)")),
     ('B', 'bookmark', [], _("remove revs only reachable from given"
                             " bookmark"))] + metadataopts,
    _('[OPTION] [-r] REV...'))
# XXX -U  --noupdate option to prevent wc update and or bookmarks update ?
def cmdprune(ui, repo, *revs, **opts):
    """hide changesets by marking them obsolete

    Pruned changesets are obsolete with no successors. If they also have no
    descendants, they are hidden (invisible to all commands).

    Non-obsolete descendants of pruned changesets become "unstable". Use :hg:`evolve`
    to handle this situation.

    When you prune the parent of your working copy, Mercurial updates the working
    copy to a non-obsolete parent.

    You can use ``--succ`` to tell Mercurial that a newer version (successor) of the
    pruned changeset exists. Mercurial records successor revisions in obsolescence
    markers.

    You can use the ``--biject`` option to specify a 1-1 mapping (bijection) between
    revisions to pruned (precursor) and successor changesets. This option may be
    removed in a future release (with the functionality provided automatically).

    If you specify multiple revisions in ``--succ``, you are recording a "split" and
    must acknowledge it by passing ``--split``. Similarly, when you prune multiple
    changesets with a single successor, you must pass the ``--fold`` option.
    """
    revs = scmutil.revrange(repo, list(revs) + opts.get('rev'))
    succs = opts['new'] + opts['succ']
    bookmarks = set(opts.get('bookmark'))
    metadata = _getmetadata(**opts)
    biject = opts.get('biject')
    fold = opts.get('fold')
    split = opts.get('split')

    options = [o for o in ('biject', 'fold', 'split') if opts.get(o)]
    if 1 < len(options):
        raise error.Abort(_("can only specify one of %s") % ', '.join(options))

    if bookmarks:
        repomarks, revs = _reachablefrombookmark(repo, revs, bookmarks)
        if not revs:
            # no revisions to prune - delete bookmark immediately
            _deletebookmark(repo, repomarks, bookmarks)

    if not revs:
        raise error.Abort(_('nothing to prune'))

    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction('prune')
        # defines pruned changesets
        precs = []
        revs.sort()
        for p in revs:
            cp = repo[p]
            if not cp.mutable():
                # note: createmarkers() would have raised something anyway
                raise error.Abort('cannot prune immutable changeset: %s' % cp,
                                  hint="see 'hg help phases' for details")
            precs.append(cp)
        if not precs:
            raise error.Abort('nothing to prune')

        if _disallowednewunstable(repo, revs):
            raise error.Abort(_("cannot prune in the middle of a stack"),
                              hint=_("new unstable changesets are not allowed"))

        # defines successors changesets
        sucs = scmutil.revrange(repo, succs)
        sucs.sort()
        sucs = tuple(repo[n] for n in sucs)
        if not biject and len(sucs) > 1 and len(precs) > 1:
            msg = "Can't use multiple successors for multiple precursors"
            hint = _("use --biject to mark a series as a replacement"
                     " for another")
            raise error.Abort(msg, hint=hint)
        elif biject and len(sucs) != len(precs):
            msg = "Can't use %d successors for %d precursors" \
                % (len(sucs), len(precs))
            raise error.Abort(msg)
        elif (len(precs) == 1 and len(sucs) > 1) and not split:
            msg = "please add --split if you want to do a split"
            raise error.Abort(msg)
        elif len(sucs) == 1 and len(precs) > 1 and not fold:
            msg = "please add --fold if you want to do a fold"
            raise error.Abort(msg)
        elif biject:
            relations = [(p, (s,)) for p, s in zip(precs, sucs)]
        else:
            relations = [(p, sucs) for p in precs]

        wdp = repo['.']

        if len(sucs) == 1 and len(precs) == 1 and wdp in precs:
            # '.' killed, so update to the successor
            newnode = sucs[0]
        else:
            # update to an unkilled parent
            newnode = wdp

            while newnode in precs or newnode.obsolete():
                newnode = newnode.parents()[0]

        if newnode.node() != wdp.node():
            if opts.get('keep', False):
                # This is largely the same as the implementation in
                # strip.stripcmd(). We might want to refactor this somewhere
                # common at some point.

                # only reset the dirstate for files that would actually change
                # between the working context and uctx
                descendantrevs = repo.revs("%d::." % newnode.rev())
                changedfiles = []
                for rev in descendantrevs:
                    # blindly reset the files, regardless of what actually
                    # changed
                    changedfiles.extend(repo[rev].files())

                # reset files that only changed in the dirstate too
                dirstate = repo.dirstate
                dirchanges = [f for f in dirstate if dirstate[f] != 'n']
                changedfiles.extend(dirchanges)
                repo.dirstate.rebuild(newnode.node(), newnode.manifest(),
                                      changedfiles)
                dirstate.write(tr)
            else:
                bookactive = repo._activebookmark
                # Active bookmark that we don't want to delete (with -B option)
                # we deactivate and move it before the update and reactivate it
                # after
                movebookmark = bookactive and not bookmarks
                if movebookmark:
                    bookmarksmod.deactivate(repo)
                    repo._bookmarks[bookactive] = newnode.node()
                    repo._bookmarks.recordchange(tr)
                commands.update(ui, repo, newnode.rev())
                ui.status(_('working directory now at %s\n')
                          % ui.label(str(newnode), 'evolve.node'))
                if movebookmark:
                    bookmarksmod.activate(repo, bookactive)

        # update bookmarks
        if bookmarks:
            _deletebookmark(repo, repomarks, bookmarks)

        # create markers
        obsolete.createmarkers(repo, relations, metadata=metadata)

        # informs that changeset have been pruned
        ui.status(_('%i changesets pruned\n') % len(precs))

        for ctx in repo.unfiltered().set('bookmark() and %ld', precs):
            # used to be:
            #
            #   ldest = list(repo.set('max((::%d) - obsolete())', ctx))
            #   if ldest:
            #      c = ldest[0]
            #
            # but then revset took a lazy arrow in the knee and became much
            # slower. The new forms makes as much sense and a much faster.
            for dest in ctx.ancestors():
                if not dest.obsolete():
                    updatebookmarks = _bookmarksupdater(repo, ctx.node(), tr)
                    updatebookmarks(dest.node())
                    break

        tr.close()
    finally:
        lockmod.release(tr, lock, wlock)

@eh.command(
    'amend|refresh',
    [('A', 'addremove', None,
      _('mark new/missing files as added/removed before committing')),
     ('e', 'edit', False, _('invoke editor on commit messages')),
     ('', 'close-branch', None,
      _('mark a branch as closed, hiding it from the branch list')),
     ('s', 'secret', None, _('use the secret phase for committing')),
    ] + walkopts + commitopts + commitopts2 + commitopts3 + interactiveopt,
    _('[OPTION]... [FILE]...'))
def amend(ui, repo, *pats, **opts):
    """combine a changeset with updates and replace it with a new one

    Commits a new changeset incorporating both the changes to the given files
    and all the changes from the current parent changeset into the repository.

    See :hg:`commit` for details about committing changes.

    If you don't specify -m, the parent's message will be reused.

    Behind the scenes, Mercurial first commits the update as a regular child
    of the current parent. Then it creates a new commit on the parent's parents
    with the updated contents. Then it changes the working copy parent to this
    new combined changeset. Finally, the old changeset and its update are hidden
    from :hg:`log` (unless you use --hidden with log).

    Returns 0 on success, 1 if nothing changed.
    """
    opts = opts.copy()
    edit = opts.pop('edit', False)
    log = opts.get('logfile')
    opts['amend'] = True
    if not (edit or opts['message'] or log):
        opts['message'] = repo['.'].description()
    _resolveoptions(ui, opts)
    _alias, commitcmd = cmdutil.findcmd('commit', commands.table)
    return commitcmd[0](ui, repo, *pats, **opts)


def _touchedbetween(repo, source, dest, match=None):
    touched = set()
    for files in repo.status(source, dest, match=match)[:3]:
        touched.update(files)
    return touched

def _commitfiltered(repo, ctx, match, target=None):
    """Recommit ctx with changed files not in match. Return the new
    node identifier, or None if nothing changed.
    """
    base = ctx.p1()
    if target is None:
        target = base
    # ctx
    initialfiles = _touchedbetween(repo, base, ctx)
    if base == target:
        affected = set(f for f in initialfiles if match(f))
        newcontent = set()
    else:
        affected = _touchedbetween(repo, target, ctx, match=match)
        newcontent = _touchedbetween(repo, target, base, match=match)
    # The commit touchs all existing files
    # + all file that needs a new content
    # - the file affected bny uncommit with the same content than base.
    files = (initialfiles - affected) | newcontent
    if not newcontent and files == initialfiles:
        return None

    # Filter copies
    copied = copies.pathcopies(target, ctx)
    copied = dict((dst, src) for dst, src in copied.iteritems()
                  if dst in files)

    def filectxfn(repo, memctx, path, contentctx=ctx, redirect=newcontent):
        if path in redirect:
            return filectxfn(repo, memctx, path, contentctx=target, redirect=())
        if path not in contentctx:
            return None
        fctx = contentctx[path]
        flags = fctx.flags()
        mctx = context.memfilectx(repo, fctx.path(), fctx.data(),
                                  islink='l' in flags,
                                  isexec='x' in flags,
                                  copied=copied.get(path))
        return mctx

    new = context.memctx(repo,
                         parents=[base.node(), node.nullid],
                         text=ctx.description(),
                         files=files,
                         filectxfn=filectxfn,
                         user=ctx.user(),
                         date=ctx.date(),
                         extra=ctx.extra())
    # commitctx always create a new revision, no need to check
    newid = repo.commitctx(new)
    return newid

def _uncommitdirstate(repo, oldctx, match):
    """Fix the dirstate after switching the working directory from
    oldctx to a copy of oldctx not containing changed files matched by
    match.
    """
    ctx = repo['.']
    ds = repo.dirstate
    copies = dict(ds.copies())
    m, a, r = repo.status(oldctx.p1(), oldctx, match=match)[:3]
    for f in m:
        if ds[f] == 'r':
            # modified + removed -> removed
            continue
        ds.normallookup(f)

    for f in a:
        if ds[f] == 'r':
            # added + removed -> unknown
            ds.drop(f)
        elif ds[f] != 'a':
            ds.add(f)

    for f in r:
        if ds[f] == 'a':
            # removed + added -> normal
            ds.normallookup(f)
        elif ds[f] != 'r':
            ds.remove(f)

    # Merge old parent and old working dir copies
    oldcopies = {}
    for f in (m + a):
        src = oldctx[f].renamed()
        if src:
            oldcopies[f] = src[0]
    oldcopies.update(copies)
    copies = dict((dst, oldcopies.get(src, src))
                  for dst, src in oldcopies.iteritems())
    # Adjust the dirstate copies
    for dst, src in copies.iteritems():
        if (src not in ctx or dst in ctx or ds[dst] != 'a'):
            src = None
        ds.copy(src, dst)

@eh.command(
    '^uncommit',
    [('a', 'all', None, _('uncommit all changes when no arguments given')),
     ('r', 'rev', '', _('revert commit content to REV instead')),
     ] + commands.walkopts,
    _('[OPTION]... [NAME]'))
def uncommit(ui, repo, *pats, **opts):
    """move changes from parent revision to working directory

    Changes to selected files in the checked out revision appear again as
    uncommitted changed in the working directory. A new revision
    without the selected changes is created, becomes the checked out
    revision, and obsoletes the previous one.

    The --include option specifies patterns to uncommit.
    The --exclude option specifies patterns to keep in the commit.

    The --rev argument let you change the commit file to a content of another
    revision. It still does not change the content of your file in the working
    directory.

    Return 0 if changed files are uncommitted.
    """

    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        wctx = repo[None]
        if len(wctx.parents()) <= 0:
            raise error.Abort(_("cannot uncommit null changeset"))
        if len(wctx.parents()) > 1:
            raise error.Abort(_("cannot uncommit while merging"))
        old = repo['.']
        if old.phase() == phases.public:
            raise error.Abort(_("cannot rewrite immutable changeset"))
        if len(old.parents()) > 1:
            raise error.Abort(_("cannot uncommit merge changeset"))
        oldphase = old.phase()

        rev = None
        if opts.get('rev'):
            rev = scmutil.revsingle(repo, opts.get('rev'))
            ctx = repo[None]
            if ctx.p1() == rev or ctx.p2() == rev:
                raise error.Abort(_("cannot uncommit to parent changeset"))

        onahead = old.rev() in repo.changelog.headrevs()
        disallowunstable = not obsolete.isenabled(repo,
                                                  obsolete.allowunstableopt)
        if disallowunstable and not onahead:
            raise error.Abort(_("cannot uncommit in the middle of a stack"))

        # Recommit the filtered changeset
        tr = repo.transaction('uncommit')
        updatebookmarks = _bookmarksupdater(repo, old.node(), tr)
        newid = None
        includeorexclude = opts.get('include') or opts.get('exclude')
        if (pats or includeorexclude or opts.get('all')):
            match = scmutil.match(old, pats, opts)
            newid = _commitfiltered(repo, old, match, target=rev)
        if newid is None:
            raise error.Abort(_('nothing to uncommit'),
                              hint=_("use --all to uncommit all files"))
        # Move local changes on filtered changeset
        obsolete.createmarkers(repo, [(old, (repo[newid],))])
        phases.retractboundary(repo, tr, oldphase, [newid])
        with repo.dirstate.parentchange():
            repo.dirstate.setparents(newid, node.nullid)
            _uncommitdirstate(repo, old, match)
        updatebookmarks(newid)
        if not repo[newid].files():
            ui.warn(_("new changeset is empty\n"))
            ui.status(_("(use 'hg prune .' to remove it)\n"))
        tr.close()
    finally:
        lockmod.release(tr, lock, wlock)

@eh.wrapcommand('commit')
def commitwrapper(orig, ui, repo, *arg, **kwargs):
    tr = None
    if kwargs.get('amend', False):
        wlock = lock = None
    else:
        wlock = repo.wlock()
        lock = repo.lock()
    try:
        obsoleted = kwargs.get('obsolete', [])
        if obsoleted:
            obsoleted = repo.set('%lr', obsoleted)
        result = orig(ui, repo, *arg, **kwargs)
        if not result: # commit succeeded
            new = repo['-1']
            oldbookmarks = []
            markers = []
            for old in obsoleted:
                oldbookmarks.extend(repo.nodebookmarks(old.node()))
                markers.append((old, (new,)))
            if markers:
                obsolete.createmarkers(repo, markers)
            for book in oldbookmarks:
                repo._bookmarks[book] = new.node()
            if oldbookmarks:
                if not wlock:
                    wlock = repo.wlock()
                if not lock:
                    lock = repo.lock()
                tr = repo.transaction('commit')
                repo._bookmarks.recordchange(tr)
                tr.close()
        return result
    finally:
        lockmod.release(tr, lock, wlock)

@eh.command(
    '^split',
    [('r', 'rev', [], _("revision to split")),
    ] + commitopts + commitopts2,
    _('hg split [OPTION]... [-r] REV'))
def cmdsplit(ui, repo, *revs, **opts):
    """split a changeset into smaller changesets

    By default, split the current revision by prompting for all its hunks to be
    redistributed into new changesets.

    Use --rev to split a given changeset instead.
    """
    tr = wlock = lock = None
    newcommits = []

    revarg = (list(revs) + opts.get('rev')) or ['.']
    if len(revarg) != 1:
        msg = _("more than one revset is given")
        hnt = _("use either `hg split <rs>` or `hg split --rev <rs>`, not both")
        raise error.Abort(msg, hint=hnt)

    rev = scmutil.revsingle(repo, revarg[0])
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        cmdutil.bailifchanged(repo)
        tr = repo.transaction('split')
        ctx = repo[rev]
        r = ctx.rev()
        disallowunstable = not obsolete.isenabled(repo,
                                                  obsolete.allowunstableopt)
        if disallowunstable:
            # XXX We should check head revs
            if repo.revs("(%d::) - %d", rev, rev):
                raise error.Abort(_("cannot split commit: %s not a head") % ctx)

        if len(ctx.parents()) > 1:
            raise error.Abort(_("cannot split merge commits"))
        prev = ctx.p1()
        bmupdate = _bookmarksupdater(repo, ctx.node(), tr)
        bookactive = repo._activebookmark
        if bookactive is not None:
            repo.ui.status(_("(leaving bookmark %s)\n") % repo._activebookmark)
        bookmarksmod.deactivate(repo)
        hg.update(repo, prev)

        commands.revert(ui, repo, rev=r, all=True)

        def haschanges():
            modified, added, removed, deleted = repo.status()[:4]
            return modified or added or removed or deleted
        msg = ("HG: This is the original pre-split commit message. "
               "Edit it as appropriate.\n\n")
        msg += ctx.description()
        opts['message'] = msg
        opts['edit'] = True
        while haschanges():
            pats = ()
            cmdutil.dorecord(ui, repo, commands.commit, 'commit', False,
                             cmdutil.recordfilter, *pats, **opts)
            # TODO: Does no seem like the best way to do this
            # We should make dorecord return the newly created commit
            newcommits.append(repo['.'])
            if haschanges():
                if ui.prompt('Done splitting? [yN]', default='n') == 'y':
                    commands.commit(ui, repo, **opts)
                    newcommits.append(repo['.'])
                    break
            else:
                ui.status(_("no more change to split\n"))

        if newcommits:
            tip = repo[newcommits[-1]]
            bmupdate(tip.node())
            if bookactive is not None:
                bookmarksmod.activate(repo, bookactive)
            obsolete.createmarkers(repo, [(repo[r], newcommits)])
        tr.close()
    finally:
        lockmod.release(tr, lock, wlock)


@eh.wrapcommand('strip', extension='strip', opts=[
    ('', 'bundle', None, _("delete the commit entirely and move it to a "
                           "backup bundle")),
    ])
def stripwrapper(orig, ui, repo, *revs, **kwargs):
    if (not ui.configbool('experimental', 'prunestrip') or
        kwargs.get('bundle', False)):
        return orig(ui, repo, *revs, **kwargs)

    if kwargs.get('force'):
        ui.warn(_("warning: --force has no effect during strip with evolve "
                  "enabled\n"))
    if kwargs.get('no_backup', False):
        ui.warn(_("warning: --no-backup has no effect during strips with "
                  "evolve enabled\n"))

    revs = list(revs) + kwargs.pop('rev', [])
    revs = set(scmutil.revrange(repo, revs))
    revs = repo.revs("(%ld)::", revs)
    kwargs['rev'] = []
    kwargs['new'] = []
    kwargs['succ'] = []
    kwargs['biject'] = False
    return cmdprune(ui, repo, *revs, **kwargs)

@eh.command(
    '^touch',
    [('r', 'rev', [], 'revision to update'),
     ('D', 'duplicate', False,
      'do not mark the new revision as successor of the old one'),
     ('A', 'allowdivergence', False,
      'mark the new revision as successor of the old one potentially creating '
      'divergence')],
    # allow to choose the seed ?
    _('[-r] revs'))
def touch(ui, repo, *revs, **opts):
    """create successors that are identical to their predecessors except
    for the changeset ID

    This is used to "resurrect" changesets
    """
    duplicate = opts['duplicate']
    allowdivergence = opts['allowdivergence']
    revs = list(revs)
    revs.extend(opts['rev'])
    if not revs:
        revs = ['.']
    revs = scmutil.revrange(repo, revs)
    if not revs:
        ui.write_err('no revision to touch\n')
        return 1
    if not duplicate and repo.revs('public() and %ld', revs):
        raise error.Abort("can't touch public revision")
    displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction('touch')
        revs.sort() # ensure parent are run first
        newmapping = {}
        for r in revs:
            ctx = repo[r]
            extra = ctx.extra().copy()
            extra['__touch-noise__'] = random.randint(0, 0xffffffff)
            # search for touched parent
            p1 = ctx.p1().node()
            p2 = ctx.p2().node()
            p1 = newmapping.get(p1, p1)
            p2 = newmapping.get(p2, p2)

            if not (duplicate or allowdivergence):
                # The user hasn't yet decided what to do with the revived
                # cset, let's ask
                sset = obsolete.successorssets(repo, ctx.node())
                nodivergencerisk = (len(sset) == 0 or
                                    (len(sset) == 1 and
                                     len(sset[0]) == 1 and
                                     repo[sset[0][0]].rev() == ctx.rev()
                                    ))
                if nodivergencerisk:
                    duplicate = False
                else:
                    displayer.show(ctx)
                    index = ui.promptchoice(
                        _("reviving this changeset will create divergence"
                          " unless you make a duplicate.\n(a)llow divergence or"
                          " (d)uplicate the changeset? $$ &Allowdivergence $$ "
                          "&Duplicate"), 0)
                    choice = ['allowdivergence', 'duplicate'][index]
                    if choice == 'allowdivergence':
                        duplicate = False
                    else:
                        duplicate = True

            new, unusedvariable = rewrite(repo, ctx, [], ctx,
                                          [p1, p2],
                                          commitopts={'extra': extra})
            # store touched version to help potential children
            newmapping[ctx.node()] = new

            if not duplicate:
                obsolete.createmarkers(repo, [(ctx, (repo[new],))])
            phases.retractboundary(repo, tr, ctx.phase(), [new])
            if ctx in repo[None].parents():
                with repo.dirstate.parentchange():
                    repo.dirstate.setparents(new, node.nullid)
        tr.close()
    finally:
        lockmod.release(tr, lock, wlock)

@eh.command(
    '^fold|squash',
    [('r', 'rev', [], _("revision to fold")),
     ('', 'exact', None, _("only fold specified revisions")),
     ('', 'from', None, _("fold revisions linearly to working copy parent"))
    ] + commitopts + commitopts2,
    _('hg fold [OPTION]... [-r] REV'))
def fold(ui, repo, *revs, **opts):
    """fold multiple revisions into a single one

    With --from, folds all the revisions linearly between the given revisions
    and the parent of the working directory.

    With --exact, folds only the specified revisions while ignoring the
    parent of the working directory. In this case, the given revisions must
    form a linear unbroken chain.

    .. container:: verbose

     Some examples:

     - Fold the current revision with its parent::

         hg fold --from .^

     - Fold all draft revisions with working directory parent::

         hg fold --from 'draft()'

       See :hg:`help phases` for more about draft revisions and
       :hg:`help revsets` for more about the `draft()` keyword

     - Fold revisions between 3 and 6 with the working directory parent::

         hg fold --from 3::6

     - Fold revisions 3 and 4:

        hg fold "3 + 4" --exact

     - Only fold revisions linearly between foo and @::

         hg fold foo::@ --exact
    """
    revs = list(revs)
    revs.extend(opts['rev'])
    if not revs:
        raise error.Abort(_('no revisions specified'))

    revs = scmutil.revrange(repo, revs)

    if opts['from'] and opts['exact']:
        raise error.Abort(_('cannot use both --from and --exact'))
    elif opts['from']:
        # Try to extend given revision starting from the working directory
        extrevs = repo.revs('(%ld::.) or (.::%ld)', revs, revs)
        discardedrevs = [r for r in revs if r not in extrevs]
        if discardedrevs:
            msg = _("cannot fold non-linear revisions")
            hint = _("given revisions are unrelated to parent of working"
                     " directory")
            raise error.Abort(msg, hint=hint)
        revs = extrevs
    elif opts['exact']:
        # Nothing to do; "revs" is already set correctly
        pass
    else:
        raise error.Abort(_('must specify either --from or --exact'))

    if not revs:
        raise error.Abort(_('specified revisions evaluate to an empty set'),
                          hint=_('use different revision arguments'))
    elif len(revs) == 1:
        ui.write_err(_('single revision specified, nothing to fold\n'))
        return 1

    wlock = lock = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()

        root, head = _foldcheck(repo, revs)

        tr = repo.transaction('fold')
        try:
            commitopts = opts.copy()
            allctx = [repo[r] for r in revs]
            targetphase = max(c.phase() for c in allctx)

            if commitopts.get('message') or commitopts.get('logfile'):
                commitopts['edit'] = False
            else:
                msgs = ["HG: This is a fold of %d changesets." % len(allctx)]
                msgs += ["HG: Commit message of changeset %s.\n\n%s\n" %
                         (c.rev(), c.description()) for c in allctx]
                commitopts['message'] = "\n".join(msgs)
                commitopts['edit'] = True

            newid, unusedvariable = rewrite(repo, root, allctx, head,
                                            [root.p1().node(),
                                             root.p2().node()],
                                            commitopts=commitopts)
            phases.retractboundary(repo, tr, targetphase, [newid])
            obsolete.createmarkers(repo, [(ctx, (repo[newid],))
                                   for ctx in allctx])
            tr.close()
        finally:
            tr.release()
        ui.status('%i changesets folded\n' % len(revs))
        if repo['.'].rev() in revs:
            hg.update(repo, newid)
    finally:
        lockmod.release(lock, wlock)

@eh.command(
    '^metaedit',
    [('r', 'rev', [], _("revision to edit")),
     ('', 'fold', None, _("also fold specified revisions into one")),
    ] + commitopts + commitopts2,
    _('hg metaedit [OPTION]... [-r] [REV]'))
def metaedit(ui, repo, *revs, **opts):
    """edit commit information

    Edits the commit information for the specified revisions. By default, edits
    commit information for the working directory parent.

    With --fold, also folds multiple revisions into one if necessary. In this
    case, the given revisions must form a linear unbroken chain.

    .. container:: verbose

     Some examples:

     - Edit the commit message for the working directory parent::

         hg metaedit

     - Change the username for the working directory parent::

         hg metaedit --user 'New User <new-email@example.com>'

     - Combine all draft revisions that are ancestors of foo but not of @ into
       one::

         hg metaedit --fold 'draft() and only(foo,@)'

       See :hg:`help phases` for more about draft revisions, and
       :hg:`help revsets` for more about the `draft()` and `only()` keywords.
    """
    revs = list(revs)
    revs.extend(opts['rev'])
    if not revs:
        if opts['fold']:
            raise error.Abort(_('revisions must be specified with --fold'))
        revs = ['.']

    wlock = lock = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()

        revs = scmutil.revrange(repo, revs)
        if not opts['fold'] and len(revs) > 1:
            # TODO: handle multiple revisions. This is somewhat tricky because
            # if we want to edit a series of commits:
            #
            #   a ---- b ---- c
            #
            # we need to rewrite a first, then directly rewrite b on top of the
            # new a, then rewrite c on top of the new b. So we need to handle
            # revisions in topological order.
            raise error.Abort(_('editing multiple revisions without --fold is '
                                'not currently supported'))

        if opts['fold']:
            root, head = _foldcheck(repo, revs)
        else:
            if repo.revs("%ld and public()", revs):
                raise error.Abort(_('cannot edit commit information for public '
                                    'revisions'))
            newunstable = _disallowednewunstable(repo, revs)
            if newunstable:
                msg = _('cannot edit commit information in the middle'
                        ' of a stack')
                hint = _('%s will become unstable and new unstable changes'
                         ' are not allowed')
                hint %= repo[newunstable.first()]
                raise error.Abort(msg, hint=hint)
            root = head = repo[revs.first()]

        wctx = repo[None]
        p1 = wctx.p1()
        tr = repo.transaction('metaedit')
        newp1 = None
        try:
            commitopts = opts.copy()
            allctx = [repo[r] for r in revs]
            targetphase = max(c.phase() for c in allctx)

            if commitopts.get('message') or commitopts.get('logfile'):
                commitopts['edit'] = False
            else:
                if opts['fold']:
                    msgs = ["HG: This is a fold of %d changesets." % len(allctx)]
                    msgs += ["HG: Commit message of changeset %s.\n\n%s\n" %
                             (c.rev(), c.description()) for c in allctx]
                else:
                    msgs = [head.description()]
                commitopts['message'] = "\n".join(msgs)
                commitopts['edit'] = True

            # TODO: if the author and message are the same, don't create a new
            # hash. Right now we create a new hash because the date can be
            # different.
            newid, created = rewrite(repo, root, allctx, head,
                                     [root.p1().node(), root.p2().node()],
                                     commitopts=commitopts)
            if created:
                if p1.rev() in revs:
                    newp1 = newid
                phases.retractboundary(repo, tr, targetphase, [newid])
                obsolete.createmarkers(repo, [(ctx, (repo[newid],))
                                              for ctx in allctx])
            else:
                ui.status(_("nothing changed\n"))
            tr.close()
        finally:
            tr.release()

        if opts['fold']:
            ui.status('%i changesets folded\n' % len(revs))
        if newp1 is not None:
            hg.update(repo, newp1)
    finally:
        lockmod.release(lock, wlock)

def _foldcheck(repo, revs):
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
    if _disallowednewunstable(repo, revs):
        msg = _("cannot fold chain not ending with a head or with branching")
        hint = _("new unstable changesets are not allowed")
        raise error.Abort(msg, hint=hint)
    return root, head

def _disallowednewunstable(repo, revs):
    allowunstable = obsolete.isenabled(repo, obsolete.allowunstableopt)
    if allowunstable:
        return revset.baseset()
    return repo.revs("(%ld::) - %ld", revs, revs)

@eh.wrapcommand('graft')
def graftwrapper(orig, ui, repo, *revs, **kwargs):
    kwargs = dict(kwargs)
    revs = list(revs) + kwargs.get('rev', [])
    kwargs['rev'] = []
    obsoleted = kwargs.setdefault('obsolete', [])

    wlock = lock = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        if kwargs.get('old_obsolete'):
            if kwargs.get('continue'):
                obsoleted.extend(repo.vfs.read('graftstate').splitlines())
            else:
                obsoleted.extend(revs)
        # convert obsolete target into revs to avoid alias joke
        obsoleted[:] = [str(i) for i in repo.revs('%lr', obsoleted)]
        if obsoleted and len(revs) > 1:

            raise error.Abort(_('cannot graft multiple revisions while '
                                'obsoleting (for now).'))

        return commitwrapper(orig, ui, repo, *revs, **kwargs)
    finally:
        lockmod.release(lock, wlock)

@eh.extsetup
def oldevolveextsetup(ui):
    for cmd in ['prune', 'uncommit', 'touch', 'fold']:
        try:
            entry = extensions.wrapcommand(cmdtable, cmd,
                                           warnobserrors)
        except error.UnknownCommand:
            # Commands may be disabled
            continue

    entry = cmdutil.findcmd('commit', commands.table)[1]
    entry[1].append(('o', 'obsolete', [],
                     _("make commit obsolete this revision (DEPRECATED)")))
    entry = cmdutil.findcmd('graft', commands.table)[1]
    entry[1].append(('o', 'obsolete', [],
                     _("make graft obsoletes this revision (DEPRECATED)")))
    entry[1].append(('O', 'old-obsolete', False,
                     _("make graft obsoletes its source (DEPRECATED)")))

@eh.wrapfunction(obsolete, '_checkinvalidmarkers')
def _checkinvalidmarkers(orig, markers):
    """search for marker with invalid data and raise error if needed

    Exist as a separated function to allow the evolve extension for a more
    subtle handling.
    """
    if 'debugobsconvert' in sys.argv:
        return
    for mark in markers:
        if node.nullid in mark[1]:
            msg = _('bad obsolescence marker detected: invalid successors nullid')
            hint = _('You should run `hg debugobsconvert`')
            raise error.Abort(msg, hint=hint)

@eh.command(
    'debugobsconvert',
    [('', 'new-format', obsexchange._bestformat, _('Destination format for markers.'))],
    '')
def debugobsconvert(ui, repo, new_format):
    origmarkers = repo.obsstore._all  # settle version
    if new_format == repo.obsstore._version:
        msg = _('New format is the same as the old format, not upgrading!')
        raise error.Abort(msg)
    f = repo.svfs('obsstore', 'wb', atomictemp=True)
    known = set()
    markers = []
    for m in origmarkers:
        # filter out invalid markers
        if nullid in m[1]:
            m = list(m)
            m[1] = tuple(s for s in m[1] if s != nullid)
            m = tuple(m)
        if m in known:
            continue
        known.add(m)
        markers.append(m)
    ui.write(_('Old store is version %d, will rewrite in version %d\n') % (
        repo.obsstore._version, new_format))
    map(f.write, obsolete.encodemarkers(markers, True, new_format))
    f.close()
    ui.write(_('Done!\n'))


def _helploader(ui):
    return help.gettext(evolutionhelptext)

@eh.uisetup
def _setuphelp(ui):
    for entry in help.helptable:
        if entry[0] == "evolution":
            break
    else:
        help.helptable.append((["evolution"], _("Safely Rewriting History"),
                              _helploader))
        help.helptable.sort()

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
    destphase = repo[nodesrc].phase()
    oldbookmarks = repo.nodebookmarks(nodesrc)
    if nodenew is not None:
        phases.retractboundary(repo, tr, destphase, [nodenew])
        obsolete.createmarkers(repo, [(repo[nodesrc], (repo[nodenew],))])
        for book in oldbookmarks:
            repo._bookmarks[book] = nodenew
    else:
        obsolete.createmarkers(repo, [(repo[nodesrc], ())])
        # Behave like rebase, move bookmarks to dest
        for book in oldbookmarks:
            repo._bookmarks[book] = dest.node()
    for book in destbookmarks: # restore bookmark that rebase move
        repo._bookmarks[book] = dest.node()
    if oldbookmarks or destbookmarks:
        repo._bookmarks.recordchange(tr)

evolvestateversion = 0

@eh.uisetup
def setupevolveunfinished(ui):
    data = ('evolvestate', True, False, _('evolve in progress'),
            _("use 'hg evolve --continue' or 'hg update -C .' to abort"))
    cmdutil.unfinishedstates.append(data)

@eh.wrapfunction(hg, 'clean')
def clean(orig, repo, *args, **kwargs):
    ret = orig(repo, *args, **kwargs)
    util.unlinkpath(repo.vfs.join('evolvestate'), ignoremissing=True)
    return ret

def _evolvestatewrite(repo, state):
    # [version]
    # [type][length][content]
    #
    # `version` is a 4 bytes integer (handled at higher level)
    # `type` is a single character, `length` is a 4 byte integer, and
    # `content` is an arbitrary byte sequence of length `length`.
    f = repo.vfs('evolvestate', 'w')
    try:
        f.write(_pack('>I', evolvestateversion))
        current = state['current']
        key = 'C' # as in 'current'
        format = '>sI%is' % len(current)
        f.write(_pack(format, key, len(current), current))
    finally:
        f.close()

def _evolvestateread(repo):
    try:
        f = repo.vfs('evolvestate')
    except IOError as err:
        if err.errno != errno.ENOENT:
            raise
        return None
    try:
        versionblob = f.read(4)
        if len(versionblob) < 4:
            repo.ui.debug('ignoring corrupted evolvestte (file contains %i bits)'
                          % len(versionblob))
            return None
        version = _unpack('>I', versionblob)[0]
        if version != evolvestateversion:
            msg = _('unknown evolvestate version %i') % version
            raise error.Abort(msg, hint=_('upgrade your evolve'))
        records = []
        data = f.read()
        off = 0
        end = len(data)
        while off < end:
            rtype = data[off]
            off += 1
            length = _unpack('>I', data[off:(off + 4)])[0]
            off += 4
            record = data[off:(off + length)]
            off += length
            if rtype == 't':
                rtype, record = record[0], record[1:]
            records.append((rtype, record))
        state = {}
        for rtype, rdata in records:
            if rtype == 'C':
                state['current'] = rdata
            elif rtype.lower():
                repo.ui.debug('ignore evolve state record type %s' % rtype)
            else:
                raise error.Abort(_('unknown evolvestate field type %r')
                                  % rtype, hint=_('upgrade your evolve'))
        return state
    finally:
        f.close()

def _evolvestatedelete(repo):
    util.unlinkpath(repo.vfs.join('evolvestate'), ignoremissing=True)

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

    return merge.graft(repo, orig, pctx, ['local', 'graft'], True)
