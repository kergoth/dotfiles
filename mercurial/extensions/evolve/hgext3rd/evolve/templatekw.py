# Copyright 2011 Peter Arrenbrecht <peter.arrenbrecht@gmail.com>
#                Logilab SA        <contact@logilab.fr>
#                Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#                Patrick Mezard <patrick@mezard.eu>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""evolve templates
"""

from . import (
    exthelper,
    obshistory
)

from mercurial import (
    templatekw,
    node,
)

eh = exthelper.exthelper()

### template keywords
# XXX it does not handle troubles well :-/

@eh.templatekw('obsolete')
def obsoletekw(repo, ctx, templ, **args):
    """:obsolete: String. Whether the changeset is ``obsolete``.
    """
    if ctx.obsolete():
        return 'obsolete'
    return ''

@eh.templatekw('troubles')
def showtroubles(**args):
    """:troubles: List of strings. Evolution troubles affecting the changeset
    (zero or more of "unstable", "divergent" or "bumped")."""
    ctx = args['ctx']
    try:
        # specify plural= explicitly to trigger TypeError on hg < 4.2
        return templatekw.showlist('trouble', ctx.troubles(), args,
                                   plural='troubles')
    except TypeError:
        return templatekw.showlist('trouble', ctx.troubles(), plural='troubles',
                                   **args)

def closestprecursors(repo, nodeid):
    """ Yield the list of next precursors pointing on visible changectx nodes
    """

    precursors = repo.obsstore.precursors
    stack = [nodeid]

    while stack:
        current = stack.pop()
        currentpreccs = precursors.get(current, ())

        for prec in currentpreccs:
            precnodeid = prec[0]

            if precnodeid in repo:
                yield precnodeid
            else:
                stack.append(precnodeid)

@eh.templatekw("precursors")
def shownextvisibleprecursors(repo, ctx, **args):
    """Returns a string containing the list if the closest successors
    displayed
    """
    precursors = sorted(closestprecursors(repo, ctx.node()))

    # <= hg-4.1 requires an explicite gen.
    # we can use None once the support is dropped
    #
    # They also requires an iterator instead of an iterable.
    gen = iter(" ".join(map(node.short, precursors)))
    return templatekw._hybrid(gen.__iter__(), precursors, lambda x: {'precursor': x},
                              lambda d: "%s" % node.short(d['precursor']))

def closestsuccessors(repo, nodeid):
    """ returns the closest visible successors sets instead.
    """
    return directsuccessorssets(repo, nodeid)

@eh.templatekw("successors")
def shownextvisiblesuccessors(repo, ctx, templ, **args):
    """Returns a string of sets of successors for a changectx in this format:
    [ctx1, ctx2], [ctx3] if ctx has been splitted into ctx1 and ctx2 while
    also diverged into ctx3"""
    if not ctx.obsolete():
        return ''

    ssets = closestsuccessors(repo, ctx.node())

    data = []
    gen = []
    for ss in ssets:
        subgen = '[%s]' % ', '.join(map(node.short, ss))
        gen.append(subgen)
        h = templatekw._hybrid(iter(subgen), ss, lambda x: {'successor': x},
                               lambda d: "%s" % d["successor"])
        data.append(h)

    gen = ', '.join(gen)
    return templatekw._hybrid(iter(gen), data, lambda x: {'successorset': x},
                              lambda d: d["successorset"])

@eh.templatekw("obsfate_quiet")
def showobsfate_quiet(repo, ctx, templ, **args):
    if not ctx.obsolete():
        return ''

    successorssets = closestsuccessors(repo, ctx.node())
    return obshistory._humanizedobsfate(*obshistory._getobsfateandsuccs(repo, ctx, successorssets))

# copy from mercurial.obsolete with a small change to stop at first known changeset.

def directsuccessorssets(repo, initialnode, cache=None):
    """return set of all direct successors of initial nodes
    """

    succmarkers = repo.obsstore.successors

    # Stack of nodes we search successors sets for
    toproceed = [initialnode]
    # set version of above list for fast loop detection
    # element added to "toproceed" must be added here
    stackedset = set(toproceed)
    if cache is None:
        cache = {}
    while toproceed:
        current = toproceed[-1]
        if current in cache:
            stackedset.remove(toproceed.pop())
        elif current != initialnode and current in repo:
            # We have a valid direct successors.
            cache[current] = [(current,)]
        elif current not in succmarkers:
            if current in repo:
                # We have a valid last successors.
                cache[current] = [(current,)]
            else:
                # Final obsolete version is unknown locally.
                # Do not count that as a valid successors
                cache[current] = []
        else:
            for mark in sorted(succmarkers[current]):
                for suc in mark[1]:
                    if suc not in cache:
                        if suc in stackedset:
                            # cycle breaking
                            cache[suc] = []
                        else:
                            # case (3) If we have not computed successors sets
                            # of one of those successors we add it to the
                            # `toproceed` stack and stop all work for this
                            # iteration.
                            toproceed.append(suc)
                            stackedset.add(suc)
                            break
                else:
                    continue
                break
            else:
                succssets = []
                for mark in sorted(succmarkers[current]):
                    # successors sets contributed by this marker
                    markss = [[]]
                    for suc in mark[1]:
                        # cardinal product with previous successors
                        productresult = []
                        for prefix in markss:
                            for suffix in cache[suc]:
                                newss = list(prefix)
                                for part in suffix:
                                    # do not duplicated entry in successors set
                                    # first entry wins.
                                    if part not in newss:
                                        newss.append(part)
                                productresult.append(newss)
                        markss = productresult
                    succssets.extend(markss)
                # remove duplicated and subset
                seen = []
                final = []
                candidate = sorted(((set(s), s) for s in succssets if s),
                                   key=lambda x: len(x[1]), reverse=True)
                for setversion, listversion in candidate:
                    for seenset in seen:
                        if setversion.issubset(seenset):
                            break
                    else:
                        final.append(listversion)
                        seen.append(setversion)
                final.reverse() # put small successors set first
                cache[current] = final
    return cache[initialnode]
