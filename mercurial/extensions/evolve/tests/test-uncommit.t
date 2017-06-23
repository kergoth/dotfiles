  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ glog() {
  >   hg glog --template '{rev}:{node|short}@{branch}({separate("/", obsolete, phase)}) {desc|firstline}\n' "$@"
  > }

  $ hg init repo
  $ cd repo

Cannot uncommit null changeset

  $ hg uncommit
  abort: cannot rewrite immutable changeset
  [255]

Cannot uncommit public changeset

  $ echo a > a
  $ hg ci -Am adda a
  $ hg phase --public .
  $ hg uncommit
  abort: cannot rewrite immutable changeset
  [255]
  $ hg phase --force --draft .

Cannot uncommit merge

  $ hg up -q null
  $ echo b > b
  $ echo c > c
  $ echo d > d
  $ echo f > f
  $ echo g > g
  $ echo j > j
  $ echo m > m
  $ echo n > n
  $ echo o > o
  $ hg ci -Am addmore
  adding b
  adding c
  adding d
  adding f
  adding g
  adding j
  adding m
  adding n
  adding o
  created new head
  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg uncommit
  abort: cannot uncommit while merging
  [255]
  $ hg ci -m merge
  $ hg uncommit
  abort: cannot uncommit merge changeset
  [255]

Prepare complicated changeset

  $ hg branch bar
  marked working directory as branch bar
  (branches are permanent and global, did you want a bookmark?)
  $ hg cp a aa
  $ echo b >> b
  $ hg rm c
  $ echo d >> d
  $ echo e > e
  $ hg mv f ff
  $ hg mv g h
  $ echo j >> j
  $ echo k > k
  $ echo l > l
  $ hg rm m
  $ hg rm n
  $ echo o >> o
  $ hg ci -Am touncommit
  adding e
  adding k
  adding l
  $ hg st --copies --change .
  M b
  M d
  M j
  M o
  A aa
    a
  A e
  A ff
    f
  A h
    g
  A k
  A l
  R c
  R f
  R g
  R m
  R n
  $ hg man -r .
  a
  aa
  b
  d
  e
  ff
  h
  j
  k
  l
  o

Add a couple of bookmarks

  $ glog --hidden
  @  3:5eb72dbe0cb4@bar(draft) touncommit
  |
  o    2:f63b90038565@default(draft) merge
  |\
  | o  1:f15c744d48e8@default(draft) addmore
  |
  o  0:07f494440405@default(draft) adda
  
  $ hg bookmark -r 2 unrelated
  $ hg bookmark touncommit-bm
  $ hg bookmark --inactive touncommit-bm-inactive
  $ hg bookmarks
   * touncommit-bm             3:5eb72dbe0cb4
     touncommit-bm-inactive    3:5eb72dbe0cb4
     unrelated                 2:f63b90038565

Prepare complicated working directory

  $ hg branch foo
  marked working directory as branch foo
  $ hg mv ff f
  $ hg mv h i
  $ hg rm j
  $ hg rm k
  $ echo l >> l
  $ echo m > m
  $ echo o > o

Test uncommit without argument, should be a no-op

  $ hg uncommit
  abort: nothing to uncommit
  (use --all to uncommit all files)
  [255]
  $ hg bookmarks
   * touncommit-bm             3:5eb72dbe0cb4
     touncommit-bm-inactive    3:5eb72dbe0cb4
     unrelated                 2:f63b90038565

Test no matches

  $ hg uncommit --include nothere
  abort: nothing to uncommit
  (use --all to uncommit all files)
  [255]

Enjoy uncommit

  $ hg uncommit aa b c f ff g h j k l m o
  $ hg branch
  foo
  $ hg st --copies
  M b
  A aa
    a
  A i
    g
  A l
  R c
  R g
  R j
  R m
  $ cat aa
  a
  $ cat b
  b
  b
  $ cat l
  l
  l
  $ cat m
  m
  $ test -f c && echo 'error: c was removed!'
  [1]
  $ test -f j && echo 'error: j was removed!'
  [1]
  $ test -f k && echo 'error: k was removed!'
  [1]
  $ hg st --copies --change .
  M d
  A e
  R n
  $ hg man -r .
  a
  b
  c
  d
  e
  f
  g
  j
  m
  o
  $ hg cat -r . d
  d
  d
  $ hg cat -r . e
  e
  $ glog --hidden
  @  4:e8db4aa611f6@bar(draft) touncommit
  |
  | x  3:5eb72dbe0cb4@bar(obsolete/draft) touncommit
  |/
  o    2:f63b90038565@default(draft) merge
  |\
  | o  1:f15c744d48e8@default(draft) addmore
  |
  o  0:07f494440405@default(draft) adda
  
  $ hg bookmarks
   * touncommit-bm             4:e8db4aa611f6
     touncommit-bm-inactive    4:e8db4aa611f6
     unrelated                 2:f63b90038565
  $ hg debugobsolete
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 e8db4aa611f6d5706374288e6898e498f5c44098 0 (*) {'ef1': '*', 'user': 'test'} (glob)

