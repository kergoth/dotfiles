  $ . $TESTDIR/testlib/common.sh

setup
  $ cat >> $HGRCPATH << EOF
  > [extensions]
  > share=
  > blackbox=
  > [web]
  > allow_push = *
  > push_ssl = no
  > [phases]
  > publish = False
  > [paths]
  > enabled = http://localhost:$HGPORT/
  > disabled = http://localhost:$HGPORT2/
  > EOF

  $ hg init ./server-enabled
  $ cat >> server-enabled/.hg/hgrc << EOF
  > [extensions]
  > serverminitopic=
  > [experimental]
  > server-mini-topic = yes
  > EOF

  $ hg share ./server-enabled ./server-disabled
  updating working directory
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat >> server-disabled/.hg/hgrc << EOF
  > [extensions]
  > serverminitopic=
  > [experimental]
  > server-mini-topic = no
  > EOF

  $ hg init client-disabled
  $ hg init client-enabled
  $ cat >> client-enabled/.hg/hgrc << EOF
  > [extensions]
  > topic=
  > EOF

  $ hg serve -R server-enabled -p $HGPORT -d --pid-file hg1.pid --errorlog hg1.error
  $ cat hg1.pid > $DAEMON_PIDS
  $ hg serve -R server-disabled -p $HGPORT2 -d --pid-file hg2.pid --errorlog hg2.error
  $ cat hg2.pid >> $DAEMON_PIDS

  $ curl --silent http://localhost:$HGPORT/?cmd=capabilities | grep -o topics
  topics
  $ curl --silent http://localhost:$HGPORT2/?cmd=capabilities | grep -o topics
  [1]

Pushing first changesets to the servers
--------------------------------------

  $ cd client-enabled
  $ mkcommit c_A0
  $ hg push enabled
  pushing to http://localhost:$HGPORT/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  $ mkcommit c_B0
  $ hg push disabled
  pushing to http://localhost:$HGPORT2/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files

  $ cat $TESTTMP/hg1.error
  $ cat $TESTTMP/hg2.error

Pushing new head
----------------

  $ hg up 'desc("c_A0")'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit c_C0
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg push enabled
  pushing to http://localhost:$HGPORT/
  searching for changes
  abort: push creates new remote head 22c9514ed811!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg push disabled
  pushing to http://localhost:$HGPORT2/
  searching for changes
  abort: push creates new remote head 22c9514ed811!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]

  $ curl --silent http://localhost:$HGPORT/?cmd=branchmap | sort
  default 0ab6d544d0efd629fda056601cfe95e73d1af210
  $ curl --silent http://localhost:$HGPORT2/?cmd=branchmap | sort
  default 0ab6d544d0efd629fda056601cfe95e73d1af210
  $ cat $TESTTMP/hg1.error
  $ cat $TESTTMP/hg2.error

Pushing new topic
-----------------

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ mkcommit c_D0
  $ hg log -G
  @    changeset:   3:9c660cf97499
  |\   tag:         tip
  | |  parent:      2:22c9514ed811
  | |  parent:      1:0ab6d544d0ef
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     c_D0
  | |
  | o  changeset:   2:22c9514ed811
  | |  parent:      0:14faebcf9752
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     c_C0
  | |
  o |  changeset:   1:0ab6d544d0ef
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     c_B0
  |
  o  changeset:   0:14faebcf9752
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     c_A0
  
  $ hg push enabled
  pushing to http://localhost:$HGPORT/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  $ hg up 'desc("c_C0")'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg topic topic_A
  marked working directory as topic: topic_A
  $ mkcommit c_E0
  active topic 'topic_A' grew its first changeset
  $ hg push disabled
  pushing to http://localhost:$HGPORT2/
  searching for changes
  abort: push creates new remote head f31af349535e!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg push enabled
  pushing to http://localhost:$HGPORT/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)

  $ curl --silent http://localhost:$HGPORT/?cmd=branchmap | sort
  default 9c660cf97499ae01ccb6894880455c6ffa4b19cf
  default%3Atopic_A f31af349535e413b6023f11b51a6afccf4139180
  $ curl --silent http://localhost:$HGPORT2/?cmd=branchmap | sort
  default 9c660cf97499ae01ccb6894880455c6ffa4b19cf f31af349535e413b6023f11b51a6afccf4139180
  $ cat $TESTTMP/hg1.error
  $ cat $TESTTMP/hg2.error

Pushing new head to a topic
---------------------------

  $ hg up 'desc("c_D0")'
  2 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic topic_A
  marked working directory as topic: topic_A
  $ mkcommit c_F0
  $ hg log -G
  @  changeset:   5:82c5842e0472
  |  tag:         tip
  |  topic:       topic_A
  |  parent:      3:9c660cf97499
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     c_F0
  |
  | o  changeset:   4:f31af349535e
  | |  topic:       topic_A
  | |  parent:      2:22c9514ed811
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     c_E0
  | |
  o |  changeset:   3:9c660cf97499
  |\|  parent:      2:22c9514ed811
  | |  parent:      1:0ab6d544d0ef
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     c_D0
  | |
  | o  changeset:   2:22c9514ed811
  | |  parent:      0:14faebcf9752
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     c_C0
  | |
  o |  changeset:   1:0ab6d544d0ef
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     c_B0
  |
  o  changeset:   0:14faebcf9752
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     c_A0
  
  $ hg push enabled
  pushing to http://localhost:$HGPORT/
  searching for changes
  abort: push creates new remote head 82c5842e0472 on branch 'default:topic_A'!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg push disabled
  pushing to http://localhost:$HGPORT2/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files

  $ curl --silent http://localhost:$HGPORT/?cmd=branchmap | sort
  default 9c660cf97499ae01ccb6894880455c6ffa4b19cf
  default%3Atopic_A f31af349535e413b6023f11b51a6afccf4139180 82c5842e047215160763f81ae93ae42c65b20a63
  $ curl --silent http://localhost:$HGPORT2/?cmd=branchmap | sort
  default f31af349535e413b6023f11b51a6afccf4139180 82c5842e047215160763f81ae93ae42c65b20a63
  $ cat $TESTTMP/hg1.error
  $ cat $TESTTMP/hg2.error
