# Code dedicated to the discovery of obsolescence marker "over the wire"
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

# Status: Experiment in progress // open question
#
#   The final discovery algorithm and protocol will go into core when we'll be
#   happy with it.
#
#   Some of the code in this module is for compatiblity with older version
#   of evolve and will be eventually dropped.

from __future__ import absolute_import

try:
    import StringIO as io
    StringIO = io.StringIO
except ImportError:
    import io
    StringIO = io.StringIO

import hashlib
import heapq
import os
import sqlite3
import struct
import time
import weakref

from mercurial import (
    dagutil,
    error,
    exchange,
    extensions,
    localrepo,
    node,
    obsolete,
    pycompat,
    scmutil,
    setdiscovery,
    util,
    wireproto,
)
from mercurial.hgweb import hgweb_mod
from mercurial.i18n import _

from . import (
    exthelper,
    obscache,
    utility,
    stablerange,
)

# prior to hg-4.2 there are not util.timer
if util.safehasattr(util, 'timer'):
    timer = util.timer
elif util.safehasattr(time, "perf_counter"):
    timer = time.perf_counter
elif getattr(pycompat, 'osname', os.name) == 'nt':
    timer = time.clock
else:
    timer = time.time

_pack = struct.pack
_unpack = struct.unpack
_calcsize = struct.calcsize

eh = exthelper.exthelper()
eh.merge(stablerange.eh)
obsexcmsg = utility.obsexcmsg

##################################
###  Code performing discovery ###
##################################

def findcommonobsmarkers(ui, local, remote, probeset,
                         initialsamplesize=100,
                         fullsamplesize=200):
    # from discovery
    roundtrips = 0
    cl = local.changelog
    dag = dagutil.revlogdag(cl)
    missing = set()
    common = set()
    undecided = set(probeset)
    totalnb = len(undecided)
    ui.progress(_("comparing with other"), 0, total=totalnb)
    _takefullsample = setdiscovery._takefullsample
    if remote.capable('_evoext_obshash_1'):
        getremotehash = remote.evoext_obshash1
        localhash = _obsrelsethashtreefm1(local)
    else:
        getremotehash = remote.evoext_obshash
        localhash = _obsrelsethashtreefm0(local)

    while undecided:

        ui.note(_("sampling from both directions\n"))
        if len(undecided) < fullsamplesize:
            sample = set(undecided)
        else:
            sample = _takefullsample(dag, undecided, size=fullsamplesize)

        roundtrips += 1
        ui.progress(_("comparing with other"), totalnb - len(undecided),
                    total=totalnb)
        ui.debug("query %i; still undecided: %i, sample size is: %i\n"
                 % (roundtrips, len(undecided), len(sample)))
        # indices between sample and externalized version must match
        sample = list(sample)
        remotehash = getremotehash(dag.externalizeall(sample))

        yesno = [localhash[ix][1] == remotehash[si]
                 for si, ix in enumerate(sample)]

        commoninsample = set(n for i, n in enumerate(sample) if yesno[i])
        common.update(dag.ancestorset(commoninsample, common))

        missinginsample = [n for i, n in enumerate(sample) if not yesno[i]]
        missing.update(dag.descendantset(missinginsample, missing))

        undecided.difference_update(missing)
        undecided.difference_update(common)

    ui.progress(_("comparing with other"), None)
    result = dag.headsetofconnecteds(common)
    ui.debug("%d total queries\n" % roundtrips)

    if not result:
        return set([node.nullid])
    return dag.externalizeall(result)

