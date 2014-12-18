
Initial setup

  $ . $TESTDIR/_exc-util.sh


=== B.7 Prune on non-targeted common changeset ===
..
.. {{{
..     ⊗ B
..     |
..     ◕ A
..     |
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * B (prune)
..
.. Command run:
..
..  * hg push -r O
........  * hg push
..
.. Expected exchange:
..
..  * ø
.......  * B (prune)

  $ setuprepos B.7
  creating test repo for test case B.7
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ hg push -q ../pushdest
  $ hg push -q ../pulldest
  $ mkcommit B
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  f6fbb35d8ac9 (draft): B
  |
  @  f5bc6836db60 (draft): A
  |
  o  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

Actual Test
-------------------------------------

  $ dotest B.7 O
  ## Running testcase B.7
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  ## post push state
  # obstore: main
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  ## post pull state
  # obstore: main
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest

