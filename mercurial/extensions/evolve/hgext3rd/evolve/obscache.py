# Code dedicated to an cache around obsolescence property
#
# This module content aims at being upstreamed.
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import errno
import hashlib
import os
import struct
import time
import weakref

from mercurial import (
    error,
    localrepo,
    obsolete,
    phases,
    pycompat,
    node,
    util,
)

from mercurial.i18n import _

from . import (
    exthelper,
)

eh = exthelper.exthelper()

# prior to hg-4.2 there are not util.timer
if util.safehasattr(util, 'timer'):
    timer = util.timer
elif util.safehasattr(time, "perf_counter"):
    timer = time.perf_counter
elif getattr(pycompat, 'osname', os.name) == 'nt':
    timer = time.clock
else:
    timer = time.time


try:
    obsstorefilecache = localrepo.localrepository.obsstore
except AttributeError:
    # XXX hg-3.8 compat
    #
    # mercurial 3.8 has issue with accessing file cache property from their
    # cache. This is fix by 36fbd72c2f39fef8ad52d7c559906c2bc388760c in core
    # and shipped in 3.9
    obsstorefilecache = localrepo.localrepository.__dict__['obsstore']

# obsstore is a filecache so we have do to some spacial dancing
@eh.wrapfunction(obsstorefilecache, 'func')
def obsstorewithcache(orig, repo):
    obsstore = orig(repo)
    obsstore.obscache = obscache(repo.unfiltered())

    class cachekeyobsstore(obsstore.__class__):

        _obskeysize = 200

        def cachekey(self, index=None):
            """return (current-length, cachekey)

            'current-length': is the current length of the obsstore storage file,
            'cachekey' is the hash of the last 200 bytes ending at 'index'.

            if 'index' is unspecified, current obsstore length is used.
            Cacheckey will be set to null id if the obstore is empty.

            If the index specified is higher than the current obsstore file
            length, cachekey will be set to None."""
            # default value
            obsstoresize = 0
            keydata = ''
            # try to get actual data from the obsstore
            try:
                with self.svfs('obsstore') as obsfile:
                    obsfile.seek(0, 2)
                    obsstoresize = obsfile.tell()
                    if index is None:
                        index = obsstoresize
                    elif obsstoresize < index:
                        return obsstoresize, None
                    actualsize = min(index, self._obskeysize)
                    if actualsize:
                        obsfile.seek(index - actualsize, 0)
                        keydata = obsfile.read(actualsize)
            except (OSError, IOError) as e:
                if e.errno != errno.ENOENT:
                    raise
            if keydata:
                key = hashlib.sha1(keydata).digest()
            else:
                # reusing an existing "empty" value make it easier to define a
                # default cachekey for 'no data'.
                key = node.nullid
            return obsstoresize, key

    obsstore.__class__ = cachekeyobsstore

    return obsstore

# XXX copied as is from Mercurial 4.2 and added the "offset" parameters
@util.nogc
def _readmarkers(data, offset=None):
    """Read and enumerate markers from raw data"""
    off = 0
    diskversion = struct.unpack('>B', data[off:off + 1])[0]
    if offset is None:
        off += 1
    else:
        assert 1 <= offset
        off = offset
    if diskversion not in obsolete.formats:
        raise error.Abort(_('parsing obsolete marker: unknown version %r')
                          % diskversion)
    return diskversion, obsolete.formats[diskversion][0](data, off)

def markersfrom(obsstore, byteoffset, firstmarker):
    if not firstmarker:
        return list(obsstore)
    elif '_all' in vars(obsstore):
        # if the data are in memory, just use that
        return obsstore._all[firstmarker:]
    else:
        obsdata = obsstore.svfs.tryread('obsstore')
        return _readmarkers(obsdata, byteoffset)[1]


