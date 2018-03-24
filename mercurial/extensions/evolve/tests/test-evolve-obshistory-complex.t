Global setup
============

  $ . $TESTDIR/testlib/common.sh
  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = true
  > [phases]
  > publish=False
  > [extensions]
  > evolve =
  > EOF

Test obslog with split + fold + split
=====================================

Test setup
----------

  $ hg init $TESTTMP/splitfoldsplit
  $ cd $TESTTMP/splitfoldsplit
  $ mkcommit ROOT
  $ mkcommit A
  $ mkcommit B
  $ mkcommit C
  $ mkcommit D
  $ mkcommit E
  $ mkcommit F
  $ hg log -G
  @  changeset:   6:d9f908fde1a1
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     F
  |
  o  changeset:   5:0da815c333f6
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     E
  |
  o  changeset:   4:868d2e0eb19c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     D
  |
  o  changeset:   3:a8df460dbbfe
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C
  |
  o  changeset:   2:c473644ee0e9
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B
  |
  o  changeset:   1:2a34000d3544
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Split commits two by two
------------------------

  $ hg fold --exact -r 1 -r 2 --date "0 0" -m "fold0"
  4 new orphan changesets
  2 changesets folded
  $ hg fold --exact -r 3 -r 4 --date "0 0" -m "fold1"
  2 changesets folded
  $ hg fold --exact -r 5 -r 6 --date "0 0" -m "fold2" -n "folding changesets to test"
  2 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg obslog -r .
  @    100cc25b765f (9) fold2
  |\
  x |  0da815c333f6 (5) E
   /     rewritten(description, content) as 100cc25b765f using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  |        note: folding changesets to test
  |
  x  d9f908fde1a1 (6) F
       rewritten(description, parent, content) as 100cc25b765f using fold by test (Thu Jan 01 00:00:00 1970 +0000)
         note: folding changesets to test
  
  $ hg log -G 
  @  changeset:   9:100cc25b765f
  |  tag:         tip
  |  parent:      4:868d2e0eb19c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: orphan
  |  summary:     fold2
  |
  | *  changeset:   8:d15d0ffc75f6
  | |  parent:      2:c473644ee0e9
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     fold1
  | |
  | | o  changeset:   7:b868bc49b0a4
  | | |  parent:      0:ea207398892e
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     fold0
  | | |
  x | |  changeset:   4:868d2e0eb19c
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  obsolete:    rewritten using fold as 8:d15d0ffc75f6
  | | |  summary:     D
  | | |
  x | |  changeset:   3:a8df460dbbfe
  |/ /   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    obsolete:    rewritten using fold as 8:d15d0ffc75f6
  | |    summary:     C
  | |
  x |  changeset:   2:c473644ee0e9
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  obsolete:    rewritten using fold as 7:b868bc49b0a4
  | |  summary:     B
  | |
  x |  changeset:   1:2a34000d3544
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten using fold as 7:b868bc49b0a4
  |    summary:     A
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

