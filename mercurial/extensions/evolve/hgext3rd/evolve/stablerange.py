# Code dedicated to the computation and properties of "stable ranges"
#
# These stable ranges are use for obsolescence markers discovery
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import collections
import heapq
import math
import os
import sqlite3
import time
import weakref

from mercurial import (
    commands,
    cmdutil,
    error,
    localrepo,
    node as nodemod,
    pycompat,
    scmutil,
    util,
)

from mercurial.i18n import _

from . import (
    exthelper,
)

eh = exthelper.exthelper()

# prior to hg-4.2 there are not util.timer
if util.safehasattr(util, 'timer'):
    timer = util.timer
elif util.safehasattr(time, "perf_counter"):
    timer = time.perf_counter
elif getattr(pycompat, 'osname', os.name) == 'nt':
    timer = time.clock
else:
    timer = time.time

##################################
### Stable topological sorting ###
##################################
@eh.command(
    'debugstablesort',
    [
        ('', 'rev', [], 'heads to start from'),
    ] + commands.formatteropts,
    _(''))
def debugstablesort(ui, repo, **opts):
    """display the ::REVS set topologically sorted in a stable way
    """
    revs = scmutil.revrange(repo, opts['rev'])
    displayer = cmdutil.show_changeset(ui, repo, opts, buffered=True)
    for r in stablesort(repo, revs):
        ctx = repo[r]
        displayer.show(ctx)
        displayer.flush(ctx)
    displayer.close()

def stablesort(repo, revs, mergecallback=None):
    """return '::revs' topologically sorted in "stable" order

    This is a depth first traversal starting from 'nullrev', using node as a
    tie breaker.
    """
    # Various notes:
    #
    # * Bitbucket is used dates as tie breaker, that might be a good idea.
    #
    # * It seemds we can traverse in the same order from (one) head to bottom,
    #   if we the following record data for each merge:
    #
    #  - highest (stablesort-wise) common ancestors,
    #  - order of parents (tablesort-wise)
    cl = repo.changelog
    parents = cl.parentrevs
    nullrev = nodemod.nullrev
    n = cl.node
    # step 1: We need a parents -> children mapping for 2 reasons.
    #
    # * we build the order from nullrev to tip
    #
    # * we need to detect branching
    children = collections.defaultdict(list)
    for r in cl.ancestors(revs, inclusive=True):
        p1, p2 = parents(r)
        children[p1].append(r)
        if p2 != nullrev:
            children[p2].append(r)
    # step two: walk back up
    # * pick lowest node in case of branching
    # * stack disregarded part of the branching
    # * process merge when both parents are yielded

    # track what changeset has been
    seen = [0] * (max(revs) + 2)
    seen[-1] = True # nullrev is known
    # starts from repository roots
    # reuse the list form the mapping as we won't need it again anyway
    stack = children[nullrev]
    if not stack:
        return []
    if 1 < len(stack):
        stack.sort(key=n, reverse=True)

    # list of rev, maybe we should yield, but since we built a children mapping we are 'O(N)' already
    result = []

    current = stack.pop()
    while current is not None or stack:
        if current is None:
            # previous iteration reached a merge or an unready merge,
            current = stack.pop()
            if seen[current]:
                current = None
                continue
        p1, p2 = parents(current)
        if not (seen[p1] and seen[p2]):
            # we can't iterate on this merge yet because other child is not
            # yielded yet (and we are topo sorting) we can discard it for now
            # because it will be reached from the other child.
            current = None
            continue
        assert not seen[current]
        seen[current] = True
        result.append(current) # could be yield, cf earlier comment
        if mergecallback is not None and p2 != nullrev:
            mergecallback(result, current)
        cs = children[current]
        if not cs:
            current = None
        elif 1 == len(cs):
            current = cs[0]
        else:
            cs.sort(key=n, reverse=True)
            current = cs.pop() # proceed on smallest
            stack.extend(cs)   # stack the rest for later
    assert len(result) == len(set(result))
    return result

#################################
### Stable Range computation  ###
#################################

