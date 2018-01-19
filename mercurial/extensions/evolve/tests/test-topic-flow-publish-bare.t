=====================
Test workflow options
=====================

  $ . "$TESTDIR/testlib/topic_setup.sh"
  $ . "$TESTDIR/testlib/common.sh"

Publishing of bare branch
=========================

  $ hg init bare-branch-server
  $ cd bare-branch-server
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish = no
  > [experimental]
  > topic.publish-bare-branch = yes
  > EOF
  $ mkcommit ROOT
  $ mkcommit c_dA0
  $ hg phase --public -r 'all()'
  $ cd ..

  $ hg clone bare-branch-server bare-client
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

pushing a simple branch publish it
----------------------------------

  $ cd bare-client
  $ mkcommit c_dB0
  $ hg push
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
  

pushing two heads at the same time
----------------------------------

  $ hg update 'desc("c_dA0")'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit c_dC0
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg update 'desc("c_dA0")'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit c_dD0
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg push -f
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files (+2 heads)
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  4:9bf953aa81f6 c_dD0 public default
  |
  | o  3:9d5b8e1f08a4 c_dC0 public default
  |/
  | o  2:286d02a6e2a2 c_dB0 public default
  |/
  o  1:134bc3852ad2 c_dA0 public default
  |
  o  0:ea207398892e ROOT public default
  

pushing something not on default
--------------------------------

  $ hg update 'desc("ROOT")'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg branch branchA
  marked working directory as branch branchA
  (branches are permanent and global, did you want a bookmark?)
  $ mkcommit c_aE0
  $ hg push --new-branch
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  5:0db08e758601 c_aE0 public branchA
  |
  | o  4:9bf953aa81f6 c_dD0 public default
  | |
  | | o  3:9d5b8e1f08a4 c_dC0 public default
  | |/
  | | o  2:286d02a6e2a2 c_dB0 public default
  | |/
  | o  1:134bc3852ad2 c_dA0 public default
  |/
  o  0:ea207398892e ROOT public default
  

pushing topic
-------------

  $ hg update 'desc("c_dD0")'
  2 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic foo
  marked working directory as topic: foo
  $ mkcommit c_dF0
  active topic 'foo' grew its first changeset
  $ hg push
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  6:0867c4471796 c_dF0 draft default foo
  |
  o  4:9bf953aa81f6 c_dD0 public default
  |
  | o  3:9d5b8e1f08a4 c_dC0 public default
  |/
  | o  2:286d02a6e2a2 c_dB0 public default
  |/
  o  1:134bc3852ad2 c_dA0 public default
  |
  | o  5:0db08e758601 c_aE0 public branchA
  |/
  o  0:ea207398892e ROOT public default
  

pushing topic over a bare branch
--------------------------------

  $ hg update 'desc("c_dC0")'
  1 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit c_dG0
  $ hg topic bar
  marked working directory as topic: bar
  $ mkcommit c_dH0
  active topic 'bar' grew its first changeset
  $ hg push
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  8:858be9a8daaf c_dH0 draft default bar
  |
  o  7:0e4041d324d0 c_dG0 public default
  |
  o  3:9d5b8e1f08a4 c_dC0 public default
  |
  | o  2:286d02a6e2a2 c_dB0 public default
  |/
  | o  6:0867c4471796 c_dF0 draft default foo
  | |
  | o  4:9bf953aa81f6 c_dD0 public default
  |/
  o  1:134bc3852ad2 c_dA0 public default
  |
  | o  5:0db08e758601 c_aE0 public branchA
  |/
  o  0:ea207398892e ROOT public default
  

Pushing topic in between bare branch
------------------------------------

  $ hg update 'desc("c_dB0")'
  1 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ mkcommit c_dI0
  $ hg update 'desc("c_dH0")'
  switching to topic bar
  3 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit c_dJ0
  $ hg update 'desc("c_aE0")'
  1 files updated, 0 files merged, 5 files removed, 0 files unresolved
  $ mkcommit c_aK0
  $ hg push
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @  11:b0a00ebdfd24 c_aK0 public branchA
  |
  o  5:0db08e758601 c_aE0 public branchA
  |
  | o  10:abb5c84eb9e9 c_dJ0 draft default bar
  | |
  | o  8:858be9a8daaf c_dH0 draft default bar
  | |
  | o  7:0e4041d324d0 c_dG0 public default
  | |
  | o  3:9d5b8e1f08a4 c_dC0 public default
  | |
  | | o  9:4b5570d89f0f c_dI0 public default
  | | |
  | | o  2:286d02a6e2a2 c_dB0 public default
  | |/
  | | o  6:0867c4471796 c_dF0 draft default foo
  | | |
  | | o  4:9bf953aa81f6 c_dD0 public default
  | |/
  | o  1:134bc3852ad2 c_dA0 public default
  |/
  o  0:ea207398892e ROOT public default
  

merging a topic in branch
-------------------------

  $ hg update default
  3 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg merge foo
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m 'c_dL0'
  $ hg push
  pushing to $TESTTMP/bare-branch-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files (-1 heads)
  $ hg log --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  @    12:a6f9f8c6c6cc c_dL0 public default
  |\
  | o  9:4b5570d89f0f c_dI0 public default
  | |
  o |  6:0867c4471796 c_dF0 public default
  | |
  o |  4:9bf953aa81f6 c_dD0 public default
  | |
  | | o  10:abb5c84eb9e9 c_dJ0 draft default bar
  | | |
  | | o  8:858be9a8daaf c_dH0 draft default bar
  | | |
  | | o  7:0e4041d324d0 c_dG0 public default
  | | |
  +---o  3:9d5b8e1f08a4 c_dC0 public default
  | |
  | o  2:286d02a6e2a2 c_dB0 public default
  |/
  o  1:134bc3852ad2 c_dA0 public default
  |
  | o  11:b0a00ebdfd24 c_aK0 public branchA
  | |
  | o  5:0db08e758601 c_aE0 public branchA
  |/
  o  0:ea207398892e ROOT public default
  
  $ hg log -R ../bare-branch-server --rev 'sort(all(), "topo")' -GT '{rev}:{node|short} {desc} {phase} {branch} {topics}'
  o    12:a6f9f8c6c6cc c_dL0 public default
  |\
  | o  9:4b5570d89f0f c_dI0 public default
  | |
  o |  6:0867c4471796 c_dF0 public default
  | |
  o |  4:9bf953aa81f6 c_dD0 public default
  | |
  | | o  10:abb5c84eb9e9 c_dJ0 draft default bar
  | | |
  | | o  8:858be9a8daaf c_dH0 draft default bar
  | | |
  | | o  7:0e4041d324d0 c_dG0 public default
  | | |
  +---o  3:9d5b8e1f08a4 c_dC0 public default
  | |
  | o  2:286d02a6e2a2 c_dB0 public default
  |/
  @  1:134bc3852ad2 c_dA0 public default
  |
  | o  11:b0a00ebdfd24 c_aK0 public branchA
  | |
  | o  5:0db08e758601 c_aE0 public branchA
  |/
  o  0:ea207398892e ROOT public default
  
