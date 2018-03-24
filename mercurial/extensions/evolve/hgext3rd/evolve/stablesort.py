# Code dedicated to the computation of stable sorting
#
# These stable sorting are used stable ranges
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import array
import collections
import struct
import weakref

from mercurial import (
    commands,
    localrepo,
    error,
    node as nodemod,
    scmutil,
    util,
)

from mercurial.i18n import _

from . import (
    compat,
    depthcache,
    exthelper,
    utility,
    genericcaches,
)

filterparents = utility.filterparents

eh = exthelper.exthelper()
eh.merge(depthcache.eh)

def _mergepoint_tie_breaker(repo):
    """the key use to tie break merge parent

    Exists as a function to help playing with different approaches.

    Possible other factor are:
        * depth of node,
        * number of exclusive merges,
        * number of jump points.
        * <insert-your-idea>
    """
    node = repo.changelog.node
    depth = repo.depthcache.get

    def key(rev):
        return (-depth(rev), node(rev))
    return key

@eh.command(
    'debugstablesort',
    [
        ('r', 'rev', [], 'heads to start from'),
        ('', 'method', 'branchpoint', "method used for sorting, one of: "
         "branchpoint, basic-mergepoint and basic-headstart"),
        ('l', 'limit', '', 'number of revision display (default to all)')
    ] + commands.formatteropts,
    _(''))
def debugstablesort(ui, repo, **opts):
    """display the ::REVS set topologically sorted in a stable way
    """
    revs = scmutil.revrange(repo, opts['rev'])

    method = opts['method']
    sorting = _methodmap.get(method)
    if sorting is None:
        valid_method = ', '.join(sorted(_methodmap))
        raise error.Abort('unknown sorting method: "%s"' % method,
                          hint='pick one of: %s' % valid_method)

    displayer = compat.changesetdisplayer(ui, repo, opts, buffered=True)
    kwargs = {}
    if opts['limit']:
        kwargs['limit'] = int(opts['limit'])
    for r in sorting(repo, revs, **kwargs):
        ctx = repo[r]
        displayer.show(ctx)
        displayer.flush(ctx)
    displayer.close()

def stablesort_branchpoint(repo, revs, mergecallback=None):
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
        ps = filterparents(parents(r))
        if not ps:
            children[nullrev].append(r)
        for p in ps:
            children[p].append(r)
    # step two: walk back up
    # * pick lowest node in case of branching
    # * stack disregarded part of the branching
    # * process merge when both parents are yielded

    # track what changeset has been
    seen = [0] * (max(revs) + 2)
    seen[nullrev] = True # nullrev is known
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
        ps = filterparents(parents(current))
        if not all(seen[p] for p in ps):
            # we can't iterate on this merge yet because other child is not
            # yielded yet (and we are topo sorting) we can discard it for now
            # because it will be reached from the other child.
            current = None
            continue
        assert not seen[current]
        seen[current] = True
        result.append(current) # could be yield, cf earlier comment
        if mergecallback is not None and 2 <= len(ps):
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

def stablesort_mergepoint_multirevs(repo, revs):
    """return '::revs' topologically sorted in "stable" order

    This is a depth first traversal starting from 'revs' (toward root), using node as a
    tie breaker.
    """
    cl = repo.changelog
    tiebreaker = _mergepoint_tie_breaker(repo)
    if not revs:
        return []
    elif len(revs) == 1:
        heads = list(revs)
    else:
        # keeps heads only
        heads = sorted(repo.revs('heads(%ld::%ld)', revs, revs), key=tiebreaker)

    results = []
    while heads:
        h = heads.pop()
        if revs:
            bound = cl.findmissingrevs(common=heads, heads=[h])
        else:
            bound = cl.ancestors([h], inclusive=True)
        results.append(stablesort_mergepoint_bounded(repo, h, bound))
    if len(results) == 1:
        return results[0]
    finalresults = []
    for r in results[::-1]:
        finalresults.extend(r)
    return finalresults

def stablesort_mergepoint_bounded(repo, head, revs):
    """return 'revs' topologically sorted in "stable" order.

    The 'revs' set MUST have 'head' as its one and unique head.
    """
    # Various notes:
    #
    # * Bitbucket is using dates as tie breaker, that might be a good idea.
    cl = repo.changelog
    parents = cl.parentrevs
    nullrev = nodemod.nullrev
    tiebreaker = _mergepoint_tie_breaker(repo)
    # step 1: We need a parents -> children mapping to detect dependencies
    children = collections.defaultdict(set)
    parentmap = {}
    for r in revs:
        ps = filterparents(parents(r))
        if 2 <= len(ps):
            ps = tuple(sorted(ps, key=tiebreaker))
        parentmap[r] = ps
        for p in ps:
            children[p].add(r)
        if not ps:
            children[nullrev].add(r)
    # step two: walk again,
    stack = [head]
    resultset = set()
    result = []

    def add(current):
        resultset.add(current)
        result.append(current)

    while stack:
        current = stack.pop()
        add(current)
        parents = parentmap[current]
        for p in parents:
            if 1 < len(children[p]) and not children[p].issubset(resultset):
                # we need other children to be yield first
                continue
            if p in revs:
                stack.append(p)

    result.reverse()
    assert len(result) == len(resultset)
    return result

