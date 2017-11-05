=====================
Test workflow options
=====================

  $ . "$TESTDIR/testlib/topic_setup.sh"
  $ . "$TESTDIR/testlib/common.sh"

testing hg push --publish flag
==============================

  $ hg init bare-branch-server
  $ cd bare-branch-server
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish = no
  > EOF
  $ mkcommit ROOT
  $ mkcommit c_dA0
  $ hg phase --public -r 'all()'
  $ cd ..

  $ hg clone bare-branch-server bare-client
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd bare-client

Pushing a 1 new changeset
-------------------------

  $ mkcommit c_dB0
  $ hg push --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

Pushing a 2 new changeset (same branch)
---------------------------------------

  $ mkcommit c_dC0
  $ mkcommit c_dD0
  $ hg push --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

Pushing a 2 new changeset two head
----------------------------------

  $ mkcommit c_dE0
  $ hg update 'desc("c_dD0")'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg branch other
  marked working directory as branch other
  (branches are permanent and global, did you want a bookmark?)
  $ mkcommit c_oF0
  $ hg push -f --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files (+1 heads)
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  6:45b23c834b6a c_oF0 public other
  |
  | o  5:5576ae39eaee c_dE0 public default
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

Publishing 1 common changeset
-----------------------------
  $ mkcommit c_oG0
  $ hg push
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  7:d293f74a1233 c_oG0 draft other
  |
  o  6:45b23c834b6a c_oF0 public other
  |
  | o  5:5576ae39eaee c_dE0 public default
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  
  $ hg push --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  no changes found
  [1]
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  7:d293f74a1233 c_oG0 public other
  |
  o  6:45b23c834b6a c_oF0 public other
  |
  | o  5:5576ae39eaee c_dE0 public default
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

Selectively publishing 1 changeset
----------------------------------

  $ mkcommit c_oH0
  $ hg update default
  1 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ mkcommit c_dI0
  $ hg push -r default --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  9:fbf2be276221 c_dI0 public default
  |
  o  5:5576ae39eaee c_dE0 public default
  |
  | o  8:8e85646c135f c_oH0 draft other
  | |
  | o  7:d293f74a1233 c_oG0 public other
  | |
  | o  6:45b23c834b6a c_oF0 public other
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

Selectively publishing 1 common changeset
-----------------------------------------

  $ mkcommit c_dJ0
  $ hg push
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  10:ac4cf59f2aac c_dJ0 draft default
  |
  o  9:fbf2be276221 c_dI0 public default
  |
  o  5:5576ae39eaee c_dE0 public default
  |
  | o  8:8e85646c135f c_oH0 draft other
  | |
  | o  7:d293f74a1233 c_oG0 public other
  | |
  | o  6:45b23c834b6a c_oF0 public other
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  
  $ hg push --rev default --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  no changes found
  [1]
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  10:ac4cf59f2aac c_dJ0 public default
  |
  o  9:fbf2be276221 c_dI0 public default
  |
  o  5:5576ae39eaee c_dE0 public default
  |
  | o  8:8e85646c135f c_oH0 draft other
  | |
  | o  7:d293f74a1233 c_oG0 public other
  | |
  | o  6:45b23c834b6a c_oF0 public other
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

Selectively publishing no changeset
-----------------------------------

  $ hg push --rev default --publish
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  no changes found
  [1]
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  10:ac4cf59f2aac c_dJ0 public default
  |
  o  9:fbf2be276221 c_dI0 public default
  |
  o  5:5576ae39eaee c_dE0 public default
  |
  | o  8:8e85646c135f c_oH0 draft other
  | |
  | o  7:d293f74a1233 c_oG0 public other
  | |
  | o  6:45b23c834b6a c_oF0 public other
  |/
  o  4:c63e7dd93a91 c_dD0 public default
  |
  o  3:7d56a56d2547 c_dC0 public default
  |
  o  2:286d02a6e2a2 c_dB0 public default
  |
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  
