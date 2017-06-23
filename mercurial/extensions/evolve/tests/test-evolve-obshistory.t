This test file test the various messages when accessing obsolete
revisions.

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
  > [experimental]
  > evolution.effect-flags = yes
  > EOF

Test output on amended commit
=============================

Test setup
----------

  $ hg init $TESTTMP/local-amend
  $ cd $TESTTMP/local-amend
  $ mkcommit ROOT
  $ mkcommit A0
  $ echo 42 >> A0
  $ hg amend -m "A1
  > 
  > Better commit message"
  $ hg log --hidden -G
  @  changeset:   3:4ae3a4151de9
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A1
  |
  | x  changeset:   2:f137d23bb3e1
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     temporary amend commit for 471f378eab4c
  | |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------
  $ hg obslog 4ae3a4151de9
  @  4ae3a4151de9 (3) A1
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) by test (*) as 4ae3a4151de9 (glob)
  
  $ hg obslog 4ae3a4151de9 --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "4ae3a4151de9",
          "debugobshistory.rev": 3,
          "debugobshistory.shortdescription": "A1"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "4ae3a4151de9"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
  $ hg obslog --hidden 471f378eab4c
  x  471f378eab4c (1) A0
       rewritten(description, content) by test (*) as 4ae3a4151de9 (glob)
  
  $ hg obslog --hidden 471f378eab4c --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      *, (glob)
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "4ae3a4151de9"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
  $ hg update 471f378eab4c
  abort: hidden revision '471f378eab4c'!
  (use --hidden to access hidden revisions; successor: 4ae3a4151de9)
  [255]
  $ hg update --hidden "desc(A0)"
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: 4ae3a4151de9)

Test output with pruned commit
==============================

Test setup
----------

  $ hg init $TESTTMP/local-prune
  $ cd $TESTTMP/local-prune
  $ mkcommit ROOT
  $ mkcommit A0 # 0
  $ mkcommit B0 # 1
  $ hg log --hidden -G
  @  changeset:   2:0dec01379d3b
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B0
  |
  o  changeset:   1:471f378eab4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg prune -r 'desc(B0)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 471f378eab4c
  1 changesets pruned
  $ hg log --hidden -G
  x  changeset:   2:0dec01379d3b
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B0
  |
  @  changeset:   1:471f378eab4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

Actual test
-----------

  $ hg obslog 'desc(B0)' --hidden
  x  0dec01379d3b (2) B0
       pruned by test (*) (glob)
  
  $ hg obslog 'desc(B0)' --hidden --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.verb": "pruned"
              }
          ],
          "debugobshistory.node": "0dec01379d3b",
          "debugobshistory.rev": 2,
          "debugobshistory.shortdescription": "B0"
      }
  ]
  $ hg obslog 'desc(A0)'
  @  471f378eab4c (1) A0
  
  $ hg obslog 'desc(A0)' --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
  $ hg up 1
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up 0dec01379d3b
  abort: hidden revision '0dec01379d3b'!
  (use --hidden to access hidden revisions; pruned)
  [255]
  $ hg up --hidden -r 'desc(B0)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its parent successor)

Test output with splitted commit
================================

Test setup
----------

  $ hg init $TESTTMP/local-split
  $ cd $TESTTMP/local-split
  $ mkcommit ROOT
  $ echo 42 >> a
  $ echo 43 >> b
  $ hg commit -A -m "A0"
  adding a
  adding b
  $ hg log --hidden -G
  @  changeset:   1:471597cad322
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg split -r 'desc(A0)' -d "0 0" << EOF
  > y
  > y
  > n
  > n
  > y
  > y
  > EOF
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  adding a
  adding b
  diff --git a/a b/a
  new file mode 100644
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +42
  record change 1/2 to 'a'? [Ynesfdaq?] y
  
  diff --git a/b b/b
  new file mode 100644
  examine changes to 'b'? [Ynesfdaq?] n
  
  created new head
  Done splitting? [yN] n
  diff --git a/b b/b
  new file mode 100644
  examine changes to 'b'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +43
  record this change to 'b'? [Ynesfdaq?] y
  
  no more change to split

  $ hg log --hidden -G
  @  changeset:   3:f257fde29c7a
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   2:337fec4d2edc
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  | x  changeset:   1:471597cad322
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

