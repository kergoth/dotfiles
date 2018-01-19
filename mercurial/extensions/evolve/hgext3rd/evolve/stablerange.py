# Code dedicated to the computation and properties of "stable ranges"
#
# These stable ranges are use for obsolescence markers discovery
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import abc
import functools
import heapq
import math
import os
import time

from mercurial import (
    error,
    node as nodemod,
    pycompat,
    scmutil,
    util,
)

from mercurial.i18n import _

from . import (
    exthelper,
    firstmergecache,
    stablesort,
    utility,
)

filterparents = utility.filterparents

eh = exthelper.exthelper()
eh.merge(stablesort.eh)
eh.merge(firstmergecache.eh)

# prior to hg-4.2 there are not util.timer
if util.safehasattr(util, 'timer'):
    timer = util.timer
elif util.safehasattr(time, "perf_counter"):
    timer = time.perf_counter
elif getattr(pycompat, 'osname', os.name) == 'nt':
    timer = time.clock
else:
    timer = time.time


#################################
### Stable Range computation  ###
#################################

def _hlp2(i):
    """return highest power of two lower than 'i'"""
    return 2 ** int(math.log(i - 1, 2))

def subrangesclosure(repo, stablerange, heads):
    """set of all standard subrange under heads

    This is intended for debug purposes. Range are returned from largest to
    smallest in terms of number of revision it contains."""
    subranges = stablerange.subranges
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
    rangelength = stablerange.rangelength
    ranges.sort(key=lambda r: (-rangelength(repo, r), n(r[0])))
    return ranges

_stablerangemethodmap = {
    'branchpoint': lambda repo: stablerange(),
    'default': lambda repo: repo.stablerange,
    'basic-branchpoint': lambda repo: stablerangebasic(),
    'basic-mergepoint': lambda repo: stablerangedummy_mergepoint(),
    'mergepoint': lambda repo: stablerange_mergepoint(),
}

@eh.command(
    'debugstablerange',
    [
        ('r', 'rev', [], 'operate on (rev, 0) ranges for rev in REVS'),
        ('', 'subranges', False, 'recursively display data for subranges too'),
        ('', 'verify', False, 'checks subranges content (EXPENSIVE)'),
        ('', 'method', 'branchpoint',
         'method to use, one of "branchpoint", "mergepoint"')
    ],
    _(''))
def debugstablerange(ui, repo, **opts):
    """display standard stable subrange for a set of ranges

    Range as displayed as '<node>-<index> (<rev>, <depth>, <length>)', use
    --verbose to get the extra details in ().
    """
    short = nodemod.short
    revs = scmutil.revrange(repo, opts['rev'])
    if not revs:
        raise error.Abort('no revisions specified')
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
    # prewarm depth cache
    unfi = repo.unfiltered()
    node = unfi.changelog.node

    method = opts['method']
    getstablerange = _stablerangemethodmap.get(method)
    if getstablerange is None:
        raise error.Abort('unknown stable sort method: "%s"' % method)

    stablerange = getstablerange(unfi)
    depth = stablerange.depthrev
    length = stablerange.rangelength
    subranges = stablerange.subranges
    stablerange.warmup(repo, max(revs))

    if opts['subranges']:
        ranges = subrangesclosure(unfi, stablerange, revs)
    else:
        ranges = [(r, 0) for r in revs]

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

class abstractstablerange(object):
    """The official API for a stablerange"""

    __metaclass__ = abc.ABCMeta

    @abc.abstractmethod
    def subranges(self, repo, rangeid):
        """return the stable sub-ranges of a rangeid"""
        raise NotImplemented()

    @abc.abstractmethod
    def revsfromrange(self, repo, rangeid):
        """return revision contained in a range"""
        raise NotImplemented()

    @abc.abstractmethod
    def depthrev(self, repo, rev):
        """depth a revision"""
        # Exist to allow basic implementation to ignore the depthcache
        # Could be demoted to _depthrev.
        raise NotImplemented()

    @abc.abstractmethod
    def warmup(self, repo, upto=None):
        """warmup the stable range cache"""
        raise NotImplemented()

    @abc.abstractmethod
    def rangelength(self, repo, rangeid):
        """number of revision in <range>"""
        raise NotImplemented()

    def _slicepoint(self, repo, rangeid):
        """find the standard slicing point for a range"""
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

