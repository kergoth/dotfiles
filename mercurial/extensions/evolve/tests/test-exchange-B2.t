
Initial setup

  $ . $TESTDIR/_exc-util.sh

=== B.2 Pruned changeset on head: nothing pushed ===

.. {{{
..     ⊗ A
..     |
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * A (prune)
..
.. Command run:
..
..  * hg push -r O
..  * hg push
..
.. Expected exchange:
..
..  * prune marker for A


  $ setuprepos B.2
  creating test repo for test case B.2
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  f5bc6836db60 (draft): A
  |
  @  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..


  $ cp -r B.2 B.2.a
  $ cp -r B.2 B.2.b

Actual Test (explicit push version)
-----------------------------------

  $ dotest B.2.a O
  ## Running testcase B.2.a
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  1 new obsolescence markers
  ## post pull state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

Actual Test (bare push version)
-----------------------------------

  $ dotest B.2.b
  ## Running testcase B.2.b
  ## initial state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  1 new obsolescence markers
  ## post pull state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
