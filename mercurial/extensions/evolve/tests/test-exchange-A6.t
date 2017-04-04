


Initial setup

  $ . $TESTDIR/testlib/exchange-util.sh


=== A.6 between existing changeset ===

.. {{{
..   A ◕⇠● B
..     |/
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * `A◕⇠● B`
..
.. Command run:
..
..  * hg push -r B
..  * hg push
..
.. Expected exchange:
..
..  * `A◕⇠● B`


initial

  $ setuprepos A.6
  creating test repo for test case A.6
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ hg update -q 0
  $ mkcommit A1
  created new head

make both changeset known in remote

  $ hg push -qf ../pushdest
  $ hg push -qf ../pulldest

create a marker after this

  $ hg debugobsolete `getid 'desc(A0)'` `getid 'desc(A1)'`
  $ hg log -G --hidden
  @  e5ea8f9c7314 (draft): A1
  |
  | x  28b51eb45704 (draft): A0
  |/
  o  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsrelsethashtree
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 0000000000000000000000000000000000000000
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 3bc2ee626e11a7cf8fee7a66d069271e17d5a597
  $ hg debugobshashrange --subranges --rev 'head()'
           rev         node        index         size        depth      obshash
             2 e5ea8f9c7314            0            2            2 3bc2ee626e11
             0 a9bdc8b26820            0            1            1 000000000000
             2 e5ea8f9c7314            1            1            2 3bc2ee626e11
  $ cd ..
  $ cd ..

  $ cp -r A.6 A.6.a
  $ cp -r A.6 A.6.b

Actual Test (explicit push version)
-----------------------------------

  $ dotest A.6.a A1
  ## Running testcase A.6.a
  # testing echange of "A1" (e5ea8f9c7314)
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "A1" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "e5ea8f9c7314" from main into pulldest
  pulling from main
  no changes found
  1 new obsolescence markers
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

Actual Test (bare push version)
-------------------------------

  $ dotest A.6.b
  ## Running testcase A.6.b
  ## initial state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 1 new obsolescence markers
  ## post push state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  1 new obsolescence markers
  ## post pull state
  # obstore: main
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
