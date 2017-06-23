============================================
Testing obsolescence markers push: Cases B.1
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category B: pruning case
TestCase 1: Prune on non-targeted common changeset

B.1 Prune on non-targeted common changeset
==========================================

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
.. Command runs:
..
..  * hg push -r O
..
.. Expected exclude:
..
..  * B (prune)

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

Initial

  $ setuprepos B.1
  creating test repo for test case B.1
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ mkcommit B

make both changeset known in remote

  $ hg push -qf ../pushdest
  $ hg push -qf ../pulldest

create prune marker

  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  f6fbb35d8ac9 (draft): B
  |
  @  f5bc6836db60 (draft): A
  |
  o  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 8408066feeb4e37fa26d01fe5c93bea92e450608
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 535b0c799a3a273fee10934abcb9e8eb9924b4bf
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             1 f5bc6836db60            0            2            2 8408066feeb4
             0 a9bdc8b26820            0            1            1 000000000000
             1 f5bc6836db60            1            1            2 8408066feeb4
  $ cd ..
  $ cd ..

Actual Test
-----------

  $ dotest B.1 O
  ## Running testcase B.1
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  ## post push state
  # obstore: main
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  ## post pull state
  # obstore: main
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
