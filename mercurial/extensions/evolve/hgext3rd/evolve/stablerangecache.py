# Code dedicated to the caching of "stable ranges"
#
# These stable ranges are use for obsolescence markers discovery
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import abc
import heapq
import sqlite3
import time
import weakref

from mercurial import (
    error,
    localrepo,
    util,
)

from . import (
    exthelper,
    genericcaches,
    stablerange,
    utility,
)

from mercurial.i18n import _

eh = exthelper.exthelper()
eh.merge(stablerange.eh)

class stablerangeondiskbase(stablerange.stablerangecached,
                            genericcaches.changelogsourcebase):
    """combine the generic stablerange cache usage with generic changelog one
    """

    def _updatefrom(self, repo, data):
        """compute the rev of one revision, assert previous revision has an hot cache
        """
        repo = repo.unfiltered()
        ui = repo.ui

        rangeheap = []
        for r in data:
            rangeheap.append((r, 0))
        total = len(data)

        heappop = heapq.heappop
        heappush = heapq.heappush
        heapify = heapq.heapify

        original = set(rangeheap)
        seen = 0
        # progress report is showing up in the profile for small and fast
        # repository so we only update it every so often
        progress_each = 100
        progress_last = time.time()
        heapify(rangeheap)
        while rangeheap:
            rangeid = heappop(rangeheap)
            if rangeid in original:
                if not seen % progress_each:
                    # if a lot of time passed, report more often
                    progress_new = time.time()
                    if (1 < progress_each) and (0.1 < progress_new - progress_last):
                        progress_each /= 10
                    ui.progress(_("filling stablerange cache"), seen, total=total)
                    progress_last = progress_new
                seen += 1
                original.remove(rangeid) # might have been added from other source
            rangeid = rangeid
            if self._getsub(rangeid) is None:
                for sub in self.subranges(repo, rangeid):
                    if self._getsub(sub) is None:
                        heappush(rangeheap, sub)
        ui.progress(_("filling stablerange cache"), None, total=total)

    def clear(self, reset=False):
        super(stablerangeondiskbase, self).clear()
        self._subrangescache.clear()

#############################
### simple sqlite caching ###
#############################

_sqliteschema = [
    """CREATE TABLE meta(schemaversion INTEGER NOT NULL,
                         tiprev        INTEGER NOT NULL,
                         tipnode       BLOB    NOT NULL
                        );""",
    """CREATE TABLE range(rev INTEGER  NOT NULL,
                          idx INTEGER NOT NULL,
                          PRIMARY KEY(rev, idx));""",
    """CREATE TABLE subranges(listidx INTEGER NOT NULL,
                              suprev  INTEGER NOT NULL,
                              supidx  INTEGER NOT NULL,
                              subrev  INTEGER NOT NULL,
                              subidx  INTEGER NOT NULL,
                              PRIMARY KEY(listidx, suprev, supidx),
                              FOREIGN KEY (suprev, supidx) REFERENCES range(rev, idx),
                              FOREIGN KEY (subrev, subidx) REFERENCES range(rev, idx)
    );""",
    "CREATE INDEX subranges_index ON subranges (suprev, supidx);",
    "CREATE INDEX superranges_index ON subranges (subrev, subidx);",
    "CREATE INDEX range_index ON range (rev, idx);",
]
_newmeta = "INSERT INTO meta (schemaversion, tiprev, tipnode) VALUES (?,?,?);"
_updatemeta = "UPDATE meta SET tiprev = ?, tipnode = ?;"
_updaterange = "INSERT INTO range(rev, idx) VALUES (?,?);"
_updatesubranges = """INSERT
                       INTO subranges(listidx, suprev, supidx, subrev, subidx)
                       VALUES (?,?,?,?,?);"""
_queryexist = "SELECT name FROM sqlite_master WHERE type='table' AND name='meta';"
_querymeta = "SELECT schemaversion, tiprev, tipnode FROM meta;"
_queryrange = "SELECT * FROM range WHERE (rev = ? AND idx = ?);"
_querysubranges = """SELECT subrev, subidx
                     FROM subranges
                     WHERE (suprev = ? AND supidx = ?)
                     ORDER BY listidx;"""
