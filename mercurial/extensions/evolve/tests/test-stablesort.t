Test for stable ordering capabilities
=====================================

  $ . $TESTDIR/testlib/pythonpath.sh

  $ cat << EOF >> $HGRCPATH
  > [extensions]
  > hgext3rd.evolve =
  > [ui]
  > logtemplate = "{rev} {node|short} {desc} {tags}\n"
  > [alias]
  > showsort = debugstablesort --template="{node|short}\n"
  > EOF



  $ checktopo () {
  >     seen='null';
  >     for node in `hg showsort --rev "$1"`; do
  >         echo "=== checking $node ===";
  >         hg log --rev "($seen) and $node::";
  >         seen="${seen}+${node}";
  >     done;
  > }

Basic tests
===========
(no criss cross merge)

Smoke tests
-----------

Starts with a "simple case"

  $ hg init repo_A
  $ cd repo_A
  $ hg debugbuilddag '
  > ..:g   # 2 nodes, tagged "g"
  > <2.:h   # another node base one -2 -> 0, tagged "h"
  > *1/2:m # merge -1 and -2 (1, 2), tagged "m"
  > <2+2:i # 2 nodes based on -2, tag head as "i"
  > .:c    # 1 node tagged "c"
  > <m+3:a # 3 nodes base on the "m" tag
  > <2.:b  # 1 node based on -2; tagged "b"
  > <m+2:d # 2 nodes from "m" tagged "d"
  > <2.:e  # 1 node based on -2, tagged "e"
  > <m+1:f # 1 node based on "m" tagged "f"
  > <i/f   # merge "i" and "f"
  > '
  $ hg log -G
  o    15 1d8d22637c2d r15 tip
  |\
  | o  14 43227190fef8 r14 f
  | |
  | | o  13 b4594d867745 r13 e
  | | |
  | | | o  12 e46a4836065c r12 d
  | | |/
  | | o  11 bab5d5bf48bd r11
  | |/
  | | o  10 ff43616e5d0f r10 b
  | | |
  | | | o  9 dcbb326fdec2 r9 a
  | | |/
  | | o  8 d62d843c9a01 r8
  | | |
  | | o  7 e7d9710d9fc6 r7
  | |/
  +---o  6 2702dd0c91e7 r6 c
  | |
  o |  5 f0f3ef9a6cd5 r5 i
  | |
  o |  4 4c748ffd1a46 r4
  | |
  | o  3 2b6d669947cd r3 m
  |/|
  o |  2 fa942426a6fd r2 h
  | |
  | o  1 66f7d451a68b r1 g
  |/
  o  0 1ea73414a91b r0
  
  $ hg showsort --rev 'all()' --traceback
  1ea73414a91b
  66f7d451a68b
  fa942426a6fd
  2b6d669947cd
  43227190fef8
  bab5d5bf48bd
  b4594d867745
  e46a4836065c
  e7d9710d9fc6
  d62d843c9a01
  dcbb326fdec2
  ff43616e5d0f
  4c748ffd1a46
  f0f3ef9a6cd5
  1d8d22637c2d
  2702dd0c91e7

Verify the topological order
----------------------------

Check we we did not issued a node before on ancestor

output of log should be empty

  $ checktopo 'all()'
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking fa942426a6fd ===
  === checking 2b6d669947cd ===
  === checking 43227190fef8 ===
  === checking bab5d5bf48bd ===
  === checking b4594d867745 ===
  === checking e46a4836065c ===
  === checking e7d9710d9fc6 ===
  === checking d62d843c9a01 ===
  === checking dcbb326fdec2 ===
  === checking ff43616e5d0f ===
  === checking 4c748ffd1a46 ===
  === checking f0f3ef9a6cd5 ===
  === checking 1d8d22637c2d ===
  === checking 2702dd0c91e7 ===

Check stability
===============

