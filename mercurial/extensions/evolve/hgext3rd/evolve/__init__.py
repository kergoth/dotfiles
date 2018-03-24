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

With the extension various evolution events will display warning (new unstable
changesets, obsolete working copy parent, improved error when accessing hidden
revision, etc).

In addition, the extension contains better discovery protocol for obsolescence
markers. This means less obs-markers will have to be pushed and pulled around,
speeding up such operation.

Some improvement and bug fixes available in newer version of Mercurial are also
backported to older version of Mercurial by this extension. Some older
experimental protocol are also supported for a longer time in the extensions to
help people transitioning. (The extensions is currently compatible down to
Mercurial version 4.1).

New Config::

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
algorithm has a naive implementation with too aggressive caching, creating
memory consumption issue (this will get fixed).

Medium sized repositories works fine, but be prepared for a noticeable initial
cache filling. for the Mercurial repository, this is around 20 seconds

The following config control the experiment::

  [experimental]

  # enable new discovery protocol
  # (needed on both client and server)
  obshashrange = yes

  # control cache warming at the end of transaction
  #   yes:  warm all caches at the end of each transaction,
  #   off:  warm no caches at the end of transaction,
  #   auto: warm cache at the end of server side transaction (default).
  obshashrange.warm-cache = 'auto'

The initial cache warming might be a bit slow. To make sure it is build you
can run one of the following commands in your repository::

    $ hg debugupdatecache # mercurial 4.3 and above
    $ hg debugobshashrange --rev 'head() # mercurial 4.2 and below

It is recommended to enable the blackbox extension. It gathers useful data about
the experiment. It is shipped with Mercurial so no extra install is needed::

    [extensions]
    blackbox =

Finally some extra options are available to help tame the experimental
implementation of some of the algorithms::

    [experimental]
    # restrict cache size to reduce memory consumption
    obshashrange.lru-size = 2000 # default is 2000

    # automatically disable obshashrange related computation and capabilities
    # if the repository has more than N revisions.  This is meant to help large
    # server deployment to enable the feature on smaller repositories while
    # ensuring no large repository will get affected.
    obshashrange.max-revs = 100000 # default is None

For very large repositories. it is currently recommended to disable obsmarkers
discovery (Make sure you follow release announcement to know when you can turn
it back on)::

    [experimental]
    evolution.obsdiscovery = no

Effect Flag Experiment
======================

Evolve also records what changed between two evolutions of a changeset. For
example, having this information is helpful to understand what changed between
an obsolete changeset and its tipmost successors.

Evolve currently records:

    - Meta changes, user, date
    - Tree movement, branch and parent, did the changeset moved?
    - Description, was the commit description edited
    - Diff, was there apart from potential diff change due to rebase a change in the diff?

These flags are lightweight and can be combined, so it's easy to see if 4
evolutions of the same changeset has just updated the description or if the
content changed and you need to review again the diff.

The effect flag recording is enabled by default in Evolve 6.4.0 so you have
nothing to do to enjoy it. Now every new evolution that you create will have
the effect flag attached.

The following config control the effect flag recording::

  [experimental]
  # uncomment to deactivate the registration of effect flags in obs markers
  # evolution.effect-flags = false

You can display the effect flags with the command obslog, so if you have a
changeset and you update only the message, you will see::

    $ hg commit -m "WIP
    $ hg commit -m "A better commit message!"
    $ hg obslog .
   @  8e9045855628 (3133) A better commit message!
   |
   x  7863a5bb5763 (3132) WIP
        rewritten(description) by Boris Feld <boris.feld@octobus.net> (Fri Jun 02 12:00:24 2017 +0200) as 8e9045855628

Servers does not need to activate the effect flag recording. Effect flags that
you create will not cause interference with other clients or servers without
the effect flag recording.

Templates
=========

Evolve ship several templates that you can use to have a better visibility
about your obs history:

  - precursors, for each obsolete changeset show the closest visible
    precursors.
  - successors, for each obsolete changeset show the closest visible
    successors. It is useful when your working directory is obsolete to see
    what are its successors. This information can also be retrieved with the
    obslog command and the --all option.
  - obsfate, for each obsolete changeset display a line summarizing what
    changed between the changeset and its successors. Depending on the
    verbosity level (-q and -v) it display the changeset successors, the users
    that created the obsmarkers and the date range of these changes.

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
via an extension).

