from __future__ import absolute_import

import weakref

from mercurial.i18n import _
from mercurial import (
    branchmap,
    bundle2,
    discovery,
    error,
    exchange,
    extensions,
    wireproto,
)

from . import topicmap

def _headssummary(orig, *args):
    # In mercurial < 4.2, we receive repo, remote and outgoing as arguments
    if len(args) == 3:
        repo, remote, outgoing = args

    # In mercurial > 4.3, we receive the pushop as arguments
    elif len(args) == 1:
        pushop = args[0]
        repo = pushop.repo.unfiltered()
        remote = pushop.remote
    else:
        msg = 'topic-ext _headssummary() takes 1 or 3 arguments (%d given)'
        raise TypeError(msg % len(args))

    publishing = ('phases' not in remote.listkeys('namespaces')
                  or bool(remote.listkeys('phases').get('publishing', False)))
    if publishing or not remote.capable('topics'):
        return orig(*args)
    oldrepo = repo.__class__
    oldbranchcache = branchmap.branchcache
    oldfilename = branchmap._filename
    try:
        class repocls(repo.__class__):
            def __getitem__(self, key):
                ctx = super(repocls, self).__getitem__(key)
                oldbranch = ctx.branch

                def branch():
                    branch = oldbranch()
                    topic = ctx.topic()
                    if topic:
                        branch = "%s:%s" % (branch, topic)
                    return branch

                ctx.branch = branch
                return ctx

        repo.__class__ = repocls
        branchmap.branchcache = topicmap.topiccache
        branchmap._filename = topicmap._filename
        summary = orig(*args)
        for key, value in summary.iteritems():
            if ':' in key: # This is a topic
                if value[0] is None and value[1]:
                    summary[key] = ([value[1].pop(0)], ) + value[1:]
        return summary
    finally:
        repo.__class__ = oldrepo
        branchmap.branchcache = oldbranchcache
        branchmap._filename = oldfilename

def wireprotobranchmap(orig, repo, proto):
    oldrepo = repo.__class__
    try:
        class repocls(repo.__class__):
            def branchmap(self):
                usetopic = not self.publishing()
                return super(repocls, self).branchmap(topic=usetopic)
        repo.__class__ = repocls
        return orig(repo, proto)
    finally:
        repo.__class__ = oldrepo


# Discovery have deficiency around phases, branch can get new heads with pure
# phases change. This happened with a changeset was allowed to be pushed
# because it had a topic, but it later become public and create a new branch
# head.
#
# Handle this by doing an extra check for new head creation server side
def _nbheads(repo):
    data = {}
    for b in repo.branchmap().iterbranches():
        if ':' in b[0]:
            continue
        data[b[0]] = len(b[1])
    return data

def handlecheckheads(orig, op, inpart):
    orig(op, inpart)
    if op.repo.publishing():
        return
    tr = op.gettransaction()
    if tr.hookargs['source'] not in ('push', 'serve'): # not a push
        return
    tr._prepushheads = _nbheads(op.repo)
    reporef = weakref.ref(op.repo)
    oldvalidator = tr.validator

    def validator(tr):
        repo = reporef()
        if repo is not None:
            repo.invalidatecaches()
            finalheads = _nbheads(repo)
            for branch, oldnb in tr._prepushheads.iteritems():
                newnb = finalheads.pop(branch, 0)
                if oldnb < newnb:
                    msg = _('push create a new head on branch "%s"' % branch)
                    raise error.Abort(msg)
            for branch, newnb in finalheads.iteritems():
                if 1 < newnb:
                    msg = _('push create more than 1 head on new branch "%s"'
                            % branch)
                    raise error.Abort(msg)
        return oldvalidator(tr)
    tr.validator = validator
handlecheckheads.params = frozenset()

def _pushb2phases(orig, pushop, bundler):
    hascheck = any(p.type == 'check:heads' for p in bundler._parts)
    if pushop.outdatedphases and not hascheck:
        exchange._pushb2ctxcheckheads(pushop, bundler)
    return orig(pushop, bundler)

def wireprotocaps(orig, repo, proto):
    caps = orig(repo, proto)
    if repo.peer().capable('topics'):
        caps.append('topics')
    return caps

def modsetup(ui):
    """run at uisetup time to install all destinations wrapping"""
    extensions.wrapfunction(discovery, '_headssummary', _headssummary)
    extensions.wrapfunction(wireproto, 'branchmap', wireprotobranchmap)
    extensions.wrapfunction(wireproto, '_capabilities', wireprotocaps)
    extensions.wrapfunction(bundle2, 'handlecheckheads', handlecheckheads)
    # we need a proper wrap b2 part stuff
    bundle2.handlecheckheads.params = frozenset()
    bundle2.parthandlermapping['check:heads'] = bundle2.handlecheckheads
    extensions.wrapfunction(exchange, '_pushb2phases', _pushb2phases)
    exchange.b2partsgenmapping['phase'] = exchange._pushb2phases
