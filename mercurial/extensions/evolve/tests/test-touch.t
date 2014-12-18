
  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > logtemplate={rev}:{node|short} {desc}\n
  > [defaults]
  > amend=-d "0 0"
  > [extensions]
  > hgext.rebase=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> $HGRCPATH

  $ hg init repo
  $ cd repo
  $ echo A > a
  $ hg add a
  $ hg commit -m a

Basic usage

  $ hg log -G
  @  0:e93df3427f45 a
  
  $ hg touch .
  $ hg log -G
  @  1:[0-9a-f]{12} a (re)
  


Revive usage

  $ echo A > b
  $ hg add b
  $ hg commit -m ab --amend
  $ hg up --hidden 1
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete!
  $ hg log -G
  o  3:[0-9a-f]{12} ab (re)
  
  @  1:[0-9a-f]{12} a (re)
  
  $ hg touch .
  2 new divergent changesets
  $ hg log -G
  @  4:[0-9a-f]{12} a (re)
  
  o  3:[0-9a-f]{12} ab (re)
  
  $ hg prune 3
  1 changesets pruned

Duplicate

  $ hg touch --duplicate .
  $ hg log -G
  @  5:[0-9a-f]{12} a (re)
  
  o  4:[0-9a-f]{12} a (re)
  

Multiple touch

  $ echo C > c
  $ hg add c
  $ hg commit -m c
  $ echo D > d
  $ hg add d
  $ hg commit -m d
  $ hg log -G
  @  7:[0-9a-f]{12} d (re)
  |
  o  6:[0-9a-f]{12} c (re)
  |
  o  5:[0-9a-f]{12} a (re)
  
  o  4:[0-9a-f]{12} a (re)
  
  $ hg touch 6:7
  $ hg log -G
  @  9:[0-9a-f]{12} d (re)
  |
  o  8:[0-9a-f]{12} c (re)
  |
  o  5:[0-9a-f]{12} a (re)
  
  o  4:[0-9a-f]{12} a (re)
  

check move data kept after rebase on touch:

  $ touch gna1
  $ hg commit -Am gna1
  adding gna1
  $ hg mv gna1 gna2
  $ hg commit -m move
  $ hg st -C --change=tip
  A gna2
    gna1
  R gna1
  $ hg up .^
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ hg touch
  1 new unstable changesets

  $ hg rebase -s 11 -d 12
  $ hg st -C --change=tip
  A gna2
    gna1
  R gna1