Instability
==========

(note: the vocabulary is in the process of being updated)

Rewriting changesets might introduce instability (currently 'trouble').

There are two main kinds of instability: orphaning and diverging.

Orphans are changesets left behind when their ancestors are rewritten, (currently: 'unstable').
Divergence has two variants:

* Content-divergence occurs when independent rewrites of the same changesets
  lead to different results. (currently: 'divergent')

* Phase-divergence occurs when the old (obsolete) version of a changeset
  becomes public. (currently: 'bumped')

If it possible to prevent local creation of orphans by using the following config::

    [experimental]
    evolution=createmarkers,allnewcommands,exchange

You can also enable that option explicitly::

    [experimental]
    evolution=createmarkers,allnewcommands,allowunstable,exchange

or simply::

    [experimental]
    evolution=all
""".strip()

import sys
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
    raise ImportError('evolve needs Mercurial version %s or above' %
                      min(metadata.testedwith.split()))

import mercurial
from mercurial import util

from mercurial import obsolete
if not obsolete._enabled:
    obsolete._enabled = True

from mercurial import (
    bookmarks as bookmarksmod,
    cmdutil,
    commands,
    context,
    dirstate,
    error,
    extensions,
    help,
    hg,
    lock as lockmod,
    node,
    patch,
    revset,
    scmutil,
)

from mercurial.i18n import _
from mercurial.node import nullid

from . import (
    checkheads,
    compat,
    debugcmd,
    cmdrewrite,
    state,
    evolvecmd,
    exthelper,
    metadata,
    obscache,
    obsexchange,
    obshistory,
    rewriteutil,
    safeguard,
    templatekw,
    utility,
)

TROUBLES = compat.TROUBLES
__version__ = metadata.__version__
testedwith = metadata.testedwith
minimumhgversion = metadata.minimumhgversion
buglink = metadata.buglink

# Flags for enabling optional parts of evolve
commandopt = 'allnewcommands'

obsexcmsg = utility.obsexcmsg
shorttemplate = utility.shorttemplate

colortable = {'evolve.node': 'yellow',
              'evolve.user': 'green',
              'evolve.rev': 'blue',
              'evolve.short_description': '',
              'evolve.date': 'cyan',
              'evolve.current_rev': 'bold',
              'evolve.verb': '',
              'evolve.operation': 'bold'
              }

_pack = struct.pack
_unpack = struct.unpack

aliases, entry = cmdutil.findcmd('commit', commands.table)
commitopts3 = cmdrewrite.commitopts3
interactiveopt = cmdrewrite.interactiveopt
rewrite = rewriteutil.rewrite

# This extension contains the following code
#
# - Extension Helper code
# - Obsolescence cache
# - ...
# - Older format compat

eh = exthelper.exthelper()
eh.merge(debugcmd.eh)
eh.merge(evolvecmd.eh)
eh.merge(obsexchange.eh)
eh.merge(checkheads.eh)
eh.merge(safeguard.eh)
eh.merge(obscache.eh)
eh.merge(obshistory.eh)
eh.merge(templatekw.eh)
eh.merge(compat.eh)
eh.merge(cmdrewrite.eh)
uisetup = eh.final_uisetup
extsetup = eh.final_extsetup
reposetup = eh.final_reposetup
cmdtable = eh.cmdtable
configtable = eh.configtable

# Configuration
eh.configitem('experimental', 'evolutioncommands')
eh.configitem('experimental', 'evolution.allnewcommands')
eh.configitem('experimental', 'prunestrip')

# hack around because we need an actual default there
if configtable:
    configtable['experimental']['evolution.allnewcommands'].default = None

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
    evolveopts = repo.ui.configlist('experimental', 'evolution')
    if not evolveopts:
        evolveopts = ['all']
        repo.ui.setconfig('experimental', 'evolution', evolveopts, 'evolve')
    if obsolete.isenabled(repo, 'exchange'):
        # if no config explicitly set, disable bundle1
        if not isinstance(repo.ui.config('server', 'bundle1'), str):
            repo.ui.setconfig('server', 'bundle1', False)

    class trdescrepo(repo.__class__):

        def transaction(self, desc, *args, **kwargs):
            tr = super(trdescrepo, self).transaction(desc, *args, **kwargs)
            tr.desc = desc
            return tr

    repo.__class__ = trdescrepo

@eh.uisetup
def _configurecmdoptions(ui):
    # Unregister evolve commands if the command capability is not specified.
    #
    # This must be in the same function as the option configuration above to
    # guarantee it happens after the above configuration, but before the
    # extsetup functions.
    evolvecommands = ui.configlist('experimental', 'evolutioncommands', [])
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
def setupparentcommand(ui):

    _alias, statuscmd = cmdutil.findcmd('status', commands.table)
    pstatusopts = [o for o in statuscmd[1] if o[1] != 'rev']

    @eh.command('pstatus', pstatusopts)
    def pstatus(ui, repo, *args, **kwargs):
        """show status combining committed and uncommited changes

        This show the combined status of the current working copy parent commit and
        the uncommitted change in the working copy itself. The status displayed
        match the content of the commit that a bare :hg:`amend` will creates.

        See :hg:`help status` for details."""
        kwargs['rev'] = ['.^']
        return statuscmd[0](ui, repo, *args, **kwargs)

    _alias, diffcmd = cmdutil.findcmd('diff', commands.table)
    pdiffopts = [o for o in diffcmd[1] if o[1] != 'rev']

    @eh.command('pdiff', pdiffopts)
    def pdiff(ui, repo, *args, **kwargs):
        """show diff combining committed and uncommited changes

        This show the combined diff of the current working copy parent commit and
        the uncommitted change in the working copy itself. The diff displayed
        match the content of the commit that a bare :hg:`amend` will creates.

        See :hg:`help diff` for details."""
        kwargs['rev'] = ['.^']
        return diffcmd[0](ui, repo, *args, **kwargs)

@eh.uisetup
def _installalias(ui):
    if ui.config('alias', 'odiff') is None:
        ui.setconfig('alias', 'odiff',
                     "diff --hidden --rev 'limit(precursors(.),1)' --rev .",
                     'evolve')

### Troubled revset symbol

@eh.revset('troubled()')
def revsettroubled(repo, subset, x):
    """Changesets with troubles.
    """
    revset.getargs(x, 0, 0, 'troubled takes no arguments')
    troubled = set()
    troubled.update(getrevs(repo, 'orphan'))
    troubled.update(getrevs(repo, 'phasedivergent'))
    troubled.update(getrevs(repo, 'contentdivergent'))
    troubled = revset.baseset(troubled)
    troubled.sort() # set is non-ordered, enforce order
    return subset & troubled

### Obsolescence graph

# XXX SOME MAJOR CLEAN UP TO DO HERE XXX

def _precursors(repo, s):
    """Precursor of a changeset"""
    cs = set()
    nm = repo.changelog.nodemap
    markerbysubj = repo.obsstore.predecessors
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
    allsubjects = repo.obsstore.predecessors
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
@eh.revset('suspended()')
def revsetsuspended(repo, subset, x):
    """Obsolete changesets with non-obsolete descendants.
    """
    revset.getargs(x, 0, 0, 'suspended takes no arguments')
    suspended = revset.baseset(getrevs(repo, 'suspended'))
    suspended.sort()
    return subset & suspended


@eh.revset('precursors(set)')
def revsetprecursors(repo, subset, x):
    """Immediate precursors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_precursors(repo, s))
    s.sort()
    return subset & s


