  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > logtemplate={rev}:{node|short}[{bookmarks}] ({separate('/', obsolete ,phase)}) {desc|firstline}\n
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
  $ hg phase --public .
  $ mkcommit b
  $ mkcommit c
  $ mkcommit d
  $ mkcommit e
  $ hg bookmarks BABAR
  $ hg log -G
  @  4:9d206ffc875e[BABAR] (draft) add e
  |
  o  3:47d2a3944de8[] (draft) add d
  |
  o  2:4538525df7e2[] (draft) add c
  |
  o  1:7c3bad9141dc[] (draft) add b
  |
  o  0:1f0dee641bb7[] (public) add a
  

Check arguments exclusive to each other
---------------------------------------

  $ hg prune --fold --biject
  abort: can only specify one of biject, fold
  [255]
  $ hg prune --split --fold
  abort: can only specify one of fold, split
  [255]
  $ hg prune --split --fold --biject
  abort: can only specify one of biject, fold, split
  [255]

Check simple case
----------------------------

prune current and tip changeset

  $ hg prune --user blah --date '1979-12-15' .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 47d2a3944de8
  1 changesets pruned
  $ hg bookmark
   * BABAR                     3:47d2a3944de8
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)

prune leaving instability behind

  $ hg prune 1
  1 changesets pruned
  2 new unstable changesets
  $ hg book -i BABAR
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)

pruning multiple changeset at once

(add color output to test it does not crash)

  $ hg prune 2: --color debug
  [ ui.status|0 files updated, 0 files merged, 3 files removed, 0 files unresolved]
  [ ui.status|working directory now at [evolve.node|1f0dee641bb7]]
  [ ui.status|2 changesets pruned]
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)

cannot prune public changesets

  $ hg prune 0
  abort: cannot prune immutable changeset: 1f0dee641bb7
  (see 'hg help phases' for details)
  [255]
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)

Check successors addition
----------------------------

  $ mkcommit bb
  $ mkcommit cc
  $ mkcommit dd
  $ mkcommit ee
  $ hg up 0
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ mkcommit nB
  created new head
  $ mkcommit nC
  $ mkcommit nD
  $ mkcommit nE

  $ hg log -G
  @  12:6e8148413dd5[] (draft) add nE
  |
  o  11:8ee176ff1d4b[] (draft) add nD
  |
  o  10:aa96dc3f04c2[] (draft) add nC
  |
  o  9:6f6f25e4f748[] (draft) add nB
  |
  | o  8:bb5e90a7ea1f[] (draft) add ee
  | |
  | o  7:00ded550b1e2[] (draft) add dd
  | |
  | o  6:354011cd103f[] (draft) add cc
  | |
  | o  5:814c38b95e72[] (draft) add bb
  |/
  o  0:1f0dee641bb7[BABAR] (public) add a
  

one old, one new

  $ hg up 'desc("add ee")'
  4 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ hg prune 'desc("add ee")' -s 'desc("add nE")'
  4 files updated, 0 files merged, 4 files removed, 0 files unresolved
  working directory now at 6e8148413dd5
  1 changesets pruned
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)
  bb5e90a7ea1f3b4b38b23150a4a597b6146d70ef 6e8148413dd541855b72a920a90c06fca127c7e7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg log -G
  @  12:6e8148413dd5[] (draft) add nE
  |
  o  11:8ee176ff1d4b[] (draft) add nD
  |
  o  10:aa96dc3f04c2[] (draft) add nC
  |
  o  9:6f6f25e4f748[] (draft) add nB
  |
  | o  7:00ded550b1e2[] (draft) add dd
  | |
  | o  6:354011cd103f[] (draft) add cc
  | |
  | o  5:814c38b95e72[] (draft) add bb
  |/
  o  0:1f0dee641bb7[BABAR] (public) add a
  

one old, two new

  $ hg prune 'desc("add dd")' -s 'desc("add nD")' -s 'desc("add nC")'
  abort: please add --split if you want to do a split
  [255]
  $ hg prune 'desc("add dd")' -s 'desc("add nD")' -s 'desc("add nC")' --split
  1 changesets pruned
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)
  bb5e90a7ea1f3b4b38b23150a4a597b6146d70ef 6e8148413dd541855b72a920a90c06fca127c7e7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  00ded550b1e28bba454bd34cec1269d22cf3ef25 aa96dc3f04c2c2341fe6880aeb6dc9fbffff9ef9 8ee176ff1d4b2034ce51e3efc579c2de346b631d 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg log -G
  @  12:6e8148413dd5[] (draft) add nE
  |
  o  11:8ee176ff1d4b[] (draft) add nD
  |
  o  10:aa96dc3f04c2[] (draft) add nC
  |
  o  9:6f6f25e4f748[] (draft) add nB
  |
  | o  6:354011cd103f[] (draft) add cc
  | |
  | o  5:814c38b95e72[] (draft) add bb
  |/
  o  0:1f0dee641bb7[BABAR] (public) add a
  

