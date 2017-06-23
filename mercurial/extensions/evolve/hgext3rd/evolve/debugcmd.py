# Code dedicated to debug commands around evolution
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

# Status: Ready to Upstream
#
#  * We could have the same code in core as `hg debugobsolete --stat`,
#  * We probably want a way for the extension to hook in for extra data.

from mercurial import (
    obsolete,
    node,
)

from mercurial.i18n import _

from . import exthelper

eh = exthelper.exthelper()

@eh.command('debugobsstorestat', [], '')
def cmddebugobsstorestat(ui, repo):
    """print statistics about obsolescence markers in the repo"""
    def _updateclustermap(nodes, mark, clustersmap):
        c = (set(nodes), set([mark]))
        toproceed = set(nodes)
        while toproceed:
            n = toproceed.pop()
            other = clustersmap.get(n)
            if (other is not None
                and other is not c):
                other[0].update(c[0])
                other[1].update(c[1])
                for on in c[0]:
                    if on in toproceed:
                        continue
                    clustersmap[on] = other
                c = other
            clustersmap[n] = c

    store = repo.obsstore
    unfi = repo.unfiltered()
    nm = unfi.changelog.nodemap
    nbmarkers = len(store._all)
    ui.write(_('markers total:              %9i\n') % nbmarkers)
    sucscount = [0, 0, 0, 0]
    known = 0
    parentsdata = 0
    metakeys = {}
    # node -> cluster mapping
    #   a cluster is a (set(nodes), set(markers)) tuple
    clustersmap = {}
    # same data using parent information
    pclustersmap = {}
    size_v0 = []
    size_v1 = []
    for mark in store:
        if mark[0] in nm:
            known += 1
        nbsucs = len(mark[1])
        sucscount[min(nbsucs, 3)] += 1
        meta = mark[3]
        for key, value in meta:
            metakeys.setdefault(key, 0)
            metakeys[key] += 1
        meta = dict(meta)
        parents = [meta.get('p1'), meta.get('p2')]
        parents = [node.bin(p) for p in parents if p is not None]
        if parents:
            parentsdata += 1
        # cluster handling
        nodes = set(mark[1])
        nodes.add(mark[0])
        _updateclustermap(nodes, mark, clustersmap)
        # same with parent data
        nodes.update(parents)
        _updateclustermap(nodes, mark, pclustersmap)
        size_v0.append(len(obsolete._fm0encodeonemarker(mark)))
        size_v1.append(len(obsolete._fm1encodeonemarker(mark)))

    # freezing the result
    for c in clustersmap.values():
        fc = (frozenset(c[0]), frozenset(c[1]))
        for n in fc[0]:
            clustersmap[n] = fc
    # same with parent data
    for c in pclustersmap.values():
        fc = (frozenset(c[0]), frozenset(c[1]))
        for n in fc[0]:
            pclustersmap[n] = fc
    numobs = len(unfi.revs('obsolete()'))
    numtotal = len(unfi)
    ui.write(('    for known precursors:   %9i' % known))
    ui.write((' (%i/%i obsolete changesets)\n' % (numobs, numtotal)))
    ui.write(('    with parents data:      %9i\n' % parentsdata))
    # successors data
    ui.write(('markers with no successors: %9i\n' % sucscount[0]))
    ui.write(('              1 successors: %9i\n' % sucscount[1]))
    ui.write(('              2 successors: %9i\n' % sucscount[2]))
    ui.write(('    more than 2 successors: %9i\n' % sucscount[3]))
    # meta data info
    ui.write(('    available  keys:\n'))
    for key in sorted(metakeys):
        ui.write(('    %15s:        %9i\n' % (key, metakeys[key])))

    size_v0.sort()
    size_v1.sort()
    if size_v0:
        ui.write('marker size:\n')
        # format v1
        ui.write('    format v1:\n')
        ui.write(('        smallest length:    %9i\n' % size_v1[0]))
        ui.write(('        longer length:      %9i\n' % size_v1[-1]))
        median = size_v1[nbmarkers // 2]
        ui.write(('        median length:      %9i\n' % median))
        mean = sum(size_v1) // nbmarkers
        ui.write(('        mean length:        %9i\n' % mean))
        # format v0
        ui.write('    format v0:\n')
        ui.write(('        smallest length:    %9i\n' % size_v0[0]))
        ui.write(('        longer length:      %9i\n' % size_v0[-1]))
        median = size_v0[nbmarkers // 2]
        ui.write(('        median length:      %9i\n' % median))
        mean = sum(size_v0) // nbmarkers
        ui.write(('        mean length:        %9i\n' % mean))

    allclusters = list(set(clustersmap.values()))
    allclusters.sort(key=lambda x: len(x[1]))
    ui.write(('disconnected clusters:      %9i\n' % len(allclusters)))

    ui.write('        any known node:     %9i\n'
             % len([c for c in allclusters
                    if [n for n in c[0] if nm.get(n) is not None]]))
    if allclusters:
        nbcluster = len(allclusters)
        ui.write(('        smallest length:    %9i\n' % len(allclusters[0][1])))
        ui.write(('        longer length:      %9i\n'
                 % len(allclusters[-1][1])))
        median = len(allclusters[nbcluster // 2][1])
        ui.write(('        median length:      %9i\n' % median))
        mean = sum(len(x[1]) for x in allclusters) // nbcluster
        ui.write(('        mean length:        %9i\n' % mean))
    allpclusters = list(set(pclustersmap.values()))
    allpclusters.sort(key=lambda x: len(x[1]))
    ui.write(('    using parents data:     %9i\n' % len(allpclusters)))
    ui.write('        any known node:     %9i\n'
             % len([c for c in allclusters
                    if [n for n in c[0] if nm.get(n) is not None]]))
    if allpclusters:
        nbcluster = len(allpclusters)
        ui.write(('        smallest length:    %9i\n'
                 % len(allpclusters[0][1])))
        ui.write(('        longer length:      %9i\n'
                 % len(allpclusters[-1][1])))
        median = len(allpclusters[nbcluster // 2][1])
        ui.write(('        median length:      %9i\n' % median))
        mean = sum(len(x[1]) for x in allpclusters) // nbcluster
        ui.write(('        mean length:        %9i\n' % mean))