class dualsourcecache(object):
    """An abstract class for cache that needs both changelog and obsstore

    This class handle the tracking of changelog and obsstore update. It provide
    data to performs incremental update (see the 'updatefrom' function for
    details).  This class can also detect stripping of the changelog or the
    obsstore and can reset the cache in this cache (see the 'clear' function
    for details).
    """

    # default key used for an empty cache
    #
    # The cache key covering the changesets and obsmarkers content
    #
    # The cache key parts are:
    # - tip-rev,
    # - tip-node,
    # - obsstore-length (nb markers),
    # - obsstore-file-size (in bytes),
    # - obsstore "cache key"
    emptykey = (node.nullrev, node.nullid, 0, 0, node.nullid)
    _cachename = None # used for error message

    def __init__(self):
        super(dualsourcecache, self).__init__()
        self._cachekey = None

    def _updatefrom(self, repo, revs, obsmarkers):
        """override this method to update your cache data incrementally

        revs:      list of new revision in the changelog
        obsmarker: list of new obsmarkers in the obsstore
        """
        raise NotImplementedError

    def clear(self, reset=False):
        """invalidate the cache content

        if 'reset' is passed, we detected a strip and the cache will have to be
        recomputed.
        """
        # /!\ IMPORTANT /!\
        # You must overide this method to actually
        if reset:
            self._cachekey = self.emptykey if reset else None
        else:
            self._cachekey = None

    def load(self, repo):
        """Load data from disk

        Do not forget to restore the "cachekey" attribute while doing so.
        """
        raise NotImplementedError

    # Useful public function (no need to override them)

    def uptodate(self, repo):
        """return True if the cache content is up to date False otherwise

        This method can be used to detect of the cache is lagging behind new
        data in either changelog or obsstore.
        """
        if self._cachekey is None:
            self.load(repo)
        status = self._checkkey(repo.changelog, repo.obsstore)
        return (status is not None
                and status[0] == self._cachekey[0] # tiprev
                and status[1] == self._cachekey[3]) # obssize

    def update(self, repo):
        """update the cache with new repository data

        The update will be incremental when possible"""
        repo = repo.unfiltered()
        # If we do not have any data, try loading from disk
        if self._cachekey is None:
            self.load(repo)

        assert repo.filtername is None
        cl = repo.changelog

        upgrade = self._upgradeneeded(repo)
        if upgrade is None:
            return

        reset, revs, obsmarkers, obskeypair = upgrade
        if reset or self._cachekey is None:
            repo.ui.log('evoext-cache', 'strip detected, %s cache reset\n' % self._cachename)
            self.clear(reset=True)

        starttime = timer()
        self._updatefrom(repo, revs, obsmarkers)
        duration = timer() - starttime
        repo.ui.log('evoext-cache', 'updated %s in %.4f seconds (%sr, %so)\n',
                    self._cachename, duration, len(revs), len(obsmarkers))

        # update the key from the new data
        key = list(self._cachekey)
        if revs:
            key[0] = len(cl) - 1
            key[1] = cl.node(key[0])
        if obsmarkers:
            key[2] += len(obsmarkers)
            key[3], key[4] = obskeypair
        self._cachekey = tuple(key)

    # from here, there are internal function only

    def _checkkey(self, changelog, obsstore):
        """internal function"""
        key = self._cachekey
        if key is None:
            return None

        ### Is the cache valid ?
        keytiprev, keytipnode, keyobslength, keyobssize, keyobskey = key
        # check for changelog strip
        tiprev = len(changelog) - 1
        if (tiprev < keytiprev
                or changelog.node(keytiprev) != keytipnode):
            return None
        # check for obsstore strip
        obssize, obskey = obsstore.cachekey(index=keyobssize)
        if obskey != keyobskey:
            return None
        if obssize != keyobssize:
            # we want to return the obskey for the new size
            __, obskey = obsstore.cachekey(index=obssize)
        return tiprev, obssize, obskey

    def _upgradeneeded(self, repo):
        """return (valid, start-rev, start-obs-idx)

        'valid': is "False" if older cache value needs invalidation,

        'start-rev': first revision not in the cache. None if cache is up to date,

        'start-obs-idx': index of the first obs-markers not in the cache. None is
                         up to date.
        """

        # We need to ensure we use the same changelog and obsstore through the
        # processing. Otherwise some invalidation could update the object and their
        # content after we computed the cache key.
        cl = repo.changelog
        obsstore = repo.obsstore
        key = self._cachekey

        reset = False

        status = self._checkkey(cl, obsstore)
        if status is None:
            reset = True
            key = self.emptykey
            obssize, obskey = obsstore.cachekey()
            tiprev = len(cl) - 1
        else:
            tiprev, obssize, obskey = status

        keytiprev, keytipnode, keyobslength, keyobssize, keyobskey = key

        if not reset and keytiprev == tiprev and keyobssize == obssize:
            return None # nothing to upgrade

        ### cache is valid, is there anything to update

        # any new changesets ?
        revs = ()
        if keytiprev < tiprev:
            revs = list(cl.revs(start=keytiprev + 1, stop=tiprev))

        # any new markers
        markers = ()
        if keyobssize < obssize:
            # XXX Three are a small race change here. Since the obsstore might have
            # move forward between the time we computed the cache key and we access
            # the data. To fix this we need so "up to" argument when fetching the
            # markers here. Otherwise we might return more markers than covered by
            # the cache key.
            #
            # In pratice the cache is only updated after each transaction within a
            # lock. So we should be fine. We could enforce this with a new repository
            # requirement (or fix the race, that is not too hard).
            markers = markersfrom(obsstore, keyobssize, keyobslength)

        return reset, revs, markers, (obssize, obskey)