@eh.revset('allprecursors(set)')
def revsetallprecursors(repo, subset, x):
    """Transitive precursors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_allprecursors(repo, s))
    s.sort()
    return subset & s


@eh.revset('successors(set)')
def revsetsuccessors(repo, subset, x):
    """Immediate successors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_successors(repo, s))
    s.sort()
    return subset & s

@eh.revset('allsuccessors(set)')
def revsetallsuccessors(repo, subset, x):
    """Transitive successors of changesets in set.
    """
    s = revset.getset(repo, revset.fullreposet(repo), x)
    s = revset.baseset(_allsuccessors(repo, s))
    s.sort()
    return subset & s


#####################################################################
### Various trouble warning                                       ###
#####################################################################

# This section take care of issue warning to the user when troubles appear

def _warnobsoletewc(ui, repo, prevnode=None, wasobs=None):
    rev = repo['.']

    if not rev.obsolete():
        return

    if rev.node() == prevnode and wasobs:
        return
    msg = _("working directory parent is obsolete! (%s)\n")
    shortnode = node.short(rev.node())

    ui.warn(msg % shortnode)

    # Check that evolve is activated for performance reasons
    evolvecommandenabled = any('evolve' in e for e in cmdtable)
    if ui.quiet or not evolvecommandenabled:
        return

    # Show a warning for helping the user to solve the issue
    reason, successors = obshistory._getobsfateandsuccs(repo, rev.node())

    if reason == 'pruned':
        solvemsg = _("use 'hg evolve' to update to its parent successor")
    elif reason == 'diverged':
        debugcommand = "hg evolve --list --content-divergent"
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
    ctx = repo['.']
    node = ctx.node()
    isobs = ctx.obsolete()

    def warnobsolete():
        _warnobsoletewc(ui, repo, node, isobs)
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
    # hg < 4.4 does not have the feature built in. bail out otherwise.
    if util.safehasattr(scmutil, '_reportstroubledchangesets'):
        return orig(ui, repo, *args, **kwargs)

    # part of the troubled stuff may be filtered (stash ?)
    # This needs a better implementation but will probably wait for core.
    filtered = repo.changelog.filteredrevs
    priorunstables = len(set(getrevs(repo, 'orphan')) - filtered)
    priorbumpeds = len(set(getrevs(repo, 'phasedivergent')) - filtered)
    priordivergents = len(set(getrevs(repo, 'contentdivergent')) - filtered)
    ret = orig(ui, repo, *args, **kwargs)
    filtered = repo.changelog.filteredrevs
    newunstables = \
        len(set(getrevs(repo, 'orphan')) - filtered) - priorunstables
    newbumpeds = \
        len(set(getrevs(repo, 'phasedivergent')) - filtered) - priorbumpeds
    newdivergents = \
        len(set(getrevs(repo, 'contentdivergent')) - filtered) - priordivergents

    base_msg = _('%i new %s changesets\n')
    if newunstables > 0:
        ui.warn(base_msg % (newunstables, compat.TROUBLES['ORPHAN']))
    if newbumpeds > 0:
        ui.warn(base_msg % (newbumpeds, compat.TROUBLES['PHASEDIVERGENT']))
    if newdivergents > 0:
        ui.warn(base_msg % (newdivergents, compat.TROUBLES['CONTENTDIVERGENT']))
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
    evolvestate = state.cmdstate(repo)
    if evolvestate:
        # i18n: column positioning for "hg summary"
        ui.status(_('evolve: (evolve --continue)\n'))

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