def stablesort_mergepoint_head_basic(repo, revs, limit=None):
    heads = repo.revs('heads(%ld)', revs)
    if not heads:
        return []
    elif 2 < len(heads):
        raise error.Abort('cannot use head based merging, %d heads found'
                          % len(heads))
    head = heads.first()
    revs = stablesort_mergepoint_bounded(repo, head, repo.revs('::%d', head))
    if limit is None:
        return revs
    return revs[-limit:]

def stablesort_mergepoint_head_debug(repo, revs, limit=None):
    heads = repo.revs('heads(%ld)', revs)
    if not heads:
        return []
    elif 2 < len(heads):
        raise error.Abort('cannot use head based merging, %d heads found'
                          % len(heads))
    head = heads.first()
    revs = stablesort_mergepoint_head(repo, head)
    if limit is None:
        return revs
    return revs[-limit:]

def stablesort_mergepoint_head(repo, head):
    """return '::rev' topologically sorted in "stable" order

    This is a depth first traversal starting from 'rev' (toward root), using node as a
    tie breaker.
    """
    cl = repo.changelog
    parents = cl.parentrevs
    tiebreaker = _mergepoint_tie_breaker(repo)

    top = [head]
    mid = []
    bottom = []

    ps = filterparents(parents(head))
    while len(ps) == 1:
        top.append(ps[0])
        ps = filterparents(parents(ps[0]))
    top.reverse()
    if len(ps) == 2:
        ps = sorted(ps, key=tiebreaker)

        # get the part from the highest parent. This is the part that changes
        mid_revs = repo.revs('only(%d, %d)', ps[1], ps[0])
        if mid_revs:
            mid = stablesort_mergepoint_bounded(repo, ps[1], mid_revs)

        # And follow up with part othe parent we can inherit from
        bottom = stablesort_mergepoint_head(repo, ps[0])

    return bottom + mid + top

def stablesort_mergepoint_head_cached(repo, revs, limit=None):
    heads = repo.revs('heads(%ld)', revs)
    if not heads:
        return []
    elif 2 < len(heads):
        raise error.Abort('cannot use head based merging, %d heads found'
                          % len(heads))
    head = heads.first()
    cache = stablesortcache()
    first = list(cache.get(repo, head, limit=limit))
    second = list(cache.get(repo, head, limit=limit))
    if first != second:
        repo.ui.warn('stablesort-cache: initial run different from re-run:\n'
                     '    %s\n'
                     '    %s\n' % (first, second))
    return second

