# Code dedicated to an cache around obsolescence property
#
# This module content aims at being upstreamed.
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import hashlib
import struct
import weakref
import errno

from mercurial import (
    localrepo,
    obsolete,
    phases,
    node,
    util,
)

from . import (
    exthelper,
)

eh = exthelper.exthelper()

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
            key = hashlib.sha1(keydata).digest()
            return obsstoresize, key

    obsstore.__class__ = cachekeyobsstore

    return obsstore

emptykey = (node.nullrev, node.nullid, 0, 0, node.nullid)

def getcachekey(repo):
    """get a cache key covering the changesets and obsmarkers content

    IT contains the following data. Combined with 'upgradeneeded' it allows to
    do iterative upgrade for cache depending of theses two data.

    The cache key parts are"
    - tip-rev,
    - tip-node,
    - obsstore-length (nb markers),
    - obsstore-file-size (in bytes),
    - obsstore "cache key"
    """
    assert repo.filtername is None
    cl = repo.changelog
    index, key = repo.obsstore.cachekey()
    tiprev = len(cl) - 1
    return (tiprev,
            cl.node(tiprev),
            len(repo.obsstore),
            index,
            key)

def upgradeneeded(repo, key):
    """return (valid, start-rev, start-obs-idx)

    'valid': is "False" if older cache value needs invalidation,

    'start-rev': first revision not in the cache. None if cache is up to date,

    'start-obs-idx': index of the first obs-markers not in the cache. None is
                     up to date.
    """

    # XXX ideally, this function would return a bounded amount of changeset and
    # obsmarkers and the associated new cache key. Otherwise we are exposed to
    # a race condition between the time the cache is updated and the new cache
    # key is computed. (however, we do not want to compute the full new cache
    # key in all case because we want to skip reading the obsstore content. We
    # could have a smarter implementation here.
    #
    # In pratice the cache is only updated after each transaction within a
    # lock. So we should be fine. We could enforce this with a new repository
    # requirement (or fix the race, that is not too hard).
    invalid = (False, 0, 0)
    if key is None:
        return invalid

    ### Is the cache valid ?
    keytiprev, keytipnode, keyobslength, keyobssize, keyobskey = key
    # check for changelog strip
    cl = repo.changelog
    tiprev = len(cl) - 1
    if (tiprev < keytiprev
            or cl.node(keytiprev) != keytipnode):
        return invalid
    # check for obsstore strip
    obssize, obskey = repo.obsstore.cachekey(index=keyobssize)
    if obskey != keyobskey:
        return invalid

    ### cache is valid, is there anything to update

    # any new changesets ?
    startrev = None
    if keytiprev < tiprev:
        startrev = keytiprev + 1

    # any new markers
    startidx = None
    if keyobssize < obssize:
        startidx = keyobslength

    return True, startrev, startidx

