# Code dedicated to display and exploration of the obsolescence history
#
# This module content aims at being upstreamed enventually.
#
# Copyright 2017 Octobus SAS <contact@octobus.net>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

from mercurial import (
    cmdutil,
    commands,
    error,
    graphmod,
    node as nodemod,
    scmutil,
)

from mercurial.i18n import _

from . import (
    exthelper,
)

eh = exthelper.exthelper()

@eh.command(
    'olog',
    [('G', 'graph', True, _("show the revision DAG")),
     ('r', 'rev', [], _('show the specified revision or revset'), _('REV'))
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

def _obshistorywalker(repo, revs):
    """ Directly inspired by graphmod.dagwalker,
    walk the obs marker tree and yield
    (id, CHANGESET, ctx, [parentinfo]) tuples
    """

    # Get the list of nodes and links between them
    candidates, nodesucc, nodeprec = _obshistorywalker_links(repo, revs)

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

def _obshistorywalker_links(repo, revs):
    """ Iterate the obs history tree starting from revs, traversing
    each revision precursors recursively.
    Return a tuple of:
    - The list of node crossed
    - The dictionnary of each node successors, values are a set
    - The dictionnary of each node precursors, values are a list
    """
    precursors = repo.obsstore.precursors
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

    return sorted(seen), nodesucc, nodeprec

def _debugobshistorygraph(ui, repo, revs, opts):
    displayer = obsmarker_printer(ui, repo.unfiltered(), None, opts, buffered=True)
    edges = graphmod.asciiedges
    cmdutil.displaygraph(ui, repo, _obshistorywalker(repo.unfiltered(), revs), displayer, edges)

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
