# stack.py - code related to stack workflow
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
from mercurial.i18n import _
from mercurial import (
    destutil,
    context,
    error,
    node,
    phases,
    obsolete,
    util,
)
from .evolvebits import (
    _singlesuccessor,
    MultipleSuccessorsError,
    builddependencies,
)

short = node.short

# TODO: compat

if not util.safehasattr(context.basectx, 'orphan'):
    context.basectx.orphan = context.basectx.unstable

if not util.safehasattr(context.basectx, 'isunstable'):
    context.basectx.isunstable = context.basectx.troubled

def parseusername(user):
    """parses the ctx user and returns the username without email ID if
    possible, otherwise returns the mail address from that"""
    username = None
    if user:
        # user is of form "abc <abc@xyz.com>"
        username = user.split('<')[0]
        if not username:
            # assuming user is of form "<abc@xyz.com>"
            if len(user) > 1:
                username = user[1:-1]
            else:
                username = user
        username = username.strip()

    return username

def _stackcandidates(repo):
    """build the smaller set of revs that might be part of a stack.

    The intend is to build something more efficient than what revsets do in
    this area.
    """
    phasecache = repo._phasecache
    if not phasecache._phasesets:
        return repo.revs('(not public()) - obsolete()')
    if any(s is None for s in phasecache._phasesets):
        return repo.revs('(not public()) - obsolete()')

    result = set()
    for s in phasecache._phasesets[phases.draft:]:
        result |= s

    result -= obsolete.getrevs(repo, 'obsolete')
    return result

class stack(object):
    """object represent a stack and common logic associated to it."""

    def __init__(self, repo, branch=None, topic=None):
        self._repo = repo
        self.branch = branch
        self.topic = topic
        self.behinderror = None

        subset = _stackcandidates(repo)

        if topic is not None and branch is not None:
            raise error.ProgrammingError('both branch and topic specified (not defined yet)')
        elif topic is not None:
            trevs = repo.revs("%ld and topic(%s)", subset, topic)
        elif branch is not None:
            trevs = repo.revs("%ld and branch(%s) - topic()", subset, branch)
        else:
            raise error.ProgrammingError('neither branch and topic specified (not defined yet)')
        self._revs = trevs

    def __iter__(self):
        return iter(self.revs)

    def __getitem__(self, index):
        return self.revs[index]

    def index(self, item):
        return self.revs.index(item)

    @util.propertycache
    def _dependencies(self):
        deps, rdeps = builddependencies(self._repo, self._revs)

        repo = self._repo
        srcpfunc = repo.changelog.parentrevs

        ### post process to skip over possible gaps in the stack
        #
        # For example in the following situation, we need to detect that "t3"
        # indirectly depends on t2.
        #
        #  o t3
        #  |
        #  o other
        #  |
        #  o t2
        #  |
        #  o t1

        pmap = {}

        def pfuncrev(repo, rev):
            """a special "parent func" that also consider successors"""
            parents = pmap.get(rev)
            if parents is None:
                parents = [repo[_singlesuccessor(repo, repo[p])].rev()
                           for p in srcpfunc(rev) if 0 <= p]
                pmap[rev] = parents
            return parents

        revs = self._revs
        stackrevs = set(self._revs)
        for root in [r for r in revs if not deps[r]]:
            seen = set()
            stack = [root]
            while stack:
                current = stack.pop()
                for p in pfuncrev(repo, current):
                    if p in seen:
                        continue
                    seen.add(p)
                    if p in stackrevs:
                        rdeps[p].add(root)
                        deps[root].add(p)
                    elif phases.public < repo[p].phase():
                        # traverse only if we did not found a proper candidate
                        stack.append(p)

        return deps, rdeps

    @util.propertycache
    def revs(self):
        # some duplication/change from _orderrevs because we use a post
        # processed dependency graph.

        # Step 1: compute relation of revision with each other
        dependencies, rdependencies = self._dependencies
        dependencies = dependencies.copy()
        rdependencies = rdependencies.copy()
        # Step 2: Build the ordering
        # Remove the revisions with no dependency(A) and add them to the ordering.
        # Removing these revisions leads to new revisions with no dependency (the
        # one depending on A) that we can remove from the dependency graph and add
        # to the ordering. We progress in a similar fashion until the ordering is
        # built
        solvablerevs = [r for r in sorted(dependencies.keys())
                        if not dependencies[r]]
        revs = []
        while solvablerevs:
            rev = solvablerevs.pop()
            for dependent in rdependencies[rev]:
                dependencies[dependent].remove(rev)
                if not dependencies[dependent]:
                    solvablerevs.append(dependent)
            del dependencies[rev]
            revs.append(rev)

        revs.extend(sorted(dependencies))
        # step 3: add t0
        if revs:
            pt1 = self._repo[revs[0]].p1()
        else:
            pt1 = self._repo['.']

        if pt1.obsolete():
            pt1 = self._repo[_singlesuccessor(self._repo, pt1)]
        revs.insert(0, pt1.rev())
        return revs

    @util.propertycache
    def changesetcount(self):
        return len(self._revs)

    @util.propertycache
    def troubledcount(self):
        return len([r for r in self._revs if self._repo[r].isunstable()])

    @util.propertycache
    def heads(self):
        revs = self.revs[1:]
        deps, rdeps = self._dependencies
        return [r for r in revs if not rdeps[r]]

    @util.propertycache
    def behindcount(self):
        revs = self.revs[1:]
        deps, rdeps = self._dependencies
        if revs:
            minroot = [min(r for r in revs if not deps[r])]
            try:
                dest = destutil.destmerge(self._repo, action='rebase',
                                          sourceset=minroot,
                                          onheadcheck=False)
                return len(self._repo.revs("only(%d, %ld)", dest, minroot))
            except error.NoMergeDestAbort:
                return 0
            except error.ManyMergeDestAbort as exc:
                # XXX we should make it easier for upstream to provide the information
                self.behinderror = str(exc).split('-', 1)[0].rstrip()
                return -1
        return 0

    @util.propertycache
    def branches(self):
        branches = sorted(set(self._repo[r].branch() for r in self._revs))
        if not branches:
            branches = set([self._repo[None].branch()])
        return branches