### new command
#############################

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
    newfn.__doc__ = deprecationwarning + ' (DEPRECATED)'
    cmdwrapper = eh.command(oldalias, opts, synopsis)
    cmdwrapper(newfn)

@eh.extsetup
def deprecatealiases(ui):
    _deprecatealias('gup', 'next')
    _deprecatealias('gdown', 'previous')

def _gettopic(ctx):
    """handle topic fetching with or without the extension"""
    return getattr(ctx, 'topic', lambda: '')()

def _gettopicidx(ctx):
    """handle topic fetching with or without the extension"""
    return getattr(ctx, 'topicidx', lambda: None)()

def _getcurrenttopic(repo):
    return getattr(repo, 'currenttopic', '')

def _prevupdate(repo, displayer, target, bookmark, dryrun):
    if dryrun:
        repo.ui.write(_('hg update %s;\n') % target)
        if bookmark is not None:
            repo.ui.write(_('hg bookmark %s -r %s;\n')
                          % (bookmark, target))
    else:
        ret = hg.update(repo, target.rev())
        if not ret:
            tr = lock = None
            try:
                lock = repo.lock()
                tr = repo.transaction('previous')
                if bookmark is not None:
                    bmchanges = [(bookmark, target.node())]
                    compat.bookmarkapplychanges(repo, tr, bmchanges)
                else:
                    bookmarksmod.deactivate(repo)
                tr.close()
            finally:
                lockmod.release(tr, lock)

    if not repo.ui.quiet:
        displayer.show(target)