class stablesortcache(object):

    def __init__(self):
        self._jumps = {}
        super(stablesortcache, self).__init__()

    def get(self, repo, rev, limit=None):
        result = []
        for r in self.walkfrom(repo, rev):
            result.append(r)
            if limit is not None and limit <= len(result):
                break
        result.reverse()
        return result

    def getjumps(self, repo, rev):
        if not self._hasjumpsdata(rev):
            parents = filterparents(repo.changelog.parentrevs(rev))
            if len(parents) <= 1:
                self._setjumps(rev, None)
            else:
                # merge ! warn the cache
                tiebreaker = _mergepoint_tie_breaker(repo)
                minparent = sorted(parents, key=tiebreaker)[0]
                for r in self.walkfrom(repo, rev):
                    if r == minparent:
                        break
        return self._getjumps(rev)

    def _hasjumpsdata(self, rev):
        return rev in self._jumps

    def _getjumps(self, rev):
        return self._jumps.get(rev)

    def _setjumps(self, rev, jumps):
        self._jumps[rev] = jumps

    def walkfrom(self, repo, head):
        tiebreaker = _mergepoint_tie_breaker(repo)
        cl = repo.changelog
        parentsfunc = cl.parentrevs

        def parents(rev):
            return filterparents(parentsfunc(rev))

        def oneparent(rev):
            ps = parents(rev)
            if not ps:
                return None
            if len(ps) == 1:
                return ps[0]
            return max(ps, key=tiebreaker)

        current = head
        previous_current_1 = object()
        previous_current_2 = object()

        while current is not None:
            previous_current_2 = previous_current_1
            previous_current_1 = current
            assert previous_current_1 is not previous_current_2

            jumps = self._getjumps(current)
            if jumps is not None:
                # we have enough cached information to directly iterate over
                # the exclusive size.
                for j in jumps:
                    jump_point = j[0]
                    jump_dest = j[1]
                    if current == jump_point:
                        yield current
                    else:
                        while current != jump_point:
                            yield current
                            current = oneparent(current)
                            assert current is not None
                        yield current
                    current = jump_dest
                continue

            yield current

            ps = parents(current)
            if not ps:
                current = None # break
            if len(ps) == 1:
                current = ps[0]
            elif len(ps) == 2:
                lower_parent, higher_parent = sorted(ps, key=tiebreaker)

                rev = current
                jumps = []

                def recordjump(source, destination, size):
                    jump = (source, destination, size)
                    jumps.append(jump)
                process = self._process_exclusive_side
                for rev in process(lower_parent, higher_parent, cl, parents,
                                   tiebreaker, recordjump):
                    yield rev

                if rev == current:
                    recordjump(rev, lower_parent, 1)

                self._setjumps(current, jumps)

                current = lower_parent

    def _process_exclusive_side(self, lower, higher, cl, parents, tiebreaker,
                                recordjump):

        exclusive = cl.findmissingrevs(common=[lower], heads=[higher])

        def popready(stack):
            """pop the top most ready item in the list"""
            for idx in xrange(len(stack) - 1, -1, -1):
                if children[stack[idx]].issubset(seen):
                    return stack.pop(idx)
            return None

        hardstack = []
        previous = None
        seen = set()
        current = higher
        children = collections.defaultdict(set)
        bound = set(exclusive)
        if exclusive:
            for r in exclusive:
                for p in parents(r):
                    children[p].add(r)

            hardstack.append(higher)
        nextjump = False
        size = 1 # take the merge point into account
        while hardstack:
            current = popready(hardstack)
            if current in seen:
                continue
            softstack = []
            while current in bound and current not in seen:
                if nextjump:
                    recordjump(previous, current, size)
                    nextjump = False
                    size = 0
                yield current
                size += 1
                previous = current
                seen.add(current)

                all_parents = parents(current)

                # search or next parent to walk through
                fallback, next = None, None
                if 1 == len(all_parents):
                    next = all_parents[0]
                elif 2 <= len(all_parents):
                    fallback, next = sorted(all_parents, key=tiebreaker)

                # filter parent not ready (children not emitted)
                while next is not None and not children[next].issubset(seen):
                    nextjump = True
                    next = fallback
                    fallback = None

                # stack management
                if next is None:
                    next = popready(softstack)
                    if next is not None:
                        nextjump = True
                elif fallback is not None:
                    softstack.append(fallback)

                # get ready for next iteration
                current = next

            # any in processed head has to go in the hard stack
            nextjump = True
            hardstack.extend(softstack)

        if previous is not None:
            recordjump(previous, lower, size)

def stablesort_mergepoint_head_ondisk(repo, revs, limit=None):
    heads = repo.revs('heads(%ld)', revs)
    if not heads:
        return []
    elif 2 < len(heads):
        raise error.Abort('cannot use head based merging, %d heads found'
                          % len(heads))
    head = heads.first()
    unfi = repo.unfiltered()
    cache = unfi.stablesort
    cache.save(unfi)
    return cache.get(repo, head, limit=limit)

S_INDEXSIZE = struct.Struct('>I')

