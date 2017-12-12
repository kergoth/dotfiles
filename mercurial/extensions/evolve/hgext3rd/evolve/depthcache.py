from __future__ import absolute_import

import array
import weakref

from mercurial import (
    localrepo,
    node as nodemod,
    util,
    scmutil,
)

from . import (
    error,
    exthelper,
    genericcaches,
)

from mercurial.i18n import _

eh = exthelper.exthelper()

def simpledepth(repo, rev):
    """simple but obviously right implementation of depth"""
    return len(repo.revs('::%d', rev))

@eh.command(
    'debugdepth',
    [
        ('r', 'rev', [], 'revs to print depth for'),
        ('', 'method', 'cached', "one of 'simple', 'cached', 'compare'"),
    ],
    _('REVS'))
def debugdepth(ui, repo, **opts):
    """display depth of REVS
    """
    revs = scmutil.revrange(repo, opts['rev'])
    method = opts['method']
    if method == 'cached':
        cache = repo.depthcache
        cache.save(repo)
    for r in revs:
        ctx = repo[r]
        if method == 'simple':
            depth = simpledepth(repo, r)
        elif method == 'cached':
            depth = cache.get(r)
        elif method == 'compare':
            simple = simpledepth(repo, r)
            cached = cache.get(r)
            if simple != cached:
                raise error.Abort('depth differ for revision %s: %d != %d'
                                  % (ctx, simple, cached))
        else:
            raise error.Abort('unknown method "%s"' % method)
        ui.write('%s %d\n' % (ctx, depth))

@eh.reposetup
def setupcache(ui, repo):

    class depthcacherepo(repo.__class__):

        @localrepo.unfilteredpropertycache
        def depthcache(self):
            cache = depthcache()
            cache.update(self)
            return cache

        @localrepo.unfilteredmethod
        def destroyed(self):
            if 'obsstore' in vars(self):
                self.depthcache.clear()
            super(depthcacherepo, self).destroyed()

        if util.safehasattr(repo, 'updatecaches'):
            @localrepo.unfilteredmethod
            def updatecaches(self, tr=None):
                if (repo.ui.configbool('experimental', 'obshashrange',
                                       False)
                        and repo.ui.configbool('experimental',
                                               'obshashrange.warm-cache',
                                               True)):
                    self.depthcache.update(repo)
                    self.depthcache.save(repo)
                super(depthcacherepo, self).updatecaches(tr)

        else:
            def transaction(self, *args, **kwargs):
                tr = super(depthcacherepo, self).transaction(*args, **kwargs)
                reporef = weakref.ref(self)

                def _warmcache(tr):
                    repo = reporef()
                    if repo is None:
                        return
                    repo = repo.unfiltered()
                    # As pointed in 'obscache.update', we could have the changelog
                    # and the obsstore in charge of updating the cache when new
                    # items goes it. The tranaction logic would then only be
                    # involved for the 'pending' and final writing on disk.
                    self.obsstore.obscache.update(repo)
                    self.obsstore.obscache.save(repo)

                if (repo.ui.configbool('experimental', 'obshashrange',
                                       False)
                        and repo.ui.configbool('experimental',
                                               'obshashrange.warm-cache',
                                               True)):
                    tr.addpostclose('warmcache-depthcache', _warmcache)
                return tr

    repo.__class__ = depthcacherepo

class depthcache(genericcaches.changelogsourcebase):

    _filepath = 'evoext-depthcache-00'
    _cachename = 'evo-ext-depthcache'

    def __init__(self):
        super(depthcache, self).__init__()
        self._data = array.array('l')

    def get(self, rev):
        if len(self._data) <= rev:
            raise error.ProgrammingError('depthcache must be warmed before use')
        return self._data[rev]

    def _updatefrom(self, repo, data):
        """compute the rev of one revision, assert previous revision has an hot cache
        """
        cl = repo.unfiltered().changelog
        total = len(data)

        def progress(pos, rev):
            repo.ui.progress('updating depth cache',
                             pos, 'rev %s' % rev, unit='revision', total=total)
        progress(0, '')
        for idx, rev in enumerate(data, 1):
            assert rev == len(self._data), (rev, len(self._data))
            self._data.append(self._depth(cl, rev))
            if not (idx % 10000): # progress as a too high performance impact
                progress(idx, rev)
        progress(None, '')

    def _depth(self, changelog, rev):
        cl = changelog
        p1, p2 = cl.parentrevs(rev)
        if p1 == nodemod.nullrev:
            # root case
            return 1
        elif p2 == nodemod.nullrev:
            # linear commit case
            return self.get(p1) + 1
        # merge case, must find the amount of exclusive content
        depth_p1 = self.get(p1)
        depth_p2 = self.get(p2)
        # computing depth of a merge
        ancnodes = cl.commonancestorsheads(cl.node(p1), cl.node(p2))
        if not ancnodes:
            # unrelated branch, (no common root)
            revdepth = depth_p1 + depth_p2 + 1
        elif len(ancnodes) == 1:
            # one unique branch point:
            # we can compute depth without any walk
            ancrev = cl.rev(ancnodes[0])
            depth_anc = self.get(ancrev)
            revdepth = depth_p1 + (depth_p2 - depth_anc) + 1
        else:
            # we pick the parent that is that is
            # * the deepest (less changeset outside of it),
            # * lowest revs because more chance to have descendant of other "above"
            parents = [(p1, depth_p1), (p2, depth_p2)]
            parents.sort(key=lambda x: (x[1], -x[0]))
            revdepth = parents[1][1]
            revdepth += len(cl.findmissingrevs(common=[parents[1][0]],
                                               heads=[parents[0][0]]))
            revdepth += 1 # the merge revision
        return revdepth

    # cache internal logic

    def clear(self, reset=False):
        """invalidate the cache content

        if 'reset' is passed, we detected a strip and the cache will have to be
        recomputed.

        Subclasses MUST overide this method to actually affect the cache data.
        """
        super(depthcache, self).clear()
        self._data = array.array('l')

    # crude version of a cache, to show the kind of information we have to store

    def load(self, repo):
        """load data from disk"""
        assert repo.filtername is None

        if util.safehasattr(repo, 'cachevfs'):
            data = repo.cachevfs.tryread(self._filepath)
        else:
            data = repo.vfs.tryread('cache/' + self._filepath)
        self._data = array.array('l')
        if not data:
            self._cachekey = self.emptykey
        else:
            headerdata = data[:self._cachekeysize]
            self._cachekey = self._deserializecachekey(headerdata)
            self._data.fromstring(data[self._cachekeysize:])
        self._ondiskkey = self._cachekey

    def save(self, repo):
        """save the data to disk

        Format is pretty simple, we serialise the cache key and then drop the
        bytearray.
        """
        if self._cachekey is None or self._cachekey == self._ondiskkey:
            return

        if util.safehasattr(repo, 'cachevfs'):
            cachefile = repo.cachevfs(self._filepath, 'w', atomictemp=True)
        else:
            cachefile = repo.vfs('cache/' + self._filepath, 'w', atomictemp=True)
        headerdata = self._serializecachekey()
        cachefile.write(headerdata)
        cachefile.write(self._data.tostring())
        cachefile.close()