def findmissingrange(ui, local, remote, probeset,
                     initialsamplesize=100,
                     fullsamplesize=200):
    missing = set()
    starttime = timer()

    heads = local.revs('heads(%ld)', probeset)
    local.stablerange.warmup(local)

    rangelength = local.stablerange.rangelength
    subranges = local.stablerange.subranges
    # size of slice ?
    heappop = heapq.heappop
    heappush = heapq.heappush
    heapify = heapq.heapify

    tested = set()

    sample = []
    samplesize = initialsamplesize

    def addentry(entry):
        if entry in tested:
            return False
        sample.append(entry)
        tested.add(entry)
        return True

    for h in heads:
        entry = (h, 0)
        addentry(entry)

    local.obsstore.rangeobshashcache.update(local)
    querycount = 0
    ui.progress(_("comparing obsmarker with other"), querycount)
    overflow = []
    while sample or overflow:
        if overflow:
            sample.extend(overflow)
            overflow = []

        if samplesize < len(sample):
            # too much sample already
            overflow = sample[samplesize:]
            sample = sample[:samplesize]
        elif len(sample) < samplesize:
            ui.debug("query %i; add more sample (target %i, current %i)\n"
                     % (querycount, samplesize, len(sample)))
            # we need more sample !
            needed = samplesize - len(sample)
            sliceme = []
            heapify(sliceme)
            for entry in sample:
                if 1 < rangelength(local, entry):
                    heappush(sliceme, (-rangelength(local, entry), entry))

            while sliceme and 0 < needed:
                _key, target = heappop(sliceme)
                for new in subranges(local, target):
                    # XXX we could record hierarchy to optimise drop
                    if addentry(new):
                        if 1 < len(new):
                            heappush(sliceme, (-rangelength(local, new), new))
                        needed -= 1
                        if needed <= 0:
                            break

        # no longer the first interation
        samplesize = fullsamplesize

        nbsample = len(sample)
        maxsize = max([rangelength(local, r) for r in sample])
        ui.debug("query %i; sample size is %i, largest range %i\n"
                 % (querycount, nbsample, maxsize))
        nbreplies = 0
        replies = list(_queryrange(ui, local, remote, sample))
        sample = []
        n = local.changelog.node
        for entry, remotehash in replies:
            nbreplies += 1
            if remotehash == _obshashrange(local, entry):
                continue
            elif 1 == rangelength(local, entry):
                missing.add(n(entry[0]))
            else:
                for new in subranges(local, entry):
                    addentry(new)
        assert nbsample == nbreplies
        querycount += 1
        ui.progress(_("comparing obsmarker with other"), querycount)
    ui.progress(_("comparing obsmarker with other"), None)
    local.obsstore.rangeobshashcache.save(local)
    duration = timer() - starttime
    logmsg = ('obsdiscovery, %d/%d mismatch'
              ' - %d obshashrange queries in %.4f seconds\n')
    logmsg %= (len(missing), len(probeset), querycount, duration)
    ui.log('evoext-obsdiscovery', logmsg)
    ui.debug(logmsg)
    return sorted(missing)

def _queryrange(ui, repo, remote, allentries):
    #  question are asked with node
    n = repo.changelog.node
    noderanges = [(n(entry[0]), entry[1]) for entry in allentries]
    replies = remote.evoext_obshashrange_v0(noderanges)
    result = []
    for idx, entry in enumerate(allentries):
        result.append((entry, replies[idx]))
    return result

##############################
### Range Hash computation ###
##############################

@eh.command(
    'debugobshashrange',
    [
        ('', 'rev', [], 'display obshash for all (rev, 0) range in REVS'),
        ('', 'subranges', False, 'display all subranges'),
    ],
    _(''))
def debugobshashrange(ui, repo, **opts):
    """display the ::REVS set topologically sorted in a stable way
    """
    s = node.short
    revs = scmutil.revrange(repo, opts['rev'])
    # prewarm depth cache
    if revs:
        repo.stablerange.warmup(repo, max(revs))
    cl = repo.changelog
    rangelength = repo.stablerange.rangelength
    depthrev = repo.stablerange.depthrev
    if opts['subranges']:
        ranges = stablerange.subrangesclosure(repo, revs)
    else:
        ranges = [(r, 0) for r in revs]
    headers = ('rev', 'node', 'index', 'size', 'depth', 'obshash')
    linetemplate = '%12d %12s %12d %12d %12d %12s\n'
    headertemplate = linetemplate.replace('d', 's')
    ui.status(headertemplate % headers)
    repo.obsstore.rangeobshashcache.update(repo)
    for r in ranges:
        d = (r[0],
             s(cl.node(r[0])),
             r[1],
             rangelength(repo, r),
             depthrev(repo, r[0]),
             node.short(_obshashrange(repo, r)))
        ui.status(linetemplate % d)
    repo.obsstore.rangeobshashcache.save(repo)

