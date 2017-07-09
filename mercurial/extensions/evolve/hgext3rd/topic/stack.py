# stack.py - code related to stack workflow
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
from mercurial.i18n import _
from mercurial import (
    destutil,
    error,
    node,
)
from .evolvebits import builddependencies, _orderrevs, _singlesuccessor

def getstack(repo, branch=None, topic=None):
    # XXX need sorting
    if topic is not None and branch is not None:
        raise error.ProgrammingError('both branch and topic specified (not defined yet)')
    elif topic is not None:
        trevs = repo.revs("topic(%s) - obsolete()", topic)
    elif branch is not None:
        trevs = repo.revs("branch(%s) - public() - obsolete() - topic()", branch)
    else:
        raise error.ProgrammingError('neither branch and topic specified (not defined yet)')
    return _orderrevs(repo, trevs)

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
    fm.plain(_('### branch: %s')
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
            fm.plain('ambigious rebase destination', label='topic.stack.summary.behinderror')
        elif data['behindcount']:
            fm.plain(', ')
            fm.plain('%d behind' % data['behindcount'], label='topic.stack.summary.behindcount')
    fm.plain('\n')

    for idx, r in enumerate(getstack(repo, branch=branch, topic=topic), 1):
        ctx = repo[r]
        p1 = ctx.p1()
        if p1.obsolete():
            p1 = repo[_singlesuccessor(repo, p1)]
        if p1.rev() != prev and p1.node() != node.nullid:
            entries.append((idxmap.get(p1.rev()), False, p1))
        entries.append((idx, True, ctx))
        idxmap[ctx.rev()] = idx
        prev = r

    # super crude initial version
    for idx, isentry, ctx in entries[::-1]:

        states = []
        iscurrentrevision = repo.revs('%d and parents()', ctx.rev())

        if not isentry:
            symbol = '^'
            # "base" is kind of a "ghost" entry
            # skip other label for them (no current, no unstable)
            states = ['base']
        elif ctx.unstable():
            # current revision can be unstable also, so in that case show both
            # the states and the symbol '@' (issue5553)
            if iscurrentrevision:
                states.append('current')
                symbol = '@'
            symbol = '$'
            states.append('unstable')
        elif iscurrentrevision:
            states.append('current')
            symbol = '@'
        else:
            symbol = ':'
            states.append('clean')
        fm.startitem()
        fm.data(isentry=isentry)

        if idx is None:
            fm.plain('  ')
        else:
            fm.write('topic.stack.index', '%s%%d' % prefix, idx,
                     label='topic.stack.index ' + labelsgen('topic.stack.index.%s', states))
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
    revs = getstack(repo, branch, topic)
    data['changesetcount'] = len(revs)
    data['troubledcount'] = len([r for r in revs if repo[r].troubled()])
    deps, rdeps = builddependencies(repo, revs)
    data['headcount'] = len([r for r in revs if not rdeps[r]])
    data['behindcount'] = 0
    if revs:
        minroot = [min(r for r in revs if not deps[r])]
        try:
            dest = destutil.destmerge(repo, action='rebase',
                                      sourceset=minroot,
                                      onheadcheck=False)
            data['behindcount'] = len(repo.revs("only(%d, %ld)", dest,
                                                minroot))
        except error.NoMergeDestAbort:
            data['behindcount'] = 0
        except error.ManyMergeDestAbort:
            data['behindcount'] = -1
    data['branches'] = sorted(set(repo[r].branch() for r in revs))

    return data
