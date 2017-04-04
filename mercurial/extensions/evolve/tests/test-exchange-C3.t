

Initial setup

  $ . $TESTDIR/testlib/exchange-util.sh


=== C.3 Pruned changeset on precursors of another pruned one ===

.. {{{
..   B ⊗
..     |
..   A ø⇠⊗ A'
..     |/
..     ● O
.. }}}
.. 
.. Marker exist from:
.. 
..  * A' succeed to A
..  * A' (prune
..  * B (prune)
.. 
.. Command run:
.. 
..  * hg push -r A'
..  * hg push
.. 
.. Expected exchange:
.. 
..  * `A ø⇠⊗ A'`
..  * A (prune)
..  * B (prune)

  $ setuprepos C.3
  creating test repo for test case C.3
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
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  e5ea8f9c7314 (draft): A1
  |
  | x  06055a7959d4 (draft): B
  | |
  | x  28b51eb45704 (draft): A0
  |/
  @  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsrelsethashtree
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 40be80b35671116f2c61ef25797806536a6eb5a0
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f beac7228bbe708bc7c9181c3c27f8a17f21dbd9f
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 8b648bd67281e9e525919285ac7b3bb2836c2f02
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 dcd2b566ad0983333be704afdc205066e1a6b742
  $ hg debugobshashrange --subranges --rev 'head()'
           rev         node        index         size        depth      obshash
             0 a9bdc8b26820            0            1            1 40be80b35671
  $ cd ..
  $ cd ..

  $ cp -r C.3 C.3.a
  $ cp -r C.3 C.3.b

Actual Test (explicit push)
---------------------------

  $ dotest C.3.a O
  ## Running testcase C.3.a
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 3 new obsolescence markers
  ## post push state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  3 new obsolescence markers
  ## post pull state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

Actual Test (bare push)
-------------------------------------

  $ dotest C.3.b
  ## Running testcase C.3.b
  ## initial state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 3 new obsolescence markers
  ## post push state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling from main into pulldest
  pulling from main
  searching for changes
  no changes found
  3 new obsolescence markers
  ## post pull state
  # obstore: main
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  06055a7959d4128e6e3bccfd01482e83a2db8a3a 0 {28b51eb45704506b5c603decd6bf7ac5e0f6a52f} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  28b51eb45704506b5c603decd6bf7ac5e0f6a52f e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  e5ea8f9c73143125d36658e90ef70c6d2027a5b7 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
