  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [extensions]
  > hgext.rebase=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ glog() {
  >   hg log -G --template \
  >     '{rev}:{node|short}@{branch}({phase}) bk:[{bookmarks}] {desc|firstline}\n' "$@"
  > }

Test evolve removing the changeset being evolved

  $ hg init empty
  $ cd empty
  $ echo a > a
  $ hg ci -Am adda a
  $ echo b > b
  $ hg ci -Am addb b
  $ echo a >> a
  $ hg ci -m changea
  $ hg bookmark changea
  $ hg up 1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (leaving bookmark changea)
  $ echo a >> a
  $ hg amend -m changea
  1 new orphan changesets
  $ hg evolve -v --confirm
  move:[2] changea
  atop:[3] changea
  perform evolve? [Ny] n
  abort: evolve aborted by user
  [255]
  $ echo y | hg evolve -v --confirm --config ui.interactive=True
  move:[2] changea
  atop:[3] changea
  perform evolve? [Ny] y
  hg rebase -r cce2c55b8965 -d fb9d051ec0a4
  resolving manifests
  $ glog --hidden
  @  3:fb9d051ec0a4@default(draft) bk:[changea] changea
  |
  | x  2:cce2c55b8965@default(draft) bk:[] changea
  | |
  | x  1:102a90ea7b4a@default(draft) bk:[] addb
  |/
  o  0:07f494440405@default(draft) bk:[] adda
  
  $ hg debugobsolete
  102a90ea7b4a3361e4082ed620918c261189a36a fb9d051ec0a450a4aa2ffc8c324979832ef88065 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  cce2c55b896511e0b6e04173c9450ba822ebc740 0 {102a90ea7b4a3361e4082ed620918c261189a36a} (*) {'ef1': '*', 'user': 'test'} (glob)

Test evolve with conflict

  $ ls
  a
  b
  $ hg pdiff a
  diff -r 07f494440405 a
  --- a/a	* (glob)
  +++ b/a	* (glob)
  @@ -1,1 +1,2 @@
   a
  +a
  $ echo 'newer a' >> a
  $ hg ci -m 'newer a'
  $ hg gdown
  gdown have been deprecated in favor of previous
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [3] changea
  $ echo 'a' > a
  $ hg amend
  1 new orphan changesets
  $ hg evolve
  move:[4] newer a
  atop:[5] changea
  merging a
  warning: conflicts while merging a! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]
  $ hg revert -r "orphan()" a
  $ hg diff
  diff -r 66719795a494 a
  --- a/a	* (glob)
  +++ b/a	* (glob)
  @@ -1,1 +1,3 @@
   a
  +a
  +newer a
  $ hg evolve --continue
  evolving 4:3655f0f50885 "newer a"
  abort: unresolved merge conflicts (see 'hg help resolve')
  [255]
  $ hg resolve -m a
  (no more unresolved files)
  $ hg evolve --continue
  evolving 4:3655f0f50885 "newer a"

Stabilize latecomer with different parent
=========================================

(the same-parent case is handled in test-evolve.t)

  $ glog
  @  6:1cf0aacfd363@default(draft) bk:[] newer a
  |
  o  5:66719795a494@default(draft) bk:[changea] changea
  |
  o  0:07f494440405@default(draft) bk:[] adda
  
Add another commit

  $ hg gdown
  gdown have been deprecated in favor of previous
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [5] changea
  $ echo 'c' > c
  $ hg add c
  $ hg commit -m 'add c'
  created new head

Get a successors of 8 on it

  $ hg grab 1cf0aacfd363
  rebasing 6:1cf0aacfd363 "newer a"
  ? files updated, 0 files merged, 0 files removed, 0 files unresolved (glob)

Add real change to the successors

  $ echo 'babar' >> a
  $ hg amend

Make precursors public

  $ hg phase --hidden --public 1cf0aacfd363
  1 new phase-divergent changesets
  $ glog
  @  9:(73b15c7566e9|d5c7ef82d003)@default\(draft\) bk:\[\] newer a (re)
  |
  o  7:7bc2f5967f5e@default(draft) bk:[] add c
  |
  | o  6:1cf0aacfd363@default(public) bk:[] newer a
  |/
  o  5:66719795a494@default(public) bk:[changea] changea
  |
  o  0:07f494440405@default(public) bk:[] adda
  

Stabilize!

  $ hg evolve --any --dry-run --phase-divergent
  recreate:[9] newer a
  atop:[6] newer a
  hg rebase --rev d5c7ef82d003 --dest 66719795a494;
  hg update 1cf0aacfd363;
  hg revert --all --rev d5c7ef82d003;
  hg commit --msg "phase-divergent update to d5c7ef82d003"
  $ hg evolve --any --confirm --phase-divergent
  recreate:[9] newer a
  atop:[6] newer a
  perform evolve? [Ny] n
  abort: evolve aborted by user
  [255]
  $ echo y | hg evolve --any --confirm --config ui.interactive=True --phase-divergent
  recreate:[9] newer a
  atop:[6] newer a
  perform evolve? [Ny] y
  rebasing to destination parent: 66719795a494
  computing new diff
  committed as 8c986e77913c
  working directory is now at 8c986e77913c
  $ glog
  @  11:8c986e77913c@default(draft) bk:[] phase-divergent update to 1cf0aacfd363:
  |
  | o  7:7bc2f5967f5e@default(draft) bk:[] add c
  | |
  o |  6:1cf0aacfd363@default(public) bk:[] newer a
  |/
  o  5:66719795a494@default(public) bk:[changea] changea
  |
  o  0:07f494440405@default(public) bk:[] adda
  

