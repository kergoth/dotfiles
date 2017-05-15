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

def getstack(repo, topic):
    # XXX need sorting
    trevs = repo.revs("topic(%s) - obsolete()", topic)
    return _orderrevs(repo, trevs)

def labelsgen(prefix, labelssuffix):
    """ Takes a label prefix and a list of suffixes. Returns a string of the prefix
    formatted with each suffix separated with a space.
    """
    return ' '.join(prefix % suffix for suffix in labelssuffix)

def showstack(ui, repo, topic, opts):
    fm = ui.formatter('topicstack', opts)
    prev = None
    entries = []
    idxmap = {}

    label = 'topic'
    if topic == repo.currenttopic:
        label = 'topic.active'

    data = stackdata(repo, topic)
    fm.plain(_('### topic: %s') % ui.label(topic, label),
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
    if data['behindcount'] == -1:
        fm.plain(', ')
        fm.plain('ambigious rebase destination', label='topic.stack.summary.behinderror')
    elif data['behindcount']:
        fm.plain(', ')
        fm.plain('%d behind' % data['behindcount'], label='topic.stack.summary.behindcount')
    fm.plain('\n')

    for idx, r in enumerate(getstack(repo, topic), 1):
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

        if iscurrentrevision:
            states.append('current')

        if not isentry:
            symbol = '^'
            # "base" is kind of a "ghost" entry
            # skip other label for them (no current, no unstable)
            states = ['base']
        elif iscurrentrevision:
            symbol = '@'
        elif repo.revs('%d and unstable()', ctx.rev()):
            symbol = '$'
            states.append('unstable')
        else:
            symbol = ':'
            states.append('clean')
        fm.startitem()
        fm.data(isentry=isentry)

        if idx is None:
            fm.plain('  ')
        else:
            fm.write('topic.stack.index', 't%d', idx,
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

def stackdata(repo, topic):
    """get various data about a stack

    :changesetcount: number of non-obsolete changesets in the stack
    :troubledcount: number on troubled changesets
    :headcount: number of heads on the topic
    :behindcount: number of changeset on rebase destination
    """
    data = {}
    revs = repo.revs("topic(%s) - obsolete()", topic)
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