class ondiskstablesortcache(stablesortcache, genericcaches.changelogsourcebase):

    _filepath = 'evoext-stablesortcache-00'
    _cachename = 'evo-ext-stablesort'

    def __init__(self):
        super(ondiskstablesortcache, self).__init__()
        self._index = array.array('l')
        self._data = array.array('l')
        del self._jumps

    def getjumps(self, repo, rev):
        if len(self._index) < rev:
            msg = 'stablesortcache must be warmed before use (%d < %d)'
            msg %= (len(self._index), rev)
            raise error.ProgrammingError(msg)
        return self._getjumps(rev)

    def _getjumps(self, rev):
        # very first revision
        if rev == 0:
            return None
        # no data yet
        if len(self._index) <= rev:
            return None
        index = self._index
        # non merge revision
        if index[rev] == index[rev - 1]:
            return None
        data = self._data
        # merge revision

        def jumps():
            for idx in xrange(index[rev - 1], index[rev]):
                i = idx * 3
                yield tuple(data[i:i + 3])
        return jumps()

    def _setjumps(self, rev, jumps):
        assert len(self._index) == rev, (len(self._index), rev)
        if rev == 0:
            self._index.append(0)
            return
        end = self._index[rev - 1]
        if jumps is None:
            self._index.append(end)
            return
        assert len(self._data) == end * 3, (len(self._data), end)
        for j in jumps:
            self._data.append(j[0])
            self._data.append(j[1])
            self._data.append(j[2])
            end += 1
        self._index.append(end)

    def _updatefrom(self, repo, data):
        repo = repo.unfiltered()

        total = len(data)

        def progress(pos, rev):
            repo.ui.progress('updating stablesort cache',
                             pos, 'rev %s' % rev, unit='revision', total=total)

        progress(0, '')
        for idx, rev in enumerate(data):
            parents = filterparents(repo.changelog.parentrevs(rev))
            if len(parents) <= 1:
                self._setjumps(rev, None)
            else:
                # merge! warn the cache
                tiebreaker = _mergepoint_tie_breaker(repo)
                minparent = sorted(parents, key=tiebreaker)[0]
                for r in self.walkfrom(repo, rev):
                    if r == minparent:
                        break
            if not (idx % 1000): # progress as a too high performance impact
                progress(idx, rev)
        progress(None, '')

    def clear(self, reset=False):
        super(ondiskstablesortcache, self).clear()
        self._index = array.array('l')
        self._data = array.array('l')

    def load(self, repo):
        """load data from disk

        (crude version, read everything all the time)
        """
        assert repo.filtername is None

        cachevfs = compat.getcachevfs(repo)
        data = cachevfs.tryread(self._filepath)
        self._index = array.array('l')
        self._data = array.array('l')
        if not data:
            self._cachekey = self.emptykey
        else:
            headerdata = data[:self._cachekeysize]
            self._cachekey = self._deserializecachekey(headerdata)
            offset = self._cachekeysize
            indexsizedata = data[offset:offset + S_INDEXSIZE.size]
            indexsize = S_INDEXSIZE.unpack(indexsizedata)[0]
            offset += S_INDEXSIZE.size
            self._index.fromstring(data[offset:offset + indexsize])
            offset += indexsize
            self._data.fromstring(data[offset:])
        self._ondiskkey = self._cachekey
        pass

    def save(self, repo):
        """save the data to disk

        (crude version, rewrite everything all the time)
        """
        if self._cachekey is None or self._cachekey == self._ondiskkey:
            return
        cachevfs = compat.getcachevfs(repo)
        cachefile = cachevfs(self._filepath, 'w', atomictemp=True)

        # data to write
        headerdata = self._serializecachekey()
        indexdata = self._index.tostring()
        data = self._data.tostring()
        indexsize = S_INDEXSIZE.pack(len(indexdata))

        # writing
        cachefile.write(headerdata)
        cachefile.write(indexsize)
        cachefile.write(indexdata)
        cachefile.write(data)
        cachefile.close()

@eh.reposetup
def setupcache(ui, repo):

    class stablesortrepo(repo.__class__):

        @localrepo.unfilteredpropertycache
        def stablesort(self):
            cache = ondiskstablesortcache()
            cache.update(self)
            return cache

        @localrepo.unfilteredmethod
        def destroyed(self):
            if 'stablesort' in vars(self):
                self.stablesort.clear()
            super(stablesortrepo, self).destroyed()

        if util.safehasattr(repo, 'updatecaches'):
            @localrepo.unfilteredmethod
            def updatecaches(self, tr=None, **kwargs):
                if utility.shouldwarmcache(self, tr):
                    self.stablesort.update(self)
                    self.stablesort.save(self)
                super(stablesortrepo, self).updatecaches(tr, **kwargs)

        else:
            def transaction(self, *args, **kwargs):
                tr = super(stablesortrepo, self).transaction(*args, **kwargs)
                reporef = weakref.ref(self)

                def _warmcache(tr):
                    repo = reporef()
                    if repo is None:
                        return
                    repo = repo.unfiltered()
                    repo.stablesort.update(repo)
                    repo.stablesort.save(repo)

                if utility.shouldwarmcache(self, tr):
                    tr.addpostclose('warmcache-02stablesort', _warmcache)
                return tr

    repo.__class__ = stablesortrepo

_methodmap = {
    'branchpoint': stablesort_branchpoint,
    'basic-mergepoint': stablesort_mergepoint_multirevs,
    'basic-headstart': stablesort_mergepoint_head_basic,
    'headstart': stablesort_mergepoint_head_debug,
    'headcached': stablesort_mergepoint_head_cached,
    'headondisk': stablesort_mergepoint_head_ondisk,
}
