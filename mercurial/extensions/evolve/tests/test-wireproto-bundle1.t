
  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
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
===============

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
  2 new obsolescence markers
  (run 'hg heads' to see heads)
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found

  $ cd ..