Then split
----------

  $ hg split "desc(fold0)" -d "0 0" << EOF
  > Y
  > Y
  > N
  > N
  > Y
  > Y
  > EOF
  0 files updated, 0 files merged, 6 files removed, 0 files unresolved
  adding A
  adding B
  diff --git a/A b/A
  new file mode 100644
  examine changes to 'A'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +A
  record change 1/2 to 'A'? [Ynesfdaq?] Y
  
  diff --git a/B b/B
  new file mode 100644
  examine changes to 'B'? [Ynesfdaq?] N
  
  created new head
  Done splitting? [yN] N
  diff --git a/B b/B
  new file mode 100644
  examine changes to 'B'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +B
  record this change to 'B'? [Ynesfdaq?] Y
  
  no more change to split
  $ hg split "desc(fold1)" -d "0 0" << EOF
  > Y
  > Y
  > N
  > N
  > Y
  > Y
  > EOF
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  adding C
  adding D
  diff --git a/C b/C
  new file mode 100644
  examine changes to 'C'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +C
  record change 1/2 to 'C'? [Ynesfdaq?] Y
  
  diff --git a/D b/D
  new file mode 100644
  examine changes to 'D'? [Ynesfdaq?] N
  
  created new head
  Done splitting? [yN] N
  diff --git a/D b/D
  new file mode 100644
  examine changes to 'D'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +D
  record this change to 'D'? [Ynesfdaq?] Y
  
  no more change to split
  1 new orphan changesets
  $ hg split "desc(fold2)" -d "0 0" << EOF
  > Y
  > Y
  > N
  > N
  > Y
  > Y
  > EOF
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  adding E
  adding F
  diff --git a/E b/E
  new file mode 100644
  examine changes to 'E'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +E
  record change 1/2 to 'E'? [Ynesfdaq?] Y
  
  diff --git a/F b/F
  new file mode 100644
  examine changes to 'F'? [Ynesfdaq?] N
  
  created new head
  Done splitting? [yN] N
  diff --git a/F b/F
  new file mode 100644
  examine changes to 'F'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +F
  record this change to 'F'? [Ynesfdaq?] Y
  
  no more change to split
  1 new orphan changesets
  $ hg log -G
  @  changeset:   15:d4a000f63ee9
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: orphan
  |  summary:     fold2
  |
  *  changeset:   14:ec31316faa9d
  |  parent:      4:868d2e0eb19c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: orphan
  |  summary:     fold2
  |
  | *  changeset:   13:d0f33db50670
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     fold1
  | |
  | *  changeset:   12:7b3290f6e0a0
  | |  parent:      2:c473644ee0e9
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     fold1
  | |
  | | o  changeset:   11:e036916b63ea
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     fold0
  | | |
  | | o  changeset:   10:19e14c8397fc
  | | |  parent:      0:ea207398892e
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     fold0
  | | |
  x | |  changeset:   4:868d2e0eb19c
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  obsolete:    split using fold, split as 12:7b3290f6e0a0, 13:d0f33db50670
  | | |  summary:     D
  | | |
  x | |  changeset:   3:a8df460dbbfe
  |/ /   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    obsolete:    split using fold, split as 12:7b3290f6e0a0, 13:d0f33db50670
  | |    summary:     C
  | |
  x |  changeset:   2:c473644ee0e9
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  obsolete:    split using fold, split as 10:19e14c8397fc, 11:e036916b63ea
  | |  summary:     B
  | |
  x |  changeset:   1:2a34000d3544
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    split using fold, split as 10:19e14c8397fc, 11:e036916b63ea
  |    summary:     A
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

Connect them all
----------------

  $ hg prune -s 12 -r 11
  1 changesets pruned
  $ hg prune -s 14 -r 13 -n "this is a note stored in obsmarker in prune"
  1 changesets pruned
  $ hg log -G
  @  changeset:   15:d4a000f63ee9
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: orphan
  |  summary:     fold2
  |
  *  changeset:   14:ec31316faa9d
  |  parent:      4:868d2e0eb19c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: orphan
  |  summary:     fold2
  |
  | *  changeset:   12:7b3290f6e0a0
  | |  parent:      2:c473644ee0e9
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     fold1
  | |
  | | o  changeset:   10:19e14c8397fc
  | | |  parent:      0:ea207398892e
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     fold0
  | | |
  x | |  changeset:   4:868d2e0eb19c
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  obsolete:    split using fold, prune, split as 12:7b3290f6e0a0, 14:ec31316faa9d
  | | |  summary:     D
  | | |
  x | |  changeset:   3:a8df460dbbfe
  |/ /   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    obsolete:    split using fold, prune, split as 12:7b3290f6e0a0, 14:ec31316faa9d
  | |    summary:     C
  | |
  x |  changeset:   2:c473644ee0e9
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  obsolete:    split using fold, prune, split as 10:19e14c8397fc, 12:7b3290f6e0a0
  | |  summary:     B
  | |
  x |  changeset:   1:2a34000d3544
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    split using fold, prune, split as 10:19e14c8397fc, 12:7b3290f6e0a0
  |    summary:     A
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual Test
===========

