============================================
Testing obsolescence markers push: Cases B.5
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category B: pruning case
TestCase 5: Push of a children of changeset which successors is pruned

B.5 Push of a children of changeset which successors is pruned
==============================================================

.. This case Mirror A.4, with pruned changeset successors.
..
.. {{{
..   C ◔
..     |
..   B⇠ø⇠⊗ B'
..     | |
..   A ø⇠○ A'
..     |/
..     ●
.. }}}
..
.. Marker exist from:
..
..  * `A ø⇠○ A'`
..  * `B ø⇠○ B'`
..  * chain from B
..  * `B' is pruned`
..
.. Command run:
..
..  * hg push -r C
..
.. Expected exchange:
..
..  * chain from B
..
.. Expected exclude:
..
..  * `A ø⇠○ A'`
..  * `B ø⇠○ B'`
..  * `B' prune`

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

initial

  $ setuprepos B.5
  creating test repo for test case B.5
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ mkcommit B0
  $ mkcommit C
  $ hg up --quiet 0
  $ mkcommit A1
  created new head
  $ mkcommit B1
  $ hg debugobsolete --hidden `getid 'desc(A0)'` `getid 'desc(A1)'`
  obsoleted 1 changesets
  2 new orphan changesets
  $ hg debugobsolete --hidden aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa `getid 'desc(B0)'`
  $ hg debugobsolete --hidden `getid 'desc(B0)'` `getid 'desc(B1)'`
  obsoleted 1 changesets
  $ hg prune -qd '0 0' 'desc(B1)' 
  $ hg log -G --hidden
  x  069b05c3876d (draft): B1
  |
  @  e5ea8f9c7314 (draft): A1
  |
  | *  1d0f3cd25300 (draft): C
  | |
  | x  6e72f0a95b5e (draft): B0
  | |
  | x  28b51eb45704 (draft): A0
  |/
  o  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  069b05c3876d56f62895e853a501ea58ea85f68d 0 {e5ea8f9c73143125d36658e90ef70c6d2027a5b7} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0000000000000000000000000000000000000000
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 13bd00d88332fcd3fe634ed42f9d35c9cfc06398
  1d0f3cd253006f014c7687a78abbc9287db4101d 01d985a82467333a4de7a5b4e8a0de3286f8bda8
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 eb83c031f3cbab180666ee92f54f0832b9f46eaa
  069b05c3876d56f62895e853a501ea58ea85f68d 87d03503620a7443b999bc8b8c00346f7afe7168
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             3 1d0f3cd25300            0            4            4 000000000000
             3 1d0f3cd25300            2            2            4 000000000000
             1 28b51eb45704            0            2            2 000000000000
             4 e5ea8f9c7314            0            2            2 eb83c031f3cb
             3 1d0f3cd25300            3            1            4 000000000000
             1 28b51eb45704            1            1            2 000000000000
             2 6e72f0a95b5e            2            1            3 13bd00d88332
             0 a9bdc8b26820            0            1            1 000000000000
             4 e5ea8f9c7314            1            1            2 eb83c031f3cb
  $ cd ..
  $ cd ..

Actual Test (explicit push version)
-----------------------------------

  $ dotest B.5 C -f
  ## Running testcase B.5
  # testing echange of "C" (1d0f3cd25300)
  ## initial state
  # obstore: main
  069b05c3876d56f62895e853a501ea58ea85f68d 0 {e5ea8f9c73143125d36658e90ef70c6d2027a5b7} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "C" from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 3 changesets with 3 changes to 3 files
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  069b05c3876d56f62895e853a501ea58ea85f68d 0 {e5ea8f9c73143125d36658e90ef70c6d2027a5b7} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "1d0f3cd25300" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files
  1 new obsolescence markers
  new changesets 28b51eb45704:1d0f3cd25300
  (run 'hg update' to get a working copy)
  ## post pull state
  # obstore: main
  069b05c3876d56f62895e853a501ea58ea85f68d 0 {e5ea8f9c73143125d36658e90ef70c6d2027a5b7} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
