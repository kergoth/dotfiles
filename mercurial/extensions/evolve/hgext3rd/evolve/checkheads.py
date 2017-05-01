# Code dedicated to the postprocessing new heads check with obsolescence
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import functools

from mercurial import (
    discovery,
    error,
    extensions,
    node as nodemod,
    phases,
    util,
)

from mercurial.i18n import _

from . import exthelper

nullid = nodemod.nullid
short = nodemod.short
_headssummary = discovery._headssummary
_oldheadssummary = discovery._oldheadssummary
_nowarnheads = discovery._nowarnheads

eh = exthelper.exthelper()

@eh.uisetup
def setupcheckheadswrapper(ui):
    if not util.safehasattr(discovery, '_postprocessobsolete'):
        # hg-4.2+ has all the code natively
        extensions.wrapfunction(discovery, 'checkheads',
                                checkheadsfulloverlay)

# have dedicated wrapper to keep the rest as close as core as possible
def checkheadsfulloverlay(orig, pushop):
    if pushop.repo.obsstore:
        return corecheckheads(pushop)
    else:
        return orig(pushop)

# copied from mercurial.discovery.checkheads as in a5bad127128d (4.1)
#
# The only differences are:
# * the _postprocessobsolete section have been extracted,
# * minor test adjustment to please flake8
def corecheckheads(pushop):
    """Check that a push won't add any outgoing head

    raise Abort error and display ui message as needed.
    """

    repo = pushop.repo.unfiltered()
    remote = pushop.remote
    outgoing = pushop.outgoing
    remoteheads = pushop.remoteheads
    newbranch = pushop.newbranch
    inc = bool(pushop.incoming)

    # Check for each named branch if we're creating new remote heads.
    # To be a remote head after push, node must be either:
    # - unknown locally
    # - a local outgoing head descended from update
    # - a remote head that's known locally and not
    #   ancestral to an outgoing head
    if remoteheads == [nullid]:
        # remote is empty, nothing to check.
        return

    if remote.capable('branchmap'):
        headssum = _headssummary(repo, remote, outgoing)
    else:
        headssum = _oldheadssummary(repo, remoteheads, outgoing, inc)
    newbranches = [branch for branch, heads in headssum.iteritems()
                   if heads[0] is None]
    # 1. Check for new branches on the remote.
    if newbranches and not newbranch:  # new branch requires --new-branch
        branchnames = ', '.join(sorted(newbranches))
        raise error.Abort(_("push creates new remote branches: %s!")
                          % branchnames,
                          hint=_("use 'hg push --new-branch' to create"
                                 " new remote branches"))

    # 2. Find heads that we need not warn about
    nowarnheads = _nowarnheads(pushop)

    # 3. Check for new heads.
    # If there are more heads after the push than before, a suitable
    # error message, depending on unsynced status, is displayed.
    errormsg = None
    # If there is no obsstore, allfuturecommon won't be used, so no
    # need to compute it.
    if repo.obsstore:
        allmissing = set(outgoing.missing)
        cctx = repo.set('%ld', outgoing.common)
        allfuturecommon = set(c.node() for c in cctx)
        allfuturecommon.update(allmissing)
    for branch, heads in sorted(headssum.iteritems()):
        remoteheads, newheads, unsyncedheads = heads
        candidate_newhs = set(newheads)
        # add unsynced data
        if remoteheads is None:
            oldhs = set()
        else:
            oldhs = set(remoteheads)
        oldhs.update(unsyncedheads)
        candidate_newhs.update(unsyncedheads)
        dhs = None # delta heads, the new heads on branch
        if not repo.obsstore:
            discardedheads = set()
            newhs = candidate_newhs
        else:
            newhs, discardedheads = _postprocessobsolete(pushop,
                                                         allfuturecommon,
                                                         candidate_newhs)
        unsynced = sorted(h for h in unsyncedheads if h not in discardedheads)
        if unsynced:
            if None in unsynced:
                # old remote, no heads data
                heads = None
            elif len(unsynced) <= 4 or repo.ui.verbose:
                heads = ' '.join(short(h) for h in unsynced)
            else:
                heads = (' '.join(short(h) for h in unsynced[:4]) +
                         ' ' + _("and %s others") % (len(unsynced) - 4))
            if heads is None:
                repo.ui.status(_("remote has heads that are "
                                 "not known locally\n"))
            elif branch is None:
                repo.ui.status(_("remote has heads that are "
                                 "not known locally: %s\n") % heads)
            else:
                repo.ui.status(_("remote has heads on branch '%s' that are "
                                 "not known locally: %s\n") % (branch, heads))
        if remoteheads is None:
            if len(newhs) > 1:
                dhs = list(newhs)
                if errormsg is None:
                    errormsg = (_("push creates new branch '%s' "
                                  "with multiple heads") % (branch))
                    hint = _("merge or"
                             " see 'hg help push' for details about"
                             " pushing new heads")
        elif len(newhs) > len(oldhs):
            # remove bookmarked or existing remote heads from the new heads list
            dhs = sorted(newhs - nowarnheads - oldhs)
        if dhs:
            if errormsg is None:
                if branch not in ('default', None):
                    errormsg = _("push creates new remote head %s "
                                 "on branch '%s'!") % (short(dhs[0]), branch)
                elif repo[dhs[0]].bookmarks():
                    errormsg = (_("push creates new remote head %s "
                                  "with bookmark '%s'!")
                                % (short(dhs[0]), repo[dhs[0]].bookmarks()[0]))
                else:
                    errormsg = _("push creates new remote head %s!"
                                 ) % short(dhs[0])
                if unsyncedheads:
                    hint = _("pull and merge or"
                             " see 'hg help push' for details about"
                             " pushing new heads")
                else:
                    hint = _("merge or"
                             " see 'hg help push' for details about"
                             " pushing new heads")
            if branch is None:
                repo.ui.note(_("new remote heads:\n"))
            else:
                repo.ui.note(_("new remote heads on branch '%s':\n") % branch)
            for h in dhs:
                repo.ui.note((" %s\n") % short(h))
    if errormsg:
        raise error.Abort(errormsg, hint=hint)

