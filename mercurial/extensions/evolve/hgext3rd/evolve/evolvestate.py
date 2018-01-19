# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

"""
This file contains class to wrap the state for hg evolve command and other
related logic.

All the data related to the command state is stored as dictionary in the object.
The class has methods using which the data can be stored to disk in
.hg/evolvestate file.

We store the data on disk in cbor, for which we use cbor library to serialize
and deserialize data.
"""

from __future__ import absolute_import

from .thirdparty import cbor

from mercurial import (
    util,
)

class evolvestate():
    """a wrapper class to store the state of `hg evolve` command

    All the data for the state is stored in the form of key-value pairs in a
    dictionary.

    The class object can write all the data to .hg/evolvestate file and also can
    populate the object data reading that file
    """

    def __init__(self, repo, path='evolvestate', opts={}):
        self._repo = repo
        self.path = path
        self.opts = opts

    def __nonzero__(self):
        return self.exists()

    def __getitem__(self, key):
        return self.opts[key]

    def load(self):
        """load the existing evolvestate file into the class object"""
        op = self._read()
        self.opts.update(op)

    def addopts(self, opts):
        """add more key-value pairs to the data stored by the object"""
        self.opts.update(opts)

    def save(self):
        """write all the evolvestate data stored in .hg/evolvestate file

        we use third-party library cbor to serialize data to write in the file.
        """
        with self._repo.vfs(self.path, 'wb', atomictemp=True) as fp:
            cbor.dump(self.opts, fp)

    def _read(self):
        """reads the evolvestate file and returns a dictionary which contain
        data in the same format as it was before storing"""
        with self._repo.vfs(self.path, 'rb') as fp:
            return cbor.load(fp)

    def delete(self):
        """drop the evolvestate file if exists"""
        util.unlinkpath(self._repo.vfs.join(self.path), ignoremissing=True)

    def exists(self):
        """check whether the evolvestate file exists or not"""
        return self._repo.vfs.exists(self.path)