Check that debugobshistory on splitted commit show both targets
  $ hg obslog 471597cad322 --hidden
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
  $ hg obslog 471597cad322 --hidden --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "parent",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "337fec4d2edc",
                      "f257fde29c7a"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471597cad322",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
Check that debugobshistory on the first successor after split show
the revision plus the splitted one
  $ hg obslog 337fec4d2edc
  o  337fec4d2edc (2) A0
  |
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
With the all option, it should show the three changesets
  $ hg obslog --all 337fec4d2edc
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
Check that debugobshistory on the second successor after split show
the revision plus the splitted one
  $ hg obslog f257fde29c7a
  @  f257fde29c7a (3) A0
  |
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
With the all option, it should show the three changesets
  $ hg obslog f257fde29c7a --all
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
Obslog with all option all should also works on the splitted commit
  $ hg obslog -a 471597cad322 --hidden
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
Check that debugobshistory on both successors after split show
a coherent graph
  $ hg obslog 'f257fde29c7a+337fec4d2edc'
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) by test (*) as 337fec4d2edc, f257fde29c7a (glob)
  
  $ hg update 471597cad322
  abort: hidden revision '471597cad322'!
  (use --hidden to access hidden revisions; successors: 337fec4d2edc, f257fde29c7a)
  [255]
  $ hg update --hidden 'min(desc(A0))'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471597cad322)
  (use 'hg evolve' to update to its tipmost successor: 337fec4d2edc, f257fde29c7a)

Test output with lots of splitted commit
========================================

Test setup
----------

  $ hg init $TESTTMP/local-lots-split
  $ cd $TESTTMP/local-lots-split
  $ mkcommit ROOT
  $ echo 42 >> a
  $ echo 43 >> b
  $ echo 44 >> c
  $ echo 45 >> d
  $ hg commit -A -m "A0"
  adding a
  adding b
  adding c
  adding d
  $ hg log --hidden -G
  @  changeset:   1:de7290d8b885
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

  $ hg split -r 'desc(A0)' -d "0 0" << EOF
  > y
  > y
  > n
  > n
  > n
  > n
  > y
  > y
  > n
  > n
  > n
  > y
  > y
  > n
  > n
  > y
  > y
  > EOF
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  adding a
  adding b
  adding c
  adding d
  diff --git a/a b/a
  new file mode 100644
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +42
  record change 1/4 to 'a'? [Ynesfdaq?] y
  
  diff --git a/b b/b
  new file mode 100644
  examine changes to 'b'? [Ynesfdaq?] n
  
  diff --git a/c b/c
  new file mode 100644
  examine changes to 'c'? [Ynesfdaq?] n
  
  diff --git a/d b/d
  new file mode 100644
  examine changes to 'd'? [Ynesfdaq?] n
  
  created new head
  Done splitting? [yN] n
  diff --git a/b b/b
  new file mode 100644
  examine changes to 'b'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +43
  record change 1/3 to 'b'? [Ynesfdaq?] y
  
  diff --git a/c b/c
  new file mode 100644
  examine changes to 'c'? [Ynesfdaq?] n
  
  diff --git a/d b/d
  new file mode 100644
  examine changes to 'd'? [Ynesfdaq?] n
  
  Done splitting? [yN] n
  diff --git a/c b/c
  new file mode 100644
  examine changes to 'c'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +44
  record change 1/2 to 'c'? [Ynesfdaq?] y
  
  diff --git a/d b/d
  new file mode 100644
  examine changes to 'd'? [Ynesfdaq?] n
  
  Done splitting? [yN] n
  diff --git a/d b/d
  new file mode 100644
  examine changes to 'd'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +45
  record this change to 'd'? [Ynesfdaq?] y
  
  no more change to split

  $ hg log --hidden -G
  @  changeset:   5:c7f044602e9b
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   4:1ae8bc733a14
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   3:f257fde29c7a
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   2:337fec4d2edc
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  | x  changeset:   1:de7290d8b885
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

  $ hg obslog de7290d8b885 --hidden
  x  de7290d8b885 (1) A0
       rewritten(parent, content) by test (*) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a (glob)
  
  $ hg obslog de7290d8b885 --hidden --all
  o  1ae8bc733a14 (4) A0
  |
  | o  337fec4d2edc (2) A0
  |/
  | @  c7f044602e9b (5) A0
  |/
  | o  f257fde29c7a (3) A0
  |/
  x  de7290d8b885 (1) A0
       rewritten(parent, content) by test (*) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a (glob)
  
  $ hg obslog de7290d8b885 --hidden --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "parent",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "1ae8bc733a14",
                      "337fec4d2edc",
                      "c7f044602e9b",
                      "f257fde29c7a"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "de7290d8b885",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
  $ hg obslog c7f044602e9b
  @  c7f044602e9b (5) A0
  |
  x  de7290d8b885 (1) A0
       rewritten(parent, content) by test (*) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a (glob)
  
  $ hg obslog c7f044602e9b --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "c7f044602e9b",
          "debugobshistory.rev": 5,
          "debugobshistory.shortdescription": "A0"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "parent",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "1ae8bc733a14",
                      "337fec4d2edc",
                      "c7f044602e9b",
                      "f257fde29c7a"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "de7290d8b885",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