Test phase is preserved, no local changes

  $ hg up -C 3 --hidden
  8 files updated, 0 files merged, 1 files removed, 0 files unresolved
  (leaving bookmark touncommit-bm)
  working directory parent is obsolete! (5eb72dbe0cb4)
  (use 'hg evolve' to update to its successor: e8db4aa611f6)
  $ hg --config extensions.purge= purge
  $ hg uncommit -I 'set:added() and e'
  2 new divergent changesets
  $ hg st --copies
  A e
  $ hg st --copies --change .
  M b
  M d
  M j
  M o
  A aa
    a
  A ff
    f
  A h
    g
  A k
  A l
  R c
  R f
  R g
  R m
  R n
  $ glog --hidden
  @  5:a1d4c1ad76cc@bar(draft) touncommit
  |
  | o  4:e8db4aa611f6@bar(draft) touncommit
  |/
  | x  3:5eb72dbe0cb4@bar(obsolete/draft) touncommit
  |/
  o    2:f63b90038565@default(draft) merge
  |\
  | o  1:f15c744d48e8@default(draft) addmore
  |
  o  0:07f494440405@default(draft) adda
  
  $ hg debugobsolete
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 e8db4aa611f6d5706374288e6898e498f5c44098 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 a1d4c1ad76cc7eb5e8a36ef52396da334b6d59c5 0 (*) {'ef1': '*', 'user': 'test'} (glob)

Test --all

  $ hg up -C 3 --hidden
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (5eb72dbe0cb4)
  (5eb72dbe0cb4 has diverged, use 'hg evolve --list --divergent' to resolve the issue)
  $ hg --config extensions.purge= purge
  $ hg uncommit --all -X e
  1 new divergent changesets
  $ hg st --copies
  M b
  M d
  M j
  M o
  A aa
    a
  A ff
    f
  A h
    g
  A k
  A l
  R c
  R f
  R g
  R m
  R n
  $ hg st --copies --change .
  A e

  $ hg debugobsolete
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 e8db4aa611f6d5706374288e6898e498f5c44098 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 a1d4c1ad76cc7eb5e8a36ef52396da334b6d59c5 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 c4cbebac3751269bdf12d1466deabcc78521d272 0 (*) {'ef1': '*', 'user': 'test'} (glob)

Display a warning if nothing left

  $ hg uncommit e
  new changeset is empty
  (use 'hg prune .' to remove it)
  $ hg debugobsolete
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 e8db4aa611f6d5706374288e6898e498f5c44098 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 a1d4c1ad76cc7eb5e8a36ef52396da334b6d59c5 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5eb72dbe0cb409d094e3b4ae8eaa30071c1b8730 c4cbebac3751269bdf12d1466deabcc78521d272 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  c4cbebac3751269bdf12d1466deabcc78521d272 4f1c269eab68720f54e88ce3c1dc02b2858b6b89 0 (*) {'ef1': '*', 'user': 'test'} (glob)

Test instability warning

  $ hg ci -m touncommit
  $ echo unrelated > unrelated
  $ hg ci -Am addunrelated unrelated
  $ hg previous
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [8] touncommit
  $ hg uncommit aa
  1 new unstable changesets

Test uncommiting agains a different base

  $ hg cat b --rev .
  b
  b
  $ hg cat b --rev .^
  b
  $ hg cat b --rev 0
  b: no such file in rev 07f494440405
  [1]
  $ hg uncommit --rev . b
  abort: cannot uncommit to parent changeset
  [255]
  $ hg uncommit --rev 0 b
  $ hg cat b --rev .
  b: no such file in rev 5b27f6b17da2
  [1]

Test uncommiting precursors

  $ hg uncommit --hidden --rev 'precursors(.)' b
  $ hg cat b --rev .
  b
  b
