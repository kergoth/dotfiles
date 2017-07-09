from __future__ import absolute_import

import weakref

from mercurial.i18n import _
from mercurial import (
    bundle2,
    discovery,
    error,
    exchange,
    extensions,
    util,
    wireproto,
)

def _headssummary(orig, *args):
    # In mercurial < 4.2, we receive repo, remote and outgoing as arguments
    if len(args) == 3:
        pushoparg = False
        repo, remote, outgoing = args

    # In mercurial > 4.3, we receive the pushop as arguments
    elif len(args) == 1:
        pushoparg = True
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

    class repocls(repo.__class__):
        # awful hack to see branch as "branch:topic"
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

        def revbranchcache(self):
            rbc = super(repocls, self).revbranchcache()
            changelog = self.changelog

            def branchinfo(rev):
                branch, close = changelog.branchinfo(rev)
                topic = repo[rev].topic()
                if topic:
                    branch = "%s:%s" % (branch, topic)
                return branch, close

            rbc.branchinfo = branchinfo
            return rbc

    oldrepocls = repo.__class__
    try:
        repo.__class__ = repocls
        unxx = repo.filtered('unfiltered-topic')
        repo.unfiltered = lambda: unxx
        if pushoparg:
            pushop.repo = repo
            summary = orig(pushop)
        else:
            summary = orig(repo, remote, outgoing)
        for key, value in summary.iteritems():
            if ':' in key: # This is a topic
                if value[0] is None and value[1]:
                    summary[key] = ([value[1][0]], ) + value[1:]
        return summary
    finally:
        if 'unfiltered' in vars(repo):
            del repo.unfiltered
        repo.__class__ = oldrepocls

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
    """This is used to check for new heads when publishing changeset"""
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
    checktypes = ('check:heads', 'check:updated-heads')
    hascheck = any(p.type in checktypes for p in bundler._parts)
    if not hascheck and pushop.outdatedphases:
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
    # we need a proper wrap b2 part stuff
    extensions.wrapfunction(bundle2, 'handlecheckheads', handlecheckheads)
    bundle2.handlecheckheads.params = frozenset()
    bundle2.parthandlermapping['check:heads'] = bundle2.handlecheckheads
    if util.safehasattr(bundle2, 'handlecheckupdatedheads'):
        # we still need a proper wrap b2 part stuff
        extensions.wrapfunction(bundle2, 'handlecheckupdatedheads', handlecheckheads)
        bundle2.handlecheckupdatedheads.params = frozenset()
        bundle2.parthandlermapping['check:updated-heads'] = bundle2.handlecheckupdatedheads
    extensions.wrapfunction(exchange, '_pushb2phases', _pushb2phases)
    exchange.b2partsgenmapping['phase'] = exchange._pushb2phases