Obslog should show a subset of the obs history, this test check that the
walking algorithm works no matter the level of successors + precursors

  $ hg obslog 12
  *    7b3290f6e0a0 (12) fold1
  |\
  x |    d15d0ffc75f6 (8) fold1
  |\ \     rewritten(parent, content) as 7b3290f6e0a0, d0f33db50670 using split by test (Thu Jan 01 00:00:00 1970 +0000)
  | | |
  | | x  e036916b63ea (11) fold0
  | | |    rewritten(description, parent, content) as 7b3290f6e0a0 using prune by test (Thu Jan 01 00:00:00 1970 +0000)
  | | |
  x | |  868d2e0eb19c (4) D
   / /     rewritten(description, parent, content) as d15d0ffc75f6 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  | |
  x |  a8df460dbbfe (3) C
   /     rewritten(description, content) as d15d0ffc75f6 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  |
  x    b868bc49b0a4 (7) fold0
  |\     rewritten(parent, content) as 19e14c8397fc, e036916b63ea using split by test (Thu Jan 01 00:00:00 1970 +0000)
  | |
  x |  2a34000d3544 (1) A
   /     rewritten(description, content) as b868bc49b0a4 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  |
  x  c473644ee0e9 (2) B
       rewritten(description, parent, content) as b868bc49b0a4 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  
While with all option, we should see 15 changesets

  $ hg obslog --all 15
  o  19e14c8397fc (10) fold0
  |
  | *    7b3290f6e0a0 (12) fold1
  | |\
  | | | @  d4a000f63ee9 (15) fold2
  | | | |
  | | | | *  ec31316faa9d (14) fold2
  | | | |/|
  | | | x |    100cc25b765f (9) fold2
  | | | |\ \     rewritten(parent, content) as d4a000f63ee9, ec31316faa9d using split by test (Thu Jan 01 00:00:00 1970 +0000)
  | | | | | |
  | +-------x  d0f33db50670 (13) fold1
  | | | | |      rewritten(description, parent, content) as ec31316faa9d using prune by test (Thu Jan 01 00:00:00 1970 +0000)
  | | | | |        note: this is a note stored in obsmarker in prune
  | | | | |
  +---x | |  e036916b63ea (11) fold0
  | |  / /     rewritten(description, parent, content) as 7b3290f6e0a0 using prune by test (Thu Jan 01 00:00:00 1970 +0000)
  | | | |
  | | x |  0da815c333f6 (5) E
  | |  /     rewritten(description, content) as 100cc25b765f using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  | | |        note: folding changesets to test
  | | |
  x | |    b868bc49b0a4 (7) fold0
  |\ \ \     rewritten(parent, content) as 19e14c8397fc, e036916b63ea using split by test (Thu Jan 01 00:00:00 1970 +0000)
  | | | |
  | | x |    d15d0ffc75f6 (8) fold1
  | | |\ \     rewritten(parent, content) as 7b3290f6e0a0, d0f33db50670 using split by test (Thu Jan 01 00:00:00 1970 +0000)
  | | | | |
  | | | | x  d9f908fde1a1 (6) F
  | | | |      rewritten(description, parent, content) as 100cc25b765f using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  | | | |        note: folding changesets to test
  | | | |
  x | | |  2a34000d3544 (1) A
   / / /     rewritten(description, content) as b868bc49b0a4 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  | | |
  | x |  868d2e0eb19c (4) D
  |  /     rewritten(description, parent, content) as d15d0ffc75f6 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  | |
  | x  a8df460dbbfe (3) C
  |      rewritten(description, content) as d15d0ffc75f6 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  |
  x  c473644ee0e9 (2) B
       rewritten(description, parent, content) as b868bc49b0a4 using fold by test (Thu Jan 01 00:00:00 1970 +0000)
  
