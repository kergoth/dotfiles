

Initial setup

  $ . $TESTDIR/_exc-util.sh

=== D.4 Unknown changeset in between known one ===

.. Mostly a clarification case
..
.. {{{
..     ø⇠◌⇠○
..     | |/
..     | ◔
..     |/
..     ● O
..
.. }}}
..
.. Should be treated as A.3 case:
..
.. {{{
..
..     ø⇠○
..     | |
..     | ◔
..     |/
..     ● O
..
.. }}}


initial

  $ setuprepos A.3.a
  creating test repo for test case A.3.a
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
  
  $ hg debugobsolete
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

Actual Test for first version (changeset unknown in remote)
-----------------------------------------------------------

  $ dotest A.3.a A1
  ## Running testcase A.3.a
  # testing echange of "A1" (e5ea8f9c7314)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
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
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
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
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6e72f0a95b5e01a7504743aa941f69cb1fbef8b0 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 069b05c3876d56f62895e853a501ea58ea85f68d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}