def _hlp2(i):
    """return highest power of two lower than 'i'"""
    return 2 ** int(math.log(i - 1, 2))

def subrangesclosure(repo, heads):
    """set of all standard subrange under heads

    This is intended for debug purposes. Range are returned from largest to
    smallest in terms of number of revision it contains."""
    subranges = repo.stablerange.subranges
    toproceed = [(r, 0, ) for r in heads]
    ranges = set(toproceed)
    while toproceed:
        entry = toproceed.pop()
        for r in subranges(repo, entry):
            if r not in ranges:
                ranges.add(r)
                toproceed.append(r)
    ranges = list(ranges)
    n = repo.changelog.node
    rangelength = repo.stablerange.rangelength
    ranges.sort(key=lambda r: (-rangelength(repo, r), n(r[0])))
    return ranges

@eh.command(
    'debugstablerange',
    [
        ('', 'rev', [], 'operate on (rev, 0) ranges for rev in REVS'),
        ('', 'subranges', False, 'recursively display data for subranges too'),
        ('', 'verify', False, 'checks subranges content (EXPENSIVE)'),
    ],
    _(''))
def debugstablerange(ui, repo, **opts):
    """display standard stable subrange for a set of ranges

    Range as displayed as '<node>-<index> (<rev>, <depth>, <length>)', use
    --verbose to get the extra details in ().
    """
    short = nodemod.short
    revs = scmutil.revrange(repo, opts['rev'])
    # prewarm depth cache
    unfi = repo.unfiltered()
    node = unfi.changelog.node
    stablerange = unfi.stablerange
    depth = stablerange.depthrev
    length = stablerange.rangelength
    subranges = stablerange.subranges
    if not revs:
        raise error.Abort('no revisions specified')
    repo.stablerange.warmup(repo, max(revs))
    if opts['subranges']:
        ranges = subrangesclosure(repo, revs)
    else:
        ranges = [(r, 0) for r in revs]
    if ui.verbose:
        template = '%s-%d (%d, %d, %d)'

        def _rangestring(repo, rangeid):
            return template % (
                short(node(rangeid[0])),
                rangeid[1],
                rangeid[0],
                depth(unfi, rangeid[0]),
                length(unfi, rangeid)
            )
    else:
        template = '%s-%d'

        def _rangestring(repo, rangeid):
            return template % (
                short(node(rangeid[0])),
                rangeid[1],
            )

    for r in ranges:
        subs = subranges(unfi, r)
        subsstr = ', '.join(_rangestring(unfi, s) for s in subs)
        rstr = _rangestring(unfi, r)
        if opts['verify']:
            status = 'leaf'
            if 1 < length(unfi, r):
                status = 'complete'
                revs = set(stablerange.revsfromrange(unfi, r))
                subrevs = set()
                for s in subs:
                    subrevs.update(stablerange.revsfromrange(unfi, s))
                if revs != subrevs:
                    status = 'missing'
            ui.status('%s [%s] - %s\n' % (rstr, status, subsstr))
        else:
            ui.status('%s - %s\n' % (rstr, subsstr))