class stablerangebasic(abstractstablerange):
    """a very dummy implementation of stablerange

    the implementation is here to lay down the basic algorithm in the stable
    range in a inefficient but easy to read manners. It should be used by test
    to validate output."""

    __metaclass__ = abc.ABCMeta

    def _sortfunction(self, repo, headrev):
        return stablesort.stablesort_branchpoint(repo, [headrev])

    def warmup(self, repo, upto=None):
        # no cache to warm for basic implementation
        pass

    def depthrev(self, repo, rev):
        """depth a revision"""
        return len(repo.revs('::%d', rev))

    def revsfromrange(self, repo, rangeid):
        """return revision contained in a range

        The range `(<head>, <skip>)` contains all revisions stable-sorted from
        <head>, skipping the <index>th lower revisions.
        """
        headrev, index = rangeid[0], rangeid[1]
        revs = self._sortfunction(repo, headrev)
        return revs[index:]

    def rangelength(self, repo, rangeid):
        """number of revision in <range>"""
        return len(self.revsfromrange(repo, rangeid))

    def subranges(self, repo, rangeid):
        """return the stable sub-ranges of a rangeid"""
        headrev, index = rangeid[0], rangeid[1]
        if self.rangelength(repo, rangeid) == 1:
            return []
        slicepoint = self._slicepoint(repo, rangeid)

        # search for range defining the lower set of revision
        #
        # we walk the lower set from the top following the stable order of the
        # current "head" of the lower range.
        #
        # As soon as the revision in the lowerset diverges from the one in the
        # range being generated, we emit the range and start a new one.
        result = []
        lowerrevs = self.revsfromrange(repo, rangeid)[:(slicepoint - index)]
        head = None
        headrange = None
        skip = None
        for rev in lowerrevs[::-1]:
            if head is None:
                head = rev
                headrange = self.revsfromrange(repo, (head, 0))
                skip = self.depthrev(repo, rev) - 1
            elif rev != headrange[skip - 1]:
                result.append((head, skip))
                head = rev
                headrange = self.revsfromrange(repo, (head, 0))
                skip = self.depthrev(repo, rev) - 1
            else:
                skip -= 1
        result.append((head, skip))

        result.reverse()

        # top part is trivial
        top = (headrev, slicepoint)
        result.append(top)

        # double check the result
        initialrevs = self.revsfromrange(repo, rangeid)
        subrangerevs = sum((self.revsfromrange(repo, sub) for sub in result),
                           [])
        assert initialrevs == subrangerevs
        return result

class stablerangedummy_mergepoint(stablerangebasic):
    """a very dummy implementation of stablerange use 'mergepoint' sorting
    """

    def _sortfunction(self, repo, headrev):
        return stablesort.stablesort_mergepoint_head_basic(repo, [headrev])

class stablerangecached(abstractstablerange):
    """an implementation of stablerange using caching"""

    __metaclass__ = abc.ABCMeta

    def __init__(self):
        # cache the standard stable subranges or a range
        self._subrangescache = {}
        super(stablerangecached, self).__init__()

    def depthrev(self, repo, rev):
        return repo.depthcache.get(rev)

    def rangelength(self, repo, rangeid):
        """number of revision in <range>"""
        headrev, index = rangeid[0], rangeid[1]
        return self.depthrev(repo, headrev) - index

    def subranges(self, repo, rangeid):
        assert 0 <= rangeid[1] <= rangeid[0], rangeid
        cached = self._getsub(rangeid)
        if cached is not None:
            return cached
        value = self._subranges(repo, rangeid)
        self._setsub(rangeid, value)
        return value

    def _getsub(self, rev):
        """utility function used to access the subranges cache

        This mostly exist to help the on disk persistence"""
        return self._subrangescache.get(rev)

    def _setsub(self, rev, value):
        """utility function used to set the subranges cache

        This mostly exist to help the on disk persistence."""
        self._subrangescache[rev] = value