Check that debugobshistory on all heads show a coherent graph
  $ hg obslog 2::5
  o  1ae8bc733a14 (4) A0
  |
  | o  337fec4d2edc (2) A0
  |/
  | @  c7f044602e9b (5) A0
  |/
  | o  f257fde29c7a (3) A0
  |/
  x  de7290d8b885 (1) A0
       rewritten(parent, content) by test (*) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a (glob)
  
  $ hg obslog 5 --all
  o  1ae8bc733a14 (4) A0
  |
  | o  337fec4d2edc (2) A0
  |/
  | @  c7f044602e9b (5) A0
  |/
  | o  f257fde29c7a (3) A0
  |/
  x  de7290d8b885 (1) A0
       rewritten(parent, content) by test (*) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a (glob)
  
  $ hg update de7290d8b885
  abort: hidden revision 'de7290d8b885'!
  (use --hidden to access hidden revisions; successors: 337fec4d2edc, f257fde29c7a and 2 more)
  [255]
  $ hg update --hidden 'min(desc(A0))'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (de7290d8b885)
  (use 'hg evolve' to update to its tipmost successor: 337fec4d2edc, f257fde29c7a and 2 more)

Test output with folded commit
==============================

Test setup
----------

  $ hg init $TESTTMP/local-fold
  $ cd $TESTTMP/local-fold
  $ mkcommit ROOT
  $ mkcommit A0
  $ mkcommit B0
  $ hg log --hidden -G
  @  changeset:   2:0dec01379d3b
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B0
  |
  o  changeset:   1:471f378eab4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg fold --exact -r 'desc(A0) + desc(B0)' --date "0 0" -m "C0"
  2 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log --hidden -G
  @  changeset:   3:eb5a0daa2192
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C0
  |
  | x  changeset:   2:0dec01379d3b
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     B0
  | |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
 Actual test
 -----------

Check that debugobshistory on the first folded revision show only
the revision with the target
  $ hg obslog --hidden 471f378eab4c
  x  471f378eab4c (1) A0
       rewritten(description, content) by test (*) as eb5a0daa2192 (glob)
  
Check that with all option, all changesets are shown
  $ hg obslog --hidden --all 471f378eab4c
  @    eb5a0daa2192 (3) C0
  |\
  x |  0dec01379d3b (2) B0
   /     rewritten(description, parent, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) by test (*) as eb5a0daa2192 (glob)
  
Check that debugobshistory on the second folded revision show only
the revision with the target
  $ hg obslog --hidden 0dec01379d3b
  x  0dec01379d3b (2) B0
       rewritten(description, parent, content) by test (*) as eb5a0daa2192 (glob)
  
Check that with all option, all changesets are shown
  $ hg obslog --hidden --all 0dec01379d3b
  @    eb5a0daa2192 (3) C0
  |\
  x |  0dec01379d3b (2) B0
   /     rewritten(description, parent, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) by test (*) as eb5a0daa2192 (glob)
  
Check that debugobshistory on the successor revision show a coherent
graph
  $ hg obslog eb5a0daa2192
  @    eb5a0daa2192 (3) C0
  |\
  x |  0dec01379d3b (2) B0
   /     rewritten(description, parent, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) by test (*) as eb5a0daa2192 (glob)
  
  $ hg obslog eb5a0daa2192 --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "eb5a0daa2192",
          "debugobshistory.rev": 3,
          "debugobshistory.shortdescription": "C0"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "eb5a0daa2192"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description",
                      "parent",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "eb5a0daa2192"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "0dec01379d3b",
          "debugobshistory.rev": 2,
          "debugobshistory.shortdescription": "B0"
      }
  ]
  $ hg update 471f378eab4c
  abort: hidden revision '471f378eab4c'!
  (use --hidden to access hidden revisions; successor: eb5a0daa2192)
  [255]
  $ hg update --hidden 'desc(A0)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg update 0dec01379d3b
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  abort: hidden revision '0dec01379d3b'!
  (use --hidden to access hidden revisions; successor: eb5a0daa2192)
  [255]
  $ hg update --hidden 'desc(B0)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)