def _obshashrange(repo, rangeid):
    """return the obsolete hash associated to a range"""
    cache = repo.obsstore.rangeobshashcache
    cl = repo.changelog
    obshash = cache.get(rangeid)
    if obshash is not None:
        return obshash
    pieces = []
    nullid = node.nullid
    if repo.stablerange.rangelength(repo, rangeid) == 1:
        rangenode = cl.node(rangeid[0])
        tmarkers = repo.obsstore.relevantmarkers([rangenode])
        pieces = []
        for m in tmarkers:
            mbin = obsolete._fm1encodeonemarker(m)
            pieces.append(mbin)
        pieces.sort()
    else:
        for subrange in repo.stablerange.subranges(repo, rangeid):
            obshash = _obshashrange(repo, subrange)
            if obshash != nullid:
                pieces.append(obshash)

    sha = hashlib.sha1()
    # note: if there is only one subrange with actual data, we'll just
    # reuse the same hash.
    if not pieces:
        obshash = node.nullid
    elif len(pieces) != 1 or obshash is None:
        sha = hashlib.sha1()
        for p in pieces:
            sha.update(p)
        obshash = sha.digest()
    cache[rangeid] = obshash
    return obshash

### sqlite caching

_sqliteschema = [
    """CREATE TABLE meta(schemaversion INTEGER NOT NULL,
                         tiprev        INTEGER NOT NULL,
                         tipnode       BLOB    NOT NULL,
                         nbobsmarker   INTEGER NOT NULL,
                         obssize       BLOB    NOT NULL,
                         obskey        BLOB    NOT NULL
                        );""",
    """CREATE TABLE obshashrange(rev     INTEGER NOT NULL,
                                 idx     INTEGER NOT NULL,
                                 obshash BLOB    NOT NULL,
                                 PRIMARY KEY(rev, idx));""",
    "CREATE INDEX range_index ON obshashrange(rev, idx);",
]
_queryexist = "SELECT name FROM sqlite_master WHERE type='table' AND name='meta';"
_clearmeta = """DELETE FROM meta;"""
_newmeta = """INSERT INTO meta (schemaversion, tiprev, tipnode, nbobsmarker, obssize, obskey)
            VALUES (?,?,?,?,?,?);"""
_updateobshash = "INSERT INTO obshashrange(rev, idx, obshash) VALUES (?,?,?);"
_querymeta = "SELECT schemaversion, tiprev, tipnode, nbobsmarker, obssize, obskey FROM meta;"
_queryobshash = "SELECT obshash FROM obshashrange WHERE (rev = ? AND idx = ?);"

_reset = "DELETE FROM obshashrange;"