class stablerange_mergepoint(stablerangecached):
    """Stablerange implementation using 'mergepoint' based sorting
    """

    def __init__(self):
        super(stablerange_mergepoint, self).__init__()

    def warmup(self, repo, upto=None):
        # no cache to warm for basic implementation
        pass

    def revsfromrange(self, repo, rangeid):
        """return revision contained in a range

        The range `(<head>, <skip>)` contains all revisions stable-sorted from
        <head>, skipping the <index>th lower revisions.
        """
        limit = self.rangelength(repo, rangeid)
        return repo.stablesort.get(repo, rangeid[0], limit=limit)

    def _stableparent(self, repo, headrev):
        """The parent of the changeset with reusable subrange

        For non-merge it is simple, there is a single parent. For Mercurial we
        have to find the right one. Since the stable sort use merge-point, we
        know that one of REV parents stable sort is a subset of REV stable
        sort. In other word:

            sort(::REV) = sort(::min(parents(REV))
                          + sort(only(max(parents(REV)), min(parents(REV)))
                          + [REV]

        We are looking for that `min(parents(REV))`. Since the subrange are
        based on the sort, we can reuse its subrange as well.
        """
        ps = filterparents(repo.changelog.parentrevs(headrev))
        if not ps:
            return nodemod.nullrev
        elif len(ps) == 1:
            return ps[0]
        else:
            tiebreaker = stablesort._mergepoint_tie_breaker(repo)
            return min(ps, key=tiebreaker)

    def _parentrange(self, repo, rangeid):
        stable_parent = self._stableparent(repo, rangeid[0])
        stable_parent_depth = self.depthrev(repo, stable_parent)
        stable_parent_range = (stable_parent, rangeid[1])
        return stable_parent_depth, stable_parent_range

    def _warmcachefor(self, repo, rangeid, slicepoint):
        """warm cache with all the element necessary"""
        stack = []
        depth, current = self._parentrange(repo, rangeid)
        while current not in self._subrangescache and slicepoint < depth:
            stack.append(current)
            depth, current = self._parentrange(repo, current)
        while stack:
            current = stack.pop()
            self.subranges(repo, current)

    def _subranges(self, repo, rangeid):
        headrev, initial_index = rangeid
        # size 1 range can't be sliced
        if self.rangelength(repo, rangeid) == 1:
            return []
        # find were we need to slice
        slicepoint = self._slicepoint(repo, rangeid)

        self._warmcachefor(repo, rangeid, slicepoint)

        stable_parent_data = self._parentrange(repo, rangeid)
        stable_parent_depth, stable_parent_range = stable_parent_data

        # top range is always the same, so we can build it early for all
        top_range = (headrev, slicepoint)

        # now find out about the lower range, if we are lucky there is only
        # one, otherwise we need to issue multiple one to cover every revision
        # on the lower set. (and cover them only once).
        if slicepoint == stable_parent_depth:
            # luckly shot, the parent is actually the head of the lower range
            subranges = [
                stable_parent_range,
                top_range,
            ]
        elif slicepoint < stable_parent_depth:
            # The parent is above the slice point,
            # it's lower subrange will be the same so we just get them,
            # (and the top range is always the same)
            subranges = self.subranges(repo, stable_parent_range)[:-1]
            subranges.append(top_range)
        elif initial_index < stable_parent_depth < slicepoint:
            # the parent is below the range we are considering, we need to
            # compute these uniques subranges
            subranges = [stable_parent_range]
            subranges.extend(self._unique_subranges(repo, headrev,
                                                    stable_parent_depth,
                                                    slicepoint))
            subranges.append(top_range)
        else:
            # we cannot reuse the parent range at all
            subranges = list(self._unique_subranges(repo, headrev,
                                                    initial_index,
                                                    slicepoint))
            subranges.append(top_range)

        return subranges

    def _unique_subranges(self, repo, headrev, initial_index, slicepoint):
        """Compute subrange unique to the exclusive part of merge"""
        result = []
        depth = repo.depthcache.get
        nextmerge = repo.firstmergecache.get
        walkfrom = functools.partial(repo.stablesort.walkfrom, repo)
        getjumps = functools.partial(repo.stablesort.getjumps, repo)
        skips = depth(headrev) - slicepoint
        tomap = slicepoint - initial_index

        jumps = getjumps(headrev)
        # this function is only caled if headrev is a merge
        # and initial_index is above its lower parents
        assert jumps is not None
        jumps = iter(jumps)
        assert 0 < skips, skips
        assert 0 < tomap, (tomap, (headrev, initial_index), slicepoint)

        # utility function to find the next changeset with jump information
        # (and the distance to it)
        def nextmergedata(startrev):
            merge = nextmerge(startrev)
            depthrev = depth(startrev)
            if merge == startrev:
                return 0, startrev
            elif merge == nodemod.nullrev:
                return depthrev, None
            depthmerge = depth(merge)
            return depthrev - depthmerge, merge

        # skip over all necesary data
        mainjump = None
        jumpdest = headrev
        while 0 < skips:
            jumphead = jumpdest
            currentjump = next(jumps)
            skipped = size = currentjump[2]
            jumpdest = currentjump[1]
            if size == skips:
                jumphead = jumpdest
                mainjump = next(jumps)
                mainsize = mainjump[2]
            elif skips < size:
                revs = walkfrom(jumphead)
                next(revs)
                for i in xrange(skips):
                    jumphead = next(revs)
                    assert jumphead is not None
                skipped = skips
                size -= skips
                mainjump = currentjump
                mainsize = size
            skips -= skipped
        assert skips == 0, skips

        # exiting from the previous block we should have:
        # jumphead: first non-skipped revision (head of the high subrange)
        # mainjump: next jump coming jump on main iteration
        # mainsize: len(mainjump[0]::jumphead)

        # Now we need to compare walk on the main iteration with walk from the
        # current subrange head. Instead of doing a full walk, we just skim
        # over the jumps for each iteration.
        rangehead = jumphead
        refjumps = None
        size = 0
        while size < tomap:
            assert mainjump is not None
            if refjumps is None:
                dist2merge, merge = nextmergedata(jumphead)
                if (mainsize <= dist2merge) or merge is None:
                    refjumps = iter(())
                    ref = None
                else:
                    # advance counters
                    size += dist2merge
                    mainsize -= dist2merge
                    jumphead = merge
                    refjumps = iter(getjumps(merge))
                    ref = next(refjumps, None)
            elif ref is not None and mainjump[0:2] == ref[0:2]:
                # both follow the same path
                size += mainsize
                jumphead = mainjump[1]
                mainjump = next(jumps, None)
                mainsize = mainjump[2]
                ref = next(refjumps, None)
                if ref is None:
                    # we are doing with section specific to the last merge
                    # reset `refjumps` to trigger the logic that search for the
                    # next merge
                    refjumps = None
            else:
                size += mainsize
                if size < tomap:
                    subrange = (rangehead, depth(rangehead) - size)
                    assert subrange[1] < depth(subrange[0])
                    result.append(subrange)
                    tomap -= size
                    size = 0
                    jumphead = rangehead = mainjump[1]
                    mainjump = next(jumps, None)
                    mainsize = mainjump[2]
                    refjumps = None

        if tomap:
            subrange = (rangehead, depth(rangehead) - tomap)
            assert subrange[1] < depth(subrange[0]), (rangehead, depth(rangehead), tomap)
            result.append(subrange)
        result.reverse()
        return result

