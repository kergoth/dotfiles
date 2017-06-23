# Code dedicated to display and exploration of the obsolescence history
#
# This module content aims at being upstreamed enventually.
#
# Copyright 2017 Octobus SAS <contact@octobus.net>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import re

from mercurial import (
    cmdutil,
    commands,
    error,
    graphmod,
    obsolete,
    node as nodemod,
    scmutil,
)

from mercurial.i18n import _

from . import (
    exthelper,
)

eh = exthelper.exthelper()

@eh.command(
    'obslog|olog',
    [('G', 'graph', True, _("show the revision DAG")),
     ('r', 'rev', [], _('show the specified revision or revset'), _('REV')),
     ('a', 'all', False, _('show all related changesets, not only precursors'))
    ] + commands.formatteropts,
    _('hg olog [OPTION]... [REV]'))
def cmdobshistory(ui, repo, *revs, **opts):
    """show the obsolescence history of the specified revisions.

    If no revision range is specified, we display the log for the current
    working copy parent.

    By default this command prints the selected revisions and all its
    precursors. For precursors pointing on existing revisions in the repository,
    it will display revisions node id, revision number and the first line of the
    description. For precursors pointing on non existing revisions in the
    repository (that can happen when exchanging obsolescence-markers), display
    only the node id.

    In both case, for each node, its obsolescence marker will be displayed with
    the obsolescence operation (rewritten or pruned) in addition of the user and
    date of the operation.

    The output is a graph by default but can deactivated with the option '--no-
    graph'.

    'o' is a changeset, '@' is a working directory parent, 'x' is obsolete,
    and '+' represents a fork where the changeset from the lines below is a
    parent of the 'o' merge on the same line.

    Paths in the DAG are represented with '|', '/' and so forth.

    Returns 0 on success.
    """
    revs = list(revs) + opts['rev']
    if not revs:
        revs = ['.']
    revs = scmutil.revrange(repo, revs)

    if opts['graph']:
        return _debugobshistorygraph(ui, repo, revs, opts)

    fm = ui.formatter('debugobshistory', opts)
    revs.reverse()
    _debugobshistorysingle(fm, repo, revs)

    fm.end()

class obsmarker_printer(cmdutil.changeset_printer):
    """show (available) information about a node

    We display the node, description (if available) and various information
    about obsolescence markers affecting it"""

    def show(self, ctx, copies=None, matchfn=None, **props):
        if self.buffered:
            self.ui.pushbuffer(labeled=True)

            changenode = ctx.node()

            fm = self.ui.formatter('debugobshistory', props)
            _debugobshistorydisplaynode(fm, self.repo, changenode)

            succs = self.repo.obsstore.successors.get(changenode, ())

            markerfm = fm.nested("debugobshistory.markers")
            for successor in sorted(succs):
                _debugobshistorydisplaymarker(markerfm, self.repo, successor)
            markerfm.end()

            markerfm.plain('\n')

            self.hunk[ctx.node()] = self.ui.popbuffer()
        else:
            ### graph output is buffered only
            msg = 'cannot be used outside of the graphlog (yet)'
            raise error.ProgrammingError(msg)

    def flush(self, ctx):
        ''' changeset_printer has some logic around buffering data
        in self.headers that we don't use
        '''
        pass

class missingchangectx(object):
    ''' a minimal object mimicking changectx for change contexts
    references by obs markers but not available locally '''

    def __init__(self, repo, nodeid):
        self._repo = repo
        self._node = nodeid

    def node(self):
        return self._node

    def obsolete(self):
        # If we don't have it locally, it's obsolete
        return True

def cyclic(graph):
    """Return True if the directed graph has a cycle.
    The graph must be represented as a dictionary mapping vertices to
    iterables of neighbouring vertices. For example:

    >>> cyclic({1: (2,), 2: (3,), 3: (1,)})
    True
    >>> cyclic({1: (2,), 2: (3,), 3: (4,)})
    False

    Taken from: https://codereview.stackexchange.com/a/86067

    """
    visited = set()
    o = object()
    path = [o]
    path_set = set(path)
    stack = [iter(graph)]
    while stack:
        for v in sorted(stack[-1]):
            if v in path_set:
                path_set.remove(o)
                return path_set
            elif v not in visited:
                visited.add(v)
                path.append(v)
                path_set.add(v)
                stack.append(iter(graph.get(v, ())))
                break
        else:
            path_set.remove(path.pop())
            stack.pop()
    return False

