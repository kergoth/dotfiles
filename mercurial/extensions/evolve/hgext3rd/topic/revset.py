from __future__ import absolute_import

from mercurial import (
    registrar,
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

revsetpredicate = registrar.revsetpredicate()

@revsetpredicate('topic([topic])')
def topicset(repo, subset, x):
    """Specified topic or all changes with any topic specified.

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

    mutable = revset._notpublic(repo, revset.fullreposet(repo), ())

    rawchange = repo.changelog.changelogrevision
    key = constants.extrakey

    def matchtopic(r):
        topic = rawchange(r).extra.get(key)
        if topic is None:
            return False
        return matcher(topic)
    return (subset & mutable).filter(matchtopic)

@revsetpredicate('ngtip([branch])')
def ngtipset(repo, subset, x):
    """The untopiced tip.

    Name is horrible so that people change it.
    """
    args = revset.getargs(x, 1, 1, 'topic takes one')
    # match a specific topic
    branch = revset.getstring(args[0], 'ngtip() argument must be a string')
    if branch == '.':
        branch = repo['.'].branch()
    return subset & revset.baseset(destination.ngtip(repo, branch))

@revsetpredicate('stack()')
def stackset(repo, subset, x):
    """All relevant changes in the current topic,

    This is roughly equivalent to 'topic(.) - obsolete' with a sorting moving
    unstable changeset after there future parent (as if evolve where already
    run)."""
    err = 'stack() takes no argument, it works on current topic'
    revset.getargs(x, 0, 0, err)
    topic = repo.currenttopic
    topic = None
    branch = None
    if not topic and repo.currenttopic:
        topic = repo.currenttopic
    if not topic:
        branch = repo[None].branch()
    return revset.baseset(stack.stack(repo, branch=branch, topic=topic)[1:]) & subset
