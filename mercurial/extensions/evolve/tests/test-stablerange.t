Test for stable ordering capabilities
=====================================

  $ . $TESTDIR/testlib/pythonpath.sh

  $ cat << EOF >> $HGRCPATH
  > [extensions]
  > hgext3rd.evolve =
  > [ui]
  > logtemplate = "{rev} {node|short} {desc} {tags}\n"
  > EOF

Simple linear test
==================

  $ hg init repo_linear
  $ cd repo_linear
  $ hg debugbuilddag '.+6'
  $ hg debugstablerange --verify --verbose --subranges --rev 1
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 1 > 1.range

bigger subset reuse most of the previous one

  $ hg debugstablerange --verify --verbose --subranges --rev 4
  bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  bebd167eb94d-4 (4, 5, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 4 > 4.range
  $ diff -u 1.range 4.range
  --- 1.range	* (glob)
  +++ 4.range	* (glob)
  @@ -1,3 +1,9 @@
  +bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  +2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  +01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
  +2dc09a01254d-3 (3, 4, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
  +bebd167eb94d-4 (4, 5, 1) [leaf] - 
  [1]

Using a range not ending on 2**N boundary
we fall back on 2**N as much as possible

  $ hg debugstablerange --verify --verbose --subranges --rev 5
  c8d03c1b5e94-0 (5, 6, 6) [complete] - 2dc09a01254d-0 (3, 4, 4), c8d03c1b5e94-4 (5, 6, 2)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  c8d03c1b5e94-4 (5, 6, 2) [complete] - bebd167eb94d-4 (4, 5, 1), c8d03c1b5e94-5 (5, 6, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  bebd167eb94d-4 (4, 5, 1) [leaf] - 
  c8d03c1b5e94-5 (5, 6, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 5 > 5.range
  $ diff -u 4.range 5.range
  --- 4.range	* (glob)
  +++ 5.range	* (glob)
  @@ -1,9 +1,11 @@
  -bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  +c8d03c1b5e94-0 (5, 6, 6) [complete] - 2dc09a01254d-0 (3, 4, 4), c8d03c1b5e94-4 (5, 6, 2)
   2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
   2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  +c8d03c1b5e94-4 (5, 6, 2) [complete] - bebd167eb94d-4 (4, 5, 1), c8d03c1b5e94-5 (5, 6, 1)
   01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
   2dc09a01254d-3 (3, 4, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
   bebd167eb94d-4 (4, 5, 1) [leaf] - 
  +c8d03c1b5e94-5 (5, 6, 1) [leaf] - 
  [1]

Even two unperfect range overlap a lot

  $ hg debugstablerange --verify --verbose --subranges --rev tip
  f69452c5b1af-0 (6, 7, 7) [complete] - 2dc09a01254d-0 (3, 4, 4), f69452c5b1af-4 (6, 7, 3)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  f69452c5b1af-4 (6, 7, 3) [complete] - c8d03c1b5e94-4 (5, 6, 2), f69452c5b1af-6 (6, 7, 1)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  c8d03c1b5e94-4 (5, 6, 2) [complete] - bebd167eb94d-4 (4, 5, 1), c8d03c1b5e94-5 (5, 6, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  bebd167eb94d-4 (4, 5, 1) [leaf] - 
  c8d03c1b5e94-5 (5, 6, 1) [leaf] - 
  f69452c5b1af-6 (6, 7, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev tip > tip.range
  $ diff -u 5.range tip.range
  --- 5.range	* (glob)
  +++ tip.range	* (glob)
  @@ -1,5 +1,6 @@
  -c8d03c1b5e94-0 (5, 6, 6) [complete] - 2dc09a01254d-0 (3, 4, 4), c8d03c1b5e94-4 (5, 6, 2)
  +f69452c5b1af-0 (6, 7, 7) [complete] - 2dc09a01254d-0 (3, 4, 4), f69452c5b1af-4 (6, 7, 3)
   2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +f69452c5b1af-4 (6, 7, 3) [complete] - c8d03c1b5e94-4 (5, 6, 2), f69452c5b1af-6 (6, 7, 1)
   2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
   c8d03c1b5e94-4 (5, 6, 2) [complete] - bebd167eb94d-4 (4, 5, 1), c8d03c1b5e94-5 (5, 6, 1)
  @@ -9,3 +10,4 @@
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
   bebd167eb94d-4 (4, 5, 1) [leaf] - 
   c8d03c1b5e94-5 (5, 6, 1) [leaf] - 
  +f69452c5b1af-6 (6, 7, 1) [leaf] - 
  [1]

  $ cd ..

Case with merge
===============

Simple case: branching is on a boundary
--------------------------------------------

  $ hg init repo_merge_split_on_boundary
  $ cd repo_merge_split_on_boundary
  $ hg debugbuilddag '.:base
  > +3:left
  > <base+3:right
  > <left/right:merge
  > +2:head
  > '
  $ hg log -G
  o  9 0338daf18215 r9 head tip
  |
  o  8 71b32fcf3f71 r8
  |
  o    7 5f18015f9110 r7 merge
  |\
  | o  6 a2f58e9c1e56 r6 right
  | |
  | o  5 3a367db1fabc r5
  | |
  | o  4 e7bd5218ca15 r4
  | |
  o |  3 2dc09a01254d r3 left
  | |
  o |  2 01241442b3c2 r2
  | |
  o |  1 66f7d451a68b r1
  |/
  o  0 1ea73414a91b r0 base
  

Each of the linear branch reuse range internally

(left branch)

  $ hg debugstablerange --verify --verbose --subranges --rev 'left~2'
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'left~2' > left-2.range
  $ hg debugstablerange --verify --verbose --subranges --rev left
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'left' > left.range
  $ diff -u left-2.range left.range
  --- left-2.range	* (glob)
  +++ left.range	* (glob)
  @@ -1,3 +1,7 @@
  +2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  +01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
  +2dc09a01254d-3 (3, 4, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
  [1]

(right branch)

  $ hg debugstablerange --verify --verbose --subranges --rev right~2
  e7bd5218ca15-0 (4, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), e7bd5218ca15-1 (4, 2, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  e7bd5218ca15-1 (4, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'right~2' > right-2.range
  $ hg debugstablerange --verify --verbose --subranges --rev right
  a2f58e9c1e56-0 (6, 4, 4) [complete] - e7bd5218ca15-0 (4, 2, 2), a2f58e9c1e56-2 (6, 4, 2)
  a2f58e9c1e56-2 (6, 4, 2) [complete] - 3a367db1fabc-2 (5, 3, 1), a2f58e9c1e56-3 (6, 4, 1)
  e7bd5218ca15-0 (4, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), e7bd5218ca15-1 (4, 2, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  3a367db1fabc-2 (5, 3, 1) [leaf] - 
  a2f58e9c1e56-3 (6, 4, 1) [leaf] - 
  e7bd5218ca15-1 (4, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'right' > right.range
  $ diff -u right-2.range right.range
  --- right-2.range	* (glob)
  +++ right.range	* (glob)
  @@ -1,3 +1,7 @@
  +a2f58e9c1e56-0 (6, 4, 4) [complete] - e7bd5218ca15-0 (4, 2, 2), a2f58e9c1e56-2 (6, 4, 2)
  +a2f58e9c1e56-2 (6, 4, 2) [complete] - 3a367db1fabc-2 (5, 3, 1), a2f58e9c1e56-3 (6, 4, 1)
   e7bd5218ca15-0 (4, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), e7bd5218ca15-1 (4, 2, 1)
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
  +3a367db1fabc-2 (5, 3, 1) [leaf] - 
  +a2f58e9c1e56-3 (6, 4, 1) [leaf] - 
   e7bd5218ca15-1 (4, 2, 1) [leaf] - 
  [1]

The merge reuse as much of the slicing created for one of the branch

  $ hg debugstablerange --verify --verbose --subranges --rev merge
  5f18015f9110-0 (7, 8, 8) [complete] - 2dc09a01254d-0 (3, 4, 4), 5f18015f9110-4 (7, 8, 4)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  5f18015f9110-4 (7, 8, 4) [complete] - 3a367db1fabc-1 (5, 3, 2), 5f18015f9110-6 (7, 8, 2)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  3a367db1fabc-1 (5, 3, 2) [complete] - e7bd5218ca15-1 (4, 2, 1), 3a367db1fabc-2 (5, 3, 1)
  5f18015f9110-6 (7, 8, 2) [complete] - a2f58e9c1e56-3 (6, 4, 1), 5f18015f9110-7 (7, 8, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  3a367db1fabc-2 (5, 3, 1) [leaf] - 
  5f18015f9110-7 (7, 8, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  a2f58e9c1e56-3 (6, 4, 1) [leaf] - 
  e7bd5218ca15-1 (4, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'merge' > merge.range
  $ diff -u left.range merge.range
  --- left.range	* (glob)
  +++ merge.range	* (glob)
  @@ -1,7 +1,15 @@
  +5f18015f9110-0 (7, 8, 8) [complete] - 2dc09a01254d-0 (3, 4, 4), 5f18015f9110-4 (7, 8, 4)
   2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +5f18015f9110-4 (7, 8, 4) [complete] - 3a367db1fabc-1 (5, 3, 2), 5f18015f9110-6 (7, 8, 2)
   2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  +3a367db1fabc-1 (5, 3, 2) [complete] - e7bd5218ca15-1 (4, 2, 1), 3a367db1fabc-2 (5, 3, 1)
  +5f18015f9110-6 (7, 8, 2) [complete] - a2f58e9c1e56-3 (6, 4, 1), 5f18015f9110-7 (7, 8, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
   01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
   2dc09a01254d-3 (3, 4, 1) [leaf] - 
  +3a367db1fabc-2 (5, 3, 1) [leaf] - 
  +5f18015f9110-7 (7, 8, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
  +a2f58e9c1e56-3 (6, 4, 1) [leaf] - 
  +e7bd5218ca15-1 (4, 2, 1) [leaf] - 
  [1]
  $ diff -u right.range merge.range
  --- right.range	* (glob)
  +++ merge.range	* (glob)
  @@ -1,7 +1,15 @@
  -a2f58e9c1e56-0 (6, 4, 4) [complete] - e7bd5218ca15-0 (4, 2, 2), a2f58e9c1e56-2 (6, 4, 2)
  -a2f58e9c1e56-2 (6, 4, 2) [complete] - 3a367db1fabc-2 (5, 3, 1), a2f58e9c1e56-3 (6, 4, 1)
  -e7bd5218ca15-0 (4, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), e7bd5218ca15-1 (4, 2, 1)
  +5f18015f9110-0 (7, 8, 8) [complete] - 2dc09a01254d-0 (3, 4, 4), 5f18015f9110-4 (7, 8, 4)
  +2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +5f18015f9110-4 (7, 8, 4) [complete] - 3a367db1fabc-1 (5, 3, 2), 5f18015f9110-6 (7, 8, 2)
  +2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  +3a367db1fabc-1 (5, 3, 2) [complete] - e7bd5218ca15-1 (4, 2, 1), 3a367db1fabc-2 (5, 3, 1)
  +5f18015f9110-6 (7, 8, 2) [complete] - a2f58e9c1e56-3 (6, 4, 1), 5f18015f9110-7 (7, 8, 1)
  +66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  +01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
  +2dc09a01254d-3 (3, 4, 1) [leaf] - 
   3a367db1fabc-2 (5, 3, 1) [leaf] - 
  +5f18015f9110-7 (7, 8, 1) [leaf] - 
  +66f7d451a68b-1 (1, 2, 1) [leaf] - 
   a2f58e9c1e56-3 (6, 4, 1) [leaf] - 
   e7bd5218ca15-1 (4, 2, 1) [leaf] - 
  [1]
  $ cd ..

slice create multiple heads
---------------------------

  $ hg init repo_merge_split_heads
  $ cd repo_merge_split_heads
  $ hg debugbuilddag '.:base
  > +4:left
  > <base+5:right
  > <left/right:merge
  > +2:head
  > '
  $ hg debugbuilddag '.:base
  > +3:left
  > <base+3:right
  > <left/right:merge
  > +2:head
  > '
  abort: repository is not empty
  [255]
  $ hg log -G
  o  12 e6b8d5b46647 r12 head tip
  |
  o  11 485383494a89 r11
  |
  o    10 8aca7f8c9bd2 r10 merge
  |\
  | o  9 f4b7da68b467 r9 right
  | |
  | o  8 857477a9aebb r8
  | |
  | o  7 42b07e8da27d r7
  | |
  | o  6 b9bc20507e0b r6
  | |
  | o  5 de561312eff4 r5
  | |
  o |  4 bebd167eb94d r4 left
  | |
  o |  3 2dc09a01254d r3
  | |
  o |  2 01241442b3c2 r2
  | |
  o |  1 66f7d451a68b r1
  |/
  o  0 1ea73414a91b r0 base
  

Each of the linear branch reuse range internally

(left branch)

  $ hg debugstablerange --verify --verbose --subranges --rev 'left~2'
  01241442b3c2-0 (2, 3, 3) [complete] - 66f7d451a68b-0 (1, 2, 2), 01241442b3c2-2 (2, 3, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'left~2' > left-2.range
  $ hg debugstablerange --verify --verbose --subranges --rev left
  bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  bebd167eb94d-4 (4, 5, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'left' > left.range
  $ diff -u left-2.range left.range
  --- left-2.range	* (glob)
  +++ left.range	* (glob)
  @@ -1,5 +1,9 @@
  -01241442b3c2-0 (2, 3, 3) [complete] - 66f7d451a68b-0 (1, 2, 2), 01241442b3c2-2 (2, 3, 1)
  +bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  +2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
   01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
  +2dc09a01254d-3 (3, 4, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
  +bebd167eb94d-4 (4, 5, 1) [leaf] - 
  [1]

(right branch)

  $ hg debugstablerange --verify --verbose --subranges --rev right~2
  42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
  de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  42b07e8da27d-3 (7, 4, 1) [leaf] - 
  b9bc20507e0b-2 (6, 3, 1) [leaf] - 
  de561312eff4-1 (5, 2, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'right~2' > right-2.range
  $ hg debugstablerange --verify --verbose --subranges --rev right
  f4b7da68b467-0 (9, 6, 6) [complete] - 42b07e8da27d-0 (7, 4, 4), f4b7da68b467-4 (9, 6, 2)
  42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
  de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
  f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  42b07e8da27d-3 (7, 4, 1) [leaf] - 
  857477a9aebb-4 (8, 5, 1) [leaf] - 
  b9bc20507e0b-2 (6, 3, 1) [leaf] - 
  de561312eff4-1 (5, 2, 1) [leaf] - 
  f4b7da68b467-5 (9, 6, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'right' > right.range
  $ diff -u right-2.range right.range
  --- right-2.range	* (glob)
  +++ right.range	* (glob)
  @@ -1,7 +1,11 @@
  +f4b7da68b467-0 (9, 6, 6) [complete] - 42b07e8da27d-0 (7, 4, 4), f4b7da68b467-4 (9, 6, 2)
   42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
   42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
   de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
  +f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
   42b07e8da27d-3 (7, 4, 1) [leaf] - 
  +857477a9aebb-4 (8, 5, 1) [leaf] - 
   b9bc20507e0b-2 (6, 3, 1) [leaf] - 
   de561312eff4-1 (5, 2, 1) [leaf] - 
  +f4b7da68b467-5 (9, 6, 1) [leaf] - 
  [1]

In this case, the bottom of the split will have multiple heads,

So we'll create more than 1 subrange out of it.

We are still able to reuse one of the branch however

  $ hg debugstablerange --verify --verbose --subranges --rev merge
  8aca7f8c9bd2-0 (10, 11, 11) [complete] - bebd167eb94d-0 (4, 5, 5), 42b07e8da27d-0 (7, 4, 4), 8aca7f8c9bd2-8 (10, 11, 3)
  bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  8aca7f8c9bd2-8 (10, 11, 3) [complete] - f4b7da68b467-4 (9, 6, 2), 8aca7f8c9bd2-10 (10, 11, 1)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
  f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  42b07e8da27d-3 (7, 4, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  857477a9aebb-4 (8, 5, 1) [leaf] - 
  8aca7f8c9bd2-10 (10, 11, 1) [leaf] - 
  b9bc20507e0b-2 (6, 3, 1) [leaf] - 
  bebd167eb94d-4 (4, 5, 1) [leaf] - 
  de561312eff4-1 (5, 2, 1) [leaf] - 
  f4b7da68b467-5 (9, 6, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'merge' > merge.range
  $ diff -u left.range merge.range
  --- left.range	* (glob)
  +++ merge.range	* (glob)
  @@ -1,9 +1,21 @@
  +8aca7f8c9bd2-0 (10, 11, 11) [complete] - bebd167eb94d-0 (4, 5, 5), 42b07e8da27d-0 (7, 4, 4), 8aca7f8c9bd2-8 (10, 11, 3)
   bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
   2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  +42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  +8aca7f8c9bd2-8 (10, 11, 3) [complete] - f4b7da68b467-4 (9, 6, 2), 8aca7f8c9bd2-10 (10, 11, 1)
   2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  +42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  +de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
  +f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
   01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
   2dc09a01254d-3 (3, 4, 1) [leaf] - 
  +42b07e8da27d-3 (7, 4, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
  +857477a9aebb-4 (8, 5, 1) [leaf] - 
  +8aca7f8c9bd2-10 (10, 11, 1) [leaf] - 
  +b9bc20507e0b-2 (6, 3, 1) [leaf] - 
   bebd167eb94d-4 (4, 5, 1) [leaf] - 
  +de561312eff4-1 (5, 2, 1) [leaf] - 
  +f4b7da68b467-5 (9, 6, 1) [leaf] - 
  [1]
  $ diff -u right.range merge.range
  --- right.range	* (glob)
  +++ merge.range	* (glob)
  @@ -1,11 +1,21 @@
  -f4b7da68b467-0 (9, 6, 6) [complete] - 42b07e8da27d-0 (7, 4, 4), f4b7da68b467-4 (9, 6, 2)
  +8aca7f8c9bd2-0 (10, 11, 11) [complete] - bebd167eb94d-0 (4, 5, 5), 42b07e8da27d-0 (7, 4, 4), 8aca7f8c9bd2-8 (10, 11, 3)
  +bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  +2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
   42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  +8aca7f8c9bd2-8 (10, 11, 3) [complete] - f4b7da68b467-4 (9, 6, 2), 8aca7f8c9bd2-10 (10, 11, 1)
  +2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
  +66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
   de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
   f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
  +01241442b3c2-2 (2, 3, 1) [leaf] - 
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
  +2dc09a01254d-3 (3, 4, 1) [leaf] - 
   42b07e8da27d-3 (7, 4, 1) [leaf] - 
  +66f7d451a68b-1 (1, 2, 1) [leaf] - 
   857477a9aebb-4 (8, 5, 1) [leaf] - 
  +8aca7f8c9bd2-10 (10, 11, 1) [leaf] - 
   b9bc20507e0b-2 (6, 3, 1) [leaf] - 
  +bebd167eb94d-4 (4, 5, 1) [leaf] - 
   de561312eff4-1 (5, 2, 1) [leaf] - 
   f4b7da68b467-5 (9, 6, 1) [leaf] - 
  [1]

Range above the merge, reuse subrange from the merge

  $ hg debugstablerange --verify --verbose --subranges --rev tip
  e6b8d5b46647-0 (12, 13, 13) [complete] - bebd167eb94d-0 (4, 5, 5), 42b07e8da27d-0 (7, 4, 4), e6b8d5b46647-8 (12, 13, 5)
  bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  e6b8d5b46647-8 (12, 13, 5) [complete] - 485383494a89-8 (11, 12, 4), e6b8d5b46647-12 (12, 13, 1)
  2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
  42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  485383494a89-8 (11, 12, 4) [complete] - f4b7da68b467-4 (9, 6, 2), 485383494a89-10 (11, 12, 2)
  2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
  42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
  485383494a89-10 (11, 12, 2) [complete] - 8aca7f8c9bd2-10 (10, 11, 1), 485383494a89-11 (11, 12, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
  f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
  01241442b3c2-2 (2, 3, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2dc09a01254d-3 (3, 4, 1) [leaf] - 
  42b07e8da27d-3 (7, 4, 1) [leaf] - 
  485383494a89-11 (11, 12, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  857477a9aebb-4 (8, 5, 1) [leaf] - 
  8aca7f8c9bd2-10 (10, 11, 1) [leaf] - 
  b9bc20507e0b-2 (6, 3, 1) [leaf] - 
  bebd167eb94d-4 (4, 5, 1) [leaf] - 
  de561312eff4-1 (5, 2, 1) [leaf] - 
  e6b8d5b46647-12 (12, 13, 1) [leaf] - 
  f4b7da68b467-5 (9, 6, 1) [leaf] - 
  $ hg debugstablerange --verify --verbose --subranges --rev 'tip' > tip.range
  $ diff -u merge.range tip.range
  --- merge.range	* (glob)
  +++ tip.range	* (glob)
  @@ -1,10 +1,12 @@
  -8aca7f8c9bd2-0 (10, 11, 11) [complete] - bebd167eb94d-0 (4, 5, 5), 42b07e8da27d-0 (7, 4, 4), 8aca7f8c9bd2-8 (10, 11, 3)
  +e6b8d5b46647-0 (12, 13, 13) [complete] - bebd167eb94d-0 (4, 5, 5), 42b07e8da27d-0 (7, 4, 4), e6b8d5b46647-8 (12, 13, 5)
   bebd167eb94d-0 (4, 5, 5) [complete] - 2dc09a01254d-0 (3, 4, 4), bebd167eb94d-4 (4, 5, 1)
  +e6b8d5b46647-8 (12, 13, 5) [complete] - 485383494a89-8 (11, 12, 4), e6b8d5b46647-12 (12, 13, 1)
   2dc09a01254d-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2dc09a01254d-2 (3, 4, 2)
   42b07e8da27d-0 (7, 4, 4) [complete] - de561312eff4-0 (5, 2, 2), 42b07e8da27d-2 (7, 4, 2)
  -8aca7f8c9bd2-8 (10, 11, 3) [complete] - f4b7da68b467-4 (9, 6, 2), 8aca7f8c9bd2-10 (10, 11, 1)
  +485383494a89-8 (11, 12, 4) [complete] - f4b7da68b467-4 (9, 6, 2), 485383494a89-10 (11, 12, 2)
   2dc09a01254d-2 (3, 4, 2) [complete] - 01241442b3c2-2 (2, 3, 1), 2dc09a01254d-3 (3, 4, 1)
   42b07e8da27d-2 (7, 4, 2) [complete] - b9bc20507e0b-2 (6, 3, 1), 42b07e8da27d-3 (7, 4, 1)
  +485383494a89-10 (11, 12, 2) [complete] - 8aca7f8c9bd2-10 (10, 11, 1), 485383494a89-11 (11, 12, 1)
   66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
   de561312eff4-0 (5, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), de561312eff4-1 (5, 2, 1)
   f4b7da68b467-4 (9, 6, 2) [complete] - 857477a9aebb-4 (8, 5, 1), f4b7da68b467-5 (9, 6, 1)
  @@ -12,10 +14,12 @@
   1ea73414a91b-0 (0, 1, 1) [leaf] - 
   2dc09a01254d-3 (3, 4, 1) [leaf] - 
   42b07e8da27d-3 (7, 4, 1) [leaf] - 
  +485383494a89-11 (11, 12, 1) [leaf] - 
   66f7d451a68b-1 (1, 2, 1) [leaf] - 
   857477a9aebb-4 (8, 5, 1) [leaf] - 
   8aca7f8c9bd2-10 (10, 11, 1) [leaf] - 
   b9bc20507e0b-2 (6, 3, 1) [leaf] - 
   bebd167eb94d-4 (4, 5, 1) [leaf] - 
   de561312eff4-1 (5, 2, 1) [leaf] - 
  +e6b8d5b46647-12 (12, 13, 1) [leaf] - 
   f4b7da68b467-5 (9, 6, 1) [leaf] - 
  [1]

  $ cd ..

Tests range with criss cross merge in the graph
===============================================

  $ hg init repo_criss_cross
  $ cd repo_criss_cross
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
  
  $ hg debugstablerange --verify --verbose --subranges --rev 'head()'
  1d8d22637c2d-0 (15, 8, 8) [complete] - 2b6d669947cd-0 (3, 4, 4), 1d8d22637c2d-4 (15, 8, 4)
  dcbb326fdec2-0 (9, 7, 7) [complete] - 2b6d669947cd-0 (3, 4, 4), dcbb326fdec2-4 (9, 7, 3)
  ff43616e5d0f-0 (10, 7, 7) [complete] - 2b6d669947cd-0 (3, 4, 4), ff43616e5d0f-4 (10, 7, 3)
  b4594d867745-0 (13, 6, 6) [complete] - 2b6d669947cd-0 (3, 4, 4), b4594d867745-4 (13, 6, 2)
  e46a4836065c-0 (12, 6, 6) [complete] - 2b6d669947cd-0 (3, 4, 4), e46a4836065c-4 (12, 6, 2)
  2702dd0c91e7-0 (6, 5, 5) [complete] - f0f3ef9a6cd5-0 (5, 4, 4), 2702dd0c91e7-4 (6, 5, 1)
  1d8d22637c2d-4 (15, 8, 4) [complete] - 4c748ffd1a46-2 (4, 3, 1), 43227190fef8-4 (14, 5, 1), 1d8d22637c2d-6 (15, 8, 2)
  2b6d669947cd-0 (3, 4, 4) [complete] - 66f7d451a68b-0 (1, 2, 2), 2b6d669947cd-2 (3, 4, 2)
  f0f3ef9a6cd5-0 (5, 4, 4) [complete] - fa942426a6fd-0 (2, 2, 2), f0f3ef9a6cd5-2 (5, 4, 2)
  dcbb326fdec2-4 (9, 7, 3) [complete] - d62d843c9a01-4 (8, 6, 2), dcbb326fdec2-6 (9, 7, 1)
  ff43616e5d0f-4 (10, 7, 3) [complete] - d62d843c9a01-4 (8, 6, 2), ff43616e5d0f-6 (10, 7, 1)
  1d8d22637c2d-6 (15, 8, 2) [complete] - f0f3ef9a6cd5-3 (5, 4, 1), 1d8d22637c2d-7 (15, 8, 1)
  2b6d669947cd-2 (3, 4, 2) [complete] - fa942426a6fd-1 (2, 2, 1), 2b6d669947cd-3 (3, 4, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  b4594d867745-4 (13, 6, 2) [complete] - bab5d5bf48bd-4 (11, 5, 1), b4594d867745-5 (13, 6, 1)
  d62d843c9a01-4 (8, 6, 2) [complete] - e7d9710d9fc6-4 (7, 5, 1), d62d843c9a01-5 (8, 6, 1)
  e46a4836065c-4 (12, 6, 2) [complete] - bab5d5bf48bd-4 (11, 5, 1), e46a4836065c-5 (12, 6, 1)
  f0f3ef9a6cd5-2 (5, 4, 2) [complete] - 4c748ffd1a46-2 (4, 3, 1), f0f3ef9a6cd5-3 (5, 4, 1)
  fa942426a6fd-0 (2, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), fa942426a6fd-1 (2, 2, 1)
  1d8d22637c2d-7 (15, 8, 1) [leaf] - 
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  2702dd0c91e7-4 (6, 5, 1) [leaf] - 
  2b6d669947cd-3 (3, 4, 1) [leaf] - 
  43227190fef8-4 (14, 5, 1) [leaf] - 
  4c748ffd1a46-2 (4, 3, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  b4594d867745-5 (13, 6, 1) [leaf] - 
  bab5d5bf48bd-4 (11, 5, 1) [leaf] - 
  d62d843c9a01-5 (8, 6, 1) [leaf] - 
  dcbb326fdec2-6 (9, 7, 1) [leaf] - 
  e46a4836065c-5 (12, 6, 1) [leaf] - 
  e7d9710d9fc6-4 (7, 5, 1) [leaf] - 
  f0f3ef9a6cd5-3 (5, 4, 1) [leaf] - 
  fa942426a6fd-1 (2, 2, 1) [leaf] - 
  ff43616e5d0f-6 (10, 7, 1) [leaf] - 
  $ cd ..

Tests range where a toprange is rooted on a merge
=================================================

  $ hg init slice_on_merge
  $ cd slice_on_merge
  $ hg debugbuilddag '
  > ..:a   # 2 nodes, tagged "a"
  > <2..:b   # another branch with two node based on 0, tagged b
  > *a/b:m # merge -1 and -2 (1, 2), tagged "m"
  > '
  $ hg log -G
  o    4 f37e476fba9a r4 m tip
  |\
  | o  3 36315563e2fa r3 b
  | |
  | o  2 fa942426a6fd r2
  | |
  o |  1 66f7d451a68b r1 a
  |/
  o  0 1ea73414a91b r0
  
  $ hg debugstablerange --verify --verbose --subranges --rev 'head()'
  f37e476fba9a-0 (4, 5, 5) [complete] - 66f7d451a68b-0 (1, 2, 2), 36315563e2fa-0 (3, 3, 3), f37e476fba9a-4 (4, 5, 1)
  36315563e2fa-0 (3, 3, 3) [complete] - fa942426a6fd-0 (2, 2, 2), 36315563e2fa-2 (3, 3, 1)
  66f7d451a68b-0 (1, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), 66f7d451a68b-1 (1, 2, 1)
  fa942426a6fd-0 (2, 2, 2) [complete] - 1ea73414a91b-0 (0, 1, 1), fa942426a6fd-1 (2, 2, 1)
  1ea73414a91b-0 (0, 1, 1) [leaf] - 
  36315563e2fa-2 (3, 3, 1) [leaf] - 
  66f7d451a68b-1 (1, 2, 1) [leaf] - 
  f37e476fba9a-4 (4, 5, 1) [leaf] - 
  fa942426a6fd-1 (2, 2, 1) [leaf] - 