def _obshistorywalker(repo, revs, walksuccessors=False):
    """ Directly inspired by graphmod.dagwalker,
    walk the obs marker tree and yield
    (id, CHANGESET, ctx, [parentinfo]) tuples
    """

    # Get the list of nodes and links between them
    candidates, nodesucc, nodeprec = _obshistorywalker_links(repo, revs, walksuccessors)

    # Shown, set of nodes presents in items
    shown = set()

    def isvalidcandidate(candidate):
        """ Function to filter candidates, check the candidate succ are
        in shown set
        """
        return nodesucc.get(candidate, set()).issubset(shown)

    # While we have some nodes to show
    while candidates:

        # Filter out candidates, returns only nodes with all their successors
        # already shown
        validcandidates = filter(isvalidcandidate, candidates)

        # If we likely have a cycle
        if not validcandidates:
            cycle = cyclic(nodesucc)
            assert cycle

            # Then choose a random node from the cycle
            breaknode = sorted(cycle)[0]
            # And display it by force
            repo.ui.debug('obs-cycle detected, forcing display of %s\n'
                          % nodemod.short(breaknode))
            validcandidates = [breaknode]

        # Display all valid candidates
        for cand in sorted(validcandidates):
            # Remove candidate from candidates set
            candidates.remove(cand)
            # And remove it from nodesucc in case of future cycle detected
            try:
                del nodesucc[cand]
            except KeyError:
                pass

            shown.add(cand)

            # Add the right changectx class
            if cand in repo:
                changectx = repo[cand]
            else:
                changectx = missingchangectx(repo, cand)

            childrens = [(graphmod.PARENT, x) for x in nodeprec.get(cand, ())]
            yield (cand, 'M', changectx, childrens)

def _obshistorywalker_links(repo, revs, walksuccessors=False):
    """ Iterate the obs history tree starting from revs, traversing
    each revision precursors recursively.
    If walksuccessors is True, also check that every successor has been
    walked, which ends up walking on all connected obs markers. It helps
    getting a better view with splits and divergences.
    Return a tuple of:
    - The list of node crossed
    - The dictionnary of each node successors, values are a set
    - The dictionnary of each node precursors, values are a list
    """
    precursors = repo.obsstore.precursors
    successors = repo.obsstore.successors
    nodec = repo.changelog.node

    # Parents, set of parents nodes seen during walking the graph for node
    nodesucc = dict()
    # Childrens
    nodeprec = dict()

    nodes = [nodec(r) for r in revs]
    seen = set(nodes)

    # Iterate on each node
    while nodes:
        node = nodes.pop()

        precs = precursors.get(node, ())

        nodeprec[node] = []

        for prec in sorted(precs):
            precnode = prec[0]

            # Mark node as prec successor
            nodesucc.setdefault(precnode, set()).add(node)

            # Mark precnode as node precursor
            nodeprec[node].append(precnode)

            # Add prec for future processing if not node already processed
            if precnode not in seen:
                seen.add(precnode)
                nodes.append(precnode)

        # Also walk on successors if the option is enabled
        if walksuccessors:
            for successor in successors.get(node, ()):
                for succnodeid in successor[1]:
                    if succnodeid not in seen:
                        seen.add(succnodeid)
                        nodes.append(succnodeid)

    return sorted(seen), nodesucc, nodeprec

def _debugobshistorygraph(ui, repo, revs, opts):
    displayer = obsmarker_printer(ui, repo.unfiltered(), None, opts, buffered=True)
    edges = graphmod.asciiedges
    walker = _obshistorywalker(repo.unfiltered(), revs, opts.get('all', False))
    cmdutil.displaygraph(ui, repo, walker, displayer, edges)