class _obshashcache(obscache.dualsourcecache):

    _schemaversion = 2

    _cachename = 'evo-ext-obshashrange' # used for error message

    def __init__(self, repo):
        super(_obshashcache, self).__init__()
        self._vfs = repo.vfs
        self._path = repo.vfs.join('cache/evoext_obshashrange_v1.sqlite')
        self._new = set()
        self._valid = True
        self._repo = weakref.ref(repo.unfiltered())
        # cache status
        self._ondiskcachekey = None
        self._data = {}

    def clear(self, reset=False):
        super(_obshashcache, self).clear(reset=reset)
        self._data.clear()
        self._new.clear()
        if reset:
            self._valid = False
        if '_con' in vars(self):
            del self._con

    def get(self, rangeid):
        # revision should be covered by the tiprev
        #
        # XXX there are issue with cache warming, we hack around it for now
        if not getattr(self, '_updating', False):
            if self._cachekey[0] < rangeid[0]:
                msg = ('using unwarmed obshashrangecache (%s %s)'
                       % (rangeid[0], self._cachekey[0]))
                raise error.ProgrammingError(msg)

        value = self._data.get(rangeid)
        if value is None and self._con is not None:
            nrange = (rangeid[0], rangeid[1])
            obshash = self._con.execute(_queryobshash, nrange).fetchone()
            if obshash is not None:
                value = obshash[0]
            self._data[rangeid] = value
        return value

    def __setitem__(self, rangeid, obshash):
        self._new.add(rangeid)
        self._data[rangeid] = obshash

    def _updatefrom(self, repo, revs, obsmarkers):
        """override this method to update your cache data incrementally

        revs:      list of new revision in the changelog
        obsmarker: list of new obsmarkers in the obsstore
        """
        # XXX for now, we'll not actually update the cache, but we'll be
        # smarter at invalidating it.
        #
        # 1) new revisions does not get their entry updated (not update)
        # 2) if we detect markers affecting non-new revision we reset the cache

        self._updating = True

        setrevs = set(revs)
        rev = repo.changelog.nodemap.get
        # if we have a new markers affecting a node already covered by the
        # cache, we must abort.
        affected = set()
        for m in obsmarkers:
            # check successors and parent
            for l in (m[1], m[5]):
                if l is None:
                    continue
                for p in l:
                    r = rev(p)
                    if r is not None and r not in setrevs:
                        # XXX should check < min(setrevs) or tiprevs
                        affected.add(r)

        if affected:
            repo.ui.log('evoext-cache', 'obshashcache reset - '
                        'new markers affect cached ranges\n')
            # XXX the current reset is too strong we could just drop the affected range
            con = self._con
            if con is not None:
                con.execute(_reset)
            # rewarm key revisions
            #
            # (The current invalidation is too wide, but rewarming every single
            # revision is quite costly)
            newrevs = []
            stop = self._cachekey[0] # tiprev
            for h in repo.filtered('immutable').changelog.headrevs():
                if h <= stop:
                    newrevs.append(h)
            newrevs.extend(revs)
            revs = newrevs

        # warm the cache for the new revs
        for r in revs:
            _obshashrange(repo, (r, 0))

        del self._updating

    @property
    def _fullcachekey(self):
        return (self._schemaversion, ) + self._cachekey

    def load(self, repo):
        if self._con is None:
            self._cachekey = self.emptykey
            self._ondiskcachekey = self.emptykey
        assert self._cachekey is not None

    def _db(self):
        try:
            util.makedirs(self._vfs.dirname(self._path))
        except OSError:
            return None
        con = sqlite3.connect(self._path)
        con.text_factory = str
        return con

    @util.propertycache
    def _con(self):
        if not self._valid:
            return None
        repo = self._repo()
        if repo is None:
            return None
        con = self._db()
        if con is None:
            return None
        cur = con.execute(_queryexist)
        if cur.fetchone() is None:
            self._valid = False
            return None
        meta = con.execute(_querymeta).fetchone()
        if meta is None or meta[0] != self._schemaversion:
            self._valid = False
            return None
        self._cachekey = self._ondiskcachekey = meta[1:]
        return con

    def save(self, repo):
        if self._cachekey is None:
            return
        if self._cachekey == self._ondiskcachekey and not self._new:
            return
        repo = repo.unfiltered()
        try:
            with repo.lock():
                self._save(repo)
        except error.LockError:
            # Exceptionnally we are noisy about it since performance impact
            # is large We should address that before using this more
            # widely.
            msg = _('obshashrange cache: skipping save unable to lock repo\n')
            repo.ui.warn(msg)

    def _save(self, repo):
        if self._con is None:
            util.unlinkpath(self._path, ignoremissing=True)
            if '_con' in vars(self):
                del self._con

            con = self._db()
            if con is None:
                repo.ui.log('evoext-cache', 'unable to write obshashrange cache'
                            ' - cannot create database')
                return
            with con:
                for req in _sqliteschema:
                    con.execute(req)

                con.execute(_newmeta, self._fullcachekey)
        else:
            con = self._con
            if self._ondiskcachekey is not None:
                meta = con.execute(_querymeta).fetchone()
                if meta[1:] != self._ondiskcachekey:
                    # drifting is currently an issue because this means another
                    # process might have already added the cache line we are about
                    # to add. This will confuse sqlite
                    msg = _('obshashrange cache: skipping write, '
                            'database drifted under my feet\n')
                    data = (meta[2], meta[1], self._ondiskcachekey[0], self._ondiskcachekey[1])
                    repo.ui.warn(msg)
                    return
        data = ((rangeid[0], rangeid[1], self.get(rangeid)) for rangeid in self._new)
        con.executemany(_updateobshash, data)
        cachekey = self._fullcachekey
        con.execute(_clearmeta) # remove the older entry
        con.execute(_newmeta, cachekey)
        con.commit()
        self._new.clear()
        self._ondiskcachekey = self._cachekey
        self._valid = True