def labelsgen(prefix, labelssuffix):
    """ Takes a label prefix and a list of suffixes. Returns a string of the prefix
    formatted with each suffix separated with a space.
    """
    return ' '.join(prefix % suffix for suffix in labelssuffix)

def showstack(ui, repo, branch=None, topic=None, opts=None):
    if opts is None:
        opts = {}

    if topic is not None and branch is not None:
        msg = 'both branch and topic specified [%s]{%s}(not defined yet)'
        msg %= (branch, topic)
        raise error.ProgrammingError(msg)
    elif topic is not None:
        prefix = 't'
        if topic not in repo.topics:
            raise error.Abort(_('cannot resolve "%s": no such topic found') % topic)
    elif branch is not None:
        prefix = 'b'
    else:
        raise error.ProgrammingError('neither branch and topic specified (not defined yet)')

    fm = ui.formatter('topicstack', opts)
    prev = None
    entries = []
    idxmap = {}

    label = 'topic'
    if topic == repo.currenttopic:
        label = 'topic.active'

    data = stackdata(repo, branch=branch, topic=topic)
    empty = False
    if data['changesetcount'] == 0:
        empty = True
    if topic is not None:
        fm.plain(_('### topic: %s')
                 % ui.label(topic, label),
                 label='topic.stack.summary.topic')

        if 1 < data['headcount']:
            fm.plain(' (')
            fm.plain('%d heads' % data['headcount'],
                     label='topic.stack.summary.headcount.multiple')
            fm.plain(')')
        fm.plain('\n')
    fm.plain(_('### target: %s (branch)')
             % '+'.join(data['branches']), # XXX handle multi branches
             label='topic.stack.summary.branches')
    if topic is None:
        if 1 < data['headcount']:
            fm.plain(' (')
            fm.plain('%d heads' % data['headcount'],
                     label='topic.stack.summary.headcount.multiple')
            fm.plain(')')
    else:
        if data['behindcount'] == -1:
            fm.plain(', ')
            fm.plain('ambiguous rebase destination - %s' % data['behinderror'],
                     label='topic.stack.summary.behinderror')
        elif data['behindcount']:
            fm.plain(', ')
            fm.plain('%d behind' % data['behindcount'], label='topic.stack.summary.behindcount')
    fm.plain('\n')

    if empty:
        fm.plain(_("(stack is empty)\n"))

    for idx, r in enumerate(stack(repo, branch=branch, topic=topic), 0):
        ctx = repo[r]
        # special case for t0, b0 as it's hard to plugin into rest of the logic
        if idx == 0:
            # t0, b0 can be None
            if r == -1:
                continue
            entries.append((idx, False, ctx))
            prev = ctx.rev()
            continue
        p1 = ctx.p1()
        p2 = ctx.p2()
        if p1.obsolete():
            try:
                p1 = repo[_singlesuccessor(repo, p1)]
            except MultipleSuccessorsError as e:
                successors = e.successorssets
                if len(successors) > 1:
                    # case of divergence which we don't handle yet
                    raise
                p1 = repo[successors[0][-1]]

        if p2.node() != node.nullid:
            entries.append((idxmap.get(p1.rev()), False, p1))
            entries.append((idxmap.get(p2.rev()), False, p2))
        elif p1.rev() != prev and p1.node() != node.nullid:
            entries.append((idxmap.get(p1.rev()), False, p1))
        entries.append((idx, True, ctx))
        idxmap[ctx.rev()] = idx
        prev = r

    # super crude initial version
    for idx, isentry, ctx in entries[::-1]:

        symbol = None
        states = []
        iscurrentrevision = repo.revs('%d and parents()', ctx.rev())

        if iscurrentrevision:
            states.append('current')
            symbol = '@'

        if ctx.orphan():
            symbol = '$'
            states.append('unstable')

        if not isentry:
            symbol = '^'
            # "base" is kind of a "ghost" entry
            states.append('base')

        # none of the above if statments get executed
        if not symbol:
            symbol = ':'
            states.append('clean')

        states.sort()

        fm.startitem()
        fm.data(isentry=isentry)

        if idx is None:
            fm.plain('  ')
            if ui.verbose:
                fm.plain('              ')
        else:
            fm.write('topic.stack.index', '%s%%d' % prefix, idx,
                     label='topic.stack.index ' + labelsgen('topic.stack.index.%s', states))
            if ui.verbose:
                fm.write('topic.stack.shortnode', '(%s)', short(ctx.node()),
                         label='topic.stack.shortnode ' + labelsgen('topic.stack.shortnode.%s', states))
        fm.write('topic.stack.state.symbol', '%s', symbol,
                 label='topic.stack.state ' + labelsgen('topic.stack.state.%s', states))
        fm.plain(' ')
        fm.write('topic.stack.desc', '%s', ctx.description().splitlines()[0],
                 label='topic.stack.desc ' + labelsgen('topic.stack.desc.%s', states))
        fm.condwrite(states != ['clean'] and idx is not None, 'topic.stack.state',
                     ' (%s)', fm.formatlist(states, 'topic.stack.state'),
                     label='topic.stack.state ' + labelsgen('topic.stack.state.%s', states))
        fm.plain('\n')
    fm.end()

def stackdata(repo, branch=None, topic=None):
    """get various data about a stack

    :changesetcount: number of non-obsolete changesets in the stack
    :troubledcount: number on troubled changesets
    :headcount: number of heads on the topic
    :behindcount: number of changeset on rebase destination
    """
    data = {}
    current = stack(repo, branch, topic)
    data['changesetcount'] = current.changesetcount
    data['troubledcount'] = current.troubledcount
    data['headcount'] = len(current.heads)
    data['behindcount'] = current.behindcount
    data['behinderror'] = current.behinderror
    data['branches'] = current.branches
    return data
