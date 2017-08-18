====================================
Testing head checking code: Case B-6
====================================

Mercurial checks for the introduction of new heads on push. Evolution comes
into play to detect if existing branches on the server are being replaced by
some of the new one we push.

This case is part of a series of tests checking this behavior.

Category B: simple case involving pruned changesets
TestCase 6: single changesets, pruned then superseeded (on a new changeset)

.. old-state:
..
.. * 1 changeset branch
..
.. new-state:
..
.. * old branch is rewritten onto another one,
.. * the new version is then pruned.
..
.. expected-result:
..
.. * push allowed
..
.. graph-summary:
..
..   A ø⇠⊗ A'
..     | |
..     | ◔ B
..     |/
..     ●

  $ . $TESTDIR/testlib/push-checkheads-util.sh

Test setup
----------

  $ mkdir B6
  $ cd B6
  $ setuprepos
  creating basic server and client repo
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd client
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit B0
  created new head
  $ mkcommit A1
  $ hg up 'desc(B0)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg debugobsolete `getid "desc(A0)"` `getid "desc(A1)"`
  obsoleted 1 changesets
  $ hg debugobsolete --record-parents `getid "desc(A1)"`
  obsoleted 1 changesets
  $ hg log -G --hidden
  x  ba93660aff8d (draft): A1
  |
  @  74ff5441d343 (draft): B0
  |
  | x  8aaa48160adc (draft): A0
  |/
  o  1e4be0697311 (public): root
  

Actual testing
--------------

  $ hg push
  pushing to $TESTTMP/B6/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers
  obsoleted 1 changesets

  $ cd ../..