@eh.wrapfunction(obsolete.obsstore, '_addmarkers')
def _addmarkers(orig, obsstore, *args, **kwargs):
    obsstore.rangeobshashcache.clear()
    return orig(obsstore, *args, **kwargs)

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
    obsstore.rangeobshashcache = _obshashcache(repo.unfiltered())
    return obsstore

@eh.reposetup
def setupcache(ui, repo):

    class obshashrepo(repo.__class__):
        @localrepo.unfilteredmethod
        def destroyed(self):
            if 'obsstore' in vars(self):
                self.obsstore.rangeobshashcache.clear()
            super(obshashrepo, self).destroyed()

        def transaction(self, *args, **kwargs):
            tr = super(obshashrepo, self).transaction(*args, **kwargs)
            reporef = weakref.ref(self)

            def _warmcache(tr):
                repo = reporef()
                if repo is None:
                    return
                hasobshashrange = _useobshashrange(repo)
                hascachewarm = repo.ui.configbool('experimental',
                                                  'obshashrange.warm-cache',
                                                  True)
                if not (hasobshashrange and hascachewarm):
                    return
                repo = repo.unfiltered()
                # As pointed in 'obscache.update', we could have the changelog
                # and the obsstore in charge of updating the cache when new
                # items goes it. The tranaction logic would then only be
                # involved for the 'pending' and final writing on disk.
                self.obsstore.rangeobshashcache.update(repo)
                self.obsstore.rangeobshashcache.save(repo)

            tr.addpostclose('warmcache-20-obscacherange', _warmcache)
            return tr

    repo.__class__ = obshashrepo

### wire protocol commands

def _obshashrange_v0(repo, ranges):
    """return a list of hash from a list of range

    The range have the id encoded as a node

    return 'wdirid' for unknown range"""
    nm = repo.changelog.nodemap
    ranges = [(nm.get(n), idx) for n, idx in ranges]
    if ranges:
        maxrev = max(r for r, i in ranges)
        if maxrev is not None:
            repo.stablerange.warmup(repo, upto=maxrev)
    result = []
    repo.obsstore.rangeobshashcache.update(repo)
    for r in ranges:
        if r[0] is None:
            result.append(node.wdirid)
        else:
            result.append(_obshashrange(repo, r))
    repo.obsstore.rangeobshashcache.save(repo)
    return result

@eh.addattr(localrepo.localpeer, 'evoext_obshashrange_v0')
def local_obshashrange_v0(peer, ranges):
    return _obshashrange_v0(peer._repo, ranges)


_indexformat = '>I'
_indexsize = _calcsize(_indexformat)
def _encrange(node_rangeid):
    """encode a (node) range"""
    headnode, index = node_rangeid
    return headnode + _pack(_indexformat, index)

def _decrange(data):
    """encode a (node) range"""
    assert _indexsize < len(data), len(data)
    headnode = data[:-_indexsize]
    index = _unpack(_indexformat, data[-_indexsize:])[0]
    return (headnode, index)