class stablerange(object):

    def __init__(self, lrusize=2000):
        # The point up to which we have data in cache
        self._tiprev = None
        self._tipnode = None
        # cache the 'depth' of a changeset, the size of '::rev'
        self._depthcache = {}
        # cache the standard stable subranges or a range
        self._subrangescache = {}
        # To slices merge, we need to walk their descendant in reverse stable
        # sort order. For now we perform a full stable sort their descendant
        # and then use the relevant top most part. This order is going to be
        # the same for all ranges headed at the same merge. So we cache these
        # value to reuse them accross the same invocation.
        self._stablesortcache = util.lrucachedict(lrusize)
        # something useful to compute the above
        # mergerev -> stablesort, length
        self._stablesortprepared = util.lrucachedict(lrusize)
        # caching parent call # as we do so many of them
        self._parentscache = {}
        # The first part of the stable sorted list of revision of a merge will
        # shared with the one of others. This means we can reuse subranges
        # computed from that point to compute some of the subranges from the
        # merge.
        self._inheritancecache = {}

    def warmup(self, repo, upto=None):
        """warm the cache up"""
        repo = repo.unfiltered()
        cl = repo.changelog
        # subrange should be warmed from head to range to be able to benefit
        # from revsfromrange cache. otherwise each merge will trigger its own
        # stablesort.
        #
        # we use the revnumber as an approximation for depth
        ui = repo.ui
        starttime = timer()

        if upto is None:
            upto = len(cl) - 1
        if self._tiprev is None:
            revs = cl.revs(stop=upto)
            nbrevs = upto + 1
        else:
            assert cl.node(self._tiprev) == self._tipnode
            if upto <= self._tiprev:
                return
            revs = cl.revs(start=self._tiprev + 1, stop=upto)
            nbrevs = upto - self._tiprev
        rangeheap = []
        for idx, r in enumerate(revs):
            if not idx % 1000:
                ui.progress(_("filling depth cache"), idx, total=nbrevs)
            # warm up depth
            self.depthrev(repo, r)
            rangeheap.append((-r, (r, 0)))
        ui.progress(_("filling depth cache"), None, total=nbrevs)

        heappop = heapq.heappop
        heappush = heapq.heappush
        heapify = heapq.heapify

        original = set(rangeheap)
        seen = 0
        # progress report is showing up in the profile for small and fast
        # repository so we build that complicated work around.
        progress_each = 100
        progress_last = time.time()
        heapify(rangeheap)
        while rangeheap:
            value = heappop(rangeheap)
            if value in original:
                if not seen % progress_each:
                    # if a lot of time passed, report more often
                    progress_new = time.time()
                    if (1 < progress_each) and (0.1 < progress_new - progress_last):
                        progress_each /= 10
                    ui.progress(_("filling stablerange cache"), seen, total=nbrevs)
                    progress_last = progress_new
                seen += 1
                original.remove(value) # might have been added from other source
            __, rangeid = value
            if self._getsub(rangeid) is None:
                for sub in self.subranges(repo, rangeid):
                    if self._getsub(sub) is None:
                        heappush(rangeheap, (-sub[0], sub))
        ui.progress(_("filling stablerange cache"), None, total=nbrevs)

        self._tiprev = upto
        self._tipnode = cl.node(upto)

        duration = timer() - starttime
        repo.ui.log('evoext-cache', 'updated stablerange cache in %.4f seconds\n',
                    duration)

    def depthrev(self, repo, rev):
        repo = repo.unfiltered()
        cl = repo.changelog
        depth = self._getdepth
        nullrev = nodemod.nullrev
        stack = [rev]
        while stack:
            revdepth = None
            current = stack[-1]
            revdepth = depth(current)
            if revdepth is not None:
                stack.pop()
                continue
            p1, p2 = self._parents(current, cl.parentrevs)
            if p1 == nullrev:
                # root case
                revdepth = 1
            elif p2 == nullrev:
                # linear commit case
                parentdepth = depth(p1)
                if parentdepth is None:
                    stack.append(p1)
                else:
                    revdepth = parentdepth + 1
            else:
                # merge case
                revdepth = self._depthmerge(cl, current, p1, p2, stack)
            if revdepth is not None:
                self._setdepth(current, revdepth)
                stack.pop()
        # actual_depth = len(list(cl.ancestors([rev], inclusive=True)))
        # assert revdepth == actual_depth, (rev, revdepth, actual_depth)
        return revdepth

    def rangelength(self, repo, rangeid):
        headrev, index = rangeid[0], rangeid[1]
        return self.depthrev(repo, headrev) - index

    def subranges(self, repo, rangeid):
        cached = self._getsub(rangeid)
        if cached is not None:
            return cached
        value = self._subranges(repo, rangeid)
        self._setsub(rangeid, value)
        return value

    def revsfromrange(self, repo, rangeid):
        headrev, index = rangeid
        rangelength = self.rangelength(repo, rangeid)
        if rangelength == 1:
            revs = [headrev]
        else:
            # get all revs under heads in stable order
            #
            # note: In the general case we can just walk down and then request
            # data about the merge. But I'm not sure this function will be even
            # call for the general case.

            # Lrudict.get in hg-3.9 returns the lrunode instead of the
            # value, use __getitem__ instead and catch the exception directly
            try:
                allrevs = self._stablesortcache[headrev]
            except KeyError:
                allrevs = None

            if allrevs is None:
                allrevs = self._getrevsfrommerge(repo, headrev)
                if allrevs is None:
                    allrevs = stablesort(repo, [headrev],
                                         mergecallback=self._filestablesortcache)
                self._stablesortcache[headrev] = allrevs
            # takes from index
            revs = allrevs[index:]
        # sanity checks
        assert len(revs) == rangelength
        return revs

    def _parents(self, rev, func):
        parents = self._parentscache.get(rev)
        if parents is None:
            parents = func(rev)
            self._parentscache[rev] = parents
        return parents

    def _getdepth(self, rev):
        """utility function used to access the depth cache

        This mostly exist to help the on disk persistence."""
        return self._depthcache.get(rev)

    def _setdepth(self, rev, value):
        """utility function used to set the depth cache

        This mostly exist to help the on disk persistence."""
        self._depthcache[rev] = value

    def _getsub(self, rev):
        """utility function used to access the subranges cache

        This mostly exist to help the on disk persistence"""
        return self._subrangescache.get(rev)

    def _setsub(self, rev, value):
        """utility function used to set the subranges cache

        This mostly exist to help the on disk persistence."""
        self._subrangescache[rev] = value

    def _filestablesortcache(self, sortedrevs, merge):
        if merge not in self._stablesortprepared:
            self._stablesortprepared[merge] = (sortedrevs, len(sortedrevs))

    def _getrevsfrommerge(self, repo, merge):
        # Lrudict.get in hg-3.9 returns the lrunode instead of the
        # value, use __getitem__ instead and catch the exception directly
        try:
            prepared = self._stablesortprepared[merge]
        except KeyError:
            return None

        mergedepth = self.depthrev(repo, merge)
        allrevs = prepared[0][:prepared[1]]
        nbextrarevs = prepared[1] - mergedepth
        if not nbextrarevs:
            return allrevs

        anc = repo.changelog.ancestors([merge], inclusive=True)
        top = []
        counter = nbextrarevs
        for rev in reversed(allrevs):
            if rev in anc:
                top.append(rev)
            else:
                counter -= 1
                if counter <= 0:
                    break

        bottomidx = prepared[1] - (nbextrarevs + len(top))
        revs = allrevs[:bottomidx]
        revs.extend(reversed(top))
        return revs

    def _inheritancepoint(self, repo, merge):
        """Find the inheritance point of a Merge

        The first part of the stable sorted list of revision of a merge will shared with
        the one of others. This means we can reuse subranges computed from that point to
        compute some of the subranges from the merge.

        That point is latest point in the stable sorted list where the depth of the
        revisions match its index (that means all revision earlier in the stable sorted
        list are its ancestors, no dangling unrelated branches exists).
        """
        value = self._inheritancecache.get(merge)
        if value is None:
            revs = self.revsfromrange(repo, (merge, 0))
            i = reversed(revs)
            i.next() # pop the merge
            expected = len(revs) - 1
            # Since we do warmup properly, we can expect the cache to be hot
            # for everythin under the merge we investigate
            cache = self._depthcache
            # note: we cannot do a binary search because element under the
            # inherited point might have mismatching depth because of inner
            # branching.
            for rev in i:
                if cache[rev] == expected:
                    break
                expected -= 1
            value = (expected - 1, rev)
            self._inheritancecache[merge] = value
        return value

    def _depthmerge(self, cl, rev, p1, p2, stack):
        # sub method to simplify the main 'depthrev' one
        revdepth = None
        depth = self._getdepth
        depth_p1 = depth(p1)
        depth_p2 = depth(p2)
        missingparent = False
        if depth_p1 is None:
            stack.append(p1)
            missingparent = True
        if depth_p2 is None:
            stack.append(p2)
            missingparent = True
        if missingparent:
            return None
        # computin depth of a merge
        # XXX the common ancestors heads could be cached
        ancnodes = cl.commonancestorsheads(cl.node(p1), cl.node(p2))
        ancrevs = [cl.rev(a) for a in ancnodes]
        anyunkown = False
        ancdepth = []
        for r in ancrevs:
            d = depth(r)
            if d is None:
                anyunkown = True
                stack.append(r)
            ancdepth.append((r, d))
        if anyunkown:
            return None
        if not ancrevs:
            # unrelated branch, (no common root)
            revdepth = depth_p1 + depth_p2 + 1
        elif len(ancrevs) == 1:
            # one unique branch point:
            # we can compute depth without any walk
            depth_anc = ancdepth[0][1]
            revdepth = depth_p1 + (depth_p2 - depth_anc) + 1
        else:
            # multiple ancestors, we pick one that is
            # * the deepest (less changeset outside of it),
            # * lowest revs because more chance to have descendant of other "above"
            anc, revdepth = max(ancdepth, key=lambda x: (x[1], -x[0]))
            revdepth += len(cl.findmissingrevs(common=[anc], heads=[rev]))
        return revdepth

    def _subranges(self, repo, rangeid):
        if self.rangelength(repo, rangeid) == 1:
            return []
        slicepoint = self._slicepoint(repo, rangeid)

        # make sure we have cache for all relevant parent first to prevent
        # recursion (python is bad with recursion
        stack = []
        current = rangeid
        while current is not None:
            current = self._cold_reusable(repo, current, slicepoint)
            if current is not None:
                stack.append(current)
        while stack:
            # these call will directly compute the subranges
            self.subranges(repo, stack.pop())
        return self._slicesrangeat(repo, rangeid, slicepoint)

    def _cold_reusable(self, repo, rangeid, slicepoint):
        """return parent range that it would be useful to prepare to slice
        rangeid at slicepoint

        This function also have the important task to update the revscache of
        the parent rev s if possible and needed"""
        p1, p2 = self._parents(rangeid[0], repo.changelog.parentrevs)
        if p2 == nodemod.nullrev:
            # regular changesets, we pick the parent
            reusablerev = p1
        else:
            # merge, we try the inheritance point
            # if it is too low, it will be ditched by the depth check anyway
            index, reusablerev = self._inheritancepoint(repo, rangeid[0])

        # if we reached the slicepoint, no need to go further
        if self.depthrev(repo, reusablerev) <= slicepoint:
            return None

        reurange = (reusablerev, rangeid[1])
        # if we have an entry for the current range, lets update the cache
        # if we already have subrange for this range, no need to prepare it.
        if self._getsub(reurange) is not None:
            return None

        # look like we found a relevent parentrange with no cache yet
        return reurange

    def _slicepoint(self, repo, rangeid):
        rangedepth = self.depthrev(repo, rangeid[0])
        step = _hlp2(rangedepth)
        standard_start = 0
        while standard_start < rangeid[1] and 0 < step:
            if standard_start + step < rangedepth:
                standard_start += step
            step //= 2
        if rangeid[1] == standard_start:
            slicesize = _hlp2(self.rangelength(repo, rangeid))
            slicepoint = rangeid[1] + slicesize
        else:
            assert standard_start < rangedepth
            slicepoint = standard_start
        return slicepoint

    def _slicesrangeat(self, repo, rangeid, globalindex):
        p1, p2 = self._parents(rangeid[0], repo.changelog.parentrevs)
        if p2 == nodemod.nullrev:
            reuserev = p1
        else:
            index, reuserev = self._inheritancepoint(repo, rangeid[0])
            if index < globalindex:
                return self._slicesrangeatmerge(repo, rangeid, globalindex)

        assert reuserev != nodemod.nullrev

        reuserange = (reuserev, rangeid[1])
        top = (rangeid[0], globalindex)

        if rangeid[1] + self.rangelength(repo, reuserange) == globalindex:
            return [reuserange, top]
        # This will not initiate a recursion since we took appropriate
        # precaution in the caller of this method to ensure it will be so.
        # It the parent is a merge that will not be the case but computing
        # subranges from a merge will not recurse.
        reusesubranges = self.subranges(repo, reuserange)
        slices = reusesubranges[:-1] # pop the top
        slices.append(top)
        return slices

    def _slicesrangeatmerge(self, repo, rangeid, globalindex):
        localindex = globalindex - rangeid[1]
        cl = repo.changelog

        result = []
        allrevs = self.revsfromrange(repo, rangeid)
        bottomrevs = allrevs[:localindex]

        if globalindex == self.depthrev(repo, bottomrevs[-1]):
            # simple case, top revision in the bottom set contains exactly the
            # revision we needs
            result.append((bottomrevs[-1], rangeid[1]))
        else:
            parentrevs = cl.parentrevs
            parents = self._parents
            bheads = set(bottomrevs)
            du = bheads.difference_update
            reachableroots = repo.changelog.reachableroots
            minrev = min(bottomrevs)
            for r in bottomrevs:
                du(parents(r, parentrevs))
            for h in bheads:
                # reachable roots is fast because is C
                #
                # It is worth noting that will use this kind of filtering from
                # "h" multiple time in a warming run. So using "ancestors" and
                # caching that should be faster. But python code filtering on
                # the ancestors end up being slower.
                hrevs = reachableroots(minrev, [h], bottomrevs, True)
                start = self.depthrev(repo, h) - len(hrevs)
                entry = (h, start)
                result.append(entry)

            # Talking about python code being slow, the following code is an
            # alternative implementation.
            #
            # It complexity is better since is does a single traversal on the
            # bottomset. However since it is all python it end up being
            # slower.
            # I'm keeping it here as an inspiration for a future C version
            # branches = []
            # for current in reversed(bottomrevs):
            #     ps = parents(current, parentrevs)
            #     found = False
            #     for brevs, bexpect in branches:
            #         if current in bexpect:
            #             found = True
            #             brevs.append(current)
            #             bexpect.discard(current)
            #             bexpect.update(ps)
            #     if not found:
            #         branches.append(([current], set(ps)))
            # for revs, __ in reversed(branches):
            #     head = revs[0]
            #     index = self.depthrev(repo, head) - len(revs)
            #     result.append((head, index))

        # top part is trivial
        top = (rangeid[0], globalindex)
        result.append(top)
        return result

