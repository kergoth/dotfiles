=====================
Test workflow options
=====================

  $ . "$TESTDIR/testlib/topic_setup.sh"
  $ . "$TESTDIR/testlib/common.sh"

Test single head enforcing - Setup
=============================================

  $ hg init single-head-server
  $ cd single-head-server
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish = no
  > [experimental]
  > enforce-single-head = yes
  > evolution = all
  > EOF
  $ mkcommit ROOT
  $ mkcommit c_dA0
  $ cd ..

  $ hg clone single-head-server client
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

Test single head enforcing - with branch only
---------------------------------------------

  $ cd client

continuing the current defaultbranch

  $ mkcommit c_dB0
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

creating a new branch

  $ hg up 'desc("ROOT")'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg branch branch_A
  marked working directory as branch branch_A
  (branches are permanent and global, did you want a bookmark?)
  $ mkcommit c_aC0
  $ hg push --new-branch
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)

Create a new head on the default branch

  $ hg up 'desc("c_dA0")'
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit c_dD0
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg push -f
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  transaction abort!
  rollback completed
  abort: 2 heads on "default"
  (286d02a6e2a2, 9bf953aa81f6)
  [255]

remerge them

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ mkcommit c_dE0
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files

Test single head enforcing - with topic
---------------------------------------

pushing a new topic

  $ hg topic foo
  marked working directory as topic: foo
  $ mkcommit c_dF0
  active topic 'foo' grew its first changeset
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

pushing a new topo branch (with a topic)

  $ hg up 'desc("c_dD0")'
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg topic bar
  marked working directory as topic: bar
  $ mkcommit c_dG0
  active topic 'bar' grew its first changeset
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)

detect multiple heads on the topic

  $ mkcommit c_dH0
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg up 'desc("c_dG0")'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit c_dI0
  $ hg push  -f
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  transaction abort!
  rollback completed
  abort: 2 heads on "default:bar"
  (5194f5dcd542, 48a01453c1c5)
  [255]

merge works fine

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ mkcommit c_dJ0
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files

Test single head enforcing - by phase move
------------------------------------------

  $ hg -R ../single-head-server phase --public 'desc("c_dJ0")'
  abort: 2 heads on "default"
  (6ed1df20edb1, 678bca4de98c)
  [255]

Test single head enforcing - after rewrite
------------------------------------------

  $ hg up foo
  switching to topic foo
  3 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ hg commit --amend -m c_dF1
  $ hg push
  pushing to $TESTTMP/single-head-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 1 files (+1 heads)
  1 new obsolescence markers
  obsoleted 1 changesets