@eh.addattr(wireproto.wirepeer, 'evoext_obshashrange_v0')
def peer_obshashrange_v0(self, ranges):
    binranges = [_encrange(r) for r in ranges]
    encranges = wireproto.encodelist(binranges)
    d = self._call("evoext_obshashrange_v0", ranges=encranges)
    try:
        return wireproto.decodelist(d)
    except ValueError:
        self._abort(error.ResponseError(_("unexpected response:"), d))

def srv_obshashrange_v0(repo, proto, ranges):
    ranges = wireproto.decodelist(ranges)
    ranges = [_decrange(r) for r in ranges]
    hashes = _obshashrange_v0(repo, ranges)
    return wireproto.encodelist(hashes)

def _useobshashrange(repo):
    base = repo.ui.configbool('experimental', 'obshashrange', False)
    if base:
        maxrevs = repo.ui.configint('experimental', 'obshashrange.max-revs', None)
        if maxrevs is not None and maxrevs < len(repo.unfiltered()):
            base = False
    return base

def _canobshashrange(local, remote):
    return (_useobshashrange(local)
            and remote.capable('_evoext_obshashrange_v0'))

def _obshashrange_capabilities(orig, repo, proto):
    """wrapper to advertise new capability"""
    caps = orig(repo, proto)
    enabled = _useobshashrange(repo)
    if obsolete.isenabled(repo, obsolete.exchangeopt) and enabled:
        caps = caps.split()
        caps.append('_evoext_obshashrange_v0')
        caps.sort()
        caps = ' '.join(caps)
    return caps

@eh.extsetup
def obshashrange_extsetup(ui):
    hgweb_mod.perms['evoext_obshashrange_v0'] = 'pull'

    wireproto.commands['evoext_obshashrange_v0'] = (srv_obshashrange_v0, 'ranges')
    ###
    extensions.wrapfunction(wireproto, 'capabilities', _obshashrange_capabilities)
    # wrap command content
    oldcap, args = wireproto.commands['capabilities']

    def newcap(repo, proto):
        return _obshashrange_capabilities(oldcap, repo, proto)
    wireproto.commands['capabilities'] = (newcap, args)

#############################
### Tree Hash computation ###
#############################

# Dash computed from a given changesets using all markers relevant to it and
# the obshash of its parents.  This is similar to what happend for changeset
# node where the parent is used in the computation

def _canobshashtree(repo, remote):
    return remote.capable('_evoext_obshash_0')

@eh.command(
    'debugobsrelsethashtree',
    [('', 'v0', None, 'hash on marker format "0"'),
     ('', 'v1', None, 'hash on marker format "1" (default)')], _(''))
def debugobsrelsethashtree(ui, repo, v0=False, v1=False):
    """display Obsolete markers, Relevant Set, Hash Tree
    changeset-node obsrelsethashtree-node

    It computed form the "orsht" of its parent and markers
    relevant to the changeset itself."""
    if v0 and v1:
        raise error.Abort('cannot only specify one format')
    elif v0:
        treefunc = _obsrelsethashtreefm0
    else:
        treefunc = _obsrelsethashtreefm1

    for chg, obs in treefunc(repo):
        ui.status('%s %s\n' % (node.hex(chg), node.hex(obs)))

def _obsrelsethashtreefm0(repo):
    return _obsrelsethashtree(repo, obsolete._fm0encodeonemarker)

def _obsrelsethashtreefm1(repo):
    return _obsrelsethashtree(repo, obsolete._fm1encodeonemarker)