#############################
### simple sqlite caching ###
#############################

_sqliteschema = [
    """CREATE TABLE meta(schemaversion INTEGER NOT NULL,
                         tiprev        INTEGER NOT NULL,
                         tipnode       BLOB    NOT NULL
                        );""",
    "CREATE TABLE depth(rev INTEGER NOT NULL PRIMARY KEY, depth INTEGER NOT NULL);",
    """CREATE TABLE range(rev INTEGER  NOT NULL,
                          idx INTEGER NOT NULL,
                          PRIMARY KEY(rev, idx));""",
    """CREATE TABLE subranges(listidx INTEGER NOT NULL,
                              suprev  INTEGER NOT NULL,
                              supidx  INTEGER NOT NULL,
                              subrev  INTEGER NOT NULL,
                              subidx  INTEGER NOT NULL,
                              PRIMARY KEY(listidx, suprev, supidx),
                              FOREIGN KEY (suprev, supidx) REFERENCES range(rev, idx),
                              FOREIGN KEY (subrev, subidx) REFERENCES range(rev, idx)
    );""",
    "CREATE INDEX subranges_index ON subranges (suprev, supidx);",
    "CREATE INDEX range_index ON range (rev, idx);",
    "CREATE INDEX depth_index ON depth (rev);"
]
_newmeta = "INSERT INTO meta (schemaversion, tiprev, tipnode) VALUES (?,?,?);"
_updatemeta = "UPDATE meta SET tiprev = ?, tipnode = ?;"
_updatedepth = "INSERT INTO depth(rev, depth) VALUES (?,?);"
_updaterange = "INSERT INTO range(rev, idx) VALUES (?,?);"
_updatesubranges = """INSERT
                       INTO subranges(listidx, suprev, supidx, subrev, subidx)
                       VALUES (?,?,?,?,?);"""