_querysuperranges = """SELECT suprev, supidx
                       FROM subranges
                       WHERE (subrev = ? AND subidx = ?)
                       ORDER BY listidx;"""

class stablerangesqlbase(stablerange.stablerangecached):
    """class that can handle all the bits needed to store range into sql
    """

    __metaclass__ = abc.ABCMeta

    _schemaversion = None
    _cachefile = None

    def __init__(self, repo, **kwargs):
        super(stablerangesqlbase, self).__init__(**kwargs)
        self._vfs = repo.vfs
        self._path = repo.vfs.join(self._cachefile)
        self._cl = repo.unfiltered().changelog # (okay to keep an old one)
        self._ondisktiprev = None
        self._ondisktipnode = None
        self._unsavedsubranges = {}

    def contains(self, repo, revs):
        new = set()
        known = set()
        depth = repo.depthcache.get
        for r in revs:
            new.add((r, depth(r) - 1))
            new.add((r, 0))
        con = self._con
        while new and con is not None:
            # many execute is not efficient
            next = new.pop()
            known.add(next)
            ranges = set(con.execute(_querysuperranges, next).fetchall())
            new.update(ranges)
            new -= known
        return sorted(known)

    def _getsub(self, rangeid):
        # 1) check the in memory cache
        # 2) check the sqlcaches (and warm in memory cache we want we find)
        cache = self._subrangescache
        if rangeid not in cache and rangeid[0] <= self._ondisktiprev and self._con is not None:
            value = None
            result = self._con.execute(_queryrange, rangeid).fetchone()
            if result is not None: # database know about this node (skip in the future?)
                value = self._con.execute(_querysubranges, rangeid).fetchall()
            # in memory caching of the value
            cache[rangeid] = value
        return cache.get(rangeid)

    def _setsub(self, rangeid, value):
        assert rangeid not in self._unsavedsubranges
        self._unsavedsubranges[rangeid] = value
        super(stablerangesqlbase, self)._setsub(rangeid, value)

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
        con = self._db()
        if con is None:
            return None
        cur = con.execute(_queryexist)
        if cur.fetchone() is None:
            return None
        meta = con.execute(_querymeta).fetchone()
        if meta is None:
            return None
        if meta[0] != self._schemaversion:
            return None
        if len(self._cl) <= meta[1]:
            return None
        if self._cl.node(meta[1]) != meta[2]:
            return None
        self._ondisktiprev = meta[1]
        self._ondisktipnode = meta[2]
        if self._tiprev < self._ondisktiprev:
            self._tiprev = self._ondisktiprev
            self._tipnode = self._ondisktipnode
        return con

    def _save(self, repo):
        repo = repo.unfiltered()
        repo.depthcache.save(repo)
        if not self._unsavedsubranges:
            return # no new data

        if self._con is None:
            util.unlinkpath(self._path, ignoremissing=True)
            if '_con' in vars(self):
                del self._con

            con = self._db()
            if con is None:
                return
            con.execute('BEGIN IMMEDIATE;')
            with con:
                for req in _sqliteschema:
                    con.execute(req)

                meta = [self._schemaversion,
                        self._tiprev,
                        self._tipnode,
                ]
                con.execute(_newmeta, meta)
        else:
            con = self._con
            con.execute('BEGIN IMMEDIATE;')
            meta = con.execute(_querymeta).fetchone()
            if meta[2] != self._ondisktipnode or meta[1] != self._ondisktiprev:
                # drifting is currently an issue because this means another
                # process might have already added the cache line we are about
                # to add. This will confuse sqlite
                msg = _('stable-range cache: skipping write, '
                        'database drifted under my feet\n')
                hint = _('(disk: %s-%s vs mem: %s%s)\n')
                data = (meta[2], meta[1], self._ondisktiprev, self._ondisktipnode)
                repo.ui.warn(msg)
                repo.ui.warn(hint % data)
                con.execute('ROLLBACK;')
                return
            meta = [self._tiprev,
                    self._tipnode,
            ]
            con.execute(_updatemeta, meta)

        self._saverange(con, repo)
        con.commit()
        self._ondisktiprev = self._tiprev
        self._ondisktipnode = self._tipnode
        self._unsavedsubranges.clear()

    def _saverange(self, con, repo):
        repo = repo.unfiltered()
        data = []
        allranges = set()
        for key, value in self._unsavedsubranges.items():
            allranges.add(key)
            for idx, sub in enumerate(value):
                data.append((idx, key[0], key[1], sub[0], sub[1]))

        con.executemany(_updaterange, allranges)
        con.executemany(_updatesubranges, data)

