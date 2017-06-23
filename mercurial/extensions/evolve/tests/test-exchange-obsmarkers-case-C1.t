============================================
Testing obsolescence markers push: Cases C.1
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category C: advanced case
TestCase 1: Multiple pruned changeset atop each other
Variants:
# a: explicite push
# b: bare push

C.1 Multiple pruned changeset atop each other
=============================================

.. {{{
..   ⊗ B
..   |
..   ⊗ A
..   |
..   ● O
.. }}}
..
.. Marker exist from:
..
..  * A (prune)
..  * B (prune)
..
.. Commands run:
..
..  * hg push -r O
..  * hg push
..
.. Expected exchange:
..
..  * A (prune)
..  * B (prune)

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

Initial

  $ setuprepos C.1
  creating test repo for test case C.1
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ mkcommit B
  $ hg prune -qd '0 0' '.~1'
  1 new unstable changesets
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  f6fbb35d8ac9 (draft): B
  |
  x  f5bc6836db60 (draft): A
  |
  @  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 2eae6a894c52a556ac692c2d0da80e81548b9f08
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 36f7fefb84e169c95144b085ce25607908f43c05
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af b5e9a0fe6060fb80fa51366d6fc5b8f3a5c6e1ed
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             0 a9bdc8b26820            0            1            1 2eae6a894c52
  $ cd ..
  $ cd ..

  $ cp -R C.1 C.1.a
  $ cp -R C.1 C.1.b

Actual Test (explicit push)
---------------------------

  $ dotest C.1.a O
  ## Running testcase C.1.a
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  2 new obsolescence markers
  ## post pull state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)

Actual Test (bare push)
-------------------------------------

  $ dotest C.1.b
  ## Running testcase C.1.b
  ## initial state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  2 new obsolescence markers
  ## post pull state
  # obstore: main
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 0 {f5bc6836db60e308a17ba08bf050154ba9c4fad7} (*) {'ef1': '*', 'user': 'test'} (glob)