_queryexist = "SELECT name FROM sqlite_master WHERE type='table' AND name='meta';"
_querymeta = "SELECT schemaversion, tiprev, tipnode FROM meta;"
_querydepth = "SELECT depth FROM depth WHERE rev = ?;"
_batchdepth = "SELECT rev, depth FROM depth;"
_queryrange = "SELECT * FROM range WHERE (rev = ? AND idx = ?);"
_querysubranges = """SELECT subrev, subidx
                     FROM subranges
                     WHERE (suprev = ? AND supidx = ?)
                     ORDER BY listidx;"""

class sqlstablerange(stablerange):

    _schemaversion = 0

    def __init__(self, repo):
        lrusize = repo.ui.configint('experimental', 'obshashrange.lru-size',
                                    2000)
        super(sqlstablerange, self).__init__(lrusize=lrusize)
        self._vfs = repo.vfs
        self._path = repo.vfs.join('cache/evoext_stablerange_v0.sqlite')
        self._cl = repo.unfiltered().changelog # (okay to keep an old one)
        self._ondisktiprev = None
        self._ondisktipnode = None
        self._unsaveddepth = {}
        self._unsavedsubranges = {}
        self._fulldepth = False

    def warmup(self, repo, upto=None):
        self._con # make sure the data base is loaded
        try:
            # samelessly lock the repo to ensure nobody will update the repo
            # concurently. This should not be too much of an issue if we warm
            # at the end of the transaction.
            #
            # XXX However, we lock even if we are up to date so we should check
            # before locking
            with repo.lock():
                super(sqlstablerange, self).warmup(repo, upto)
                self._save(repo)
        except error.LockError:
            # Exceptionnally we are noisy about it since performance impact is
            # large We should address that before using this more widely.
            repo.ui.warn('stable-range cache: unable to lock repo while warming\n')
            repo.ui.warn('(cache will not be saved)\n')
            super(sqlstablerange, self).warmup(repo, upto)

    def _getdepth(self, rev):
        cache = self._depthcache
        if rev not in cache and rev <= self._ondisktiprev and self._con is not None:
            value = None
            result = self._con.execute(_querydepth, (rev,)).fetchone()
            if result is not None:
                value = result[0]
            # in memory caching of the value
            cache[rev] = value
        return cache.get(rev)

    def _setdepth(self, rev, depth):
        assert rev not in self._unsaveddepth
        self._unsaveddepth[rev] = depth
        super(sqlstablerange, self)._setdepth(rev, depth)

    def _getsub(self, rangeid):
        cache = self._subrangescache
        if rangeid not in cache and rangeid[0] <= self._ondisktiprev and self._con is not None:
            value = None
            result = self._con.execute(_queryrange, rangeid).fetchone()
            if result is not None: # database know about this node (skip in the future?)
                value = self._con.execute(_querysubranges, rangeid).fetchall()
            # in memory caching of the value
            cache[rangeid] = value
        return cache.get(rangeid)

    def _setsub(self, rangeid, value):
        assert rangeid not in self._unsavedsubranges
        self._unsavedsubranges[rangeid] = value
        super(sqlstablerange, self)._setsub(rangeid, value)

    def _inheritancepoint(self, *args, **kwargs):
        self._loaddepth()
        return super(sqlstablerange, self)._inheritancepoint(*args, **kwargs)

    def _db(self):
        try:
            util.makedirs(self._vfs.dirname(self._path))
        except OSError:
            return None
        con = sqlite3.connect(self._path)
        con.text_factory = str
        return con

    @util.propertycache
    def _con(self):
        con = self._db()
        if con is None:
            return None
        cur = con.execute(_queryexist)
        if cur.fetchone() is None:
            return None
        meta = con.execute(_querymeta).fetchone()
        if meta is None:
            return None
        if meta[0] != self._schemaversion:
            return None
        if len(self._cl) <= meta[1]:
            return None
        if self._cl.node(meta[1]) != meta[2]:
            return None
        self._ondisktiprev = meta[1]
        self._ondisktipnode = meta[2]
        if self._tiprev < self._ondisktiprev:
            self._tiprev = self._ondisktiprev
            self._tipnode = self._ondisktipnode
        return con

    def _save(self, repo):
        repo = repo.unfiltered()
        if not (self._unsavedsubranges or self._unsaveddepth):
            return # no new data

        if self._con is None:
            util.unlinkpath(self._path, ignoremissing=True)
            if '_con' in vars(self):
                del self._con

            con = self._db()
            if con is None:
                return
            with con:
                for req in _sqliteschema:
                    con.execute(req)

                meta = [self._schemaversion,
                        self._tiprev,
                        self._tipnode,
                ]
                con.execute(_newmeta, meta)
        else:
            con = self._con
            meta = con.execute(_querymeta).fetchone()
            if meta[2] != self._ondisktipnode or meta[1] != self._ondisktiprev:
                # drifting is currently an issue because this means another
                # process might have already added the cache line we are about
                # to add. This will confuse sqlite
                msg = _('stable-range cache: skipping write, '
                        'database drifted under my feet\n')
                hint = _('(disk: %s-%s vs mem: %s%s)\n')
                data = (meta[2], meta[1], self._ondisktiprev, self._ondisktipnode)
                repo.ui.warn(msg)
                repo.ui.warn(hint % data)
                return
            meta = [self._tiprev,
                    self._tipnode,
            ]
            con.execute(_updatemeta, meta)

        self._savedepth(con, repo)
        self._saverange(con, repo)
        con.commit()
        self._ondisktiprev = self._tiprev
        self._ondisktipnode = self._tipnode
        self._unsaveddepth.clear()
        self._unsavedsubranges.clear()

    def _savedepth(self, con, repo):
        repo = repo.unfiltered()
        data = self._unsaveddepth.items()
        con.executemany(_updatedepth, data)

    def _loaddepth(self):
        """batch load all data about depth"""
        if not (self._fulldepth or self._con is None):
            result = self._con.execute(_batchdepth)
            self._depthcache.update(result.fetchall())
            self._fulldepth = True

    def _saverange(self, con, repo):
        repo = repo.unfiltered()
        data = []
        allranges = set()
        for key, value in self._unsavedsubranges.items():
            allranges.add(key)
            for idx, sub in enumerate(value):
                data.append((idx, key[0], key[1], sub[0], sub[1]))

        con.executemany(_updaterange, allranges)
        con.executemany(_updatesubranges, data)


@eh.reposetup
def setupcache(ui, repo):

    class stablerangerepo(repo.__class__):

        @localrepo.unfilteredpropertycache
        def stablerange(self):
            return sqlstablerange(repo)

        @localrepo.unfilteredmethod
        def destroyed(self):
            if 'stablerange' in vars(self):
                del self.stablerange
            super(stablerangerepo, self).destroyed()

        def transaction(self, *args, **kwargs):
            tr = super(stablerangerepo, self).transaction(*args, **kwargs)
            if not repo.ui.configbool('experimental', 'obshashrange', False):
                return tr
            if not repo.ui.configbool('experimental', 'obshashrange.warm-cache',
                                      True):
                return tr
            maxrevs = self.ui.configint('experimental', 'obshashrange.max-revs', None)
            if maxrevs is not None and maxrevs < len(self.unfiltered()):
                return tr
            reporef = weakref.ref(self)

            def _warmcache(tr):
                repo = reporef()
                if repo is None:
                    return
                if 'node' in tr.hookargs:
                    # new nodes !
                    repo.stablerange.warmup(repo)

            tr.addpostclose('warmcache-10-stablerange', _warmcache)
            return tr

    repo.__class__ = stablerangerepo
