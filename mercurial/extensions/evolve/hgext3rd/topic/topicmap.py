import contextlib
import hashlib

from mercurial.i18n import _
from mercurial.node import nullid
from mercurial import (
    branchmap,
    changegroup,
    cmdutil,
    extensions,
    repoview,
)

basefilter = set(['base', 'immutable'])
def topicfilter(name):
    """return a "topic" version of a filter level"""
    if name in basefilter:
        return name
    elif name is None:
        return None
    elif name.endswith('-topic'):
        return name
    else:
        return name + '-topic'

def istopicfilter(filtername):
    if filtername is None:
        return False
    return filtername.endswith('-topic')

def gettopicrepo(repo):
    filtername = topicfilter(repo.filtername)
    if filtername == repo.filtername:
        return repo
    return repo.filtered(filtername)

def _setuptopicfilter(ui):
    """extend the filter related mapping with topic related one"""
    funcmap = repoview.filtertable
    partialmap = branchmap.subsettable

    # filter level not affected by topic that we should not override

    for plainname in list(funcmap):
        newfilter = topicfilter(plainname)
        if newfilter == plainname:
            continue

        def revsfunc(repo, name=plainname):
            return repoview.filterrevs(repo, name)

        base = topicfilter(partialmap[plainname])

        if newfilter not in funcmap:
            funcmap[newfilter] = revsfunc
            partialmap[newfilter] = base
    funcmap['unfiltered-topic'] = lambda repo: frozenset()
    partialmap['unfiltered-topic'] = 'visible-topic'

def _phaseshash(repo, maxrev):
    """uniq ID for a phase matching a set of rev"""
    revs = set()
    cl = repo.changelog
    fr = cl.filteredrevs
    nm = cl.nodemap
    for roots in repo._phasecache.phaseroots[1:]:
        for n in roots:
            r = nm.get(n)
            if r not in fr and r < maxrev:
                revs.add(r)
    key = nullid
    revs = sorted(revs)
    if revs:
        s = hashlib.sha1()
        for rev in revs:
            s.update('%s;' % rev)
        key = s.digest()
    return key

def modsetup(ui):
    """call at uisetup time to install various wrappings"""
    _setuptopicfilter(ui)
    _wrapbmcache(ui)
    extensions.wrapfunction(changegroup.cg1unpacker, 'apply', cgapply)
    extensions.wrapfunction(cmdutil, 'commitstatus', commitstatus)

def cgapply(orig, self, repo, *args, **kwargs):
    """make sure a topicmap is used when applying a changegroup"""
    other = repo.filtered(topicfilter(repo.filtername))
    return orig(self, other, *args, **kwargs)

def commitstatus(orig, repo, node, branch, bheads=None, opts=None):
    # wrap commit status use the topic branch heads
    ctx = repo[node]
    if ctx.topic() and ctx.branch() == branch:
        subbranch = "%s:%s" % (branch, ctx.topic())
        bheads = repo.branchheads("%s:%s" % (subbranch, ctx.topic()))

    ret = orig(repo, node, branch, bheads=bheads, opts=opts)

    # logic copy-pasted from cmdutil.commitstatus()
    if opts is None:
        opts = {}
    ctx = repo[node]
    if ctx.topic():
        return ret
    parents = ctx.parents()

    if (not opts.get('amend') and bheads and node not in bheads and not
        [x for x in parents if x.node() in bheads and x.branch() == branch]):
        repo.ui.status(_("(consider using topic for lightweight branches."
                         " See 'hg help topic')\n"))

    return ret

def _wrapbmcache(ui):
    class topiccache(_topiccache, branchmap.branchcache):
        pass
    branchmap.branchcache = topiccache
    extensions.wrapfunction(branchmap, 'updatecache', _wrapupdatebmcache)

def _wrapupdatebmcache(orig, repo):
    previous = getattr(repo, '_autobranchmaptopic', False)
    try:
        repo._autobranchmaptopic = False
        return orig(repo)
    finally:
        repo._autobranchmaptopic = previous

# needed to prevent reference used for 'super()' call using in branchmap.py to
# no go into cycle. (yes, URG)
_oldbranchmap = branchmap.branchcache

@contextlib.contextmanager
def oldbranchmap():
    previous = branchmap.branchcache
    try:
        branchmap.branchcache = _oldbranchmap
        yield
    finally:
        branchmap.branchcache = previous

class _topiccache(object): # combine me with branchmap.branchcache

    def __init__(self, *args, **kwargs):
        # super() call may fail otherwise
        with oldbranchmap():
            super(_topiccache, self).__init__(*args, **kwargs)
        self.phaseshash = None

    def copy(self):
        """return an deep copy of the branchcache object"""
        new = self.__class__(self, self.tipnode, self.tiprev, self.filteredhash,
                             self._closednodes)
        new.phaseshash = self.phaseshash
        return new

    def branchtip(self, branch, topic=''):
        '''Return the tipmost open head on branch head, otherwise return the
        tipmost closed head on branch.
        Raise KeyError for unknown branch.'''
        if topic:
            branch = '%s:%s' % (branch, topic)
        return super(_topiccache, self).branchtip(branch)

    def branchheads(self, branch, closed=False, topic=''):
        if topic:
            branch = '%s:%s' % (branch, topic)
        return super(_topiccache, self).branchheads(branch, closed=closed)

    def validfor(self, repo):
        """Is the cache content valid regarding a repo

        - False when cached tipnode is unknown or if we detect a strip.
        - True when cache is up to date or a subset of current repo."""
        valid = super(_topiccache, self).validfor(repo)
        if not valid:
            return False
        elif not istopicfilter(repo.filtername) or self.phaseshash is None:
            # phasehash at None means this is a branchmap
            # come from non topic thing
            return True
        else:
            try:
                valid = self.phaseshash == _phaseshash(repo, self.tiprev)
                return valid
            except IndexError:
                return False

    def write(self, repo):
        # we expect mutable set to be small enough to be that computing it all
        # the time will be fast enough
        if not istopicfilter(repo.filtername):
            super(_topiccache, self).write(repo)

    def update(self, repo, revgen):
        """Given a branchhead cache, self, that may have extra nodes or be
        missing heads, and a generator of nodes that are strictly a superset of
        heads missing, this function updates self to be correct.
        """
        if not istopicfilter(repo.filtername):
            return super(_topiccache, self).update(repo, revgen)
        unfi = repo.unfiltered()
        oldgetbranchinfo = unfi.revbranchcache().branchinfo

        def branchinfo(r):
            info = oldgetbranchinfo(r)
            topic = ''
            ctx = unfi[r]
            if ctx.mutable():
                topic = ctx.topic()
            branch = info[0]
            if topic:
                branch = '%s:%s' % (branch, topic)
            return (branch, info[1])
        try:
            unfi.revbranchcache().branchinfo = branchinfo
            super(_topiccache, self).update(repo, revgen)
            self.phaseshash = _phaseshash(repo, self.tiprev)
        finally:
            unfi.revbranchcache().branchinfo = oldgetbranchinfo
