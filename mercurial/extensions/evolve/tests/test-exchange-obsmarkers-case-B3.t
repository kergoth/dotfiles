============================================
Testing obsolescence markers push: Cases B.3
============================================

Mercurial pushes obsolescences markers relevant to the "pushed-set", the set of
all changesets that requested to be "in sync" after the push (even if they are
already on both side).

This test belongs to a series of tests checking such set is properly computed
and applied. This does not tests "obsmarkers" discovery capabilities.

Category B: pruning case
TestCase 3: Pruned changeset on non-pushed part of the history

B.3 Pruned changeset on non-pushed part of the history
======================================================

.. {{{
..   ⊗ C
..   |
..   ○ B
..   | ◔ A
..   |/
..   ● O
.. }}}
..
.. Marker exists from:
..
..  * C (prune)
..
.. Commands run:
..
..  * hg push -r A
..
.. Expected exchange:
..
..  * ø
..
.. Expected exclude:
..
..  * chain from B

Setup
-----

  $ . $TESTDIR/testlib/exchange-obsmarker-util.sh

initial

  $ setuprepos B.3
  creating test repo for test case B.3
  - pulldest
  - main
  - pushdest
  cd into `main` and proceed with env setup
  $ cd main
  $ mkcommit A
  $ hg up --quiet 0
  $ mkcommit B
  created new head
  $ mkcommit C
  $ hg prune -qd '0 0' .
  $ hg log -G --hidden
  x  e56289ab6378 (draft): C
  |
  @  35b183996678 (draft): B
  |
  | o  f5bc6836db60 (draft): A
  |/
  o  a9bdc8b26820 (public): O
  
  $ inspect_obsmarkers
  obsstore content
  ================
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  obshashtree
  ===========
  a9bdc8b26820b1b87d585b82eb0ceb4a2ecdbc04 0000000000000000000000000000000000000000
  f5bc6836db60e308a17ba08bf050154ba9c4fad7 0000000000000000000000000000000000000000
  35b1839966785d5703a01607229eea932db42f87 3bb8cd8ac8f52487f2ef21e0bdf795a5cd293351
  e56289ab6378dc752fd7965f8bf66b58bda740bd b62eedd8d9194225136e5908c492ab03569079da
  obshashrange
  ============
           rev         node        index         size        depth      obshash
             2 35b183996678            0            2            2 3bb8cd8ac8f5
             1 f5bc6836db60            0            2            2 000000000000
             2 35b183996678            1            1            2 3bb8cd8ac8f5
             0 a9bdc8b26820            0            1            1 000000000000
             1 f5bc6836db60            1            1            2 000000000000
  $ cd ..
  $ cd ..

Actual Test
-----------------------------------

  $ dotest B.3 A
  ## Running testcase B.3
  # testing echange of "A" (f5bc6836db60)
  ## initial state
  # obstore: main
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pushing "A" from main to pushdest
  pushing to pushdest
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  ## post push state
  # obstore: main
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pulling "f5bc6836db60" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  new changesets f5bc6836db60
  (run 'hg update' to get a working copy)
  ## post pull state
  # obstore: main
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '0', 'operation': 'prune', 'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest

