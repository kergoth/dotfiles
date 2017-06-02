Set up some configs
  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > rebase=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

Test the instability listing
  $ hg init r2
  $ cd r2
  $ echo a > a && hg ci -Am a
  adding a
  $ echo b > b && hg ci -Am b
  adding b
  $ echo c > c && hg ci -Am c
  adding c
  $ hg up 0
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo a >> a && hg ci --amend -m a
  2 new unstable changesets
  $ hg evolve --list
  d2ae7f538514: b
    unstable: cb9a9f314b8b (obsolete parent)
  
  177f92b77385: c
    unstable: d2ae7f538514 (unstable parent)
  
  $ cd ..

Test the bumpedness listing
  $ hg init r3
  $ cd r3
  $ echo a > a && hg ci -Am a
  adding a
  $ echo b > b && hg ci --amend -m ab
  $ hg phase --public --rev 0 --hidden
  1 new bumped changesets
  $ hg evolve --list
  88cc282e27fc: ab
    bumped: cb9a9f314b8b (immutable precursor)
  
  $ cd ..

Test the divergence listing
  $ hg init r1
  $ cd r1
  $ echo a > a && hg ci -Am a
  adding a
  $ hg up 0
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo b > b && hg ci -Am b
  adding b
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo c > c && hg ci -Am c
  adding c
  created new head
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo d > d && hg ci -Am d
  adding d
  created new head
  $ hg rebase -s 1 -d 2
  rebasing 1:d2ae7f538514 "b"
  $ hg rebase -s 1 -d 3 --hidden --config experimental.allowdivergence=True
  rebasing 1:d2ae7f538514 "b"
  2 new divergent changesets
  $ hg evolve --list
  c882616e9d84: b
    divergent: a922b3733e98 (draft) (precursor d2ae7f538514)
  
  a922b3733e98: b
    divergent: c882616e9d84 (draft) (precursor d2ae7f538514)
  
  $ hg evolve --list --rev c882616e9d84
  c882616e9d84: b
    divergent: a922b3733e98 (draft) (precursor d2ae7f538514)
  
  $ hg phase -p a922b3733e98
  $ hg evolve --list
  c882616e9d84: b
    divergent: a922b3733e98 (public) (precursor d2ae7f538514)
  
  $ cd ..