two old, two new (should be denied)

  $ hg prune 'desc("add cc")' 'desc("add bb")' -s 'desc("add nD")' -s 'desc("add nC")'
  abort: Can't use multiple successors for multiple precursors
  (use --biject to mark a series as a replacement for another)
  [255]
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)
  bb5e90a7ea1f3b4b38b23150a4a597b6146d70ef 6e8148413dd541855b72a920a90c06fca127c7e7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  00ded550b1e28bba454bd34cec1269d22cf3ef25 aa96dc3f04c2c2341fe6880aeb6dc9fbffff9ef9 8ee176ff1d4b2034ce51e3efc579c2de346b631d 0 (*) {'ef1': '*', 'user': 'test'} (glob)

two old, one new:

  $ hg prune 'desc("add cc")' 'desc("add bb")' -s 'desc("add nB")'
  abort: please add --fold if you want to do a fold
  [255]
  $ hg prune 'desc("add cc")' 'desc("add bb")' -s 'desc("add nB")' --fold
  2 changesets pruned
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)
  bb5e90a7ea1f3b4b38b23150a4a597b6146d70ef 6e8148413dd541855b72a920a90c06fca127c7e7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  00ded550b1e28bba454bd34cec1269d22cf3ef25 aa96dc3f04c2c2341fe6880aeb6dc9fbffff9ef9 8ee176ff1d4b2034ce51e3efc579c2de346b631d 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  814c38b95e72dfe2cbf675b1649ea9d780c89a80 6f6f25e4f748d8f7571777e6e168aedf50350ce8 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  354011cd103f58bbbd9091a3cee6d6a6bd0dddf7 6f6f25e4f748d8f7571777e6e168aedf50350ce8 0 (*) {'ef1': '*', 'user': 'test'} (glob)