class obscache(object):
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

    def __init__(self, repo):
        self._vfs = repo.vfs
        # The cache key parts are"
        # - tip-rev,
        # - tip-node,
        # - obsstore-length (nb markers),
        # - obsstore-file-size (in bytes),
        # - obsstore "cache key"
        self._cachekey = None
        self._ondiskkey = None
        self._data = bytearray()

    def get(self, rev):
        """return True if "rev" is used as "precursors for any obsmarkers

        Make sure the cache has been updated to match the repository content before using it"""
        return self._data[rev]

    def clear(self):
        """invalidate the cache content"""
        self._cachekey = None
        self._data = bytearray()

    def uptodate(self, repo):
        if self._cachekey is None:
            self.load(repo)
        valid, startrev, startidx = upgradeneeded(repo, self._cachekey)
        return (valid and startrev is None and startidx is None)

    def update(self, repo):
        """Iteratively update the cache with new repository data"""
        # If we do not have any data, try loading from disk
        if self._cachekey is None:
            self.load(repo)

        valid, startrev, startidx = upgradeneeded(repo, self._cachekey)
        if not valid:
            self.clear()

        if startrev is None and startidx is None:
            return

        # process the new changesets
        cl = repo.changelog
        if startrev is not None:
            node = cl.node
            # Note:
            #
            #  Newly added changeset might be affected by obsolescence markers
            #  we already have locally. So we needs to have soem global
            #  knowledge about the markers to handle that question. Right this
            #  requires parsing all markers in the obsstore. However, we could
            #  imagine using various optimisation (eg: bloom filter, other on
            #  disk cache) to remove this full parsing.
            #
            #  For now we stick to the simpler approach or paying the
            #  performance cost on new changesets.
            succs = repo.obsstore.successors
            for r in cl.revs(startrev):
                if node(r) in succs:
                    val = 1
                else:
                    val = 0
                self._data.append(val)
        assert len(self._data) == len(cl), (len(self._data), len(cl))

        # process the new obsmarkers
        if startidx is not None:
            rev = cl.nodemap.get
            markers = repo.obsstore._all
            # Note:
            #
            #   There are no actually needs to load the full obsstore here,
            #   since we only read the latest ones.  We do it for simplicity in
            #   the first implementation. Loading the full obsstore has a
            #   performance cost and should go away in this case too. We have
            #   two simples options for that:
            #
            #   1) provide and API to start reading markers from a byte offset
            #      (we have that data in the cache key)
            #
            #   2) directly update the cache at a lower level, in the code
            #      responsible for adding a markers.
            #
            #   Option 2 is probably a bit more invasive, but more solid on the long run

            for i in xrange(startidx, len(repo.obsstore)):
                r = rev(markers[i][0])
                # If markers affect a newly added nodes, it would have been
                # caught in the previous loop, (so we skip < startrev)
                if r is not None and (startrev is None or r < startrev):
                    self._data[r] = 1

        assert repo._currentlock(repo._lockref) is not None
        # XXX note that there are a potential race condition here, since the
        # repo "might" have changed side the cache update above. However, this
        # code will only be running in a lock so we ignore the issue for now.
        #
        # To work around this, 'upgradeneeded' should return a bounded amount
        # of changeset and markers to read with their associated cachekey. see
        # 'upgradeneeded' for detail.
        self._cachekey = getcachekey(repo)

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
            self._cachekey = emptykey
            self._data = bytearray()
        else:
            headersize = struct.calcsize(self._headerformat)
            self._cachekey = struct.unpack(self._headerformat, data[:headersize])
            self._data = bytearray(data[headersize:])
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
        # should be up to date. However a non-enabled client might have touced
        # the repository.
        #
        # Updating the cache without a lock is sloppy, so we fallback to the
        # old method and rely on the fact the next transaction will write the
        # cache down anyway.
        #
        # With the current implementation updating the cache will requires to
        # load the obsstore anyway. Once loaded, hitting the obsstore directly
        # will be about as fast..
        if not obscache.uptodate(repo):
            if repo.currenttransaction() is None:
                repo.ui.log('evoext-obscache',
                            'obscache is out of date, '
                            'falling back to slower obsstore version\n')
                repo.ui.debug('obscache is out of date')
                return orig(repo)
            else:
                # If a transaction is open, it is worthwhile to update and use the
                # cache as it will be written on disk when the transaction close.
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

        def transaction(self, *args, **kwargs):
            tr = super(obscacherepo, self).transaction(*args, **kwargs)
            reporef = weakref.ref(self)

            def _warmcache(tr):
                repo = reporef()
                if repo is None:
                    return
                repo = repo.unfiltered()
                # As pointed in 'obscache.update', we could have the
                # changelog and the obsstore in charge of updating the
                # cache when new items goes it. The tranaction logic would
                # then only be involved for the 'pending' and final saving
                # logic.
                self.obsstore.obscache.update(repo)
                self.obsstore.obscache.save(repo)

            tr.addpostclose('warmcache-obscache', _warmcache)
            return tr

    repo.__class__ = obscacherepo
