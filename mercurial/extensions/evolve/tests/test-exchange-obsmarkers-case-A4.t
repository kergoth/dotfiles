============================================
Testing obsolescence markers push: Cases A.4
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. this does not tests "obsmarkers" discovery capabilities.

Category A: simple cases
Testcase 4: Push in the middle of the obsolescence chain

A.4 Push in the middle of the obsolescence chain
================================================

.. (Where we show that we should not push the marker without the successors)
..
.. {{{
..   B ◔
..     |
..   A⇠ø⇠○ A'
..     |/
..     ● O
.. }}}
..
.. Markers exist from:
..
..  * `A ø⇠○ A'`
..  * chain from A
..
.. Command runs:
..
..  * hg push -r B
..
.. Expected exchange:
..
..  * Chain from A
..
.. Expected Exclude:
..
..  * `Ai ø⇠○ A'`

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

initial

  $ setuprepos A.4
  creating test repo for test case A.4
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ mkcommit B
  $ hg update 0
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit A1
  created new head
  $ hg debugobsolete aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa `getid 'desc(A0)'`
  $ hg debugobsolete `getid 'desc(A0)'` `getid 'desc(A1)'`
  $ hg log -G --hidden
  @  e5ea8f9c7314 (draft): A1
  |
  | o  06055a7959d4 (draft): B
  | |
  | x  28b51eb45704 (draft): A0
  |/
  o  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 5d69322fad9eb1ba8f8f2c2312346ed347fdde76
  06055a7959d4128e6e3bccfd01482e83a2db8a3a fd3e5712c9c2d216547d7a1b87ac815ee1fb7542
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 cf518031fa753e9b049d727e6b0e19f645bab38f
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             2 06055a7959d4            0            3            3 000000000000
             1 28b51eb45704            0            2            2 5d69322fad9e
             3 e5ea8f9c7314            0            2            2 cf518031fa75
             2 06055a7959d4            2            1            3 000000000000
             1 28b51eb45704            1            1            2 5d69322fad9e
             0 a9bdc8b26820            0            1            1 000000000000
             3 e5ea8f9c7314            1            1            2 cf518031fa75
  $ cd ..
  $ cd ..

Actual Test for first version
-----------------------------

  $ dotest A.4 B -f
  ## Running testcase A.4
  # testing echange of "B" (06055a7959d4)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "B" from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "06055a7959d4" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  1 new obsolescence markers
  (run 'hg update' to get a working copy)
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