def _debugobshistorysingle(fm, repo, revs):
    """ Display the obsolescence history for a single revision
    """
    precursors = repo.obsstore.precursors
    successors = repo.obsstore.successors
    nodec = repo.changelog.node
    nodes = [nodec(r) for r in revs]

    seen = set(nodes)

    while nodes:
        ctxnode = nodes.pop()

        _debugobshistorydisplaynode(fm, repo, ctxnode)

        succs = successors.get(ctxnode, ())

        markerfm = fm.nested("debugobshistory.markers")
        for successor in sorted(succs):
            _debugobshistorydisplaymarker(markerfm, repo, successor)
        markerfm.end()

        precs = precursors.get(ctxnode, ())
        for p in sorted(precs):
            # Only show nodes once
            if p[0] not in seen:
                seen.add(p[0])
                nodes.append(p[0])

def _debugobshistorydisplaynode(fm, repo, node):
    if node in repo.unfiltered():
        _debugobshistorydisplayctx(fm, repo.unfiltered()[node])
    else:
        _debugobshistorydisplaymissingctx(fm, node)

def _debugobshistorydisplayctx(fm, ctx):
    shortdescription = ctx.description().splitlines()[0]

    fm.startitem()
    fm.write('debugobshistory.node', '%s', str(ctx),
             label="evolve.node")
    fm.plain(' ')

    fm.write('debugobshistory.rev', '(%d)', int(ctx),
             label="evolve.rev")
    fm.plain(' ')

    fm.write('debugobshistory.shortdescription', '%s', shortdescription,
             label="evolve.short_description")
    fm.plain('\n')

def _debugobshistorydisplaymissingctx(fm, nodewithoutctx):
    hexnode = nodemod.short(nodewithoutctx)
    fm.startitem()
    fm.write('debugobshistory.node', '%s', hexnode,
             label="evolve.node evolve.missing_change_ctx")
    fm.plain('\n')

def _debugobshistorydisplaymarker(fm, repo, marker):
    succnodes = marker[1]
    date = marker[4]
    metadata = dict(marker[3])

    fm.startitem()
    fm.plain('  ')

    # Detect pruned revisions
    if len(succnodes) == 0:
        verb = 'pruned'
    else:
        verb = 'rewritten'

    fm.write('debugobshistory.verb', '%s', verb,
             label="evolve.verb")

    effectflag = metadata.get('ef1')
    if effectflag is not None:
        try:
            effectflag = int(effectflag)
        except ValueError:
            effectflag = None
    if effectflag:
        effect = []

        # XXX should be a dict
        if effectflag & DESCCHANGED:
            effect.append('description')
        if effectflag & METACHANGED:
            effect.append('meta')
        if effectflag & USERCHANGED:
            effect.append('user')
        if effectflag & DATECHANGED:
            effect.append('date')
        if effectflag & BRANCHCHANGED:
            effect.append('branch')
        if effectflag & PARENTCHANGED:
            effect.append('parent')
        if effectflag & DIFFCHANGED:
            effect.append('content')

        if effect:
            fmteffect = fm.formatlist(effect, 'debugobshistory.effect', sep=', ')
            fm.write('debugobshistory.effect', '(%s)', fmteffect)

    fm.plain(' by ')

    fm.write('debugobshistory.marker_user', '%s', metadata['user'],
             label="evolve.user")
    fm.plain(' ')

    fm.write('debugobshistory.marker_date', '(%s)', fm.formatdate(date),
             label="evolve.date")

    if len(succnodes) > 0:
        fm.plain(' as ')

        shortsnodes = (nodemod.short(succnode) for succnode in sorted(succnodes))
        nodes = fm.formatlist(shortsnodes, 'debugobshistory.succnodes', sep=', ')
        fm.write('debugobshistory.succnodes', '%s', nodes,
                 label="evolve.node")

    fm.plain("\n")

# logic around storing and using effect flags
DESCCHANGED = 1 << 0 # action changed the description
METACHANGED = 1 << 1 # action change the meta
PARENTCHANGED = 1 << 2 # action change the parent
DIFFCHANGED = 1 << 3 # action change diff introduced by the changeset
USERCHANGED = 1 << 4 # the user changed
DATECHANGED = 1 << 5 # the date changed
BRANCHCHANGED = 1 << 6 # the branch changed

