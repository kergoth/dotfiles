from __future__ import absolute_import

from mercurial.i18n import _
from mercurial import (
    error,
    revset,
    util,
)

from . import (
    constants,
    destination,
    stack,
)

try:
    mkmatcher = revset._stringmatcher
except AttributeError:
    mkmatcher = util.stringmatcher


def topicset(repo, subset, x):
    """`topic([topic])`
    Specified topic or all changes with any topic specified.

    If `topic` starts with `re:` the remainder of the name is treated
    as a regular expression.

    TODO: make `topic(revset)` work the same as `branch(revset)`.
    """
    args = revset.getargs(x, 0, 1, 'topic takes one or no arguments')
    if args:
        # match a specific topic
        topic = revset.getstring(args[0], 'topic() argument must be a string')
        if topic == '.':
            topic = repo['.'].extra().get('topic', '')
        _kind, _pattern, matcher = mkmatcher(topic)
    else:
        matcher = lambda t: bool(t)
    drafts = subset.filter(lambda r: repo[r].mutable())
    return drafts.filter(
        lambda r: matcher(repo[r].extra().get(constants.extrakey, '')))

def ngtipset(repo, subset, x):
    """`ngtip([branch])`

    The untopiced tip.

    Name is horrible so that people change it.
    """
    args = revset.getargs(x, 1, 1, 'topic takes one')
    # match a specific topic
    branch = revset.getstring(args[0], 'ngtip() argument must be a string')
    if branch == '.':
        branch = repo['.'].branch()
    return subset & revset.baseset(destination.ngtip(repo, branch))

def stackset(repo, subset, x):
    """`stack()`
    All relevant changes in the current topic,

    This is roughly equivalent to 'topic(.) - obsolete' with a sorting moving
    unstable changeset after there future parent (as if evolve where already
    run)."""
    topic = repo.currenttopic
    if not topic:
        raise error.Abort(_('no active topic to list'))
    # ordering hack, boo
    return revset.baseset(stack.getstack(repo, topic)) & subset


def modsetup(ui):
    revset.symbols.update({'topic': topicset})
    revset.symbols.update({'ngtip': ngtipset})
    revset.symbols.update({'stack': stackset})