def _obsrelsethashtree(repo, encodeonemarker):
    cache = []
    unfi = repo.unfiltered()
    markercache = {}
    repo.ui.progress(_("preparing locally"), 0, total=len(unfi))
    for i in unfi:
        ctx = unfi[i]
        entry = 0
        sha = hashlib.sha1()
        # add data from p1
        for p in ctx.parents():
            p = p.rev()
            if p < 0:
                p = node.nullid
            else:
                p = cache[p][1]
            if p != node.nullid:
                entry += 1
                sha.update(p)
        tmarkers = repo.obsstore.relevantmarkers([ctx.node()])
        if tmarkers:
            bmarkers = []
            for m in tmarkers:
                if m not in markercache:
                    markercache[m] = encodeonemarker(m)
                bmarkers.append(markercache[m])
            bmarkers.sort()
            for m in bmarkers:
                entry += 1
                sha.update(m)
        if entry:
            cache.append((ctx.node(), sha.digest()))
        else:
            cache.append((ctx.node(), node.nullid))
        repo.ui.progress(_("preparing locally"), i, total=len(unfi))
    repo.ui.progress(_("preparing locally"), None)
    return cache

def _obshash(repo, nodes, version=0):
    if version == 0:
        hashs = _obsrelsethashtreefm0(repo)
    elif version == 1:
        hashs = _obsrelsethashtreefm1(repo)
    else:
        assert False
    nm = repo.changelog.nodemap
    revs = [nm.get(n) for n in nodes]
    return [r is None and node.nullid or hashs[r][1] for r in revs]

@eh.addattr(localrepo.localpeer, 'evoext_obshash')
def local_obshash(peer, nodes):
    return _obshash(peer._repo, nodes)

@eh.addattr(localrepo.localpeer, 'evoext_obshash1')
def local_obshash1(peer, nodes):
    return _obshash(peer._repo, nodes, version=1)

@eh.addattr(wireproto.wirepeer, 'evoext_obshash')
def peer_obshash(self, nodes):
    d = self._call("evoext_obshash", nodes=wireproto.encodelist(nodes))
    try:
        return wireproto.decodelist(d)
    except ValueError:
        self._abort(error.ResponseError(_("unexpected response:"), d))

@eh.addattr(wireproto.wirepeer, 'evoext_obshash1')
def peer_obshash1(self, nodes):
    d = self._call("evoext_obshash1", nodes=wireproto.encodelist(nodes))
    try:
        return wireproto.decodelist(d)
    except ValueError:
        self._abort(error.ResponseError(_("unexpected response:"), d))

def srv_obshash(repo, proto, nodes):
    return wireproto.encodelist(_obshash(repo, wireproto.decodelist(nodes)))

def srv_obshash1(repo, proto, nodes):
    return wireproto.encodelist(_obshash(repo, wireproto.decodelist(nodes),
                                version=1))

def _obshash_capabilities(orig, repo, proto):
    """wrapper to advertise new capability"""
    caps = orig(repo, proto)
    if obsolete.isenabled(repo, obsolete.exchangeopt):
        caps = caps.split()
        caps.append('_evoext_obshash_0')
        caps.append('_evoext_obshash_1')
        caps.sort()
        caps = ' '.join(caps)
    return caps

@eh.extsetup
def obshash_extsetup(ui):
    hgweb_mod.perms['evoext_obshash'] = 'pull'
    hgweb_mod.perms['evoext_obshash1'] = 'pull'

    wireproto.commands['evoext_obshash'] = (srv_obshash, 'nodes')
    wireproto.commands['evoext_obshash1'] = (srv_obshash1, 'nodes')
    extensions.wrapfunction(wireproto, 'capabilities', _obshash_capabilities)
    # wrap command content
    oldcap, args = wireproto.commands['capabilities']

    def newcap(repo, proto):
        return _obshash_capabilities(oldcap, repo, proto)
    wireproto.commands['capabilities'] = (newcap, args)

##########################################
###  trigger discovery during exchange ###
##########################################

def _dopushmarkers(pushop):
    return (# we have any markers to push
            pushop.repo.obsstore
            # exchange of obsmarkers is enabled locally
            and obsolete.isenabled(pushop.repo, obsolete.exchangeopt)
            # remote server accept markers
            and 'obsolete' in pushop.remote.listkeys('namespaces'))

def _pushobshashrange(pushop, commonrevs):
    repo = pushop.repo.unfiltered()
    remote = pushop.remote
    missing = findmissingrange(pushop.ui, repo, remote, commonrevs)
    missing += pushop.outgoing.missing
    return missing

