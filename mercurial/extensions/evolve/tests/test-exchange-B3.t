

Initial setup

  $ . $TESTDIR/_exc-util.sh

=== B.3 Pruned changeset on non-pushed part of the history ===

.. {{{
..   ⊗ C
..   |
..   ○ B
..   | ◔ A
..   |/
..   ● O
.. }}}
..
.. Marker exist from:
..
..  * C (prune)
..
.. Command run:
..
..  * hg push -r A
..  * hg push
..
.. Expected exchange:
..
..  * ø
..
.. Expected Exclude:
..
..  * chain from B


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
  
  $ hg debugobsolete
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ cd ..
  $ cd ..


Actual Test
-----------------------------------

  $ dotest B.3 A
  ## Running testcase B.3
  # testing echange of "A" (f5bc6836db60)
  ## initial state
  # obstore: main
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
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
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest
  ## pulling "f5bc6836db60" from main into pulldest
  pulling from main
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  (run 'hg update' to get a working copy)
  ## post pull state
  # obstore: main
  e56289ab6378dc752fd7965f8bf66b58bda740bd 0 {35b1839966785d5703a01607229eea932db42f87} (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  # obstore: pushdest
  # obstore: pulldest

