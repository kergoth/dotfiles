


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
  $ mkcommit B
  created new head
  $ mkcommit A1
  $ hg debugobsolete `getid 'desc(A0)'` `getid 'desc(A1)'`
  $ hg prune -d '0 0' .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 35b183996678
  1 changesets pruned
  $ hg strip --hidden -q 'desc(A1)'
  $ hg log -G --hidden
  @  35b183996678 (draft): B
  |
  | x  28b51eb45704 (draft): A0
  |/
  o  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

Actual Test
-------------------------------------

  $ dotest D.2 O
  ## Running testcase D.2
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  6aa67a7b4baa6fb41b06aed38d5b1201436546e2 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest

