"""enable a minimal verison of topic for server

Non publishing repository will see topic as "branch:topic" in the branch field.

In addition to adding the extensions, the feature must be manually enabled in the config:

    [experimental]
    server-mini-topic = yes
"""
import hashlib
import contextlib

from mercurial import (
    branchmap,
    context,
    encoding,
    extensions,
    node,
    registrar,
    util,
    wireproto,
)

if util.safehasattr(registrar, 'configitem'):

    configtable = {}
    configitem = registrar.configitem(configtable)
    configitem('experimental', 'server-mini-topic',
               default=False,
    )

def hasminitopic(repo):
    """true if minitopic is enabled on the repository

    (The value is cached on the repository)
    """
    enabled = getattr(repo, '_hasminitopic', None)
    if enabled is None:
        enabled = (repo.ui.configbool('experimental', 'server-mini-topic')
                   and not repo.publishing())
        repo._hasminitopic = enabled
    return enabled

### make topic visible though "ctx.branch()"

class topicchangectx(context.changectx):
    """a sunclass of changectx that add topic to the branch name"""

    def branch(self):
        branch = super(topicchangectx, self).branch()
        if hasminitopic(self._repo) and self.phase():
            topic = self._changeset.extra.get('topic')
            if topic is not None:
                topic = encoding.tolocal(topic)
                branch = '%s:%s' % (branch, topic)
        return branch

### avoid caching topic data in rev-branch-cache

class revbranchcacheoverlay(object):
    """revbranch mixin that don't use the cache for non public changeset"""

    def _init__(self, *args, **kwargs):
        super(revbranchcacheoverlay, self).__init__(*args, **kwargs)
        if 'branchinfo' in vars(self):
            del self.branchinfo

    def branchinfo(self, rev):
        """return branch name and close flag for rev, using and updating
        persistent cache."""
        phase = self._repo._phasecache.phase(self, rev)
        if phase:
            ctx = self._repo[rev]
            return ctx.branch(), ctx.closesbranch()
        return super(revbranchcacheoverlay, self).branchinfo(rev)

def reposetup(ui, repo):
    """install a repo class with a special revbranchcache"""

    if hasminitopic(repo):
        repo = repo.unfiltered()

        class minitopicrepo(repo.__class__):
            """repository subclass that install the modified cache"""

            def revbranchcache(self):
                if self._revbranchcache is None:
                    cache = super(minitopicrepo, self).revbranchcache()

                    class topicawarerbc(revbranchcacheoverlay, cache.__class__):
                        pass
                    cache.__class__ = topicawarerbc
                    if 'branchinfo' in vars(cache):
                        del cache.branchinfo
                    self._revbranchcache = cache
                return self._revbranchcache

        repo.__class__ = minitopicrepo

### topic aware branch head cache

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
    key = node.nullid
    revs = sorted(revs)
    if revs:
        s = hashlib.sha1()
        for rev in revs:
            s.update('%s;' % rev)
        key = s.digest()
    return key

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

_publiconly = set([
    'base',
    'immutable',
])

def mighttopic(repo):
    return hasminitopic(repo) and repo.filtername not in _publiconly

class _topiccache(branchmap.branchcache): # combine me with branchmap.branchcache

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

    def validfor(self, repo):
        """Is the cache content valid regarding a repo

        - False when cached tipnode is unknown or if we detect a strip.
        - True when cache is up to date or a subset of current repo."""
        valid = super(_topiccache, self).validfor(repo)
        if not valid:
            return False
        elif not mighttopic(repo) and self.phaseshash is None:
            # phasehash at None means this is a branchmap
            # coming from a public only set
            return True
        else:
            try:
                valid = self.phaseshash == _phaseshash(repo, self.tiprev)
                return valid
            except IndexError:
                return False

    def write(self, repo):
        # we expect (hope) mutable set to be small enough to be that computing
        # it all the time will be fast enough
        if not mighttopic(repo):
            super(_topiccache, self).write(repo)

    def update(self, repo, revgen):
        """Given a branchhead cache, self, that may have extra nodes or be
        missing heads, and a generator of nodes that are strictly a superset of
        heads missing, this function updates self to be correct.
        """
        super(_topiccache, self).update(repo, revgen)
        if mighttopic(repo):
            self.phaseshash = _phaseshash(repo, self.tiprev)

def wrapread(orig, repo):
    # Avoiding to write cache for filter where topic applies is a good step,
    # but we need to also avoid reading it. Existing branchmap cache might
    # exists before the turned the feature on.
    if mighttopic(repo):
        return None
    return orig(repo)

# advertise topic capabilities

def wireprotocaps(orig, repo, proto):
    caps = orig(repo, proto)
    if hasminitopic(repo):
        caps.append('topics')
    return caps

# wrap the necessary bit

def wrapclass(container, oldname, new):
    old = getattr(container, oldname)
    if not issubclass(old, new):
        targetclass = new
        # check if someone else already wrapped the class and handle that
        if not issubclass(new, old):
            class targetclass(new, old):
                pass
        setattr(container, oldname, targetclass)
    current = getattr(container, oldname)
    assert issubclass(current, new), (current, new, targetclass)

def uisetup(ui):
    wrapclass(context, 'changectx', topicchangectx)
    wrapclass(branchmap, 'branchcache', _topiccache)
    extensions.wrapfunction(branchmap, 'read', wrapread)
    extensions.wrapfunction(wireproto, '_capabilities', wireprotocaps)