def _postprocessobsolete(pushop, futurecommon, candidate):
    """post process the list of new heads with obsolescence information

    Exist as a subfunction to contains the complexity and allow extensions to
    experiment with smarter logic.
    Returns (newheads, discarded_heads) tuple
    """
    # remove future heads which are actually obsoleted by another
    # pushed element:
    #
    # known issue
    #
    # * We "silently" skip processing on all changeset unknown locally
    #
    # * if <nh> is public on the remote, it won't be affected by obsolete
    #     marker and a new is created
    repo = pushop.repo
    unfi = repo.unfiltered()
    tonode = unfi.changelog.node
    public = phases.public
    getphase = unfi._phasecache.phase
    ispublic = (lambda r: getphase(unfi, r) == public)
    hasoutmarker = functools.partial(pushingmarkerfor, unfi.obsstore, futurecommon)
    successorsmarkers = unfi.obsstore.successors
    newhs = set()
    discarded = set()
    # I leave the print in the code because they are so handy at debugging
    # and I keep getting back to this piece of code.
    #
    localcandidate = set()
    unknownheads = set()
    for h in candidate:
        if h in unfi:
            localcandidate.add(h)
        else:
            if successorsmarkers.get(h) is not None:
                msg = ('checkheads: remote head unknown locally has'
                       ' local marker: %s\n')
                repo.ui.debug(msg % nodemod.hex(h))
            unknownheads.add(h)
    if len(localcandidate) == 1:
        return unknownheads | set(candidate), set()
    while localcandidate:
        nh = localcandidate.pop()
        # run this check early to skip the revset on the whole branch
        if (nh in futurecommon
                or unfi[nh].phase() <= public):
            newhs.add(nh)
            continue
        # XXX there is a corner case if there is a merge in the branch. we
        # might end up with -more- heads.  However, these heads are not "added"
        # by the push, but more by the "removal" on the remote so I think is a
        # okay to ignore them,
        branchrevs = unfi.revs('only(%n, (%ln+%ln))',
                               nh, localcandidate, newhs)
        branchnodes = [tonode(r) for r in branchrevs]

        # The branch will still exist on the remote if
        # * any part of it is public,
        # * any part of it is considered part of the result by previous logic,
        # * if we have no markers to push to obsolete it.
        if (any(ispublic(r) for r in branchrevs)
                or any(n in futurecommon for n in branchnodes)
                or any(not hasoutmarker(n) for n in branchnodes)):
            newhs.add(nh)
        else:
            discarded.add(nh)
    newhs |= unknownheads
    return newhs, discarded

def pushingmarkerfor(obsstore, pushset, node):
    """True if some markers are to be pushed for node

    We cannot just look in to the pushed obsmarkers from the pushop because
    discover might have filtered relevant markers. In addition listing all
    markers relevant to all changeset in the pushed set would be too expensive.

    The is probably some cache opportunity in this function. but it would
    requires a two dimentions stack.
    """
    successorsmarkers = obsstore.successors
    stack = [node]
    seen = set(stack)
    while stack:
        current = stack.pop()
        if current in pushset:
            return True
        markers = successorsmarkers.get(current, ())
        # markers fields = ('prec', 'succs', 'flag', 'meta', 'date', 'parents')
        for m in markers:
            nexts = m[1] # successors
            if not nexts: # this is a prune marker
                nexts = m[5] # parents
            for n in nexts:
                if n not in seen:
                    seen.add(n)
                    stack.append(n)
    return False
