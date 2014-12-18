

Initial setup

  $ . $TESTDIR/_exc-util.sh

=== D.2 missing prune target (prune in "pushed set") ===

{{{
}}}

Marker exist from:

 * A' succeed to A
 * A' (prune)

Command run:

 * hg push

Expected exchange:

 * `A ø⇠o A'`
 * A' (prune)


  $ setuprepos D.2
  creating test repo for test case D.2
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ hg up -q 0
  $ mkcommit A1
  created new head
  $ hg debugobsolete `getid 'desc(A0)'` `getid 'desc(A1)'`
  $ hg prune --date '0 0' .
  1 changesets pruned
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at a9bdc8b26820
  $ hg strip --hidden -q 'desc(A1)'
  $ hg log -G --hidden
  x  28b51eb45704 (draft): A0
  |
  @  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

Actual Test
-------------------------------------

  $ dotest D.2
  ## Running testcase D.2
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  2 new obsolescence markers
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

