Overview
========

The shelve extension provides the shelve command to let you choose which parts
of the changes in a working directory you'd like to set aside temporarily, at
the granularity of patch hunks. You can later restore the shelved patch hunks
using the unshelve command.

The shelve extension has been adapted from Mercurial's record extension.

See ``hg shelve --help`` for the complete list of commands.

For more information please visit the `hgshelve website`_.

.. _hgshelve website: http://mercurial.selenic.com/wiki/ThirdPartyShelveExtension

Starting from version 2.8, Mercurial includes its own shelve extension,
which operates differently (more like Git's stash command) and supports
conflict resolution during unshelving. Consider using that.


Developer Info
==============

Like Mercurial, hgshelve comes with regression test suite to verify its core
functionality as changes are being made. To run this test suite, you need
the Mercurial source package::

    $ cd your-hgshelve-repo
    $ /path/to/hg-repo/tests/run-tests.py