class obscache(dualsourcecache):
    """cache the "does a rev" is the precursors of some obsmarkers data

    This is not directly holding the "is this revision obsolete" information,
    because phases data gets into play here. However, it allow to compute the
    "obsolescence" set without reading the obsstore content.

    Implementation note #1:

      The obsstore is implementing only half of the transaction logic it
      should. It properly record the starting point of the obsstore to allow
      clean rollback. However it still write to the obsstore file directly
      during the transaction. Instead it should be keeping data in memory and
      write to a '.pending' file to make the data vailable for hooks.

      This cache is not going futher than what the obstore is doing, so it does
      not has any '.pending' logic. When the obsstore gains proper '.pending'
      support, adding it to this cache should not be too hard. As the flag
      always move from 0 to 1, we could have a second '.pending' cache file to
      be read. If flag is set in any of them, the value is 1. For the same
      reason, updating the file in place should be possible.

    Implementation note #2:

      Instead of having a large final update run, we could update this cache at
      the level adding a new changeset or a new obsmarkers. More on this in the
      'update code'.

    Implementation note #3:

        Storage-wise, we could have a "start rev" to avoid storing useless
        zero. That would be especially useful for the '.pending' overlay.
    """

    _filepath = 'cache/evoext-obscache-00'
    _headerformat = '>q20sQQ20s'

    _cachename = 'evo-ext-obscache' # used for error message

    def __init__(self, repo):
        super(obscache, self).__init__()
        self._ondiskkey = None
        self._vfs = repo.vfs
        self._setdata(bytearray())

    @util.propertycache
    def get(self):
        """final signature: obscache.get(rev)

        return True if "rev" is used as "precursors for any obsmarkers

        IMPORTANT: make sure the cache has been updated to match the repository
        content before using it

        We use a property cache to skip the attribute resolution overhead in
        hot loops."""
        return self._data.__getitem__

    def _setdata(self, data):
        """set a new bytearray data, invalidating the 'get' shortcut if needed"""
        self._data = data
        if 'get' in vars(self):
            del self.get

    def clear(self, reset=False):
        """invalidate the cache content"""
        super(obscache, self).clear(reset=reset)
        self._setdata(bytearray())

    def _updatefrom(self, repo, revs, obsmarkers):
        if revs:
            self._updaterevs(repo, revs)
        if obsmarkers:
            self._updatemarkers(repo, obsmarkers)

    def _updaterevs(self, repo, revs):
        """update the cache with new revisions

        Newly added changeset might be affected by obsolescence markers
        we already have locally. So we needs to have some global
        knowledge about the markers to handle that question.

        Right now this requires parsing all markers in the obsstore. We could
        imagine using various optimisation (eg: another cache, network
        exchange, etc).

        A possible approach to this is to build a set of all node used as
        precursors in `obsstore._obscandidate`. If markers are not loaded yet,
        we could initialize it by doing a quick scan through the obsstore data
        and filling a (pre-sized) set. Doing so would be much faster than
        parsing all the obsmarkers since we would access less data, not create
        any object beside the nodes and not have to decode any complex data.

        For now we stick to the simpler approach of paying the
        performance cost on new changesets.
        """
        new_entries = bytearray(len(revs))
        if not self._data:
            self._setdata(new_entries)
        else:
            self._data.extend(new_entries)
        data = self._data
        if repo.obsstore:
            node = repo.changelog.node
            succs = repo.obsstore.successors
            for r in revs:
                if node(r) in succs:
                    data[r] = 1

    def _updatemarkers(self, repo, obsmarkers):
        """update the cache with new markers"""
        rev = repo.changelog.nodemap.get
        for m in obsmarkers:
            r = rev(m[0])
            if r is not None:
                self._data[r] = 1

    def save(self, repo):
        """save the data to disk"""

        # XXX it happens that the obsstore is (buggilly) always up to date on disk
        if self._cachekey is None or self._cachekey == self._ondiskkey:
            return

        cachefile = repo.vfs(self._filepath, 'w', atomictemp=True)
        headerdata = struct.pack(self._headerformat, *self._cachekey)
        cachefile.write(headerdata)
        cachefile.write(self._data)
        cachefile.close()

    def load(self, repo):
        """load data from disk"""
        assert repo.filtername is None

        data = repo.vfs.tryread(self._filepath)
        if not data:
            self._cachekey = self.emptykey
            self._setdata(bytearray())
        else:
            headersize = struct.calcsize(self._headerformat)
            self._cachekey = struct.unpack(self._headerformat, data[:headersize])
            self._setdata(bytearray(data[headersize:]))
        self._ondiskkey = self._cachekey

