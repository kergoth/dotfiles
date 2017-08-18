============================================
Testing obsolescence markers push: Cases D.2
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category D: Partial Information Case
TestCase 2: missing prune target (prune in "pushed set")

D.2 missing prune target (prune in "pushed set")
================================================

.. {{{
..   A ø⇠✕ A'
..     |/
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * A' succeed to A
..  * A' (prune)
..
.. Command runs:
..
..  * hg push
..
.. Expected exchange:
..
..  * `A ø⇠o A'`
..  * A' (prune)

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

Initial

  $ setuprepos D.2
  creating test repo for test case D.2
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ hg up -q 0
  $ mkcommit A1
  created new head
  $ hg debugobsolete `getid 'desc(A0)'` `getid 'desc(A1)'`
  obsoleted 1 changesets
  $ hg prune --date '0 0' .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at a9bdc8b26820
  1 changesets pruned
  $ hg strip --hidden -q 'desc(A1)' --config devel.strip-obsmarkers=no
  $ hg log -G --hidden
  x  28b51eb45704 (draft): A0
  |
  @  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 c14d90ad60c950e75009151899c742ce8cc9b2e6
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e08003a7b0ea2ec7ec7e07708d34cf3819aa8009
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             0 a9bdc8b26820            0            1            1 c14d90ad60c9
  $ cd ..
  $ cd ..

Actual Test
-----------

  $ dotest D.2
  ## Running testcase D.2
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  2 new obsolescence markers
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)