Test output with divergence
===========================

Test setup
----------

  $ hg init $TESTTMP/local-divergence
  $ cd $TESTTMP/local-divergence
  $ mkcommit ROOT
  $ mkcommit A0
  $ hg amend -m "A1"
  $ hg log --hidden -G
  @  changeset:   2:fdf9bde5129a
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg update --hidden 'desc(A0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: fdf9bde5129a)
  $ hg amend -m "A2"
  2 new divergent changesets
  $ hg log --hidden -G
  @  changeset:   3:65b757b745b9
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  trouble:     divergent
  |  summary:     A2
  |
  | o  changeset:   2:fdf9bde5129a
  |/   parent:      0:ea207398892e
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    trouble:     divergent
  |    summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

Check that debugobshistory on the divergent revision show both destinations
  $ hg obslog --hidden 471f378eab4c
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  

Check that with all option, every changeset is shown
  $ hg obslog --hidden --all 471f378eab4c
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
  $ hg obslog --hidden 471f378eab4c --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "65b757b745b9"
                  ],
                  "debugobshistory.verb": "rewritten"
              },
              {
                  "debugobshistory.effect": [
                      "description"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "fdf9bde5129a"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
Check that debugobshistory on the first diverged revision show the revision
and the diverent one
  $ hg obslog fdf9bde5129a
  o  fdf9bde5129a (2) A1
  |
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  

Check that all option show all of them
  $ hg obslog fdf9bde5129a -a
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
Check that debugobshistory on the second diverged revision show the revision
and the diverent one
  $ hg obslog 65b757b745b9
  @  65b757b745b9 (3) A2
  |
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
Check that all option show all of them
  $ hg obslog 65b757b745b9 -a
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
Check that debugobshistory on the both diverged revision show a coherent
graph
  $ hg obslog '65b757b745b9+fdf9bde5129a'
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as 65b757b745b9 (glob)
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
  $ hg obslog '65b757b745b9+fdf9bde5129a' --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "65b757b745b9",
          "debugobshistory.rev": 3,
          "debugobshistory.shortdescription": "A2"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "65b757b745b9"
                  ],
                  "debugobshistory.verb": "rewritten"
              },
              {
                  "debugobshistory.effect": [
                      "description"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "fdf9bde5129a"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      },
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "fdf9bde5129a",
          "debugobshistory.rev": 2,
          "debugobshistory.shortdescription": "A1"
      }
  ]
  $ hg update 471f378eab4c
  abort: hidden revision '471f378eab4c'!
  (use --hidden to access hidden revisions; diverged)
  [255]
  $ hg update --hidden 'desc(A0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (471f378eab4c has diverged, use 'hg evolve --list --divergent' to resolve the issue)

Test output with amended + folded commit
========================================

Test setup
----------

  $ hg init $TESTTMP/local-amend-fold
  $ cd $TESTTMP/local-amend-fold
  $ mkcommit ROOT
  $ mkcommit A0
  $ mkcommit B0
  $ hg amend -m "B1"
  $ hg log --hidden -G
  @  changeset:   3:b7ea6d14e664
  |  tag:         tip
  |  parent:      1:471f378eab4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B1
  |
  | x  changeset:   2:0dec01379d3b
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     B0
  |
  o  changeset:   1:471f378eab4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg fold --exact -r 'desc(A0) + desc(B1)' --date "0 0" -m "C0"
  2 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log --hidden -G
  @  changeset:   4:eb5a0daa2192
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C0
  |
  | x  changeset:   3:b7ea6d14e664
  | |  parent:      1:471f378eab4c
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     B1
  | |
  | | x  changeset:   2:0dec01379d3b
  | |/   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    summary:     B0
  | |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
 Actual test
 -----------