def _computeobsoleteset(orig, repo):
    """the set of obsolete revisions"""
    obs = set()
    repo = repo.unfiltered()
    if util.safehasattr(repo._phasecache, 'getrevset'):
        notpublic = repo._phasecache.getrevset(repo, (phases.draft, phases.secret))
    else:
        # < hg-4.2 compat
        notpublic = repo.revs("not public()")
    if notpublic:
        obscache = repo.obsstore.obscache
        # Since we warm the cache at the end of every transaction, the cache
        # should be up to date. However a non-enabled client might have touched
        # the repository.
        #
        # Updating the cache without a lock is sloppy, so we fallback to the
        # old method and rely on the fact the next transaction will write the
        # cache down anyway.
        #
        # With the current implementation updating the cache will requires to
        # load the obsstore anyway. Once loaded, hitting the obsstore directly
        # will be about as fast...
        if not obscache.uptodate(repo):
            if repo.currenttransaction() is None:
                repo.ui.log('evoext-cache',
                            'obscache is out of date, '
                            'falling back to slower obsstore version\n')
                repo.ui.debug('obscache is out of date\n')
                return orig(repo)
            else:
                # If a transaction is open, it is worthwhile to update and use
                # the cache, the lock prevent race and it will be written on
                # disk when the transaction close.
                obscache.update(repo)
        isobs = obscache.get
    for r in notpublic:
        if isobs(r):
            obs.add(r)
    return obs

@eh.uisetup
def cachefuncs(ui):
    orig = obsolete.cachefuncs['obsolete']
    wrapped = lambda repo: _computeobsoleteset(orig, repo)
    obsolete.cachefuncs['obsolete'] = wrapped

@eh.reposetup
def setupcache(ui, repo):

    class obscacherepo(repo.__class__):

        @localrepo.unfilteredmethod
        def destroyed(self):
            if 'obsstore' in vars(self):
                self.obsstore.obscache.clear()
            super(obscacherepo, self).destroyed()

        if util.safehasattr(repo, 'updatecaches'):
            @localrepo.unfilteredmethod
            def updatecaches(self, tr=None):
                super(obscacherepo, self).updatecaches(tr)
                self.obsstore.obscache.update(repo)
                self.obsstore.obscache.save(repo)

        else:
            def transaction(self, *args, **kwargs):
                tr = super(obscacherepo, self).transaction(*args, **kwargs)
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

                tr.addpostclose('warmcache-obscache', _warmcache)
                return tr

    repo.__class__ = obscacherepo
