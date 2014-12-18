


Initial setup

  $ . $TESTDIR/_exc-util.sh


=== B.5 Push of a children of changeset which successors is pruned ===

.. This case Mirror A.4, with pruned changeset successors.
..
.. {{{
..   B ◔
..     |
..   A⇠ø⇠⊗ A'
..     |/
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * `Aø⇠○ A'`
..  * chain from A
..  * `A'`
..
.. Command run:
..
..  * hg push -r B
..
.. Expected exchange:
..
..  * `Aø⇠○ A'`
..  * chain from A
..  * `A'`
..
.. Extra Note:
..
..   I'm not totally happy about this case and I believe some more complicated
..   graph can result in behavior wuite confusing for the user (if some tool create
..   prune maker in a the middle of a valid chain)

  $ setuprepos B.5
  creating test repo for test case B.5
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ mkcommit B
  $ hg up --quiet 0
  $ mkcommit A1
  created new head
  $ hg debugobsolete --hidden `getid 'desc(A0)'` `getid 'desc(A1)'`
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  e5ea8f9c7314 (draft): A1
  |
  | o  06055a7959d4 (draft): B
  | |
  | x  28b51eb45704 (draft): A0
  |/
  @  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

  $ cp -r B.5 B.5.a
  $ cp -r B.5 B.5.b

Actual Test (explicit push version)
-----------------------------------

  $ dotest B.5.a B -f
  ## Running testcase B.5.a
  # testing echange of "B" (06055a7959d4)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "B" from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "06055a7959d4" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  2 new obsolescence markers
  (run 'hg update' to get a working copy)
  1 new unstable changesets
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

Actual Test (bare push version)
-------------------------------------

  $ dotest B.5.b B -f
  ## Running testcase B.5.b
  # testing echange of "B" (06055a7959d4)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "B" from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "06055a7959d4" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  2 new obsolescence markers
  (run 'hg update' to get a working copy)
  1 new unstable changesets
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
