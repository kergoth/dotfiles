# Code dedicated to the computation of stable sorting
#
# These stable sorting are used stable ranges
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import collections

from mercurial import (
    commands,
    cmdutil,
    error,
    node as nodemod,
    scmutil,
)

from mercurial.i18n import _

from . import (
    depthcache,
    exthelper,
)

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
    return repo.changelog.node

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

    displayer = cmdutil.show_changeset(ui, repo, opts, buffered=True)
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
        p1, p2 = parents(r)
        children[p1].add(r)
        if p2 != nullrev:
            children[p2].add(r)
            parentmap[r] = tuple(sorted((p1, p2), key=tiebreaker))
        elif p1 != nullrev:
            parentmap[r] = (p1,)
        else:
            parentmap[r] = ()
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

    ps = [p for p in parents(head) if p is not nodemod.nullrev]
    while len(ps) == 1:
        top.append(ps[0])
        ps = [p for p in parents(ps[0]) if p is not nodemod.nullrev]
    top.reverse()
    if len(ps) == 2:
        ps.sort(key=tiebreaker)

        # get the part from the highest parent. This is the part that changes
        mid_revs = repo.revs('only(%d, %d)', ps[1], ps[0])
        if mid_revs:
            mid = stablesort_mergepoint_bounded(repo, ps[1], mid_revs)

        # And follow up with part othe parent we can inherit from
        bottom_revs = cl.ancestors([ps[0]], inclusive=True)
        bottom = stablesort_mergepoint_bounded(repo, ps[0], bottom_revs)

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
    return cache.get(repo, head, limit=limit)

class stablesortcache(object):

    def get(self, repo, rev, limit=None):
        result = []
        for r in self._revsfrom(repo, rev):
            result.append(r)
            if limit is not None and limit <= len(result):
                break
        result.reverse()
        return result

    def _revsfrom(self, repo, head):
        tiebreaker = _mergepoint_tie_breaker(repo)
        cl = repo.changelog
        parentsfunc = cl.parentrevs

        def parents(rev):
            return [p for p in parentsfunc(rev) if p is not nodemod.nullrev]

        current = head
        previous_current = None

        while current is not None:
            assert current is not previous_current
            yield current
            previous_current = current

            ps = parents(current)
            if not ps:
                current = None # break
            if len(ps) == 1:
                current = ps[0]
            elif len(ps) == 2:
                lower_parent, higher_parent = sorted(ps, key=tiebreaker)

                for rev in self._process_exclusive_side(lower_parent,
                                                        higher_parent,
                                                        cl.findmissingrevs,
                                                        parents,
                                                        tiebreaker):
                    yield rev

                current = lower_parent

    def _process_exclusive_side(self, lower, higher, findmissingrevs, parents, tiebreaker):

        exclusive = findmissingrevs(common=[lower],
                                    heads=[higher])

        stack = []
        seen = set()
        children = collections.defaultdict(set)
        if not exclusive:
            current = None
        else:
            current = higher
            bound = set(exclusive)
            for r in exclusive:
                for p in parents(r):
                    children[p].add(r)

        previous_current = None
        while current is not None:
            assert current is not previous_current
            yield current
            seen.add(current)
            previous_current = current

            ps = parents(current)

            usable_parents = [p for p in ps
                              if (p in bound and children[p].issubset(seen))]
            if not usable_parents:
                if stack:
                    current = stack.pop()
                else:
                    current = None
            elif len(usable_parents) == 1:
                    current = usable_parents[0]
            else:
                lower_parent, higher_parent = sorted(usable_parents, key=tiebreaker)
                stack.append(lower_parent)
                current = higher_parent

_methodmap = {
    'branchpoint': stablesort_branchpoint,
    'basic-mergepoint': stablesort_mergepoint_multirevs,
    'basic-headstart': stablesort_mergepoint_head_basic,
    'headstart': stablesort_mergepoint_head_debug,
    'headcached': stablesort_mergepoint_head_cached,
}
