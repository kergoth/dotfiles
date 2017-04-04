
  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [alias]
  > qlog = log --template='{rev} - {node|short} {desc} ({phase})\n'
  > [diff]
  > git = 1
  > unified = 0
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" >> "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ hg init local
  $ hg init other
  $ cd local
  $ touch 1 2 3 4 5 6 7 8 9 0
  $ hg add 1 2 3 4 5 6 7 8 9 0
  $ mkcommit A
  $ mkcommit B
  $ mkcommit C
  $ hg glog
  @  changeset:   2:829b19580856
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add C
  |
  o  changeset:   1:97b8f02ab29e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add B
  |
  o  changeset:   0:5d8dabd3961b
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add A
  
  $ hg push ../other
  pushing to ../other
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 13 changes to 13 files


  $ hg -R ../other verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  13 files, 3 changesets, 13 total revisions
  $ mkcommit D
  $ mkcommit E
  $ hg up -q .^^
  $ hg revert -r tip -a -q
  $ hg ci -m 'coin' -q
  $ hg glog
  @  changeset:   5:8313a6afebbb
  |  tag:         tip
  |  parent:      2:829b19580856
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     coin
  |
  | o  changeset:   4:076ec8ade1ac
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     add E
  | |
  | o  changeset:   3:824d9bb109f6
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     add D
  |
  o  changeset:   2:829b19580856
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add C
  |
  o  changeset:   1:97b8f02ab29e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add B
  |
  o  changeset:   0:5d8dabd3961b
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add A
  

  $ hg prune --fold -n -1 -- -2 -3
  2 changesets pruned
  $ hg push ../other
  pushing to ../other
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 2 changes to 2 files
  2 new obsolescence markers
  $ hg -R ../other verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  15 files, 4 changesets, 15 total revisions



