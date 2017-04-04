
Initial setup

  $ . $TESTDIR/testlib/exchange-util.sh

=== A.7 Non targeted common changeset ===

.. {{{
..    ⇠◕ A
..     |
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * Chain from A
..
.. Command run:
..
..  * hg push -r O
..
.. Expected exchange:
..
..  * ø


  $ setuprepos A.7
  creating test repo for test case A.7
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ hg push -q ../pushdest
  $ hg push -q ../pulldest
  $ hg debugobsolete aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa `getid 'desc(A)'`
  $ hg log -G --hidden
  @  f5bc6836db60 (draft): A
  |
  o  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsrelsethashtree
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 50656e04a95ecdfed94659dd61f663b2caa55e98
  $ hg debugobshashrange --subranges --rev 'head()'
           rev         node        index         size        depth      obshash
             1 f5bc6836db60            0            2            2 50656e04a95e
             0 a9bdc8b26820            0            1            1 000000000000
             1 f5bc6836db60            1            1            2 50656e04a95e
  $ cd ..
  $ cd ..

Actual Test
-----------------------------------

  $ dotest A.7 O
  ## Running testcase A.7
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  ## post push state
  # obstore: main
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  ## post pull state
  # obstore: main
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
