============================================
Testing obsolescence markers push: Cases D.4
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category D: Partial Information Case
TestCase 4: Unknown changeset in between known changesets

D.4 Unknown changeset in between known one
==========================================

.. Mostly a clarification case
..
.. {{{
..   B ø⇠◌⇠○ B''
..     |   |
..   A ø⇠◌⇠◔ A'
..      \ /
..       ● O
..
.. }}}
..
.. Should be treated as A.3 case:
..
.. {{{
..
..   B ø⇠○ B''
..     | |
..   A ø⇠◔ A'
..     |/
..     ● O
..
.. }}}

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

initial

  $ setuprepos D.4
  creating test repo for test case D.4
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ mkcommit B0
  $ hg update -q 0
  $ mkcommit A1
  created new head
  $ mkcommit B1
  $ hg debugobsolete `getid 'desc(A0)'` aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  $ hg debugobsolete aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa `getid 'desc(A1)'`
  $ hg debugobsolete `getid 'desc(B0)'` bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
  $ hg debugobsolete bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb `getid 'desc(B1)'`
  $ hg log -G --hidden
  @  069b05c3876d (draft): B1
  |
  o  e5ea8f9c7314 (draft): A1
  |
  | x  6e72f0a95b5e (draft): B0
  | |
  | x  28b51eb45704 (draft): A0
  |/
  o  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (*) {'user': 'test'} (glob)
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (*) {'user': 'test'} (glob)
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0000000000000000000000000000000000000000
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 0000000000000000000000000000000000000000
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0aacc2f86e8fca29f2d5fd8d0790644620acd58a
  069b05c3876d56f62895e853a501ea58ea85f68d 40b98bc2b5b1152416ea8e9665ae1c6a3ce32ba0
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             4 069b05c3876d            0            3            3 a2b2331da650
             3 e5ea8f9c7314            0            2            2 0aacc2f86e8f
             4 069b05c3876d            2            1            3 901f118d4333
             0 a9bdc8b26820            0            1            1 000000000000
             3 e5ea8f9c7314            1            1            2 0aacc2f86e8f
  $ cd ..
  $ cd ..

Actual Test
-----------

  $ dotest D.4 A1
  ## Running testcase D.4
  # testing echange of "A1" (e5ea8f9c7314)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (*) {'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "A1" from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (*) {'user': 'test'} (glob)
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling "e5ea8f9c7314" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  2 new obsolescence markers
  (run 'hg update' to get a working copy)
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (*) {'user': 'test'} (glob)
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (*) {'user': 'test'} (glob)
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (*) {'user': 'test'} (glob)
