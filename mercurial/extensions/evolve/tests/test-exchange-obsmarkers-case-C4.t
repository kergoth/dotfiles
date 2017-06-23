============================================
Testing obsolescence markers push: Cases C.4
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category C: advanced case
TestCase 4: multiple successors, one is pruned

C.4 multiple successors, one is pruned
======================================

.. (A similarish situation can appends with split markers see the Z section)
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

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

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
  
  $ inspect_obsmarkers
  obsstore content
  ================
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (*) {'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 172c7e3f43e9982efc74a27d34bd7a54cc158b57
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 c195f40b705423f406e537d1c64f6bc131a80214
  35b1839966785d5703a01607229eea932db42f87 76197cf2f9c1dcf5baa6cc3f4057980055353c03
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed e0a3b65709a8a1938e6c6cfc49a45253849e31a2
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             2 35b183996678            0            2            2 8d1b3b767a40
             2 35b183996678            1            1            2 916e804c50de
             0 a9bdc8b26820            0            1            1 172c7e3f43e9
  $ cd ..
  $ cd ..

Actual Test
-----------

  $ dotest C.4 O
  ## Running testcase C.4
  # testing echange of "O" (a9bdc8b26820)
  ## initial state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (*) {'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "O" from main to pushdest
  pushing to pushdest
  searching for changes
  no changes found
  remote: 2 new obsolescence markers
  ## post push state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (*) {'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
  # obstore: pulldest
  ## pulling "a9bdc8b26820" from main into pulldest
  pulling from main
  no changes found
  2 new obsolescence markers
  ## post pull state
  # obstore: main
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 35b1839966785d5703a01607229eea932db42f87 0 (*) {'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
  # obstore: pushdest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
  # obstore: pulldest
  7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 {a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04} (*) {'ef1': '*', 'user': 'test'} (glob)
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 7f7f229b13a629a5b20581c6cb723f4e2ca54bed 0 (*) {'user': 'test'} (glob)