METABLACKLIST = [
    re.compile('^__touch-noise__$'),
    re.compile('^branch$'),
    re.compile('^.*-source$'),
    re.compile('^.*_source$'),
    re.compile('^source$'),
]

def ismetablacklisted(metaitem):
    """ Check that the key of a meta item (extrakey, extravalue) does not
    match at least one of the blacklist pattern
    """
    metakey = metaitem[0]
    for pattern in METABLACKLIST:
        if pattern.match(metakey):
            return False

    return True

def geteffectflag(relation):
    """compute the effect flag by comparing the source and destination"""
    effects = 0

    source = relation[0]

    for changectx in relation[1]:
        # Check if description has changed
        if changectx.description() != source.description():
            effects |= DESCCHANGED

        # Check if known meta has changed
        if changectx.user() != source.user():
            effects |= USERCHANGED

        if changectx.date() != source.date():
            effects |= DATECHANGED

        if changectx.branch() != source.branch():
            effects |= BRANCHCHANGED

        # Check if other meta has changed
        changeextra = changectx.extra().items()
        ctxmeta = filter(ismetablacklisted, changeextra)

        sourceextra = source.extra().items()
        srcmeta = filter(ismetablacklisted, sourceextra)

        if ctxmeta != srcmeta:
            effects |= METACHANGED

        # Check if at least one of the parent has changes
        if changectx.parents() != source.parents():
            effects |= PARENTCHANGED

        if not _cmpdiff(source, changectx):
            effects |= DIFFCHANGED

    return effects

def _prepare_hunk(hunk):
    """Drop all information but the username and patch"""
    cleanunk = []
    for line in hunk.splitlines():
        if line.startswith(b'# User') or not line.startswith(b'#'):
            if line.startswith(b'@@'):
                line = b'@@\n'
            cleanunk.append(line)
    return cleanunk

def _getdifflines(iterdiff):
    """return a cleaned up lines"""
    try:
        # XXX-COMPAT Mercurial 4.1 compat
        if isinstance(iterdiff, list) and len(iterdiff) == 0:
            return None
        lines = iterdiff.next()
    except StopIteration:
        return None
    return _prepare_hunk(lines)

def _cmpdiff(leftctx, rightctx):
    """return True if both ctx introduce the "same diff"

    This is a first and basic implementation, with many shortcoming.
    """

    # Leftctx or right ctx might be filtered, so we need to use the contexts
    # with an unfiltered repository to safely compute the diff
    leftunfi = leftctx._repo.unfiltered()[leftctx.rev()]
    leftdiff = leftunfi.diff(git=1)
    rightunfi = rightctx._repo.unfiltered()[rightctx.rev()]
    rightdiff = rightunfi.diff(git=1)

    left, right = (0, 0)
    while None not in (left, right):
        left = _getdifflines(leftdiff)
        right = _getdifflines(rightdiff)

        if left != right:
            return False
    return True

@eh.wrapfunction(obsolete, 'createmarkers')
def createmarkerswithbits(orig, repo, relations, flag=0, date=None,
                          metadata=None, **kwargs):
    """compute 'effect-flag' and augment the created markers

    Wrap obsolete.createmarker in order to compute the effect of each
    relationship and store them as flag in the metadata.

    While we experiment, we store flag in a metadata field. This field is
    "versionned" to easilly allow moving to other meaning for flags.

    The comparison of description or other infos just before creating the obs
    marker might induce overhead in some cases. However it is a good place to
    start since it automatically makes all markers creation recording more
    meaningful data. In the future, we can introduce way for commands to
    provide precomputed effect to avoid the overhead.
    """
    if not repo.ui.configbool('experimental', 'evolution.effect-flags', True):
        return orig(repo, relations, flag, date, metadata, **kwargs)
    if metadata is None:
        metadata = {}
    tr = repo.transaction('add-obsolescence-marker')
    try:
        for r in relations:
            # Compute the effect flag for each obsmarker
            effect = geteffectflag(r)

            # Copy the metadata in order to add them, we copy because the
            # effect flag might be different per relation
            m = metadata.copy()
            # we store the effect even if "0". This disctinct markers created
            # without the feature with markers recording a no-op.
            m['ef1'] = "%d" % effect

            # And call obsolete.createmarkers for creating the obsmarker for real
            orig(repo, [r], flag, date, m, **kwargs)

        tr.close()
    finally:
        tr.release()

