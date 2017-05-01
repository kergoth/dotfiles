====================================
Testing head checking code: Case A-8
====================================

Mercurial checks for the introduction of new heads on push. Evolution comes
into play to detect if existing branches on the server are being replaced by
some of the new one we push.

This case is part of a series of tests checking this behavior.

Category A: simple case involving a branch being superceeded by another.
TestCase 8: single-changeset branch indirect rewrite

.. old-state:
..
.. * 1-changeset branch
..
.. new-state:
..
.. * 1-changeset branch succeeding to A, through another unpushed changesets
..
.. expected-result:
..
.. * push allowed
..
.. graph-summary:
..
..       A'
..   A ø⇠ø⇠◔ A''
..     |/ /
..     | /
..     |/
..     ●

  $ . $TESTDIR/testlib/push-checkheads-util.sh

Test setup
----------

  $ mkdir A8
  $ cd A8
  $ setuprepos
  creating basic server and client repo
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd client
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit A1
  created new head
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit A2
  created new head
  $ hg debugobsolete `getid "desc(A0)" ` `getid "desc(A1)"`
  $ hg debugobsolete `getid "desc(A1)" ` `getid "desc(A2)"`
  $ hg log -G --hidden
  @  c1f8d089020f (draft): A2
  |
  | x  f6082bc4ffef (draft): A1
  |/
  | x  8aaa48160adc (draft): A0
  |/
  o  1e4be0697311 (public): root
  

Actual testing
--------------

  $ hg push
  pushing to $TESTTMP/A8/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers

  $ cd ../..