two old, two new with --biject

  $ hg up 0
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ mkcommit n1
  created new head
  $ mkcommit n2

  $ hg prune 'desc("add n1")::desc("add n2")' -s 'desc("add nD")::desc("add nE")' --biject
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  working directory now at 1f0dee641bb7
  2 changesets pruned
  $ hg debugobsolete
  9d206ffc875e1bc304590549be293be36821e66c 0 {47d2a3944de8b013de3be9578e8e344ea2e6c097} (Sat Dec 15 00:00:00 1979 +0000) {'ef1': '*', 'user': 'blah'} (glob)
  7c3bad9141dcb46ff89abf5f61856facd56e476c 0 {1f0dee641bb7258c56bd60e93edfa2405381c41e} (*) {'ef1': '*', 'user': 'test'} (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0 {7c3bad9141dcb46ff89abf5f61856facd56e476c} (*) {'ef1': '*', 'user': 'test'} (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 0 {4538525df7e2b9f09423636c61ef63a4cb872a2d} (*) {'ef1': '*', 'user': 'test'} (glob)
  bb5e90a7ea1f3b4b38b23150a4a597b6146d70ef 6e8148413dd541855b72a920a90c06fca127c7e7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  00ded550b1e28bba454bd34cec1269d22cf3ef25 aa96dc3f04c2c2341fe6880aeb6dc9fbffff9ef9 8ee176ff1d4b2034ce51e3efc579c2de346b631d 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  814c38b95e72dfe2cbf675b1649ea9d780c89a80 6f6f25e4f748d8f7571777e6e168aedf50350ce8 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  354011cd103f58bbbd9091a3cee6d6a6bd0dddf7 6f6f25e4f748d8f7571777e6e168aedf50350ce8 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  cb7f8f706a6532967b98cf8583a81baab79a0fa7 8ee176ff1d4b2034ce51e3efc579c2de346b631d 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  21b6f2f1cece8c10326e575dd38239189d467190 6e8148413dd541855b72a920a90c06fca127c7e7 0 (*) {'ef1': '*', 'user': 'test'} (glob)

test hg strip replacement

  $ hg up 10
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ mkcommit n1
  created new head
  $ mkcommit n2
  $ hg --config extensions.strip= --config experimental.prunestrip=True strip -r .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at c7e58696a948
  1 changesets pruned
  $ hg --config extensions.strip= --config experimental.prunestrip=True strip -r . --bundle
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  saved backup bundle to $TESTTMP/repo/.hg/strip-backup/c7e58696a948-69ca36d3-backup.hg (glob)

test hg prune --keep
  $ mkcommit n1
  created new head
  $ hg diff -r .^
  diff -r aa96dc3f04c2 n1
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/n1	* +0000 (glob)
  @@ -0,0 +1,1 @@
  +n1
  $ hg prune -r . --keep
  1 changesets pruned
  $ hg status
  ? n1

test hg prune -B bookmark
yoinked from test-mq-strip.t

  $ cd ..
  $ hg init bookmarks
  $ cd bookmarks
  $ hg debugbuilddag '..<2.*1/2:m<2+3:c<m+3:a<2.:b<m+2:d<2.:e<m+1:f'
  $ hg bookmark -r 'a' 'todelete'
  $ hg bookmark -r 'b' 'B'
  $ hg bookmark -r 'b' 'nostrip'
  $ hg bookmark -r 'c' 'delete'
  $ hg bookmark -r 'd' 'multipledelete1'
  $ hg bookmark -r 'e' 'multipledelete2'
  $ hg bookmark -r 'f' 'singlenode1'
  $ hg bookmark -r 'f' 'singlenode2'
  $ hg up -C todelete
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (activating bookmark todelete)
  $ hg prune -B nostrip
  bookmark 'nostrip' deleted
  abort: nothing to prune
  [255]
  $ hg tag --remove --local a
  $ hg prune -B todelete
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (leaving bookmark todelete)
  working directory now at d62d843c9a01
  bookmark 'todelete' deleted
  1 changesets pruned
  $ hg id -ir dcbb326fdec2
  abort: hidden revision 'dcbb326fdec2'!
  (use --hidden to access hidden revisions; pruned)
  [255]
  $ hg id -ir d62d843c9a01
  d62d843c9a01
  $ hg bookmarks
     B                         10:ff43616e5d0f
     delete                    6:2702dd0c91e7
     multipledelete1           12:e46a4836065c
     multipledelete2           13:b4594d867745
     singlenode1               14:43227190fef8
     singlenode2               14:43227190fef8
  $ hg prune -B multipledelete1 -B multipledelete2
  bookmark 'multipledelete1' deleted
  bookmark 'multipledelete2' deleted
  2 changesets pruned
  $ hg prune -B singlenode1 -B singlenode2
  bookmark 'singlenode1' deleted
  bookmark 'singlenode2' deleted
  1 changesets pruned
  $ hg prune -B unknownbookmark
  abort: bookmark 'unknownbookmark' not found
  [255]
  $ hg prune -B unknownbookmark1 -B unknownbookmark2
  abort: bookmark 'unknownbookmark1,unknownbookmark2' not found
  [255]
  $ hg prune -B delete -B unknownbookmark
  abort: bookmark 'unknownbookmark' not found
  [255]
  $ hg prune -B delete
  bookmark 'delete' deleted
  3 changesets pruned
  $ hg tag --remove --local c
  $ hg id -ir 6:2702dd0c91e7
  abort: hidden revision '6'!
  (use --hidden to access hidden revisions; pruned)
  [255]

  $ hg debugobsstorestat
  markers total:                      7
      for known precursors:           7 (7/15 obsolete changesets)
      with parents data:              [04] (re)
  markers with no successors:         7
                1 successors:         0
                2 successors:         0
      more than 2 successors:         0
      available  keys:
                  ef1:                7
                 user:                7
  marker size:
      format v1:
          smallest length:           75
          longer length:             75
          median length:             75
          mean length:               75
      format v0:
          smallest length:          * (glob)
          longer length:            * (glob)
          median length:            * (glob)
          mean length:              * (glob)
  disconnected clusters:              7
          any known node:             7
          smallest length:            1
          longer length:              1
          median length:              1
          mean length:                1
      using parents data:             7
          any known node:             7
          smallest length:            1
          longer length:              1
          median length:              1
          mean length:                1

  $ mkcommit rg
  created new head
  $ hg bookmark rg
  $ hg up 10
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  (leaving bookmark rg)
  $ hg bookmark r10
  $ hg log -G
  o  15:cd0038e05e1b[rg] (draft) add rg
  |
  | x  14:43227190fef8[] (obsolete/draft) r14
  | |
  | | x  13:b4594d867745[] (obsolete/draft) r13
  | | |
  | | | x  12:e46a4836065c[] (obsolete/draft) r12
  | | |/
  | | o  11:bab5d5bf48bd[] (draft) r11
  | |/
  +---@  10:ff43616e5d0f[B r10] (draft) r10
  | |
  o |  8:d62d843c9a01[] (draft) r8
  | |
  o |  7:e7d9710d9fc6[] (draft) r7
  |/
  o    3:2b6d669947cd[] (draft) r3
  |\
  | o  2:fa942426a6fd[] (draft) r2
  | |
  o |  1:66f7d451a68b[] (draft) r1
  |/
  o  0:1ea73414a91b[] (draft) r0
  
  $ hg prune 11
  1 changesets pruned
  $ hg log -G
  o  15:cd0038e05e1b[rg] (draft) add rg
  |
  | x  14:43227190fef8[] (obsolete/draft) r14
  | |
  | | x  13:b4594d867745[] (obsolete/draft) r13
  | | |
  | | | x  12:e46a4836065c[] (obsolete/draft) r12
  | | |/
  | | x  11:bab5d5bf48bd[] (obsolete/draft) r11
  | |/
  +---@  10:ff43616e5d0f[B r10] (draft) r10
  | |
  o |  8:d62d843c9a01[] (draft) r8
  | |
  o |  7:e7d9710d9fc6[] (draft) r7
  |/
  o    3:2b6d669947cd[] (draft) r3
  |\
  | o  2:fa942426a6fd[] (draft) r2
  | |
  o |  1:66f7d451a68b[] (draft) r1
  |/
  o  0:1ea73414a91b[] (draft) r0
  
  $ hg book CELESTE
  $ hg prune -r . --keep
  1 changesets pruned
  $ hg book
     B                         8:d62d843c9a01
   * CELESTE                   8:d62d843c9a01
     r10                       8:d62d843c9a01
     rg                        15:cd0038e05e1b

