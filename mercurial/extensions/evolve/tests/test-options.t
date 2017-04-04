  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > logtemplate={rev}:{node|short}[{bookmarks}] ({obsolete}/{phase}) {desc|firstline}\n
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ hg init repo
  $ cd repo
  $ mkcommit a
  $ mkcommit b

test disabling commands

  $ cat >> .hg/hgrc <<EOF
  > [experimental]
  > evolution=createmarkers
  >   allowunstable
  >   exchange
  > EOF
  $ hg prune | head -n 2
  hg: unknown command 'prune'
  Mercurial Distributed SCM
  