Check that debugobshistory on head show a coherent graph
  $ hg obslog eb5a0daa2192
  @    eb5a0daa2192 (4) C0
  |\
  x |  471f378eab4c (1) A0
   /     rewritten(description, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  b7ea6d14e664 (3) B1
  |    rewritten(description, parent, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  0dec01379d3b (2) B0
       rewritten(description) by test (*) as b7ea6d14e664 (glob)
  
Check that obslog on ROOT with all option show everything
  $ hg obslog 1 --hidden --all
  @    eb5a0daa2192 (4) C0
  |\
  x |  471f378eab4c (1) A0
   /     rewritten(description, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  b7ea6d14e664 (3) B1
  |    rewritten(description, parent, content) by test (*) as eb5a0daa2192 (glob)
  |
  x  0dec01379d3b (2) B0
       rewritten(description) by test (*) as b7ea6d14e664 (glob)
  
  $ hg obslog eb5a0daa2192 --no-graph -Tjson | python -m json.tool
  [
      {
          "debugobshistory.markers": [],
          "debugobshistory.node": "eb5a0daa2192",
          "debugobshistory.rev": 4,
          "debugobshistory.shortdescription": "C0"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      *, (glob)
                      *, (glob)
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "eb5a0daa2192"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "b7ea6d14e664",
          "debugobshistory.rev": 3,
          "debugobshistory.shortdescription": "B1"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "b7ea6d14e664"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "0dec01379d3b",
          "debugobshistory.rev": 2,
          "debugobshistory.shortdescription": "B0"
      },
      {
          "debugobshistory.markers": [
              {
                  "debugobshistory.effect": [
                      "description",
                      "content"
                  ],
                  "debugobshistory.marker_date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "eb5a0daa2192"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "471f378eab4c",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A0"
      }
  ]
  $ hg update 471f378eab4c
  abort: hidden revision '471f378eab4c'!
  (use --hidden to access hidden revisions; successor: eb5a0daa2192)
  [255]
  $ hg update --hidden 'desc(A0)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg update --hidden 0dec01379d3b
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg update 0dec01379d3b
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg update --hidden 'desc(B0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)

Test output with pushed and pulled obs markers
==============================================

Test setup
----------

  $ hg init $TESTTMP/local-remote-markers-1
  $ cd $TESTTMP/local-remote-markers-1
  $ mkcommit ROOT
  $ mkcommit A0
  $ hg log --hidden -G
  @  changeset:   1:471f378eab4c
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg clone $TESTTMP/local-remote-markers-1 $TESTTMP/local-remote-markers-2
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd $TESTTMP/local-remote-markers-2
  $ hg log --hidden -G
  @  changeset:   1:471f378eab4c
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ cd $TESTTMP/local-remote-markers-1
  $ hg amend -m "A1"
  $ hg amend -m "A2"
  $ hg log --hidden -G
  @  changeset:   3:7a230b46bf61
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A2
  |
  | x  changeset:   2:fdf9bde5129a
  |/   parent:      0:ea207398892e
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
 Actual test
 -----------

  $ hg obslog 7a230b46bf61
  @  7a230b46bf61 (3) A2
  |
  x  fdf9bde5129a (2) A1
  |    rewritten(description) by test (*) as 7a230b46bf61 (glob)
  |
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
  $ cd $TESTTMP/local-remote-markers-2
  $ hg pull
  pulling from $TESTTMP/local-remote-markers-1
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 1 files (+1 heads)
  2 new obsolescence markers
  (run 'hg heads' to see heads, 'hg merge' to merge)
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: 7a230b46bf61)
Check that debugobshistory works with markers pointing to missing local
changectx
  $ hg obslog 7a230b46bf61
  o  7a230b46bf61 (2) A2
  |
  x  fdf9bde5129a
  |    rewritten(description) by test (*) as 7a230b46bf61 (glob)
  |
  @  471f378eab4c (1) A0
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  
  $ hg obslog 7a230b46bf61 --color=debug
  o  [evolve.node|7a230b46bf61] [evolve.rev|(2)] [evolve.short_description|A2]
  |
  x  [evolve.node evolve.missing_change_ctx|fdf9bde5129a]
  |    [evolve.verb|rewritten](description) by [evolve.user|test] [evolve.date|(*)] as [evolve.node|7a230b46bf61] (glob)
  |
  @  [evolve.node|471f378eab4c] [evolve.rev|(1)] [evolve.short_description|A0]
       [evolve.verb|rewritten](description) by [evolve.user|test] [evolve.date|(*)] as [evolve.node|fdf9bde5129a] (glob)
  
