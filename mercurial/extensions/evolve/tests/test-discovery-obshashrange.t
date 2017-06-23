test for range based discovery
==============================

  $ . $TESTDIR/testlib/pythonpath.sh

  $ cat << EOF >> $HGRCPATH
  > [extensions]
  > hgext3rd.evolve =
  > blackbox =
  > [defaults]
  > blackbox = -l 100
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
  >     hg log --hidden --template '{node}\n' --rev "$1" --config 'extensions.blackbox=!'
  > }

  $ hg init server
  $ hg clone ssh://user@dummy/server client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd server
  $ hg debugbuilddag '.+7'
  $ hg blackbox
  * @0000000000000000000000000000000000000000 (*)> serve --stdio (glob)
  * @0000000000000000000000000000000000000000 (*)> -R server serve --stdio exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugbuilddag .+7 (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (8r, 0o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (8r, 0o) (glob)
  * @0000000000000000000000000000000000000000 (*)> debugbuilddag .+7 exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm .hg/blackbox.log
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
  $ hg debugobsolete bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb `getid 'desc(r2)'` --config experimental.obshashrange.max-revs=1
  $ hg debugobsolete cccccccccccccccccccccccccccccccccccccccc `getid 'desc(r4)'`
  $ hg debugobsolete dddddddddddddddddddddddddddddddddddddddd `getid 'desc(r5)'` --config experimental.obshashrange.warm-cache=0
  $ hg debugobsolete eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee `getid 'desc(r7)'`
  $ hg debugobsolete
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee 4de32a90b66cd083ebf3c00b41277aa7abca51dd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

  $ hg blackbox
  * @0000000000000000000000000000000000000000 (*)> log -G (glob)
  * @0000000000000000000000000000000000000000 (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @0000000000000000000000000000000000000000 (*)> log -G exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 --config 'experimental.obshashrange.max-revs=1' exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 2o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 --config 'experimental.obshashrange.warm-cache=0' exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee 4de32a90b66cd083ebf3c00b41277aa7abca51dd (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 2o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee 4de32a90b66cd083ebf3c00b41277aa7abca51dd exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm .hg/blackbox.log
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
  $ hg -R ../server blackbox
  * @0000000000000000000000000000000000000000 (*)> debugobshashrange --subranges --rev tip (glob)
  * @0000000000000000000000000000000000000000 (*)> updated stablerange cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobshashrange --subranges --rev tip exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> serve --stdio (glob)
  * @0000000000000000000000000000000000000000 (*)> -R server serve --stdio exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm ../server/.hg/blackbox.log
  $ hg -R ../server/ debugobsolete --rev ::4 | sort
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ rm ../server/.hg/blackbox.log
  $ hg blackbox
  * @0000000000000000000000000000000000000000 (*)> pull --rev 4 (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated stablerange cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (5r, 3o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (5r, 3o) (glob)
  * @0000000000000000000000000000000000000000 (*)> 5 incoming changes - new heads: bebd167eb94d (glob)
  * @0000000000000000000000000000000000000000 (*)> pull --rev 4 exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm .hg/blackbox.log
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
  $ hg push -f --debug
  pushing to ssh://user@dummy/server
  running python "*/dummyssh" user@dummy 'hg -R server serve --stdio' (glob)
  sending hello command
  sending between command
  remote: 516
  remote: capabilities: _evoext_getbundle_obscommon _evoext_obshash_0 _evoext_obshash_1 _evoext_obshashrange_v0 _evoext_pullobsmarkers_0 _evoext_pushobsmarkers_0 batch branchmap bundle2=HG20%0Achangegroup%3D01%2C02%0Adigests%3Dmd5%2Csha1%2Csha512%0Aerror%3Dabort%2Cunsupportedcontent%2Cpushraced%2Cpushkey%0Ahgtagsfnodes%0Alistkeys%0Aobsmarkers%3DV0%2CV1%0Apushkey%0Aremote-changegroup%3Dhttp%2Chttps changegroupsubset getbundle known lookup pushkey streamreqs=generaldelta,revlogv1 unbundle=HG10GZ,HG10BZ,HG10UN unbundlehash
  remote: 1
  preparing listkeys for "phases"
  sending listkeys command
  received listkey for "phases": 58 bytes
  query 1; heads
  sending batch command
  searching for changes
  taking quick initial sample
  query 2; still undecided: 5, sample size is: 5
  sending known command
  2 total queries
  preparing listkeys for "phases"
  sending listkeys command
  received listkey for "phases": 58 bytes
  preparing listkeys for "namespaces"
  sending listkeys command
  received listkey for "namespaces": 40 bytes
  OBSEXC: computing relevant nodes
  OBSEXC: looking for common markers in 6 nodes
  query 0; add more sample (target 100, current 1)
  query 0; sample size is 9, largest range 5
  sending evoext_obshashrange_v0 command
  obsdiscovery, 0/5 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  OBSEXC: computing markers relevant to 1 nodes
  checking for updated bookmarks
  preparing listkeys for "bookmarks"
  sending listkeys command
  received listkey for "bookmarks": 0 bytes
  1 changesets found
  list of changesets:
  45f8b879de922f6a6e620ba04205730335b6fc7e
  sending unbundle command
  bundle2-output-bundle: "HG20", 4 parts total
  bundle2-output-part: "replycaps" 172 bytes payload
  bundle2-output-part: "changegroup" (params: 1 mandatory) streamed payload
  bundle2-output-part: "pushkey" (params: 4 mandatory) empty payload
  bundle2-output-part: "obsmarkers" streamed payload
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: 1 new obsolescence markers
  bundle2-input-bundle: with-transaction
  bundle2-input-part: "reply:changegroup" (advisory) (params: 0 advisory) supported
  bundle2-input-part: "reply:pushkey" (params: 0 advisory) supported
  bundle2-input-part: "reply:obsmarkers" (params: 0 advisory) supported
  bundle2-input-bundle: 2 parts total
  preparing listkeys for "phases"
  sending listkeys command
  received listkey for "phases": 58 bytes
  $ hg -R ../server blackbox
  * @0000000000000000000000000000000000000000 (*)> serve --stdio (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (1r, 0o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated served branch cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> wrote served branch cache with 1 labels and 2 nodes (glob)
  * @0000000000000000000000000000000000000000 (*)> updated stablerange cache in *.???? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (1r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> 1 incoming changes - new heads: 45f8b879de92 (glob)
  * @0000000000000000000000000000000000000000 (*)> -R server serve --stdio exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm ../server/.hg/blackbox.log

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
  $ hg -R ../server blackbox
  * @0000000000000000000000000000000000000000 (*)> serve --stdio (glob)
  * @0000000000000000000000000000000000000000 (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 2o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 2o) (glob)
  * @0000000000000000000000000000000000000000 (*)> -R server serve --stdio exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm ../server/.hg/blackbox.log
  $ hg -R ../server/ debugobsolete --rev ::tip | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  ffffffffffffffffffffffffffffffffffffffff 45f8b879de922f6a6e620ba04205730335b6fc7e 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg blackbox
  * @0000000000000000000000000000000000000000 (*)> debugobsolete (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> up (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> up exited 0 after *.?? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> add foo (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> add foo exited 0 after *.?? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> commit -m foo (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obscache in *.???? seconds (1r, 0o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated served branch cache in *.???? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> wrote served branch cache with 1 labels and 1 nodes (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (1r, 0o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> commit -m foo exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete ffffffffffffffffffffffffffffffffffffffff 45f8b879de922f6a6e620ba04205730335b6fc7e (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete ffffffffffffffffffffffffffffffffffffffff 45f8b879de922f6a6e620ba04205730335b6fc7e exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> push -f --debug (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated stablerange cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 0/5 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> push -f --debug exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> log -G (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> log -G exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete 111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete 111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete 22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete 22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> push (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 2/6 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> push exited True after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> blackbox (glob)
  $ rm .hg/blackbox.log
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

  $ hg -R ../server blackbox
  * @0000000000000000000000000000000000000000 (*)> debugobsolete --rev '::tip' (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @0000000000000000000000000000000000000000 (*)> -R ../server/ debugobsolete --rev '::tip' exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete aaaaaaa11111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> -R ../server debugobsolete aaaaaaa11111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> debugobsolete bbbbbbb2222222222bbbbbbbbbbbbb2222222222 bebd167eb94d257ace0e814aeb98e6972ed2970d (glob)
  * @0000000000000000000000000000000000000000 (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @0000000000000000000000000000000000000000 (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @0000000000000000000000000000000000000000 (*)> -R ../server debugobsolete bbbbbbb2222222222bbbbbbbbbbbbb2222222222 bebd167eb94d257ace0e814aeb98e6972ed2970d exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> serve --stdio (glob)
  * @0000000000000000000000000000000000000000 (*)> -R server serve --stdio exited 0 after *.?? seconds (glob)
  * @0000000000000000000000000000000000000000 (*)> blackbox (glob)
  $ rm ../server/.hg/blackbox.log
  $ hg -R ../server/ debugobsolete --rev '::6' | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaa11111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbb2222222222bbbbbbbbbbbbb2222222222 bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  $ hg blackbox
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> log -G (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> log -G exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull -r 6 (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 2/6 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (2r, 0o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated served branch cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> wrote served branch cache with 1 labels and 2 nodes (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated stablerange cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (2r, 3o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 3o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> 2 incoming changes - new heads: f69452c5b1af (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull -r 6 exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> blackbox (glob)
  $ rm .hg/blackbox.log
  $ hg debugobsolete --rev '::6' | sort
  111111111111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  22222222222222222bbbbbbbbbbbbb2222222222 2dc09a01254db841290af0538aa52f6f52c776e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaa11111111aaaaaaaaa1111111111111111 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 66f7d451a68b85ed82ff5fcc254daf50c74144bd 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbb2222222222bbbbbbbbbbbbb2222222222 bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb 01241442b3c2bf3211e593b549c655ea65b295e3 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  cccccccccccccccccccccccccccccccccccccccc bebd167eb94d257ace0e814aeb98e6972ed2970d 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}
  dddddddddddddddddddddddddddddddddddddddd c8d03c1b5e94af74b772900c58259d2e08917735 0 (Thu Jan 01 00:00:00 1970 +0000) {'user': 'test'}

Test cache behavior
===================

Adding markers affecting already used range:
--------------------------------------------

  $ hg debugobshashrange --subranges --rev 'heads(all())'
           rev         node        index         size        depth      obshash
             7 f69452c5b1af            0            7            7 000000000000
             5 45f8b879de92            0            6            6 1643971dbe2d
             3 2dc09a01254d            0            4            4 6be48f31976a
             7 f69452c5b1af            4            3            7 000000000000
             3 2dc09a01254d            2            2            4 9522069ae085
             5 45f8b879de92            4            2            6 9c26c72819c0
             1 66f7d451a68b            0            2            2 853c77a32154
             6 c8d03c1b5e94            4            2            6 ec8a3e92c525
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 8a2acf8e1cde
             5 45f8b879de92            5            1            6 1a0c08180b65
             1 66f7d451a68b            1            1            2 853c77a32154
             4 bebd167eb94d            4            1            5 20a2cc572e4b
             6 c8d03c1b5e94            5            1            6 446c2dc3bce5
             7 f69452c5b1af            6            1            7 000000000000
  $ hg -R ../server debugobsolete aaaa333333333aaaaa333a3a3a3a3a3a3a3a3a3a `getid 'desc(r1)'`
  $ hg -R ../server debugobsolete bb4b4b4b4b4b4b4b44b4b4b4b4b4b4b4b4b4b4b4 `getid 'desc(r3)'`
  $ hg pull -r `getid 'desc(r6)'`
  pulling from ssh://user@dummy/server
  no changes found
  OBSEXC: looking for common markers in 7 nodes
  OBSEXC: request obsmarkers for 2 common nodes
  2 new obsolescence markers
  $ hg debugobshashrange --subranges --rev 'desc("r3")' -R ../server
           rev         node        index         size        depth      obshash
             3 2dc09a01254d            0            4            4 8932bf980bb4
             3 2dc09a01254d            2            2            4 ce1937ca1278
             1 66f7d451a68b            0            2            2 327c7dd73d29
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 26f996446ecb
             1 66f7d451a68b            1            1            2 327c7dd73d29
  $ hg debugobshashrange --subranges --rev 'desc("r3")'
           rev         node        index         size        depth      obshash
             3 2dc09a01254d            0            4            4 8932bf980bb4
             3 2dc09a01254d            2            2            4 ce1937ca1278
             1 66f7d451a68b            0            2            2 327c7dd73d29
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 26f996446ecb
             1 66f7d451a68b            1            1            2 327c7dd73d29
  $ hg blackbox
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete --rev '::6' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> alias 'debugobsolete' expands to 'debugobsolete -d '0 0'' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobsolete --rev '::6' exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull -r f69452c5b1af6cbaaa56ef50cf94fff5bcc6ca23 (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 2/7 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 2o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 2o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull -r f69452c5b1af6cbaaa56ef50cf94fff5bcc6ca23 exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'desc("r3")' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'desc("r3")' exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> blackbox (glob)
  $ rm .hg/blackbox.log

Adding prune markers on existing changeset
------------------------------------------

  $ hg -R ../server debugobsolete --record-parents `getid 'desc(foo)'`
  $ hg pull -r `getid 'desc(r4)'`
  pulling from ssh://user@dummy/server
  no changes found
  OBSEXC: looking for common markers in 5 nodes
  OBSEXC: request obsmarkers for 1 common nodes
  1 new obsolescence markers
  $ hg blackbox
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull -r bebd167eb94d257ace0e814aeb98e6972ed2970d (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 1/5 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obshashcache reset - new markers affect cached ranges (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull -r bebd167eb94d257ace0e814aeb98e6972ed2970d exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> blackbox (glob)
  $ rm .hg/blackbox.log
  $ hg debugobshashrange --subranges --rev 'heads(all())'
           rev         node        index         size        depth      obshash
             7 f69452c5b1af            0            7            7 000000000000
             5 45f8b879de92            0            6            6 7c49a958a9ac
             3 2dc09a01254d            0            4            4 8932bf980bb4
             7 f69452c5b1af            4            3            7 000000000000
             3 2dc09a01254d            2            2            4 ce1937ca1278
             5 45f8b879de92            4            2            6 c6795525c540
             1 66f7d451a68b            0            2            2 327c7dd73d29
             6 c8d03c1b5e94            4            2            6 89755fd39e6d
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 26f996446ecb
             5 45f8b879de92            5            1            6 796507769034
             1 66f7d451a68b            1            1            2 327c7dd73d29
             4 bebd167eb94d            4            1            5 b21465ecb790
             6 c8d03c1b5e94            5            1            6 446c2dc3bce5
             7 f69452c5b1af            6            1            7 000000000000

Recover after rollback

  $ hg pull
  pulling from ssh://user@dummy/server
  searching for changes
  OBSEXC: looking for common markers in 8 nodes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  1 new obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg rollback
  repository tip rolled back to revision 7 (undo pull)
  $ hg blackbox
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 0/8 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (1r, 0o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated served branch cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> wrote served branch cache with 1 labels and 2 nodes (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated stablerange cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (1r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> 1 incoming changes - new heads: 4de32a90b66c (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> rollback (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated base branch cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> wrote base branch cache with 1 labels and 2 nodes (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> rollback exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> blackbox (glob)
  $ rm .hg/blackbox.log
  $ hg debugobshashrange --subranges --rev 'heads(all())'
           rev         node        index         size        depth      obshash
             7 f69452c5b1af            0            7            7 000000000000
             5 45f8b879de92            0            6            6 7c49a958a9ac
             3 2dc09a01254d            0            4            4 8932bf980bb4
             7 f69452c5b1af            4            3            7 000000000000
             3 2dc09a01254d            2            2            4 ce1937ca1278
             5 45f8b879de92            4            2            6 c6795525c540
             1 66f7d451a68b            0            2            2 327c7dd73d29
             6 c8d03c1b5e94            4            2            6 89755fd39e6d
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 26f996446ecb
             5 45f8b879de92            5            1            6 796507769034
             1 66f7d451a68b            1            1            2 327c7dd73d29
             4 bebd167eb94d            4            1            5 b21465ecb790
             6 c8d03c1b5e94            5            1            6 446c2dc3bce5
             7 f69452c5b1af            6            1            7 000000000000
  $ hg pull
  pulling from ssh://user@dummy/server
  searching for changes
  OBSEXC: looking for common markers in 8 nodes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  1 new obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg blackbox
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated stablerange cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> strip detected, evo-ext-obshashrange cache reset (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (8r, 12o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> obsdiscovery, 0/8 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> strip detected, evo-ext-obscache cache reset (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (9r, 12o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated stablerange cache in *.???? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obshashrange in *.???? seconds (1r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> updated evo-ext-obscache in *.???? seconds (0r, 1o) (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> 1 incoming changes - new heads: 4de32a90b66c (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> pull exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> blackbox (glob)
  $ rm .hg/blackbox.log
  $ hg debugobshashrange --subranges --rev 'heads(all())'
           rev         node        index         size        depth      obshash
             8 4de32a90b66c            0            8            8 c7f1f7e9925b
             5 45f8b879de92            0            6            6 7c49a958a9ac
             3 2dc09a01254d            0            4            4 8932bf980bb4
             8 4de32a90b66c            4            4            8 c681c3e58c27
             3 2dc09a01254d            2            2            4 ce1937ca1278
             5 45f8b879de92            4            2            6 c6795525c540
             8 4de32a90b66c            6            2            8 033544c939f0
             1 66f7d451a68b            0            2            2 327c7dd73d29
             6 c8d03c1b5e94            4            2            6 89755fd39e6d
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 26f996446ecb
             5 45f8b879de92            5            1            6 796507769034
             8 4de32a90b66c            7            1            8 033544c939f0
             1 66f7d451a68b            1            1            2 327c7dd73d29
             4 bebd167eb94d            4            1            5 b21465ecb790
             6 c8d03c1b5e94            5            1            6 446c2dc3bce5
             7 f69452c5b1af            6            1            7 000000000000

Recover after stripping (in the middle of the repo)

We strip a branch that is not the tip of the reporiosy so part of the affected
revision are reapplied after the target is stripped.

  $ hg log -G
  o  8 4de32a90b66c r7 tip
  |
  o  7 f69452c5b1af r6
  |
  o  6 c8d03c1b5e94 r5
  |
  | @  5 45f8b879de92 foo
  |/
  o  4 bebd167eb94d r4
  |
  o  3 2dc09a01254d r3
  |
  o  2 01241442b3c2 r2
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  
  $ hg --config extensions.strip= strip -r 'desc("foo")'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  saved backup bundle to $TESTTMP/client/.hg/strip-backup/45f8b879de92-94c82517-backup.hg (glob)
  $ hg log -G
  o  7 4de32a90b66c r7 tip
  |
  o  6 f69452c5b1af r6
  |
  o  5 c8d03c1b5e94 r5
  |
  @  4 bebd167eb94d r4
  |
  o  3 2dc09a01254d r3
  |
  o  2 01241442b3c2 r2
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  
  $ hg pull
  pulling from ssh://user@dummy/server
  searching for changes
  OBSEXC: looking for common markers in 8 nodes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg log -G
  o  8 45f8b879de92 foo tip
  |
  | o  7 4de32a90b66c r7
  | |
  | o  6 f69452c5b1af r6
  | |
  | o  5 c8d03c1b5e94 r5
  |/
  @  4 bebd167eb94d r4
  |
  o  3 2dc09a01254d r3
  |
  o  2 01241442b3c2 r2
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  
  $ hg blackbox
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> debugobshashrange --subranges --rev 'heads(all())' exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> log -G (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> log -G exited 0 after *.?? seconds (glob)
  * @45f8b879de922f6a6e620ba04205730335b6fc7e (*)> strip -r 'desc("foo")' (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> saved backup bundle to $TESTTMP/client/.hg/strip-backup/45f8b879de92-94c82517-backup.hg (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> strip detected, evo-ext-obshashrange cache reset (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obshashrange in *.???? seconds (5r, 13o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> strip detected, evo-ext-obscache cache reset (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obscache in *.???? seconds (5r, 13o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated stablerange cache in *.???? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obshashrange in *.???? seconds (3r, 0o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obscache in *.???? seconds (3r, 0o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated base branch cache in *.???? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> wrote base branch cache with 1 labels and 1 nodes (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> 3 incoming changes - new heads: 4de32a90b66c (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> --config 'extensions.strip=' strip -r 'desc("foo")' exited 0 after *.?? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> log -G (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> log -G exited 0 after *.?? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> pull (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> obsdiscovery, 0/8 mismatch - 1 obshashrange queries in *.???? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obscache in *.???? seconds (1r, 0o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated stablerange cache in *.???? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated evo-ext-obshashrange in *.???? seconds (1r, 0o) (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> updated served branch cache in *.???? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> wrote served branch cache with 1 labels and 2 nodes (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> 1 incoming changes - new heads: 45f8b879de92 (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> pull exited 0 after *.?? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> log -G (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> writing .hg/cache/tags2-visible with 0 tags (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> log -G exited 0 after *.?? seconds (glob)
  * @bebd167eb94d257ace0e814aeb98e6972ed2970d (*)> blackbox (glob)
  $ rm .hg/blackbox.log
  $ hg debugobshashrange --subranges --rev 'heads(all())'
           rev         node        index         size        depth      obshash
             7 4de32a90b66c            0            8            8 c7f1f7e9925b
             8 45f8b879de92            0            6            6 7c49a958a9ac
             3 2dc09a01254d            0            4            4 8932bf980bb4
             7 4de32a90b66c            4            4            8 c681c3e58c27
             3 2dc09a01254d            2            2            4 ce1937ca1278
             8 45f8b879de92            4            2            6 c6795525c540
             7 4de32a90b66c            6            2            8 033544c939f0
             1 66f7d451a68b            0            2            2 327c7dd73d29
             5 c8d03c1b5e94            4            2            6 89755fd39e6d
             2 01241442b3c2            2            1            3 1ed3c61fb39a
             0 1ea73414a91b            0            1            1 000000000000
             3 2dc09a01254d            3            1            4 26f996446ecb
             8 45f8b879de92            5            1            6 796507769034
             7 4de32a90b66c            7            1            8 033544c939f0
             1 66f7d451a68b            1            1            2 327c7dd73d29
             4 bebd167eb94d            4            1            5 b21465ecb790
             5 c8d03c1b5e94            5            1            6 446c2dc3bce5
             6 f69452c5b1af            6            1            7 000000000000