def _findprevtarget(repo, displayer, movebookmark=False, topic=True):
    target = bookmark = None
    wkctx = repo[None]
    p1 = wkctx.parents()[0]
    parents = p1.parents()
    currenttopic = _getcurrenttopic(repo)

    # we do not filter in the 1 case to allow prev to t0
    if currenttopic and topic and _gettopicidx(p1) != 1:
        parents = [repo[utility._singlesuccessor(repo, ctx)] if ctx.mutable() else ctx
                   for ctx in parents]
        parents = [ctx for ctx in parents if ctx.topic() == currenttopic]

    # issue message for the various case
    if p1.node() == node.nullid:
        repo.ui.warn(_('already at repository root\n'))
    elif not parents and currenttopic:
        repo.ui.warn(_('no parent in topic "%s"\n') % currenttopic)
        repo.ui.warn(_('(do you want --no-topic)\n'))
    elif len(parents) == 1:
        target = parents[0]
        bookmark = None
        if movebookmark:
            bookmark = repo._activebookmark
    else:
        header = _("multiple parents, choose one to update:")
        prevs = [p.rev() for p in parents]
        choosedrev = utility.revselectionprompt(repo.ui, repo, prevs, header)
        if choosedrev is None:
            for p in parents:
                displayer.show(p)
            repo.ui.warn(_('multiple parents, explicitly update to one\n'))
        else:
            target = repo[choosedrev]
    return target, bookmark

