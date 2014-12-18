

Initial setup

  $ . $TESTDIR/_exc-util.sh

=== C.4 multiple successors, one is pruned ===

.. Another case were prune are confusing? (A is killed without its successors being
.. pushed)
..
.. (could split of divergence, if split see the Z section)
..
.. {{{
..        A
..    B ○⇢ø⇠⊗ C
..       \|/
..        ● O
.. }}}
..
.. Marker exist from:
..
..  * `A ø⇠○ B`
..  * `A ø⇠○ C`
..  * C (prune)
..
..
.. Command run:
..
..  * hg push -r O
..
.. Expected exchange:
..
..  * `A ø⇠○ C`
..  * C (prune)
..
.. Expected exclude:
..
..  * `A ø⇠○ B`

Implemented as the non-split version

  $ setuprepos C.4
  creating test repo for test case C.4
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ hg update -q 0
  $ mkcommit B
  created new head
  $ hg update -q 0
  $ mkcommit C
  created new head
  $ hg debugobsolete --hidden `getid 'desc(A)'` `getid 'desc(B)'`
  $ hg debugobsolete --hidden `getid 'desc(A)'` `getid 'desc(C)'`
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  7f7f229b13a6 (draft): C
  |
  | o  35b183996678 (draft): B
  |/
  | x  f5bc6836db60 (draft): A
  |/
  @  a9bdc8b26820 (public): O
  
  $ hg debugobsolete
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..

Actual Test
-------------------------------------

  $ dotest C.4 O
  ## Running testcase C.4
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  2 new obsolescence markers
  ## post pull state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pulldest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

