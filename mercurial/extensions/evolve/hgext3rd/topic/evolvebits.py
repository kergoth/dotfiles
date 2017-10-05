import collections

from . import compat

# Copied from evolve 081605c2e9b6

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
    solvablerevs = [r for r in sorted(dependencies.keys())
                    if not dependencies[r]]
    ordering = []
    while solvablerevs:
        rev = solvablerevs.pop()
        for dependent in rdependencies[rev]:
            dependencies[dependent].remove(rev)
            if not dependencies[dependent]:
                solvablerevs.append(dependent)
        del dependencies[rev]
        ordering.append(rev)

    ordering.extend(sorted(dependencies))
    return ordering

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
    if 1 < len(newer):
        # divergence case
        # we should pick as arbitrary one
        raise MultipleSuccessorsError(newer)
    elif 1 < len(newer[0]):
        splitheads = list(repo.revs('heads(%ln::%ln)', newer[0], newer[0]))
        if 1 < len(splitheads):
            # split case, See if we can make sense of it.
            raise MultipleSuccessorsError(newer)
        return splitheads[0]

    return repo[newer[0][0]].rev()

class MultipleSuccessorsError(RuntimeError):
    """Exception raised by _singlesuccessor when multiple successor sets exists

    The object contains the list of successorssets in its 'successorssets'
    attribute to call to easily recover.
    """

    def __init__(self, successorssets):
        self.successorssets = successorssets
