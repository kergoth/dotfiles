====================================
Testing head checking code: Case B-3
====================================

Mercurial checks for the introduction of multiple heads on push. Evolution
comes into play to detect if existing heads on the server are being replaced by
some of the new heads we push.

This test file is part of a series of tests checking this behavior.

Category B: checking simple case involving pruned changesets
TestCase 3: multi-changeset branch, other is pruned, rest is superceeded

.. old-state:
..
.. * 2 changeset branch
..
.. new-state:
..
.. * old head is superceeded
.. * old other is pruned
..
.. expected-result:
..
.. * push allowed
..
.. graph-summary:
..
..   B ø⇠◔ B'
..     | |
..   A ⊗ |
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
  $ mkcommit B1
  created new head
  $ hg debugobsolete --record-parents `getid "desc(A0)"`
  $ hg debugobsolete `getid "desc(B0)" ` `getid "desc(B1)"`
  $ hg log -G --hidden
  @  25c56d33e4c4 (draft): B1
  |
  | x  d73caddc5533 (draft): B0
  | |
  | x  8aaa48160adc (draft): A0
  |/
  o  1e4be0697311 (public): root
  

Actual testing
--------------

  $ hg push
  pushing to $TESTTMP/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers

