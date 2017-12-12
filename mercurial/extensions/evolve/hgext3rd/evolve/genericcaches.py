# cache.py - utilities for caching
#
# Copyright 2017 Octobus SAS <contact@octobus.net>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
from __future__ import absolute_import

import abc
import struct
import time
import os

from mercurial import (
    node,
    pycompat,
    util,
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

class incrementalcachebase(object):
    """base class for incremental cache from append only source

    There are multiple append only data source we might want to cache
    computation from. One of the common pattern is to track the state of the
    file and update the cache with the extra data (eg: branchmap-cache tracking
    changelog). This pattern also needs to detect when a the source is striped

    The overall pattern is similar whatever the actual source is. This class
    introduces the basic patterns.
    """

    __metaclass__ = abc.ABCMeta

    # default key used for an empty cache
    emptykey = ()

    _cachekeyspec = '' # used for serialization
    _cachename = None # used for debug message

    @abc.abstractmethod
    def __init__(self):
        super(incrementalcachebase, self).__init__()
        self._cachekey = None

    @util.propertycache
    def _cachekeystruct(self):
        # dynamic property to help subclass to change it
        return struct.Struct('>' + self._cachekeyspec)

    @util.propertycache
    def _cachekeysize(self):
        # dynamic property to help subclass to change it
        return self._cachekeystruct.size

    @abc.abstractmethod
    def _updatefrom(self, repo, data):
        """override this method to update you date from incrementally read data.

        Content of <data> will depends of the sources.
        """
        raise NotImplementedError

    @abc.abstractmethod
    def clear(self, reset=False):
        """invalidate the cache content

        if 'reset' is passed, we detected a strip and the cache will have to be
        recomputed.

        Subclasses MUST overide this method to actually affect the cache data.
        """
        if reset:
            self._cachekey = self.emptykey if reset else None
        else:
            self._cachekey = None

    @abc.abstractmethod
    def load(self, repo):
        """Load data from disk

        Subclasses MUST restore the "cachekey" attribute while doing so.
        """
        raise NotImplementedError

    @abc.abstractmethod
    def _fetchupdatedata(self, repo):
        """Check the source for possible changes and return necessary data

        The return is a tree elements tuple: reset, data, cachekey

        * reset: `True` when a strip is detected and cache need to be reset
        * data: new data to take in account, actual type depends of the source
        * cachekey: the cache key covering <data> and precious covered data
        """
        raise NotImplementedError

    @abc.abstractmethod
    def _updatesummary(self, data):
        """return a small string to be included in debug output"""
        raise NotImplementedError

    # Useful "public" function (no need to override them)

    def update(self, repo):
        """update the cache with new repository data

        The update will be incremental when possible"""
        repo = repo.unfiltered()

        # If we do not have any data, try loading from disk
        if self._cachekey is None:
            self.load(repo)

        reset, data, newkey = self._fetchupdatedata(repo)
        if newkey == self._cachekey:
            return
        if reset or self._cachekey is None:
            repo.ui.log('cache', 'strip detected, %s cache reset\n'
                        % self._cachename)
            self.clear(reset=True)

        starttime = timer()
        self._updatefrom(repo, data)
        duration = timer() - starttime
        summary = self._updatesummary(data)
        repo.ui.log('cache', 'updated %s in %.4f seconds (%s)\n',
                    self._cachename, duration, summary)

        self._cachekey = newkey

    def _serializecachekey(self):
        """provide a bytes version of the cachekey"""
        return self._cachekeystruct.pack(*self._cachekey)

    def _deserializecachekey(self, data):
        """read the cachekey from bytes"""
        return self._cachekeystruct.unpack(data)

class changelogsourcebase(incrementalcachebase):
    """an abstract class for cache sourcing data from the changelog

    For this purpose it use a cache key covering changelog content.
    The cache key parts are: (tiprev, tipnode)
    """

    __metaclass__ = abc.ABCMeta

    # default key used for an empty cache
    emptykey = (0, node.nullid)
    _cachekeyspec = 'i20s'
    _cachename = None # used for debug message

    # Useful "public" function (no need to override them)

    def _fetchchangelogdata(self, cachekey, cl):
        """use a cachekey to fetch incremental data

        Exists as its own method to help subclass to reuse it."""
        tiprev = len(cl) - 1
        tipnode = cl.node(tiprev)
        newkey = (tiprev, tipnode)
        tiprev = len(cl) - 1
        if newkey == cachekey:
            return False, [], newkey
        keyrev, keynode = cachekey
        if tiprev < keyrev or cl.node(keyrev) != keynode:
            revs = ()
            if len(cl):
                revs = list(cl.revs(stop=tiprev))
            return True, revs, newkey
        else:
            return False, list(cl.revs(start=keyrev + 1, stop=tiprev)), newkey

    def _fetchupdatedata(self, repo):
        return self._fetchchangelogdata(self._cachekey, repo.changelog)

    def _updatesummary(self, data):
        return '%ir' % len(data)
