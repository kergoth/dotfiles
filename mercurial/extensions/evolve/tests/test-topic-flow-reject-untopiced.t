Testing the config option for rejecting draft changeset without topic
The config option is "experimental.topic-mode.server"

  $ . "$TESTDIR/testlib/topic_setup.sh"

Creating a server repo

  $ hg init server
  $ cd server
  $ cat <<EOF >>.hg/hgrc
  > [phases]
  > publish=False
  > [experimental]
  > topic-mode.server = enforce
  > EOF

  $ hg topic server
  marked working directory as topic: server
  $ for ch in a b c; do echo foo > $ch; hg ci -Aqm "Added "$ch; done
  $ hg ph -p 0

  $ hg log -G -T "{rev}:{node|short}\n{desc}  {topics}"
  @  2:a7b96f87a214
  |  Added c  server
  o  1:d6a8197e192a
  |  Added b  server
  o  0:49a3f206c9ae
     Added a

  $ cd ..

Creating a client repo

  $ hg clone server client
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd client
  $ hg up server
  switching to topic server
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G -T "{rev}:{node|short}\n{desc}  {topics}"
  @  2:a7b96f87a214
  |  Added c  server
  o  1:d6a8197e192a
  |  Added b  server
  o  0:49a3f206c9ae
     Added a

  $ hg topic
   * server (2 changesets)

Create a changeset without topic

  $ hg topic --clear
  $ echo foo > d
  $ hg ci -Aqm "added d"

  $ hg log -G -T "{rev}:{node|short}\n{desc}  {topics}"
  @  3:4e8b0e0237c6
  |  added d
  o  2:a7b96f87a214
  |  Added c  server
  o  1:d6a8197e192a
  |  Added b  server
  o  0:49a3f206c9ae
     Added a

Push a draft changeset without topic

  $ hg push ../server  --new-branch
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  transaction abort!
  rollback completed
  abort: rejecting draft changesets: 4e8b0e0237
  [255]

  $ hg push ../server -f
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  transaction abort!
  rollback completed
  abort: rejecting draft changesets: 4e8b0e0237
  [255]

Grow the stack with more changesets having topic

  $ hg topic client
  marked working directory as topic: client
  $ for ch in e f g; do echo foo > $ch; hg ci -Aqm "Added "$ch; done;

  $ hg log -G -T "{rev}:{node|short}\n{desc}  {topics}"
  @  6:42c4ac86452a
  |  Added g  client
  o  5:3dc456efb491
  |  Added f  client
  o  4:18a516babc60
  |  Added e  client
  o  3:4e8b0e0237c6
  |  added d
  o  2:a7b96f87a214
  |  Added c  server
  o  1:d6a8197e192a
  |  Added b  server
  o  0:49a3f206c9ae
     Added a

Pushing multiple changeset with some having topics and some not

  $ hg push ../server --new-branch
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 4 files
  transaction abort!
  rollback completed
  abort: rejecting draft changesets: 4e8b0e0237
  [255]

Testing case when both experimental.topic-mode.server and
experimental.topic.publish-bare-branch are set

  $ cd ../server
  $ echo 'topic.publish-bare-branch=True' >> .hg/hgrc
  $ cd ../client
  $ hg push ../server --new-branch
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 4 files
  transaction abort!
  rollback completed
  abort: rejecting draft changesets: 4e8b0e0237
  [255]

Turning the changeset public and testing push

  $ hg phase -r 3 -p
  $ hg log -G -T "{rev}:{node|short}\n{desc}  {topics}"
  @  6:42c4ac86452a
  |  Added g  client
  o  5:3dc456efb491
  |  Added f  client
  o  4:18a516babc60
  |  Added e  client
  o  3:4e8b0e0237c6
  |  added d
  o  2:a7b96f87a214
  |  Added c
  o  1:d6a8197e192a
  |  Added b
  o  0:49a3f206c9ae
     Added a

  $ hg push ../server
  pushing to ../server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 4 files
  active topic 'server' is now empty
