============================================
Testing obsolescence markers push: Cases B.4
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category B: pruning case
TestCase 4: Pruned changeset on common part of the history
Variants:
# a: explicite push
# b: bare push

B.4 Pruned changeset on common part of history
=============================================

.. {{{
..   ⊗ C
..   | ● B
..   | |
..   | ● A
..   |/
..   ● O
.. }}}
..
.. Marker exist from:
..
..  * C (prune)
..
.. Command run:
..
..  * hg push -r B
..  * hg push
..
.. Expected exchange:
..
..  * prune for C

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

initial

  $ setuprepos B.4
  creating test repo for test case B.4
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ mkcommit B
  $ hg phase --public .
  $ hg push ../pushdest
  pushing to ../pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  $ hg push ../pulldest
  pushing to ../pulldest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  $ hg update -q 0
  $ mkcommit C
  created new head
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  7f7f229b13a6 (draft): C
  |
  | o  f6fbb35d8ac9 (public): B
  | |
  | o  f5bc6836db60 (public): A
  |/
  @  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 000a06f93df9cdd3c570d38aef8cd21a4a25df9b
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 ff621c458a04f2994124b0ef4b43572f7eb2335a
  f6fbb35d8ac958bbe70035e4c789c18471cdc0af 5afda6754e34bfe9ac1942df123711f929054273
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed f3513f70438639d6687bbec74f4d3fd11853f471
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             2 f6fbb35d8ac9            0            3            3 000000000000
             1 f5bc6836db60            0            2            2 000000000000
             0 a9bdc8b26820            0            1            1 000a06f93df9
             1 f5bc6836db60            1            1            2 000000000000
             2 f6fbb35d8ac9            2            1            3 000000000000
  $ cd ..
  $ cd ..

  $ cp -R B.4 B.4.a
  $ cp -R B.4 B.4.b

Actual Test (explicit push version)
-----------------------------------

  $ dotest B.4.a O
  ## Running testcase B.4.a
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  1 new obsolescence markers
  ## post pull state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)

Actual Test (bare push version)
-----------------------------------

  $ dotest B.4.b
  ## Running testcase B.4.b
  ## initial state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  1 new obsolescence markers
  ## post pull state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  # obstore: pulldest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
