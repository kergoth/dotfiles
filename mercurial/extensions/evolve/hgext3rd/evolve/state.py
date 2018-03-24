# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

"""
This file contains class to wrap the state for commands and other
related logic.

All the data related to the command state is stored as dictionary in the object.
The class has methods using which the data can be stored to disk in a file under
.hg/ directory.

We store the data on disk in cbor, for which we use cbor library to serialize
and deserialize data.
"""

from __future__ import absolute_import

import errno
import struct

from .thirdparty import cbor

from mercurial import (
    error,
    util,
)

from mercurial.i18n import _

class cmdstate():
    """a wrapper class to store the state of commands like `evolve`, `grab`

    All the data for the state is stored in the form of key-value pairs in a
    dictionary.

    The class object can write all the data to a file in .hg/ directory and also
    can populate the object data reading that file
    """

    def __init__(self, repo, path='evolvestate', opts={}):
        self._repo = repo
        self.path = path
        self.opts = opts

    def __nonzero__(self):
        return self.exists()

    def __getitem__(self, key):
        return self.opts[key]

    def __setitem__(self, key, value):
        updates = {key: value}
        self.opts.update(updates)

    def load(self):
        """load the existing evolvestate file into the class object"""
        op = self._read()
        if isinstance(op, dict):
            self.opts.update(op)
        elif self.path == 'evolvestate':
            # it is the old evolvestate file
            oldop = _oldevolvestateread(self._repo)
            self.opts.update(oldop)

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

def _oldevolvestateread(repo):
    """function to read the old evolvestate file

    This exists for BC reasons."""
    try:
        f = repo.vfs('evolvestate')
    except IOError as err:
        if err.errno != errno.ENOENT:
            raise
    try:
        versionblob = f.read(4)
        if len(versionblob) < 4:
            repo.ui.debug('ignoring corrupted evolvestate (file contains %i bits)'
                          % len(versionblob))
            return None
        version = struct._unpack('>I', versionblob)[0]
        if version != 0:
            msg = _('unknown evolvestate version %i') % version
            raise error.Abort(msg, hint=_('upgrade your evolve'))
        records = []
        data = f.read()
        off = 0
        end = len(data)
        while off < end:
            rtype = data[off]
            off += 1
            length = struct._unpack('>I', data[off:(off + 4)])[0]
            off += 4
            record = data[off:(off + length)]
            off += length
            if rtype == 't':
                rtype, record = record[0], record[1:]
            records.append((rtype, record))
        state = {}
        for rtype, rdata in records:
            if rtype == 'C':
                state['current'] = rdata
            elif rtype.lower():
                repo.ui.debug('ignore evolve state record type %s' % rtype)
            else:
                raise error.Abort(_('unknown evolvestate field type %r')
                                  % rtype, hint=_('upgrade your evolve'))
        return state
    finally:
        f.close()
