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

The initial cache warming is currently a bit slow. To make sure it is build you
can run the following commands in your repository::

    $ hg debugobshashrange --rev 'head()

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
    # server deployement to enable the feature on smaller repositories while
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
  - successors, for each obsolete changeset show the closests visible
    successors. It is useful when your working directory is obsolete to see
    what are its successors. This information can also be retrieved with the
    obslog command and the --all option.
  - obsfate, for each obsolete changeset display a line summarizing what
    changed between the changeset and its successors. Dependending on the
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


import os
import sys
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

from mercurial.commands import mergetoolopts
from mercurial.i18n import _
from mercurial.node import nullid

from . import (
    checkheads,
    compat,
    debugcmd,
    cmdrewrite,
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

__version__ = metadata.__version__
testedwith = metadata.testedwith
minimumhgversion = metadata.minimumhgversion
buglink = metadata.buglink

sha1re = re.compile(r'\b[0-9a-f]{6,40}\b')

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
              }

_pack = struct.pack
_unpack = struct.unpack

aliases, entry = cmdutil.findcmd('commit', commands.table)
commitopts3 = cmdrewrite.commitopts3
interactiveopt = cmdrewrite.interactiveopt
_bookmarksupdater = rewriteutil.bookmarksupdater
rewrite = rewriteutil.rewrite

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
    evolveopts = ui.configlist('experimental', 'evolution')
    if not evolveopts:
        evolveopts = ['all']
        ui.setconfig('experimental', 'evolution', evolveopts, 'evolve')
    if obsolete.isenabled(repo, 'exchange'):
        repo.ui.setconfig('server', 'bundle1', False)

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
    if ui.config('alias', 'grab') is None:
        if os.name == 'nt':
            hgexe = ('"%s"' % util.hgexecutable())
            ui.setconfig('alias', 'grab', "! " + hgexe
                         + " rebase --dest . --rev $@ && "
                         + hgexe + " up tip",
                         'evolve')
        else:
            ui.setconfig('alias', 'grab',
                         "! $HG rebase --dest . --rev $@ && $HG up tip",
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
            repo.setparents(repo['.'].node(), nullid)
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

def _solveone(ui, repo, ctx, dryrun, confirm, progresscb, category):
    """Resolve the troubles affecting one revision"""
    wlock = lock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        tr = repo.transaction("evolve")
        if 'orphan' == category:
            result = _solveunstable(ui, repo, ctx, dryrun, confirm, progresscb)
        elif 'phasedivergent' == category:
            result = _solvebumped(ui, repo, ctx, dryrun, confirm, progresscb)
        elif 'contentdivergent' == category:
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
    newer = compat.successorssets(repo, obs.node())
    # search of a parent which is not killed
    while not newer:
        ui.debug("stabilize target %s is plain dead,"
                 " trying to stabilize on its parent\n" %
                 obs)
        obs = obs.parents()[0]
        newer = compat.successorssets(repo, obs.node())
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
            fm.plain('  orphan: %s (orphan parent)\n' % unpar[:hashlen])
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
     ('', 'phase-divergent', False, _('solves only phase-divergent changesets')),
     ('', 'divergent', False, _('solves only divergent changesets')),
     ('', 'content-divergent', False, _('solves only content-divergent changesets')),
     ('', 'unstable', False, _('solves only unstable changesets')),
     ('', 'orphan', False, _('solves only orphan changesets (default)')),
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

    troublecategories = ['phase_divergent', 'content_divergent', 'orphan']
    specifiedcategories = [t.replace('_', '')
                           for t in troublecategories
                           if opts[t]]
    if listopt:
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
    if targetcat == 'orphan':
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

def _solveunstable(ui, repo, orig, dryrun=False, confirm=False,
                   progresscb=None):
    """Stabilize an unstable changeset"""
    pctx = orig.p1()
    keepbranch = orig.p1().branch() != orig.branch()
    if len(orig.parents()) == 2:
        if not pctx.obsolete():
            pctx = orig.p2()  # second parent is obsolete ?
            keepbranch = orig.p2().branch() != orig.branch()
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
        cmdrewrite.amend(ui, repo, message='', logfile='')
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
        newer = compat.successorssets(ctx._repo, base.node())
        # drop filter and solution including the original ctx
        newer = [n for n in newer if n and ctx.node() not in n]
        if newer:
            return base, tuple(ctx._repo[o] for o in newer[0])
    raise error.Abort("base of divergent changeset %s not found" % ctx,
                      hint='this case is not yet handled')

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
        repo.ui.write(('hg update %s;\n' % target.rev()))
        if bookmark is not None:
            repo.ui.write(('hg bookmark %s -r %s;\n'
                           % (bookmark, target.rev())))
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

    displayer.show(target)

def _findprevtarget(repo, displayer, movebookmark=False, topic=True):
    target = bookmark = None
    wkctx = repo[None]
    p1 = wkctx.parents()[0]
    parents = p1.parents()
    currenttopic = _getcurrenttopic(repo)

    # we do not filter in the 1 case to allow prev to t0
    if currenttopic and topic and _gettopicidx(p1) != 1:
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
        for p in parents:
            displayer.show(p)
        repo.ui.warn(_('multiple parents, explicitly update to one\n'))
    return target, bookmark

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

        displayer = cmdutil.show_changeset(ui, repo, {'template': shorttemplate})
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
        topic = _getcurrenttopic(repo)
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
                            bmchanges = [(bm, c.node())]
                            compat.bookmarkapplychanges(repo, tr, bmchanges)
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
                                   False, lambda: None, category='orphan')
                if not result:
                    ui.status(_('working directory now at %s\n')
                              % ui.label(str(repo['.']), 'evolve.node'))
                return result
            return 1
        return result
    finally:
        lockmod.release(wlock)

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
    bmchanges = []

    if nodenew is not None:
        phases.retractboundary(repo, tr, destphase, [nodenew])
        obsolete.createmarkers(repo, [(repo[nodesrc], (repo[nodenew],))])
        for book in oldbookmarks:
            bmchanges.append((book, nodenew))
    else:
        obsolete.createmarkers(repo, [(repo[nodesrc], ())])
        # Behave like rebase, move bookmarks to dest
        for book in oldbookmarks:
            bmchanges.append((book, dest.node()))
    for book in destbookmarks: # restore bookmark that rebase move
        bmchanges.append((book, dest.node()))
    if bmchanges:
        compat.bookmarkapplychanges(repo, tr, bmchanges)

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
