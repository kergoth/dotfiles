

Initial setup

  $ . $TESTDIR/testlib/exchange-util.sh

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
  $ hg debugobsrelsethashtree
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 a9c02d134f5b98acc74d1dc4eb28fd59f958a2bd
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 619b4d13bd9878f04d7208dcfcf1e89da826f6be
  35b1839966785d5703a01607229eea932db42f87 ddeb7b7a87378f59cecb36d5146df0092b6b3327
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 58ef2e726c5bd89bceffb6243294b38eadbf3d60
  $ hg debugobshashrange --subranges --rev 'head()'
           rev         node        index         size        depth      obshash
             2 35b183996678            0            2            2 2a098b4a877f
             2 35b183996678            1            1            2 916e804c50de
             0 a9bdc8b26820            0            1            1 a9c02d134f5b
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