def _pushobshashtree(pushop, commonrevs):
    repo = pushop.repo.unfiltered()
    remote = pushop.remote
    node = repo.changelog.node
    common = findcommonobsmarkers(pushop.ui, repo, remote, commonrevs)
    revs = list(repo.revs('only(%ln, %ln)', pushop.futureheads, common))
    return [node(r) for r in revs]

# available discovery method, first valid is used
# tuple (canuse, perform discovery))
obsdiscoveries = [
    (_canobshashrange, _pushobshashrange),
    (_canobshashtree, _pushobshashtree),
]

obsdiscovery_skip_message = """\
(skipping discovery of obsolescence markers, will exchange everything)
(controled by 'experimental.evolution.obsdiscovery' configuration)
"""

def usediscovery(repo):
    return repo.ui.configbool('experimental', 'evolution.obsdiscovery', True)

@eh.wrapfunction(exchange, '_pushdiscoveryobsmarkers')
def _pushdiscoveryobsmarkers(orig, pushop):
    if _dopushmarkers(pushop):
        repo = pushop.repo
        remote = pushop.remote
        obsexcmsg(repo.ui, "computing relevant nodes\n")
        revs = list(repo.revs('::%ln', pushop.futureheads))
        unfi = repo.unfiltered()

        if not usediscovery(repo):
            # discovery disabled by user
            repo.ui.status(obsdiscovery_skip_message)
            return orig(pushop)

        # look for an obs-discovery protocol we can use
        discovery = None
        for candidate in obsdiscoveries:
            if candidate[0](repo, remote):
                discovery = candidate[1]
                break

        if discovery is None:
            # no discovery available, rely on core to push all relevants
            # obs markers.
            return orig(pushop)

        obsexcmsg(repo.ui, "looking for common markers in %i nodes\n"
                           % len(revs))
        commonrevs = list(unfi.revs('::%ln', pushop.outgoing.commonheads))
        # find the nodes where the relevant obsmarkers mismatches
        nodes = discovery(pushop, commonrevs)

        if nodes:
            obsexcmsg(repo.ui, "computing markers relevant to %i nodes\n"
                               % len(nodes))
            pushop.outobsmarkers = repo.obsstore.relevantmarkers(nodes)
        else:
            obsexcmsg(repo.ui, "markers already in sync\n")
            pushop.outobsmarkers = []

@eh.extsetup
def _installobsmarkersdiscovery(ui):
    olddisco = exchange.pushdiscoverymapping['obsmarker']

    def newdisco(pushop):
        _pushdiscoveryobsmarkers(olddisco, pushop)
    exchange.pushdiscoverymapping['obsmarker'] = newdisco

def buildpullobsmarkersboundaries(pullop, bundle2=True):
    """small function returning the argument for pull markers call
    may to contains 'heads' and 'common'. skip the key for None.

    It is a separed function to play around with strategy for that."""
    repo = pullop.repo
    remote = pullop.remote
    unfi = repo.unfiltered()
    revs = unfi.revs('::(%ln - null)', pullop.common)
    boundaries = {'heads': pullop.pulledsubset}
    if not revs: # nothing common
        boundaries['common'] = [node.nullid]
        return boundaries

    if not usediscovery(repo):
        # discovery disabled by users.
        repo.ui.status(obsdiscovery_skip_message)
        boundaries['common'] = [node.nullid]
        return boundaries

    if bundle2 and _canobshashrange(repo, remote):
        obsexcmsg(repo.ui, "looking for common markers in %i nodes\n"
                  % len(revs))
        boundaries['missing'] = findmissingrange(repo.ui, repo, pullop.remote,
                                                 revs)
    elif remote.capable('_evoext_obshash_0'):
        obsexcmsg(repo.ui, "looking for common markers in %i nodes\n"
                           % len(revs))
        boundaries['common'] = findcommonobsmarkers(repo.ui, repo, remote, revs)
    else:
        boundaries['common'] = [node.nullid]
    return boundaries
