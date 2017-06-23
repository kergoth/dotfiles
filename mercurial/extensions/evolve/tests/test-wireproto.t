
  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [experimental]
  > obsmarkers-exchange-debug=true
  > bundle2-exp=true
  > [ui]
  > ssh=python "$RUNTESTDIR/dummyssh"
  > [phases]
  > publish = False
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

setup repo

  $ hg init server

  $ hg clone ssh://user@dummy/server client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cp -r client other

Smoke testing
===============.t

  $ cd client
  $ mkcommit 0
  $ mkcommit a
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  $ hg pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found
  $ hg pull -R ../other
  pulling from ssh://user@dummy/server
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  (run 'hg update' to get a working copy)
  $ hg push -R ../other
  pushing to ssh://user@dummy/server
  searching for changes
  no changes found
  [1]

Push
=============

  $ echo 'A' > a
  $ hg amend
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: obsmarker-exchange: 151 bytes received
  remote: 2 new obsolescence markers
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  no changes found
  [1]

Pull
=============

  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to [12] files \(\+1 heads\) (re)
  obsmarker-exchange: 151 bytes received
  2 new obsolescence markers
  (run 'hg heads' to see heads)
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found

Test some markers discovery
===========================

  $ echo c > C
  $ hg add C
  $ hg commit -m C
  $ echo c >> C
  $ hg amend
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: obsmarker-exchange: 151 bytes received
  remote: 2 new obsolescence markers
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  obsmarker-exchange: 151 bytes received
  2 new obsolescence markers
  (run 'hg update' to get a working copy)

some common hidden

  $ hg touch .
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 0 changes to 1 files (+1 heads)
  remote: obsmarker-exchange: 227 bytes received
  remote: 1 new obsolescence markers
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 1 files (+1 heads)
  obsmarker-exchange: 227 bytes received
  1 new obsolescence markers
  (run 'hg heads' to see heads)

test discovery avoid exchanging known markers

  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  no changes found
  [1]
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found

test discovery can be disabled

  $ hg push --config experimental.evolution.obsdiscovery=no
  pushing to ssh://user@dummy/server
  searching for changes
  (skipping discovery of obsolescence markers, will exchange everything)
  (controled by 'experimental.evolution.obsdiscovery' configuration)
  no changes found
  remote: obsmarker-exchange: 377 bytes received
  [1]
  $ hg -R ../other pull --config experimental.evolution.obsdiscovery=no
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found
  (skipping discovery of obsolescence markers, will exchange everything)
  (controled by 'experimental.evolution.obsdiscovery' configuration)
  obsmarker-exchange: 377 bytes received

  $ cd ..
