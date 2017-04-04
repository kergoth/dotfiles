

Initial setup

  $ . $TESTDIR/testlib/exchange-util.sh

=== C.2 Pruned changeset on precursors ===

.. {{{
..   B ⊗
..     |
..   A ø⇠◔ A'
..     |/
..     ● O
.. }}}
..
.. Marker exist from:
..
..  * A' succeed to A
..  * B (prune)
..
.. Command run:
..
..  * hg push -r A'
..  * hg push
..
.. Expected exchange:
..
..  * `A ø⇠o A'`
..  * B (prune)

  $ setuprepos C.2
  creating test repo for test case C.2
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A0
  $ mkcommit B
  $ hg prune -qd '0 0' .
  $ hg update -q 0
  $ mkcommit A1
  created new head
  $ hg debugobsolete `getid 'desc(A0)'` `getid 'desc(A1)'`
  $ hg log -G --hidden
  @  e5ea8f9c7314 (draft): A1
  |
  | x  06055a7959d4 (draft): B
  | |
  | x  28b51eb45704 (draft): A0
  |/
  o  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsrelsethashtree
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f 72f95b7b9fa12243aeb90433d211f2c38263da31
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 58ecf9a107b10986d88da605eb0d03b7f24ae486
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 289cb0d058c81c763eca8bb438657dba9a7ba646
  $ hg debugobshashrange --subranges --rev 'head()'
           rev         node        index         size        depth      obshash
             3 e5ea8f9c7314            0            2            2 289cb0d058c8
             0 a9bdc8b26820            0            1            1 000000000000
             3 e5ea8f9c7314            1            1            2 289cb0d058c8
  $ cd ..
  $ cd ..

  $ cp -r C.2 C.2.a
  $ cp -r C.2 C.2.b

Actual Test (explicit push)
---------------------------

  $ dotest C.2.a A1
  ## Running testcase C.2.a
  # testing echange of "A1" (e5ea8f9c7314)
  ## initial state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
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
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
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
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

Actual Test (bare push)
-------------------------------------

  $ dotest C.2.b
  ## Running testcase C.2.b
  ## initial state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling from main into pulldest
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
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