def _getobsfate(successorssets):
    """ Compute a changeset obsolescence fate based on his successorssets.
    Successors can be the tipmost ones or the immediate ones.
    Returns one fate in the following list:
    - pruned
    - diverged
    - superseed
    - superseed_split
    """

    if len(successorssets) == 0:
        # The commit has been pruned
        return 'pruned'
    elif len(successorssets) > 1:
        return 'diverged'
    else:
        # No divergence, only one set of successors
        successors = successorssets[0]

        if len(successors) == 1:
            return 'superseed'
        else:
            return 'superseed_split'

def _getobsfateandsuccs(repo, revnode, successorssets=None):
    """ Return a tuple containing:
    - the reason a revision is obsolete (diverged, pruned or superseed)
    - the list of successors short node if the revision is neither pruned
    or has diverged
    """
    if successorssets is None:
        successorssets = obsolete.successorssets(repo, revnode)

    fate = _getobsfate(successorssets)

    # Apply node.short if we have no divergence
    if len(successorssets) == 1:
        successors = [nodemod.short(node_id) for node_id in successorssets[0]]
    else:
        successors = []
        for succset in successorssets:
            successors.append([nodemod.short(node_id) for node_id in succset])

    return (fate, successors)

def _successorsetdates(successorset, markers):
    """returns the max date and the min date of the markers list
    """

    if not markers:
        return {}

    dates = [m[4] for m in markers]

    return {
        'min_date': min(dates),
        'max_date': max(dates)
    }

def _successorsetusers(successorset, markers):
    """ Returns a sorted list of markers users without duplicates
    """
    if not markers:
        return {}

    # Check that user is present in meta
    markersmeta = [dict(m[3]) for m in markers]
    users = set(meta.get('user') for meta in markersmeta if meta.get('user'))

    return {'users': sorted(users)}

def _successorsetverb(successorset, markers):
    """ Return the verb summarizing the successorset
    """
    if not successorset:
        verb = 'pruned'
    elif len(successorset) == 1:
        verb = 'rewritten'
    else:
        verb = 'split'
    return {'verb': verb}

FORMATSSETSFUNCTIONS = [
    _successorsetdates,
    _successorsetusers,
    _successorsetverb
]

def successorsetallmarkers(successorset, pathscache):
    """compute all successors of a successorset.

    pathscache must contains all successors starting from selected nodes
    or revision. This way, iterating on each successor, we can take all
    precursors and have the subgraph of all obsmarkers between roots to
    successors.
    """

    markers = set()
    seen = set()

    for successor in successorset:
        stack = [successor]

        while stack:
            element = stack.pop()
            seen.add(element)
            for prec, mark in pathscache.get(element, []):
                if prec not in seen:
                    # Process element precursors
                    stack.append(prec)

                if mark not in markers:
                    markers.add(mark)

    return markers

def preparesuccessorset(successorset, rawmarkers):
    """ For a successor set, get all related markers, compute the set of user,
    the min date and the max date
    """
    hex = nodemod.hex

    successorset = [hex(n) for n in successorset]

    # hex the binary nodes in the markers
    markers = []
    for m in rawmarkers:
        hexprec = hex(m[0])
        hexsucs = tuple(hex(n) for n in m[1])
        hexparents = None
        if m[5] is not None:
            hexparents = tuple(hex(n) for n in m[5])
        newmarker = (hexprec, hexsucs) + m[2:5] + (hexparents,) + m[6:]
        markers.append(newmarker)

    # Format basic data
    data = {
        "successors": sorted(successorset),
        "markers": sorted(markers)
    }

    # Call an extensible list of functions to override or add new data
    for function in FORMATSSETSFUNCTIONS:
        data.update(function(successorset, markers))

    return data