Stabilize divergent changesets with same parent
===============================================

  $ rm a.orig
  $ hg up 7bc2f5967f5e
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat << EOF >> a
  > flore
  > arthur
  > zephir
  > some
  > less
  > conflict
  > EOF
  $ hg ci -m 'More addition'
  $ glog
  @  12:3932c176bbaa@default(draft) bk:[] More addition
  |
  | o  11:8c986e77913c@default(draft) bk:[] phase-divergent update to 1cf0aacfd363:
  | |
  o |  7:7bc2f5967f5e@default(draft) bk:[] add c
  | |
  | o  6:1cf0aacfd363@default(public) bk:[] newer a
  |/
  o  5:66719795a494@default(public) bk:[changea] changea
  |
  o  0:07f494440405@default(public) bk:[] adda
  
  $ echo 'babar' >> a
  $ hg amend
  $ hg up --hidden 3932c176bbaa
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (3932c176bbaa)
  (use 'hg evolve' to update to its successor: d2f173e25686)
  $ mv a a.old
  $ echo 'jungle' > a
  $ cat a.old >> a
  $ rm a.old
  $ hg amend
  2 new content-divergent changesets
  $ glog
  @  14:eacc9c8240fe@default(draft) bk:[] More addition
  |
  | o  13:d2f173e25686@default(draft) bk:[] More addition
  |/
  | o  11:8c986e77913c@default(draft) bk:[] phase-divergent update to 1cf0aacfd363:
  | |
  o |  7:7bc2f5967f5e@default(draft) bk:[] add c
  | |
  | o  6:1cf0aacfd363@default(public) bk:[] newer a
  |/
  o  5:66719795a494@default(public) bk:[changea] changea
  |
  o  0:07f494440405@default(public) bk:[] adda
  

Stabilize it

  $ hg evolve -qn --confirm --content-divergent
  merge:[14] More addition
  with: [13] More addition
  base: [12] More addition
  perform evolve? [Ny] n
  abort: evolve aborted by user
  [255]
  $ echo y | hg evolve -qn --confirm --config ui.interactive=True --content-divergent
  merge:[14] More addition
  with: [13] More addition
  base: [12] More addition
  perform evolve? [Ny] y
  hg update -c eacc9c8240fe &&
  hg merge d2f173e25686 &&
  hg commit -m "auto merge resolving conflict between eacc9c8240fe and d2f173e25686"&&
  hg up -C 3932c176bbaa &&
  hg revert --all --rev tip &&
  hg commit -m "`hg log -r eacc9c8240fe --template={desc}`";
  $ hg evolve -v --content-divergent
  merge:[14] More addition
  with: [13] More addition
  base: [12] More addition
  merging content-divergent changeset
  resolving manifests
  merging a
  0 files updated, 1 files merged, 0 files removed, 0 files unresolved
  amending changeset eacc9c8240fe
  committing files:
  a
  committing manifest
  committing changelog
  committed changeset 15:f344982e63c4
  working directory is now at f344982e63c4
  $ hg st
  $ glog
  @  15:f344982e63c4@default(draft) bk:[] More addition
  |
  | o  11:8c986e77913c@default(draft) bk:[] phase-divergent update to 1cf0aacfd363:
  | |
  o |  7:7bc2f5967f5e@default(draft) bk:[] add c
  | |
  | o  6:1cf0aacfd363@default(public) bk:[] newer a
  |/
  o  5:66719795a494@default(public) bk:[changea] changea
  |
  o  0:07f494440405@default(public) bk:[] adda
  
  $ hg summary
  parent: 15:f344982e63c4 tip
   More addition
  branch: default
  commit: (clean)
  update: 2 new changesets, 2 branch heads (merge)
  phases: 3 draft
  $ hg export .
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID f344982e63c462b1e44c0371c804685389e673a9
  # Parent  7bc2f5967f5e4ed277f60a89b7b04cc5d6407ced
  More addition
  
  diff -r 7bc2f5967f5e -r f344982e63c4 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,1 +1,9 @@
  +jungle
   a
  +flore
  +arthur
  +zephir
  +some
  +less
  +conflict
  +babar

Check conflict during divergence resolution
-------------------------------------------------

  $ hg up --hidden 3932c176bbaa
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (3932c176bbaa)
  (use 'hg evolve' to update to its successor: f344982e63c4)
  $ echo 'gotta break' >> a
  $ hg amend
  2 new content-divergent changesets
# reamend so that the case is not the first precursor.
  $ hg amend -m "More addition (2)"
  $ hg phase 'contentdivergent()'
  15: draft
  17: draft
  $ hg evolve -qn --content-divergent
  hg update -c 0b336205a5d0 &&
  hg merge f344982e63c4 &&
  hg commit -m "auto merge resolving conflict between 0b336205a5d0 and f344982e63c4"&&
  hg up -C 3932c176bbaa &&
  hg revert --all --rev tip &&
  hg commit -m "`hg log -r 0b336205a5d0 --template={desc}`";
  $ hg evolve --content-divergent
  merge:[17] More addition (2)
  with: [15] More addition
  base: [12] More addition
  merging a
  warning: conflicts while merging a! (edit, then use 'hg resolve --mark')
  0 files updated, 0 files merged, 0 files removed, 1 files unresolved
  use 'hg resolve' to retry unresolved file merges or 'hg update -C .' to abort
  abort: merge conflict between several amendments (this is not automated yet)
  (/!\ You can try:
  /!\ * manual merge + resolve => new cset X
  /!\ * hg up to the parent of the amended changeset (which are named W and Z)
  /!\ * hg revert --all -r X
  /!\ * hg ci -m "same message as the amended changeset" => new cset Y
  /!\ * hg prune -n Y W Z
  )
  [255]
