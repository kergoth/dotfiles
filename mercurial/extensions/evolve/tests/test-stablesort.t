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

  $ cat << EOF >> random_rev.py
  > import random
  > import sys
  > 
  > loop = int(sys.argv[1])
  > var = int(sys.argv[2])
  > for x in range(loop):
  >     print(x + random.randint(0, var))
  > EOF

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