class stablerange(stablerangecached):

    def __init__(self, lrusize=2000):
        # The point up to which we have data in cache
        self._tiprev = None
        self._tipnode = None
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
        super(stablerange, self).__init__()

    def warmup(self, repo, upto=None):
        """warm the cache up"""
        repo = repo.unfiltered()
        repo.depthcache.update(repo)
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

            allrevs = self._stablesortcache.get(headrev)
            if allrevs is None:
                allrevs = self._getrevsfrommerge(repo, headrev)
                if allrevs is None:
                    mc = self._filestablesortcache
                    sorting = stablesort.stablesort_branchpoint
                    allrevs = sorting(repo, [headrev], mergecallback=mc)
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
        prepared = self._stablesortprepared.get(merge)
        if prepared is None:
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
            cache = repo.depthcache
            # note: we cannot do a binary search because element under the
            # inherited point might have mismatching depth because of inner
            # branching.
            for rev in i:
                if cache.get(rev) == expected:
                    break
                expected -= 1
            value = (expected - 1, rev)
            self._inheritancecache[merge] = value
        return value

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
        ps = filterparents(self._parents(rangeid[0], repo.changelog.parentrevs))
        if not ps:
            return None
        elif len(ps) == 1:
            # regular changesets, we pick the parent
            reusablerev = ps[0]
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

    def _slicesrangeat(self, repo, rangeid, globalindex):
        ps = self._parents(rangeid[0], repo.changelog.parentrevs)
        if len(ps) == 1:
            reuserev = ps[0]
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

        result = []
        allrevs = self.revsfromrange(repo, rangeid)
        bottomrevs = allrevs[:localindex]

        if globalindex == self.depthrev(repo, bottomrevs[-1]):
            # simple case, top revision in the bottom set contains exactly the
            # revision we needs
            result.append((bottomrevs[-1], rangeid[1]))
        else:
            head = None
            headrange = None
            skip = None
            for rev in bottomrevs[::-1]:
                if head is None:
                    head = rev
                    headrange = self.revsfromrange(repo, (head, 0))
                    skip = self.depthrev(repo, rev) - 1
                elif rev != headrange[skip - 1]:
                    result.append((head, skip))
                    head = rev
                    headrange = self.revsfromrange(repo, (head, 0))
                    skip = self.depthrev(repo, rev) - 1
                else:
                    skip -= 1
            result.append((head, skip))

            result.reverse()

        # top part is trivial
        top = (rangeid[0], globalindex)
        result.append(top)
        return result