@eh.command(
    '^previous',
    [('B', 'move-bookmark', False,
        _('move active bookmark after update')),
     ('m', 'merge', False, _('bring uncommitted change along')),
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
            raise error.Abort(_('merge in progress'))
        if not opts['merge']:
            try:
                cmdutil.bailifchanged(repo)
            except error.Abort as exc:
                exc.hint = _('do you want --merge?')
                raise

        displayer = compat.changesetdisplayer(ui, repo,
                                              {'template': shorttemplate})
        topic = not opts.get("no_topic", False)

        target, bookmark = _findprevtarget(repo, displayer,
                                           opts.get('move_bookmark'), topic)
        if target is not None:
            backup = repo.ui.backupconfig('_internal', 'keep-topic')
            try:
                if topic and _getcurrenttopic(repo) != _gettopic(target):
                    repo.ui.setconfig('_internal', 'keep-topic', 'yes',
                                      source='topic-extension')
                _prevupdate(repo, displayer, target, bookmark, dryrunopt)
            finally:
                repo.ui.restoreconfig(backup)
            return 0
        else:
            return 1
    finally:
        lockmod.release(wlock)

@eh.command(
    '^next',
    [('B', 'move-bookmark', False,
        _('move active bookmark after update')),
     ('m', 'merge', False, _('bring uncommitted change along')),
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
            raise error.Abort(_('merge in progress'))
        if not opts['merge']:
            try:
                cmdutil.bailifchanged(repo)
            except error.Abort as exc:
                exc.hint = _('do you want --merge?')
                raise

        children = [ctx for ctx in wparents[0].children() if not ctx.obsolete()]
        topic = _getcurrenttopic(repo)
        filtered = []
        if topic and not opts.get("no_topic", False):
            filtered = [ctx for ctx in children if ctx.topic() != topic]
            # XXX N-square membership on children
            children = [ctx for ctx in children if ctx not in filtered]
        displayer = compat.changesetdisplayer(ui, repo,
                                              {'template': shorttemplate})
        if len(children) == 1:
            c = children[0]
            return _updatetonext(ui, repo, c, displayer, opts)
        elif children:
            cheader = _("ambiguous next changeset, choose one to update:")
            crevs = [c.rev() for c in children]
            choosedrev = utility.revselectionprompt(ui, repo, crevs, cheader)
            if choosedrev is None:
                ui.warn(_("ambiguous next changeset:\n"))
                for c in children:
                    displayer.show(c)
                ui.warn(_("explicitly update to one of them\n"))
                return 1
            else:
                return _updatetonext(ui, repo, repo[choosedrev], displayer, opts)
        else:
            aspchildren = evolvecmd._aspiringchildren(repo, [repo['.'].rev()])
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
                return 1
            elif 1 < len(aspchildren):
                cheader = _("ambiguous next (unstable) changeset, choose one to"
                            " evolve and update:")
                choosedrev = utility.revselectionprompt(ui, repo,
                                                        aspchildren, cheader)
                if choosedrev is None:
                    ui.warn(_("ambiguous next (unstable) changeset:\n"))
                    for c in aspchildren:
                        displayer.show(repo[c])
                    ui.warn(_("(run 'hg evolve --rev REV' on one of them)\n"))
                    return 1
                else:
                    return _nextevolve(ui, repo, repo[choosedrev], opts)
            else:
                return _nextevolve(ui, repo, aspchildren[0], opts)
    finally:
        lockmod.release(wlock)

def _nextevolve(ui, repo, aspchildren, opts):
    """logic for hg next command to evolve and update to an aspiring children"""

    cmdutil.bailifchanged(repo)
    evolvestate = state.cmdstate(repo, opts={'command': 'next'})
    result = evolvecmd._solveone(ui, repo, repo[aspchildren],
                                 evolvestate, opts.get('dry_run'), False,
                                 lambda: None, category='orphan')
    # making sure a next commit is formed
    if result[0] and result[1]:
        ui.status(_('working directory now at %s\n')
                  % ui.label(str(repo['.']), 'evolve.node'))
    return 0

def _updatetonext(ui, repo, children, displayer, opts):
    """ logic for `hg next` command to update to children and move bookmarks if
    required """
    bm = repo._activebookmark
    shouldmove = opts.get('move_bookmark') and bm is not None
    if opts.get('dry_run'):
        ui.write(_('hg update %s;\n') % children)
        if shouldmove:
            ui.write(_('hg bookmark %s -r %s;\n') % (bm, children))
    else:
        ret = hg.update(repo, children)
        if not ret:
            lock = tr = None
            try:
                lock = repo.lock()
                tr = repo.transaction('next')
                if shouldmove:
                    bmchanges = [(bm, children.node())]
                    compat.bookmarkapplychanges(repo, tr, bmchanges)
                else:
                    bookmarksmod.deactivate(repo)
                tr.close()
            finally:
                lockmod.release(tr, lock)
    if not ui.quiet:
        displayer.show(children)
    return 0

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
                compat.createmarkers(repo, markers, operation="amend")
            bmchanges = []
            for book in oldbookmarks:
                bmchanges.append((book, new.node()))
            if oldbookmarks:
                if not wlock:
                    wlock = repo.wlock()
                if not lock:
                    lock = repo.lock()
                tr = repo.transaction('commit')
                compat.bookmarkapplychanges(repo, tr, bmchanges)
                tr.close()
        return result
    finally:
        lockmod.release(tr, lock, wlock)

@eh.wrapcommand('strip', extension='strip', opts=[
    ('', 'bundle', None, _("delete the commit entirely and move it to a "
                           "backup bundle")),
    ])
def stripwrapper(orig, ui, repo, *revs, **kwargs):
    if (not ui.configbool('experimental', 'prunestrip', False) or
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
    return cmdrewrite.cmdprune(ui, repo, *revs, **kwargs)

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
    with repo.lock():
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

evolvestateversion = 0

@eh.uisetup
def setupevolveunfinished(ui):
    data = ('evolvestate', True, False, _('evolve in progress'),
            _("use 'hg evolve --continue' or 'hg update -C .' to abort"))
    cmdutil.unfinishedstates.append(data)

    afterresolved = ('evolvestate', _('hg evolve --continue'))
    grabresolved = ('grabstate', _('hg grab --continue'))
    cmdutil.afterresolvedstates.append(afterresolved)
    cmdutil.afterresolvedstates.append(grabresolved)

@eh.wrapfunction(hg, 'clean')
def clean(orig, repo, *args, **kwargs):
    ret = orig(repo, *args, **kwargs)
    util.unlinkpath(repo.vfs.join('evolvestate'), ignoremissing=True)
    return ret
