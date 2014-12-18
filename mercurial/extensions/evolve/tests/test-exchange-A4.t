
Initial setup

  $ . $TESTDIR/_exc-util.sh


=== A.4 Push in the middle of the obsolescence chain ===

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
.. Marker exist from:
..
..  * `Aø⇠○ A'`
..  * chain from A
..
.. Command run:
..
..  * hg push -r B
..
.. Expected exchange:
..
..  * Chain from A
..
.. Expected Exclude:
..
..  * `Aø⇠○ A'`


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
  
  $ hg debugobsolete
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

Actual Test for first version (changeset unknown in remote)
-----------------------------------------------------------

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