class stablerangesql(stablerangesqlbase, stablerangeondiskbase):
    """base clase able to preserve data to disk as sql"""

    __metaclass__ = abc.ABCMeta

    # self._cachekey = (tiprev, tipnode)

    @property
    def _tiprev(self):
        return self._cachekey[0]

    @_tiprev.setter
    def _tiprev(self, value):
        self._cachekey = (value, self._cachekey[1])

    @property
    def _tipnode(self):
        return self._cachekey[1]

    @_tipnode.setter
    def _tipnode(self, value):
        self._cachekey = (self._cachekey[0], value)

    def clear(self, reset=False):
        super(stablerangesql, self).clear(reset=reset)
        if '_con' in vars(self):
            del self._con
        self._subrangescache.clear()

    def load(self, repo):
        """load data from disk"""
        assert repo.filtername is None
        self._cachekey = self.emptykey

        if self._con is not None:
            self._cachekey = (self._ondisktiprev, self._ondisktipnode)
        self._ondiskkey = self._cachekey

    def save(self, repo):
        if self._cachekey is None or self._cachekey == self._ondiskkey:
            return
        self._save(repo)

class mergepointsql(stablerangesql, stablerange.stablerange_mergepoint):

    _schemaversion = 2
    _cachefile = 'cache/evoext_stablerange_v2.sqlite'
    _cachename = 'evo-ext-stablerange-mergepoint'

class sqlstablerange(stablerangesqlbase, stablerange.stablerange):

    _schemaversion = 1
    _cachefile = 'cache/evoext_stablerange_v1.sqlite'

    def warmup(self, repo, upto=None):
        self._con # make sure the data base is loaded
        try:
            # samelessly lock the repo to ensure nobody will update the repo
            # concurently. This should not be too much of an issue if we warm
            # at the end of the transaction.
            #
            # XXX However, we lock even if we are up to date so we should check
            # before locking
            with repo.lock():
                super(sqlstablerange, self).warmup(repo, upto)
                self._save(repo)
        except error.LockError:
            # Exceptionnally we are noisy about it since performance impact is
            # large We should address that before using this more widely.
            repo.ui.warn('stable-range cache: unable to lock repo while warming\n')
            repo.ui.warn('(cache will not be saved)\n')
            super(sqlstablerange, self).warmup(repo, upto)

@eh.reposetup
def setupcache(ui, repo):

    class stablerangerepo(repo.__class__):

        @localrepo.unfilteredpropertycache
        def stablerange(self):
            cache = mergepointsql(repo)
            cache.update(repo)
            return cache

        @localrepo.unfilteredmethod
        def destroyed(self):
            if 'stablerange' in vars(self):
                self.stablerange.clear()
                del self.stablerange
            super(stablerangerepo, self).destroyed()

        if util.safehasattr(repo, 'updatecaches'):
            @localrepo.unfilteredmethod
            def updatecaches(self, tr=None):
                if utility.shouldwarmcache(self, tr):
                    self.stablerange.update(self)
                    self.stablerange.save(self)
                super(stablerangerepo, self).updatecaches(tr)

        else:
            def transaction(self, *args, **kwargs):
                tr = super(stablerangerepo, self).transaction(*args, **kwargs)
                reporef = weakref.ref(self)

                def _warmcache(tr):
                    repo = reporef()
                    if repo is None:
                        return
                    repo = repo.unfiltered()
                    repo.stablerange.update(repo)
                    repo.stablerange.save(repo)

                if utility.shouldwarmcache(self, tr):
                    tr.addpostclose('warmcache-10stablerange', _warmcache)
                return tr

    repo.__class__ = stablerangerepo