have repo with changesets in orders

  $ cd ..
  $ hg -R repo_A log -G > A.log
  $ hg clone repo_A repo_B --rev 5
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R repo_B pull --rev 13
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg -R repo_B pull --rev 14
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads .' to see heads, 'hg merge' to merge)
  $ hg -R repo_B pull
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 7 changesets with 0 changes to 0 files (+3 heads)
  (run 'hg heads .' to see heads, 'hg merge' to merge)
  $ hg -R repo_B log -G
  o    15 1d8d22637c2d r15 tip
  |\
  | | o  14 e46a4836065c r12
  | | |
  | | | o  13 ff43616e5d0f r10
  | | | |
  | | | | o  12 dcbb326fdec2 r9
  | | | |/
  | | | o  11 d62d843c9a01 r8
  | | | |
  | | | o  10 e7d9710d9fc6 r7
  | | | |
  +-------o  9 2702dd0c91e7 r6
  | | | |
  | o---+  8 43227190fef8 r14
  |  / /
  | +---o  7 b4594d867745 r13
  | | |
  | o |  6 bab5d5bf48bd r11
  | |/
  | o    5 2b6d669947cd r3
  | |\
  | | o  4 66f7d451a68b r1
  | | |
  @ | |  3 f0f3ef9a6cd5 r5
  | | |
  o | |  2 4c748ffd1a46 r4
  |/ /
  o /  1 fa942426a6fd r2
  |/
  o  0 1ea73414a91b r0
  
  $ hg -R repo_B log -G > B.log

  $ hg clone repo_A repo_C --rev 10
  adding changesets
  adding manifests
  adding file changes
  added 7 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R repo_C pull --rev 12
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg -R repo_C pull --rev 15
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads .' to see heads, 'hg merge' to merge)
  $ hg -R repo_C pull
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 0 changes to 0 files (+3 heads)
  (run 'hg heads .' to see heads, 'hg merge' to merge)
  $ hg -R repo_C log -G
  o  15 b4594d867745 r13 tip
  |
  | o  14 dcbb326fdec2 r9
  | |
  | | o  13 2702dd0c91e7 r6
  | | |
  | | | o  12 1d8d22637c2d r15
  | | |/|
  | | | o  11 43227190fef8 r14
  | | | |
  | | o |  10 f0f3ef9a6cd5 r5
  | | | |
  | | o |  9 4c748ffd1a46 r4
  | | | |
  +-------o  8 e46a4836065c r12
  | | | |
  o-----+  7 bab5d5bf48bd r11
   / / /
  +-----@  6 ff43616e5d0f r10
  | | |
  o | |  5 d62d843c9a01 r8
  | | |
  o---+  4 e7d9710d9fc6 r7
   / /
  | o  3 2b6d669947cd r3
  |/|
  o |  2 fa942426a6fd r2
  | |
  | o  1 66f7d451a68b r1
  |/
  o  0 1ea73414a91b r0
  
  $ hg -R repo_C log -G > C.log

  $ hg clone repo_A repo_D --rev 2
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R repo_D pull --rev 10
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 0 changes to 0 files
  (run 'hg update' to get a working copy)
  $ hg -R repo_D pull --rev 15
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg -R repo_D pull
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 0 changes to 0 files (+4 heads)
  (run 'hg heads .' to see heads, 'hg merge' to merge)
  $ hg -R repo_D log -G
  o  15 b4594d867745 r13 tip
  |
  | o  14 e46a4836065c r12
  |/
  o  13 bab5d5bf48bd r11
  |
  | o  12 dcbb326fdec2 r9
  | |
  | | o  11 2702dd0c91e7 r6
  | | |
  | | | o  10 1d8d22637c2d r15
  | | |/|
  +-----o  9 43227190fef8 r14
  | | |
  | | o  8 f0f3ef9a6cd5 r5
  | | |
  | | o  7 4c748ffd1a46 r4
  | | |
  | +---o  6 ff43616e5d0f r10
  | | |
  | o |  5 d62d843c9a01 r8
  | | |
  | o |  4 e7d9710d9fc6 r7
  |/ /
  o |  3 2b6d669947cd r3
  |\|
  o |  2 66f7d451a68b r1
  | |
  | @  1 fa942426a6fd r2
  |/
  o  0 1ea73414a91b r0
  
  $ hg -R repo_D log -G > D.log

check the log output are different

  $ python "$RUNTESTDIR/md5sum.py" *.log
  55919ebc9c02f28070cf3255b1690f8c  A.log
  c6244b76a60d0707767dc71780e544f3  B.log
  4d8b08b8c50ecbdd2460a62e5852d84d  C.log
  0f327003593b50b9591bea8ee28acb81  D.log

bug stable ordering should be identical
---------------------------------------

  $ repos="A B C D "

for 'all()'

  $ for x in $repos; do
  >     echo $x
  >     hg -R repo_$x showsort --rev 'all()' > ${x}.all.order;
  > done
  A
  B
  C
  D

  $ python "$RUNTESTDIR/md5sum.py" *.all.order
  0c6b2e6f15249c0359b0f93e28c5bd1c  A.all.order
  0c6b2e6f15249c0359b0f93e28c5bd1c  B.all.order
  0c6b2e6f15249c0359b0f93e28c5bd1c  C.all.order
  0c6b2e6f15249c0359b0f93e28c5bd1c  D.all.order

one specific head

  $ for x in $repos; do
  >     hg -R repo_$x showsort --rev 'b4594d867745' > ${x}.b4594d867745.order;
  > done

  $ python "$RUNTESTDIR/md5sum.py" *.b4594d867745.order
  5c40900a22008f24eab8dfe2f30ad79f  A.b4594d867745.order
  5c40900a22008f24eab8dfe2f30ad79f  B.b4594d867745.order
  5c40900a22008f24eab8dfe2f30ad79f  C.b4594d867745.order
  5c40900a22008f24eab8dfe2f30ad79f  D.b4594d867745.order

