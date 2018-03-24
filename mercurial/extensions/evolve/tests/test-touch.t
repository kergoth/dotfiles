
  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > logtemplate={rev}:{node|short} {desc}\n
  > [defaults]
  > amend=-d "0 0"
  > [extensions]
  > hgext.rebase=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ hg init repo
  $ cd repo
  $ echo A > a
  $ hg add a
  $ hg commit -m a

Basic usage

  $ hg log -G
  @  0:[0-9a-f]{12} a (re)
  
  $ hg touch .
  $ hg log -G
  @  1:[0-9a-f]{12} a (re)
  


Revive usage

  $ echo A > b
  $ hg add b
  $ hg commit -m ab --amend
  $ hg up --hidden 1
  updating to a hidden changeset [0-9a-f]{12} (re)
  (hidden revision '*' was rewritten as: *) (glob)
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (*) (glob)
  (use 'hg evolve' to update to its successor: *) (glob)
  $ hg log -G
  o  2:[0-9a-f]{12} ab (re)
  
  @  1:[0-9a-f]{12} a (re)
  
  $ hg touch .
  [1] a
  reviving this changeset will create divergence unless you make a duplicate.
  (a)llow divergence or (d)uplicate the changeset?  a
  2 new content-divergent changesets
  $ hg log -G
  @  3:[0-9a-f]{12} a (re)
  
  \*  2:[0-9a-f]{12} ab (re)
  
  $ hg prune 3
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 000000000000
  1 changesets pruned

Duplicate

  $ hg touch --duplicate .
  $ hg log -G
  @  4:[0-9a-f]{12} (re)
  
  o  2:[0-9a-f]{12} ab (re)
  

Multiple touch

  $ echo C > c
  $ hg add c
  $ hg commit -m c
  $ echo D > d
  $ hg add d
  $ hg commit -m d
  $ hg log -G
  @  6:[0-9a-f]{12} d (re)
  |
  o  5:[0-9a-f]{12} c (re)
  |
  o  4:[0-9a-f]{12} (re)
  
  o  2:[0-9a-f]{12} ab (re)
  
  $ hg touch .^:.
  $ hg log -G
  @  8:[0-9a-f]{12} d (re)
  |
  o  7:[0-9a-f]{12} c (re)
  |
  o  4:[0-9a-f]{12} (re)
  
  o  2:[0-9a-f]{12} ab (re)
  

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
  1 new orphan changesets

  $ hg log -G --hidden
  @  11:[0-9a-f]{12} gna1 (re)
  |
  . \*  10:[0-9a-f]{12} move (re)
  | |
  . x  9:[0-9a-f]{12} gna1 (re)
  |/
  o  8:[0-9a-f]{12} d (re)
  |
  o  7:[0-9a-f]{12} c (re)
  |
  . x  6:[0-9a-f]{12} d (re)
  | |
  . x  5:[0-9a-f]{12} c (re)
  |/
  o  4:[0-9a-f]{12} (re)
  
  x  3:[0-9a-f]{12} a (re)
  
  o  2:[0-9a-f]{12} ab (re)
  
  x  1:[0-9a-f]{12} a (re)
  
  x  0:[0-9a-f]{12} a (re)
  

  $ hg rebase -s 10 -d 11
  rebasing 10:[0-9a-f]{12} "move" (re)
  $ hg st -C --change=tip
  A gna2
    gna1
  R gna1

check that the --duplicate option does not create divergence

  $ hg touch --duplicate 10 --hidden
  1 new orphan changesets

check that reviving a changeset with no successor does not show the prompt

  $ hg prune 13
  1 changesets pruned
  $ hg touch 13 --hidden --note "testing with no successor"
  1 new orphan changesets
  $ hg obslog -r 13 --hidden
  x  [0-9a-f]{12} (.*) move (re)
       pruned using prune by test (Thu Jan 01 00:00:00 1970 +0000)
       rewritten(.*) as [0-9a-f]{12} using touch by test (.*) (re)
         note: testing with no successor
  
