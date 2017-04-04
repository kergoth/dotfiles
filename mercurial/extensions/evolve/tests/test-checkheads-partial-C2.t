====================================
Testing head checking code: Case C-2
====================================

Mercurial checks for the introduction of multiple heads on push. Evolution
comes into play to detect if existing heads on the server are being replaced by
some of the new heads we push.

This test file is part of a series of tests checking this behavior.

Category C: checking case were the branch is only partially obsoleted.
TestCase 2: 2 changeset branch, only the base is rewritten

.. old-state:
..
.. * 2 changeset branch
..
.. new-state:
..
.. * 1 new changesets branches superceeding only the base of the old one
.. * The old branch is still alive (base is obsolete, head is alive)
..
.. expected-result:
..
.. * push denied
..
.. graph-summary:
..
..   B ○
..     |
..   A ø⇠◔ A'
..     |/
..     ○

  $ . $TESTDIR/testlib/checkheads-util.sh

Test setup
----------

  $ setuprepos
  creating basic server and client repo
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd server
  $ mkcommit B0
  $ cd ../client
  $ hg pull
  pulling from $TESTTMP/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  (run 'hg update' to get a working copy)
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit A1
  created new head
  $ hg debugobsolete `getid "desc(A0)" ` `getid "desc(A1)"`
  $ hg log -G --hidden
  @  f6082bc4ffef (draft): A1
  |
  | o  d73caddc5533 (draft): B0
  | |
  | x  8aaa48160adc (draft): A0
  |/
  o  1e4be0697311 (public): root
  


Actual testing
--------------

  $ hg push --rev 'desc(A1)'
  pushing to $TESTTMP/server
  searching for changes
  abort: push creates new remote head f6082bc4ffef!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