one secific heads, that is a merge

  $ for x in $repos; do
  >     hg -R repo_$x showsort --rev '1d8d22637c2d' > ${x}.1d8d22637c2d.order;
  > done

  $ python "$RUNTESTDIR/md5sum.py" *.1d8d22637c2d.order
  77dc20a6f86db9103df8edaae9ad2754  A.1d8d22637c2d.order
  77dc20a6f86db9103df8edaae9ad2754  B.1d8d22637c2d.order
  77dc20a6f86db9103df8edaae9ad2754  C.1d8d22637c2d.order
  77dc20a6f86db9103df8edaae9ad2754  D.1d8d22637c2d.order

changeset that are not heads

  $ for x in $repos; do
  >     hg -R repo_$x showsort --rev 'e7d9710d9fc6+43227190fef8' > ${x}.non-heads.order;
  > done

  $ python "$RUNTESTDIR/md5sum.py" *.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  A.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  B.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  C.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  D.non-heads.order

Check with different subset

  $ hg clone repo_A repo_E --rev "43227190fef8"
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R repo_E pull --rev e7d9710d9fc6
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)

  $ hg clone repo_A repo_F --rev "1d8d22637c2d"
  adding changesets
  adding manifests
  adding file changes
  added 8 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R repo_F pull --rev d62d843c9a01
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)

  $ hg clone repo_A repo_G --rev "e7d9710d9fc6"
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R repo_G pull --rev 43227190fef8
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg -R repo_G pull --rev 2702dd0c91e7
  pulling from $TESTTMP/repo_A (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 0 changes to 0 files (+1 heads)
  (run 'hg heads .' to see heads, 'hg merge' to merge)

  $ for x in E F G; do
  >     hg -R repo_$x showsort --rev 'e7d9710d9fc6+43227190fef8' > ${x}.non-heads.order;
  > done

  $ python "$RUNTESTDIR/md5sum.py" *.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  A.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  B.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  C.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  D.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  E.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  F.non-heads.order
  94e0ea8cdade135dabde4ec5e9954329  G.non-heads.order

Multiple recursions
===================

  $ cat << EOF >> random_rev.py
  > import random
  > import sys
  > 
  > loop = int(sys.argv[1])
  > var = int(sys.argv[2])
  > for x in range(loop):
  >     print(x + random.randint(0, var))
  > EOF

  $ hg init recursion_A
  $ cd recursion_A
  $ hg debugbuilddag '
  > .:base
  > +3:A
  > <base.:B
  > +2/A:C
  > <A+2:D
  > <B./D:E
  > +3:F
  > <C+3/E
  > +2
  > '
  $ hg log -G
  o  20 160a7a0adbf4 r20 tip
  |
  o  19 1c645e73dbc6 r19
  |
  o    18 0496f0a6a143 r18
  |\
  | o  17 d64d500024d1 r17
  | |
  | o  16 4dbf739dd63f r16
  | |
  | o  15 9fff0871d230 r15
  | |
  | | o  14 4bbfc6078919 r14 F
  | | |
  | | o  13 013b27f11536 r13
  | | |
  +---o  12 a66b68853635 r12
  | |
  o |    11 001194dd78d5 r11 E
  |\ \
  | o |  10 6ee532b68cfa r10
  | | |
  o | |  9 529dfc5bb875 r9 D
  | | |
  o | |  8 abf57d94268b r8
  | | |
  +---o  7 5f18015f9110 r7 C
  | | |
  | | o  6 a2f58e9c1e56 r6
  | | |
  | | o  5 3a367db1fabc r5
  | |/
  | o  4 e7bd5218ca15 r4 B
  | |
  o |  3 2dc09a01254d r3 A
  | |
  o |  2 01241442b3c2 r2
  | |
  o |  1 66f7d451a68b r1
  |/
  o  0 1ea73414a91b r0 base
  
  $ hg showsort --rev 'all()'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  2dc09a01254d
  abf57d94268b
  529dfc5bb875
  e7bd5218ca15
  3a367db1fabc
  a2f58e9c1e56
  5f18015f9110
  9fff0871d230
  4dbf739dd63f
  d64d500024d1
  6ee532b68cfa
  001194dd78d5
  0496f0a6a143
  1c645e73dbc6
  160a7a0adbf4
  a66b68853635
  013b27f11536
  4bbfc6078919
  $ checktopo 'all()'
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 2dc09a01254d ===
  === checking abf57d94268b ===
  === checking 529dfc5bb875 ===
  === checking e7bd5218ca15 ===
  === checking 3a367db1fabc ===
  === checking a2f58e9c1e56 ===
  === checking 5f18015f9110 ===
  === checking 9fff0871d230 ===
  === checking 4dbf739dd63f ===
  === checking d64d500024d1 ===
  === checking 6ee532b68cfa ===
  === checking 001194dd78d5 ===
  === checking 0496f0a6a143 ===
  === checking 1c645e73dbc6 ===
  === checking 160a7a0adbf4 ===
  === checking a66b68853635 ===
  === checking 013b27f11536 ===
  === checking 4bbfc6078919 ===
  $ hg showsort --rev 'all()' > ../multiple.source.order
  $ hg log -r tip
  20 160a7a0adbf4 r20 tip
  $ cd ..

  $ hg clone recursion_A recursion_random --rev 0
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd recursion_random
  $ for x in `python ../random_rev.py 15 5`; do
  >   # using python to benefit from the random seed
  >   hg pull -r $x --quiet
  > done;
  $ hg pull --quiet
  $ hg showsort --rev 'all()' > ../multiple.random.order
  $ python "$RUNTESTDIR/md5sum.py" ../multiple.*.order
  6ff802a0a5f0a3ddd82b25f860238fbd  ../multiple.random.order
  6ff802a0a5f0a3ddd82b25f860238fbd  ../multiple.source.order
  $ hg showsort --rev 'all()'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  2dc09a01254d
  abf57d94268b
  529dfc5bb875
  e7bd5218ca15
  3a367db1fabc
  a2f58e9c1e56
  5f18015f9110
  9fff0871d230
  4dbf739dd63f
  d64d500024d1
  6ee532b68cfa
  001194dd78d5
  0496f0a6a143
  1c645e73dbc6
  160a7a0adbf4
  a66b68853635
  013b27f11536
  4bbfc6078919
  $ cd ..

Check criss cross merge
=======================

  $ hg init crisscross_A
  $ cd crisscross_A
  $ hg debugbuilddag '
  > ...:base         # create some base
  > # criss cross #1: simple
  > +3:AbaseA      # "A" branch for CC "A"
  > <base+2:AbaseB # "B" branch for CC "B"
  > <AbaseA/AbaseB:AmergeA
  > <AbaseB/AbaseA:AmergeB
  > <AmergeA/AmergeB:Afinal
  > # criss cross #2:multiple closes ones
  > .:BbaseA
  > <AmergeB:BbaseB
  > <BbaseA/BbaseB:BmergeA
  > <BbaseB/BbaseA:BmergeB
  > <BmergeA/BmergeB:BmergeC
  > <BmergeB/BmergeA:BmergeD
  > <BmergeC/BmergeD:Bfinal
  > # criss cross #2:many branches
  > <Bfinal.:CbaseA
  > <Bfinal+2:CbaseB
  > <Bfinal.:CbaseC
  > <Bfinal+5:CbaseD
  > <Bfinal.:CbaseE
  > <CbaseA/CbaseB+7:CmergeA
  > <CbaseA/CbaseC:CmergeB
  > <CbaseA/CbaseD.:CmergeC
  > <CbaseA/CbaseE:CmergeD
  > <CbaseB/CbaseA+2:CmergeE
  > <CbaseB/CbaseC:CmergeF
  > <CbaseB/CbaseD.:CmergeG
  > <CbaseB/CbaseE:CmergeH
  > <CbaseC/CbaseA.:CmergeI
  > <CbaseC/CbaseB:CmergeJ
  > <CbaseC/CbaseD+5:CmergeK
  > <CbaseC/CbaseE+2:CmergeL
  > <CbaseD/CbaseA:CmergeM
  > <CbaseD/CbaseB...:CmergeN
  > <CbaseD/CbaseC:CmergeO
  > <CbaseD/CbaseE:CmergeP
  > <CbaseE/CbaseA:CmergeQ
  > <CbaseE/CbaseB..:CmergeR
  > <CbaseE/CbaseC.:CmergeS
  > <CbaseE/CbaseD:CmergeT
  > <CmergeA/CmergeG:CmergeWA
  > <CmergeB/CmergeF:CmergeWB
  > <CmergeC/CmergeE:CmergeWC
  > <CmergeD/CmergeH:CmergeWD
  > <CmergeT/CmergeI:CmergeWE
  > <CmergeS/CmergeJ:CmergeWF
  > <CmergeR/CmergeK:CmergeWG
  > <CmergeQ/CmergeL:CmergeWH
  > <CmergeP/CmergeM:CmergeWI
  > <CmergeO/CmergeN:CmergeWJ
  > <CmergeO/CmergeN:CmergeWK
  > <CmergeWA/CmergeWG:CmergeXA
  > <CmergeWB/CmergeWH:CmergeXB
  > <CmergeWC/CmergeWI:CmergeXC
  > <CmergeWD/CmergeWJ:CmergeXD
  > <CmergeWE/CmergeWK:CmergeXE
  > <CmergeWF/CmergeWA:CmergeXF
  > <CmergeXA/CmergeXF:CmergeYA
  > <CmergeXB/CmergeXE:CmergeYB
  > <CmergeXC/CmergeXD:CmergeYC
  > <CmergeYA/CmergeYB:CmergeZA
  > <CmergeYC/CmergeYB:CmergeZB
  > <CmergeZA/CmergeZB:Cfinal
  > '
  $ hg log -G
  o    94 01f771406cab r94 Cfinal tip
  |\
  | o    93 84d6ec6a8e21 r93 CmergeZB
  | |\
  o | |  92 721ba7c5f4ff r92 CmergeZA
  |\| |
  | | o    91 8ae32c3ed670 r91 CmergeYC
  | | |\
  | o \ \    90 8b79544bb56d r90 CmergeYB
  | |\ \ \
  o \ \ \ \    89 041e1188f5f1 r89 CmergeYA
  |\ \ \ \ \
  | o \ \ \ \    88 2472d042ec95 r88 CmergeXF
  | |\ \ \ \ \
  | | | | o \ \    87 c7d3029bf731 r87 CmergeXE
  | | | | |\ \ \
  | | | | | | | o    86 469c700e9ed8 r86 CmergeXD
  | | | | | | | |\
  | | | | | | o \ \    85 28be96b80dc1 r85 CmergeXC
  | | | | | | |\ \ \
  | | | o \ \ \ \ \ \    84 dbde319d43a3 r84 CmergeXB
  | | | |\ \ \ \ \ \ \
  o | | | | | | | | | |  83 b3cf98c3d587 r83 CmergeXA
  |\| | | | | | | | | |
  | | | | | | o | | | |    82 1da228afcf06 r82 CmergeWK
  | | | | | | |\ \ \ \ \
  | | | | | | +-+-------o  81 0bab31f71a21 r81 CmergeWJ
  | | | | | | | | | | |
  | | | | | | | | | o |    80 cd345198cf12 r80 CmergeWI
  | | | | | | | | | |\ \
  | | | | o \ \ \ \ \ \ \    79 82238c0bc950 r79 CmergeWH
  | | | | |\ \ \ \ \ \ \ \
  o \ \ \ \ \ \ \ \ \ \ \ \    78 89a0fe204177 r78 CmergeWG
  |\ \ \ \ \ \ \ \ \ \ \ \ \
  | | | o \ \ \ \ \ \ \ \ \ \    77 97d19fc5236f r77 CmergeWF
  | | | |\ \ \ \ \ \ \ \ \ \ \
  | | | | | | | | o \ \ \ \ \ \    76 37ad3ab0cddf r76 CmergeWE
  | | | | | | | | |\ \ \ \ \ \ \
  | | | | | | | | | | | | | | | o    75 790cdfecd168 r75 CmergeWD
  | | | | | | | | | | | | | | | |\
  | | | | | | | | | | | | o \ \ \ \    74 698970a2480b r74 CmergeWC
  | | | | | | | | | | | | |\ \ \ \ \
  | | | | | o \ \ \ \ \ \ \ \ \ \ \ \    73 31d7b43cc321 r73 CmergeWB
  | | | | | |\ \ \ \ \ \ \ \ \ \ \ \ \
  | | o \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \    72 eed373b0090d r72 CmergeWA
  | | |\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
  | | | | | | | | | | | o \ \ \ \ \ \ \ \    71 4f3b41956174 r71 CmergeT
  | | | | | | | | | | | |\ \ \ \ \ \ \ \ \
  | | | | | o | | | | | | | | | | | | | | |  70 c3c7fa726f88 r70 CmergeS
  | | | | | | | | | | | | | | | | | | | | |
  | | | | | o-------------+ | | | | | | | |  69 d917f77a6439 r69
  | | | | | | | | | | | | | | | | | | | | |
  | o | | | | | | | | | | | | | | | | | | |  68 fac9e582edd1 r68 CmergeR
  | | | | | | | | | | | | | | | | | | | | |
  | o | | | | | | | | | | | | | | | | | | |  67 e4cfd6264623 r67
  | | | | | | | | | | | | | | | | | | | | |
  | o---------------------+ | | | | | | | |  66 d99e0f7dad5b r66
  | | | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | o-----+ | | | | | | | |  65 c713eae2d31f r65 CmergeQ
  | | | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | | | +-+-----------o | |  64 b33fd5ad4c0c r64 CmergeP
  | | | | | | | | | | | | | | | | | |  / /
  | | | | | +-----------+-----o | | | / /  63 bf6593f7e073 r63 CmergeO
  | | | | | | | | | | | | | |  / / / / /
  | | | | | | | | | | | | | o | | | | |  62 3871506da61e r62 CmergeN
  | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | | | | | o | | | | |  61 c84da74cf586 r61
  | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | | | | | o | | | | |  60 5eec91b12a58 r60
  | | | | | | | | | | | | | | | | | | |
  | +-------------------+---o | | | | |  59 0484d39906c8 r59
  | | | | | | | | | | | | |  / / / / /
  | | | | | | | | | +---+-------o / /  58 29141354a762 r58 CmergeM
  | | | | | | | | | | | | | | |  / /
  | | | | | | | | o | | | | | | | |  57 e7135b665740 r57 CmergeL
  | | | | | | | | | | | | | | | | |
  | | | | | | | | o | | | | | | | |  56 c7c1497fc270 r56
  | | | | | | | | | | | | | | | | |
  | | | | | +-----o-------+ | | | |  55 76151e8066e1 r55
  | | | | | | | |  / / / / / / / /
  o | | | | | | | | | | | | | | |  54 9a67238ad1c4 r54 CmergeK
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  53 c37e7cd9f2bd r53
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  52 0d153e3ad632 r52
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  51 97ac964e34b7 r51
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  50 900dd066a072 r50
  | | | | | | | | | | | | | | | |
  o---------+---------+ | | | | |  49 673f5499c8c2 r49
   / / / / / / / / / / / / / / /
  +-----o / / / / / / / / / / /  48 8ecb28746ec4 r48 CmergeJ
  | | | |/ / / / / / / / / / /
  | | | | | | | o | | | | | |  47 d6c9e2d27f14 r47 CmergeI
  | | | | | | | | | | | | | |
  | | | +-------o | | | | | |  46 bfcfd9a61e84 r46
  | | | | | | |/ / / / / / /
  +---------------+-------o  45 40553f55397e r45 CmergeH
  | | | | | | | | | | | |
  | | o | | | | | | | | |  44 d94da36be176 r44 CmergeG
  | | | | | | | | | | | |
  +---o---------+ | | | |  43 4b39f229a0ce r43
  | |  / / / / / / / / /
  +---+---o / / / / / /  42 43fc0b77ff07 r42 CmergeF
  | | | |  / / / / / /
  | | | | | | | | o |  41 88eace5ce682 r41 CmergeE
  | | | | | | | | | |
  | | | | | | | | o |  40 d928b4e8a515 r40
  | | | | | | | | | |
  +-------+-------o |  39 88714f4125cb r39
  | | | | | | | |  /
  | | | | +---+---o  38 e3e6738c56ce r38 CmergeD
  | | | | | | | |
  | | | | | | | o  37 32b41ca704e1 r37 CmergeC
  | | | | | | | |
  | | | | +-+---o  36 01e29e20ea3f r36
  | | | | | | |
  | | | o | | |  35 1f4a19f83a29 r35 CmergeB
  | | |/|/ / /
  | o | | | |  34 722d1b8b8942 r34 CmergeA
  | | | | | |
  | o | | | |  33 47c836a1f13e r33
  | | | | | |
  | o | | | |  32 2ea3fbf151b5 r32
  | | | | | |
  | o | | | |  31 0c3f2ba59eb7 r31
  | | | | | |
  | o | | | |  30 f3441cd3e664 r30
  | | | | | |
  | o | | | |  29 b9c3aa92fba5 r29
  | | | | | |
  | o | | | |  28 3bdb00d5c818 r28
  | | | | | |
  | o---+ | |  27 2bd677d0f13a r27
  |/ / / / /
  | | | | o  26 de05b9c29ec7 r26 CbaseE
  | | | | |
  | | | o |  25 ad46a4a0fc10 r25 CbaseD
  | | | | |
  | | | o |  24 a457569c5306 r24
  | | | | |
  | | | o |  23 f2bdd828a3aa r23
  | | | | |
  | | | o |  22 5ce588c2b7c5 r22
  | | | | |
  | | | o |  21 17b6e6bac221 r21
  | | | |/
  | o---+  20 b115c694654e r20 CbaseC
  |  / /
  o | |  19 884936b34999 r19 CbaseB
  | | |
  o---+  18 9729470d9329 r18
   / /
  o /  17 4f5078f7da8a r17 CbaseA
  |/
  o    16 3e1560705803 r16 Bfinal
  |\
  | o    15 55bf3fdb634f r15 BmergeD
  | |\
  o---+  14 39bab1cb1cbe r14 BmergeC
  |/ /
  | o    13 f7c6e7bfbcd0 r13 BmergeB
  | |\
  o---+  12 26f59ee8b1d7 r12 BmergeA
  |/ /
  | o  11 3e2da24aee59 r11 BbaseA
  | |
  | o  10 5ba9a53052ed r10 Afinal
  |/|
  o |    9 07c648efceeb r9 AmergeB BbaseB
  |\ \
  +---o  8 c81423bf5a24 r8 AmergeA
  | |/
  | o  7 65eb34ffc3a8 r7 AbaseB
  | |
  | o  6 0c1445abb33d r6
  | |
  o |  5 c8d03c1b5e94 r5 AbaseA
  | |
  o |  4 bebd167eb94d r4
  | |
  o |  3 2dc09a01254d r3
  |/
  o  2 01241442b3c2 r2 base
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  

Basic check
-----------

  $ hg showsort --rev 'Afinal'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  $ checktopo Afinal
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===
  === checking c81423bf5a24 ===
  === checking 5ba9a53052ed ===
  $ hg showsort --rev 'AmergeA'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  c81423bf5a24
  $ checktopo AmergeA
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking c81423bf5a24 ===
  $ hg showsort --rev 'AmergeB'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  $ checktopo AmergeB
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===

close criss cross
  $ hg showsort --rev 'Bfinal'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  3e2da24aee59
  26f59ee8b1d7
  f7c6e7bfbcd0
  39bab1cb1cbe
  55bf3fdb634f
  3e1560705803
  $ checktopo Bfinal
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===
  === checking c81423bf5a24 ===
  === checking 5ba9a53052ed ===
  === checking 3e2da24aee59 ===
  === checking 26f59ee8b1d7 ===
  === checking f7c6e7bfbcd0 ===
  === checking 39bab1cb1cbe ===
  === checking 55bf3fdb634f ===
  === checking 3e1560705803 ===

many branches criss cross

  $ hg showsort --rev 'Cfinal'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  3e2da24aee59
  26f59ee8b1d7
  f7c6e7bfbcd0
  39bab1cb1cbe
  55bf3fdb634f
  3e1560705803
  17b6e6bac221
  5ce588c2b7c5
  f2bdd828a3aa
  a457569c5306
  ad46a4a0fc10
  4f5078f7da8a
  01e29e20ea3f
  32b41ca704e1
  29141354a762
  9729470d9329
  884936b34999
  0484d39906c8
  5eec91b12a58
  c84da74cf586
  3871506da61e
  2bd677d0f13a
  3bdb00d5c818
  b9c3aa92fba5
  f3441cd3e664
  0c3f2ba59eb7
  2ea3fbf151b5
  47c836a1f13e
  722d1b8b8942
  4b39f229a0ce
  d94da36be176
  eed373b0090d
  88714f4125cb
  d928b4e8a515
  88eace5ce682
  698970a2480b
  b115c694654e
  1f4a19f83a29
  43fc0b77ff07
  31d7b43cc321
  673f5499c8c2
  900dd066a072
  97ac964e34b7
  0d153e3ad632
  c37e7cd9f2bd
  9a67238ad1c4
  8ecb28746ec4
  bf6593f7e073
  0bab31f71a21
  1da228afcf06
  bfcfd9a61e84
  d6c9e2d27f14
  de05b9c29ec7
  40553f55397e
  4f3b41956174
  37ad3ab0cddf
  c7d3029bf731
  76151e8066e1
  c7c1497fc270
  e7135b665740
  b33fd5ad4c0c
  cd345198cf12
  28be96b80dc1
  c713eae2d31f
  82238c0bc950
  dbde319d43a3
  8b79544bb56d
  d917f77a6439
  c3c7fa726f88
  97d19fc5236f
  2472d042ec95
  d99e0f7dad5b
  e4cfd6264623
  fac9e582edd1
  89a0fe204177
  b3cf98c3d587
  041e1188f5f1
  721ba7c5f4ff
  e3e6738c56ce
  790cdfecd168
  469c700e9ed8
  8ae32c3ed670
  84d6ec6a8e21
  01f771406cab
  $ checktopo Cfinal
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===
  === checking c81423bf5a24 ===
  === checking 5ba9a53052ed ===
  === checking 3e2da24aee59 ===
  === checking 26f59ee8b1d7 ===
  === checking f7c6e7bfbcd0 ===
  === checking 39bab1cb1cbe ===
  === checking 55bf3fdb634f ===
  === checking 3e1560705803 ===
  === checking 17b6e6bac221 ===
  === checking 5ce588c2b7c5 ===
  === checking f2bdd828a3aa ===
  === checking a457569c5306 ===
  === checking ad46a4a0fc10 ===
  === checking 4f5078f7da8a ===
  === checking 01e29e20ea3f ===
  === checking 32b41ca704e1 ===
  === checking 29141354a762 ===
  === checking 9729470d9329 ===
  === checking 884936b34999 ===
  === checking 0484d39906c8 ===
  === checking 5eec91b12a58 ===
  === checking c84da74cf586 ===
  === checking 3871506da61e ===
  === checking 2bd677d0f13a ===
  === checking 3bdb00d5c818 ===
  === checking b9c3aa92fba5 ===
  === checking f3441cd3e664 ===
  === checking 0c3f2ba59eb7 ===
  === checking 2ea3fbf151b5 ===
  === checking 47c836a1f13e ===
  === checking 722d1b8b8942 ===
  === checking 4b39f229a0ce ===
  === checking d94da36be176 ===
  === checking eed373b0090d ===
  === checking 88714f4125cb ===
  === checking d928b4e8a515 ===
  === checking 88eace5ce682 ===
  === checking 698970a2480b ===
  === checking b115c694654e ===
  === checking 1f4a19f83a29 ===
  === checking 43fc0b77ff07 ===
  === checking 31d7b43cc321 ===
  === checking 673f5499c8c2 ===
  === checking 900dd066a072 ===
  === checking 97ac964e34b7 ===
  === checking 0d153e3ad632 ===
  === checking c37e7cd9f2bd ===
  === checking 9a67238ad1c4 ===
  === checking 8ecb28746ec4 ===
  === checking bf6593f7e073 ===
  === checking 0bab31f71a21 ===
  === checking 1da228afcf06 ===
  === checking bfcfd9a61e84 ===
  === checking d6c9e2d27f14 ===
  === checking de05b9c29ec7 ===
  === checking 40553f55397e ===
  === checking 4f3b41956174 ===
  === checking 37ad3ab0cddf ===
  === checking c7d3029bf731 ===
  === checking 76151e8066e1 ===
  === checking c7c1497fc270 ===
  === checking e7135b665740 ===
  === checking b33fd5ad4c0c ===
  === checking cd345198cf12 ===
  === checking 28be96b80dc1 ===
  === checking c713eae2d31f ===
  === checking 82238c0bc950 ===
  === checking dbde319d43a3 ===
  === checking 8b79544bb56d ===
  === checking d917f77a6439 ===
  === checking c3c7fa726f88 ===
  === checking 97d19fc5236f ===
  === checking 2472d042ec95 ===
  === checking d99e0f7dad5b ===
  === checking e4cfd6264623 ===
  === checking fac9e582edd1 ===
  === checking 89a0fe204177 ===
  === checking b3cf98c3d587 ===
  === checking 041e1188f5f1 ===
  === checking 721ba7c5f4ff ===
  === checking e3e6738c56ce ===
  === checking 790cdfecd168 ===
  === checking 469c700e9ed8 ===
  === checking 8ae32c3ed670 ===
  === checking 84d6ec6a8e21 ===
  === checking 01f771406cab ===

Test stability of this mess
---------------------------

  $ hg log -r tip
  94 01f771406cab r94 Cfinal tip
  $ hg showsort --rev 'all()' > ../crisscross.source.order
  $ cd ..

  $ hg clone crisscross_A crisscross_random --rev 0
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd crisscross_random
  $ for x in `python ../random_rev.py 50 44`; do
  >   # using python to benefit from the random seed
  >   hg pull -r $x --quiet
  > done;
  $ hg pull --quiet

  $ hg showsort --rev 'all()' > ../crisscross.random.order
  $ python "$RUNTESTDIR/md5sum.py" ../crisscross.*.order
  d9aab0d1907d5cf64d205a8b9036e959  ../crisscross.random.order
  d9aab0d1907d5cf64d205a8b9036e959  ../crisscross.source.order
  $ diff -u ../crisscross.*.order
  $ hg showsort --rev 'all()'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  3e2da24aee59
  26f59ee8b1d7
  f7c6e7bfbcd0
  39bab1cb1cbe
  55bf3fdb634f
  3e1560705803
  17b6e6bac221
  5ce588c2b7c5
  f2bdd828a3aa
  a457569c5306
  ad46a4a0fc10
  4f5078f7da8a
  01e29e20ea3f
  32b41ca704e1
  29141354a762
  9729470d9329
  884936b34999
  0484d39906c8
  5eec91b12a58
  c84da74cf586
  3871506da61e
  2bd677d0f13a
  3bdb00d5c818
  b9c3aa92fba5
  f3441cd3e664
  0c3f2ba59eb7
  2ea3fbf151b5
  47c836a1f13e
  722d1b8b8942
  4b39f229a0ce
  d94da36be176
  eed373b0090d
  88714f4125cb
  d928b4e8a515
  88eace5ce682
  698970a2480b
  b115c694654e
  1f4a19f83a29
  43fc0b77ff07
  31d7b43cc321
  673f5499c8c2
  900dd066a072
  97ac964e34b7
  0d153e3ad632
  c37e7cd9f2bd
  9a67238ad1c4
  8ecb28746ec4
  bf6593f7e073
  0bab31f71a21
  1da228afcf06
  bfcfd9a61e84
  d6c9e2d27f14
  de05b9c29ec7
  40553f55397e
  4f3b41956174
  37ad3ab0cddf
  c7d3029bf731
  76151e8066e1
  c7c1497fc270
  e7135b665740
  b33fd5ad4c0c
  cd345198cf12
  28be96b80dc1
  c713eae2d31f
  82238c0bc950
  dbde319d43a3
  8b79544bb56d
  d917f77a6439
  c3c7fa726f88
  97d19fc5236f
  2472d042ec95
  d99e0f7dad5b
  e4cfd6264623
  fac9e582edd1
  89a0fe204177
  b3cf98c3d587
  041e1188f5f1
  721ba7c5f4ff
  e3e6738c56ce
  790cdfecd168
  469c700e9ed8
  8ae32c3ed670
  84d6ec6a8e21
  01f771406cab


Test behavior with oedipus merges
=================================

  $ hg init recursion_oedipus
  $ cd recursion_oedipus
  $ echo base > base
  $ hg add base
  $ hg ci -m base
  $ hg branch foo
  marked working directory as branch foo
  (branches are permanent and global, did you want a bookmark?)
  $ echo foo1 > foo1
  $ hg add foo1
  $ hg ci -m foo1
  $ echo foo2 > foo2
  $ hg add foo2
  $ hg ci -m foo2
  $ hg up default
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg merge foo
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m oedipus_merge
  $ echo default1 > default1
  $ hg add default1
  $ hg ci -m default1
  $ hg log -G 
  @  4 7f2454f6b04f default1 tip
  |
  o    3 ed776db7ed63 oedipus_merge
  |\
  | o  2 0dedbcd995b6 foo2
  | |
  | o  1 47da0f2c25e2 foo1
  |/
  o  0 d20a80d4def3 base
  
  $ hg showsort --rev '.'
  d20a80d4def3
  47da0f2c25e2
  0dedbcd995b6
  ed776db7ed63
  7f2454f6b04f
