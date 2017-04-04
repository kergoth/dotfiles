test for range based discovery
==============================

  $ . $TESTDIR/testlib/pythonpath.sh

  $ cat << EOF >> $HGRCPATH
  > [extensions]
  > hgext3rd.evolve =
  > [experimental]
  > obshashrange=1
  > verbose-obsolescence-exchange=1
  > [ui]
  > logtemplate = "{rev} {node|short} {desc} {tags}\n"
  > ssh=python "$RUNTESTDIR/dummyssh"
  > [alias]
  > debugobsolete=debugobsolete -d '0 0'
  > EOF

  $ getid() {
  >     hg log --hidden --template '{node}\n' --rev "$1"
  > }

  $ hg init server
  $ hg clone ssh://user@dummy/server client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd server
  $ hg debugbuilddag '.+7'
  $ hg log -G
  o  7 4de32a90b66c r7 tip
  |
  o  6 f69452c5b1af r6
  |
  o  5 c8d03c1b5e94 r5
  |
  o  4 bebd167eb94d r4
  |
  o  3 2dc09a01254d r3
  |
  o  2 01241442b3c2 r2
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  

  $ hg debugobsolete aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa `getid 'desc(r1)'`
  $ hg debugobsolete bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb `getid 'desc(r2)'`
  $ hg debugobsolete cccccccccccccccccccccccccccccccccccccccc `getid 'desc(r4)'`
  $ hg debugobsolete dddddddddddddddddddddddddddddddddddddddd `getid 'desc(r5)'`
  $ hg debugobsolete eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee `getid 'desc(r7)'`
  $ hg debugobsolete
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee 4de32a90b66cd083ebf3c00b41277aa7abca51dd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

  $ hg debugobshashrange --subranges --rev tip
           rev         node        index         size        depth      obshash
             7 4de32a90b66c            0            8            8 38d1e7ad86ea
             3 2dc09a01254d            0            4            4 000000000000
             7 4de32a90b66c            4            4            8 38d1e7ad86ea
             3 2dc09a01254d            2            2            4 000000000000
             7 4de32a90b66c            6            2            8 033544c939f0
             1 66f7d451a68b            0            2            2 17ff8dd63509
             5 c8d03c1b5e94            4            2            6 57f6cf3757a2
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 000000000000
             7 4de32a90b66c            7            1            8 033544c939f0
             1 66f7d451a68b            1            1            2 17ff8dd63509
             4 bebd167eb94d            4            1            5 bbe4d7fe27a8
             5 c8d03c1b5e94            5            1            6 446c2dc3bce5
             6 f69452c5b1af            6            1            7 000000000000
  $ cd .. 

testing simple pull
===================

  $ cd client
  $ hg pull --rev 4
  pulling from ssh://user@dummy/server
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 0 changes to 0 files
  3 new obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg -R ../server/ debugobsolete --rev ::4 | sort
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsolete | sort
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

testing simple push
===================

  $ hg up
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo foo > foo
  $ hg add foo
  $ hg commit -m foo
  $ hg debugobsolete ffffffffffffffffffffffffffffffffffffffff `getid '.'`
  $ hg push -f
  pushing to ssh://user@dummy/server
  searching for changes
  OBSEXC: computing relevant nodes
  OBSEXC: looking for common markers in 6 nodes
  OBSEXC: computing markers relevant to 1 nodes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: 1 new obsolescence markers

testing push with extra local markers
=====================================

  $ hg log -G
  @  5 45f8b879de92 foo tip
  |
  o  4 bebd167eb94d r4
  |
  o  3 2dc09a01254d r3
  |
  o  2 01241442b3c2 r2
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  
  $ hg debugobsolete 111111111111111aaaaaaaaa1111111111111111 `getid 'desc(r1)'`
  $ hg debugobsolete 22222222222222222bbbbbbbbbbbbb2222222222 `getid 'desc(r3)'`
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  OBSEXC: computing relevant nodes
  OBSEXC: looking for common markers in 6 nodes
  OBSEXC: computing markers relevant to 2 nodes
  no changes found
  remote: 2 new obsolescence markers
  [1]
  $ hg -R ../server/ debugobsolete --rev ::tip | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  ffffffffffffffffffffffffffffffffffffffff 45f8b879de922f6a6e620ba04205730335b6fc7e 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsolete | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  ffffffffffffffffffffffffffffffffffffffff 45f8b879de922f6a6e620ba04205730335b6fc7e 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

testing pull with extra remote markers
=====================================

  $ hg log -G
  @  5 45f8b879de92 foo tip
  |
  o  4 bebd167eb94d r4
  |
  o  3 2dc09a01254d r3
  |
  o  2 01241442b3c2 r2
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  
  $ hg -R ../server debugobsolete aaaaaaa11111111aaaaaaaaa1111111111111111 `getid 'desc(r1)'`
  $ hg -R ../server debugobsolete bbbbbbb2222222222bbbbbbbbbbbbb2222222222 `getid 'desc(r4)'`
  $ hg pull -r 6
  pulling from ssh://user@dummy/server
  searching for changes
  OBSEXC: looking for common markers in 6 nodes
  OBSEXC: request obsmarkers for 2 common nodes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 0 changes to 0 files (+1 heads)
  3 new obsolescence markers
  (run 'hg heads' to see heads, 'hg merge' to merge)

  $ hg -R ../server/ debugobsolete --rev '::6' | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaa11111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbb2222222222bbbbbbbbbbbbb2222222222 bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg debugobsolete --rev '::6' | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaa11111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbb2222222222bbbbbbbbbbbbb2222222222 bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

