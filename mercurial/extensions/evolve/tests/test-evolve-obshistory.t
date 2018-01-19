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
  @  changeset:   2:4ae3a4151de9
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten using amend as 2:4ae3a4151de9
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------
  $ hg obslog --patch 4ae3a4151de9
  @  4ae3a4151de9 (2) A1
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) as 4ae3a4151de9 by test (*) (glob)
         diff -r 471f378eab4c -r 4ae3a4151de9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,3 @@
         -A0
         +A1
         +
         +Better commit message
  
         diff -r 471f378eab4c -r 4ae3a4151de9 A0
         --- a/A0	Thu Jan 01 00:00:00 1970 +0000
         +++ b/A0	Thu Jan 01 00:00:00 1970 +0000
         @@ -1,1 +1,2 @@
          A0
         +42
  
  
  $ hg obslog --patch --color debug
  @  [evolve.node|4ae3a4151de9] [evolve.rev|(2)] [evolve.short_description|A1]
  |
  x  [evolve.node|471f378eab4c] [evolve.rev|(1)] [evolve.short_description|A0]
       [evolve.verb|rewritten](description, content) as [evolve.node|4ae3a4151de9] by [evolve.user|test] [evolve.date|(Thu Jan 01 00:00:00 1970 +0000)]
         [diff.diffline|diff -r 471f378eab4c -r 4ae3a4151de9 changeset-description]
         [diff.file_a|--- a/changeset-description]
         [diff.file_b|+++ b/changeset-description]
         [diff.hunk|@@ -1,1 +1,3 @@]
         [diff.deleted|-A0]
         [diff.inserted|+A1]
         [diff.inserted|+]
         [diff.inserted|+Better commit message]
  
         [diff.diffline|diff -r 471f378eab4c -r 4ae3a4151de9 A0]
         [diff.file_a|--- a/A0	Thu Jan 01 00:00:00 1970 +0000]
         [diff.file_b|+++ b/A0	Thu Jan 01 00:00:00 1970 +0000]
         [diff.hunk|@@ -1,1 +1,2 @@]
          A0
         [diff.inserted|+42]
  
  

  $ hg obslog --no-graph --patch 4ae3a4151de9
  4ae3a4151de9 (2) A1
  471f378eab4c (1) A0
    rewritten(description, content) as 4ae3a4151de9 by test (Thu Jan 01 00:00:00 1970 +0000)
      diff -r 471f378eab4c -r 4ae3a4151de9 changeset-description
      --- a/changeset-description
      +++ b/changeset-description
      @@ -1,1 +1,3 @@
      -A0
      +A1
      +
      +Better commit message
  
      diff -r 471f378eab4c -r 4ae3a4151de9 A0
      --- a/A0	Thu Jan 01 00:00:00 1970 +0000
      +++ b/A0	Thu Jan 01 00:00:00 1970 +0000
      @@ -1,1 +1,2 @@
       A0
      +42
  

  $ hg obslog 4ae3a4151de9 --graph -T'{label("log.summary", shortdescription)} {if(markers, join(markers % "at {date|hgdate} by {user|person} ", " also "))}'
  @  A1
  |
  x  A0 at 0 0 by test
  
  $ hg obslog 4ae3a4151de9 --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [],
          "node": "4ae3a4151de9",
          "rev": 2,
          "shortdescription": "A1"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description",
                      "content"
                  ],
                  "succnodes": [
                      "4ae3a4151de9"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
      }
  ]
  $ hg obslog --hidden --patch 471f378eab4c
  x  471f378eab4c (1) A0
       rewritten(description, content) as 4ae3a4151de9 by test (*) (glob)
         diff -r 471f378eab4c -r 4ae3a4151de9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,3 @@
         -A0
         +A1
         +
         +Better commit message
  
         diff -r 471f378eab4c -r 4ae3a4151de9 A0
         --- a/A0	Thu Jan 01 00:00:00 1970 +0000
         +++ b/A0	Thu Jan 01 00:00:00 1970 +0000
         @@ -1,1 +1,2 @@
          A0
         +42
  
  
  $ hg obslog --hidden 471f378eab4c --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      *, (glob)
                      "content"
                  ],
                  "succnodes": [
                      "4ae3a4151de9"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
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
  |  obsolete:    pruned
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

  $ hg obslog 'desc(B0)' --hidden --patch
  x  0dec01379d3b (2) B0
       pruned by test (*) (glob)
         (No patch available, no successors)
  
  $ hg obslog 'desc(B0)' --hidden --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "user": "test",
                  "verb": "pruned"
              }
          ],
          "node": "0dec01379d3b",
          "rev": 2,
          "shortdescription": "B0"
      }
  ]
  $ hg obslog 'desc(A0)' --patch
  @  471f378eab4c (1) A0
  
  $ hg obslog 'desc(A0)' --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
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
  
  $ hg split -r 'desc(A0)' -n "testing split" -d "0 0" << EOF
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
  |    obsolete:    split as 2:337fec4d2edc, 3:f257fde29c7a
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

Check that debugobshistory on splitted commit show both targets
  $ hg obslog 471597cad322 --hidden --patch
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
  $ hg obslog 471597cad322 --hidden --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "parent",
                      "content"
                  ],
                  "note": "testing split",
                  "succnodes": [
                      "337fec4d2edc",
                      "f257fde29c7a"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471597cad322",
          "rev": 1,
          "shortdescription": "A0"
      }
  ]
Check that debugobshistory on the first successor after split show
the revision plus the splitted one
  $ hg obslog 337fec4d2edc --patch
  o  337fec4d2edc (2) A0
  |
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
With the all option, it should show the three changesets
  $ hg obslog --all 337fec4d2edc --patch
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
Check that debugobshistory on the second successor after split show
the revision plus the splitted one
  $ hg obslog f257fde29c7a --patch
  @  f257fde29c7a (3) A0
  |
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
With the all option, it should show the three changesets
  $ hg obslog f257fde29c7a --all --patch
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
Obslog with all option all should also works on the splitted commit
  $ hg obslog -a 471597cad322 --hidden --patch
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
Check that debugobshistory on both successors after split show
a coherent graph
  $ hg obslog 'f257fde29c7a+337fec4d2edc' --patch
  o  337fec4d2edc (2) A0
  |
  | @  f257fde29c7a (3) A0
  |/
  x  471597cad322 (1) A0
       rewritten(parent, content) as 337fec4d2edc, f257fde29c7a by test (*) (glob)
         note: testing split
         (No patch available, too many successors (2))
  
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
  |    obsolete:    split as 2:337fec4d2edc, 3:f257fde29c7a, 4:1ae8bc733a14, 5:c7f044602e9b
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

  $ hg obslog de7290d8b885 --hidden --patch
  x  de7290d8b885 (1) A0
       rewritten(parent, content) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a by test (*) (glob)
         (No patch available, too many successors (4))
  
  $ hg obslog de7290d8b885 --hidden --all --patch
  o  1ae8bc733a14 (4) A0
  |
  | o  337fec4d2edc (2) A0
  |/
  | @  c7f044602e9b (5) A0
  |/
  | o  f257fde29c7a (3) A0
  |/
  x  de7290d8b885 (1) A0
       rewritten(parent, content) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a by test (*) (glob)
         (No patch available, too many successors (4))
  
  $ hg obslog de7290d8b885 --hidden --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "parent",
                      "content"
                  ],
                  "succnodes": [
                      "1ae8bc733a14",
                      "337fec4d2edc",
                      "c7f044602e9b",
                      "f257fde29c7a"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "de7290d8b885",
          "rev": 1,
          "shortdescription": "A0"
      }
  ]
  $ hg obslog c7f044602e9b --patch
  @  c7f044602e9b (5) A0
  |
  x  de7290d8b885 (1) A0
       rewritten(parent, content) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a by test (*) (glob)
         (No patch available, too many successors (4))
  
  $ hg obslog c7f044602e9b --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [],
          "node": "c7f044602e9b",
          "rev": 5,
          "shortdescription": "A0"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "parent",
                      "content"
                  ],
                  "succnodes": [
                      "1ae8bc733a14",
                      "337fec4d2edc",
                      "c7f044602e9b",
                      "f257fde29c7a"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "de7290d8b885",
          "rev": 1,
          "shortdescription": "A0"
      }
  ]
Check that debugobshistory on all heads show a coherent graph
  $ hg obslog 2::5 --patch
  o  1ae8bc733a14 (4) A0
  |
  | o  337fec4d2edc (2) A0
  |/
  | @  c7f044602e9b (5) A0
  |/
  | o  f257fde29c7a (3) A0
  |/
  x  de7290d8b885 (1) A0
       rewritten(parent, content) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a by test (*) (glob)
         (No patch available, too many successors (4))
  
  $ hg obslog 5 --all --patch
  o  1ae8bc733a14 (4) A0
  |
  | o  337fec4d2edc (2) A0
  |/
  | @  c7f044602e9b (5) A0
  |/
  | o  f257fde29c7a (3) A0
  |/
  x  de7290d8b885 (1) A0
       rewritten(parent, content) as 1ae8bc733a14, 337fec4d2edc, c7f044602e9b, f257fde29c7a by test (*) (glob)
         (No patch available, too many successors (4))
  
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
  | |  obsolete:    rewritten as 3:eb5a0daa2192
  | |  summary:     B0
  | |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten as 3:eb5a0daa2192
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
  $ hg obslog --hidden 471f378eab4c --patch
  x  471f378eab4c (1) A0
       rewritten(description, content) as eb5a0daa2192 by test (*) (glob)
         diff -r 471f378eab4c -r eb5a0daa2192 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +C0
  
         diff -r 471f378eab4c -r eb5a0daa2192 B0
         --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
         +++ b/B0	Thu Jan 01 00:00:00 1970 +0000
         @@ -0,0 +1,1 @@
         +B0
  
  
Check that with all option, all changesets are shown
  $ hg obslog --hidden --all 471f378eab4c --patch
  @    eb5a0daa2192 (3) C0
  |\
  x |  0dec01379d3b (2) B0
   /     rewritten(description, parent, content) as eb5a0daa2192 by test (*) (glob)
  |        (No patch available, changesets rebased)
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) as eb5a0daa2192 by test (*) (glob)
         diff -r 471f378eab4c -r eb5a0daa2192 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +C0
  
         diff -r 471f378eab4c -r eb5a0daa2192 B0
         --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
         +++ b/B0	Thu Jan 01 00:00:00 1970 +0000
         @@ -0,0 +1,1 @@
         +B0
  
  
Check that debugobshistory on the second folded revision show only
the revision with the target
  $ hg obslog --hidden 0dec01379d3b --patch
  x  0dec01379d3b (2) B0
       rewritten(description, parent, content) as eb5a0daa2192 by test (*) (glob)
         (No patch available, changesets rebased)
  
Check that with all option, all changesets are shown
  $ hg obslog --hidden --all 0dec01379d3b --patch
  @    eb5a0daa2192 (3) C0
  |\
  x |  0dec01379d3b (2) B0
   /     rewritten(description, parent, content) as eb5a0daa2192 by test (*) (glob)
  |        (No patch available, changesets rebased)
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) as eb5a0daa2192 by test (*) (glob)
         diff -r 471f378eab4c -r eb5a0daa2192 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +C0
  
         diff -r 471f378eab4c -r eb5a0daa2192 B0
         --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
         +++ b/B0	Thu Jan 01 00:00:00 1970 +0000
         @@ -0,0 +1,1 @@
         +B0
  
  
Check that debugobshistory on the successor revision show a coherent
graph
  $ hg obslog eb5a0daa2192 --patch
  @    eb5a0daa2192 (3) C0
  |\
  x |  0dec01379d3b (2) B0
   /     rewritten(description, parent, content) as eb5a0daa2192 by test (*) (glob)
  |        (No patch available, changesets rebased)
  |
  x  471f378eab4c (1) A0
       rewritten(description, content) as eb5a0daa2192 by test (*) (glob)
         diff -r 471f378eab4c -r eb5a0daa2192 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +C0
  
         diff -r 471f378eab4c -r eb5a0daa2192 B0
         --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
         +++ b/B0	Thu Jan 01 00:00:00 1970 +0000
         @@ -0,0 +1,1 @@
         +B0
  
  
  $ hg obslog eb5a0daa2192 --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [],
          "node": "eb5a0daa2192",
          "rev": 3,
          "shortdescription": "C0"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description",
                      "content"
                  ],
                  "succnodes": [
                      "eb5a0daa2192"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description",
                      "parent",
                      "content"
                  ],
                  "succnodes": [
                      "eb5a0daa2192"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "0dec01379d3b",
          "rev": 2,
          "shortdescription": "B0"
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
  |    obsolete:    reworded using amend as 2:fdf9bde5129a
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
  2 new content-divergent changesets
  $ hg log --hidden -G
  @  changeset:   3:65b757b745b9
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: content-divergent
  |  summary:     A2
  |
  | o  changeset:   2:fdf9bde5129a
  |/   parent:      0:ea207398892e
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    instability: content-divergent
  |    summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 2:fdf9bde5129a
  |    obsolete:    reworded using amend as 3:65b757b745b9
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

Check that debugobshistory on the divergent revision show both destinations
  $ hg obslog --hidden 471f378eab4c --patch
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  

Check that with all option, every changeset is shown
  $ hg obslog --hidden --all 471f378eab4c --patch
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  
  $ hg obslog --hidden 471f378eab4c --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description"
                  ],
                  "succnodes": [
                      "65b757b745b9"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              },
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description"
                  ],
                  "succnodes": [
                      "fdf9bde5129a"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
      }
  ]
Check that debugobshistory on the first diverged revision show the revision
and the diverent one
  $ hg obslog fdf9bde5129a --patch
  o  fdf9bde5129a (2) A1
  |
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  

Check that all option show all of them
  $ hg obslog fdf9bde5129a -a --patch
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  
Check that debugobshistory on the second diverged revision show the revision
and the diverent one
  $ hg obslog 65b757b745b9 --patch
  @  65b757b745b9 (3) A2
  |
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  
Check that all option show all of them
  $ hg obslog 65b757b745b9 -a --patch
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  
Check that debugobshistory on the both diverged revision show a coherent
graph
  $ hg obslog '65b757b745b9+fdf9bde5129a' --patch
  @  65b757b745b9 (3) A2
  |
  | o  fdf9bde5129a (2) A1
  |/
  x  471f378eab4c (1) A0
       rewritten(description) as 65b757b745b9 by test (*) (glob)
         diff -r 471f378eab4c -r 65b757b745b9 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A2
  
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  
  $ hg obslog '65b757b745b9+fdf9bde5129a' --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [],
          "node": "65b757b745b9",
          "rev": 3,
          "shortdescription": "A2"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description"
                  ],
                  "succnodes": [
                      "65b757b745b9"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              },
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description"
                  ],
                  "succnodes": [
                      "fdf9bde5129a"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
      },
      {
          "markers": [],
          "node": "fdf9bde5129a",
          "rev": 2,
          "shortdescription": "A1"
      }
  ]
  $ hg update 471f378eab4c
  abort: hidden revision '471f378eab4c'!
  (use --hidden to access hidden revisions; diverged)
  [255]
  $ hg update --hidden 'desc(A0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (471f378eab4c has diverged, use 'hg evolve --list --content-divergent' to resolve the issue)

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
  |    obsolete:    reworded using amend as 3:b7ea6d14e664
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
  | |  obsolete:    rewritten as 4:eb5a0daa2192
  | |  summary:     B1
  | |
  | | x  changeset:   2:0dec01379d3b
  | |/   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    obsolete:    reworded using amend as 3:b7ea6d14e664
  | |    summary:     B0
  | |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten as 4:eb5a0daa2192
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
 Actual test
 -----------

Check that debugobshistory on head show a coherent graph
  $ hg obslog eb5a0daa2192 --patch
  @    eb5a0daa2192 (4) C0
  |\
  x |  471f378eab4c (1) A0
   /     rewritten(description, content) as eb5a0daa2192 by test (*) (glob)
  |        diff -r 471f378eab4c -r eb5a0daa2192 changeset-description
  |        --- a/changeset-description
  |        +++ b/changeset-description
  |        @@ -1,1 +1,1 @@
  |        -A0
  |        +C0
  |
  |        diff -r 471f378eab4c -r eb5a0daa2192 B0
  |        --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  |        +++ b/B0	Thu Jan 01 00:00:00 1970 +0000
  |        @@ -0,0 +1,1 @@
  |        +B0
  |
  |
  x  b7ea6d14e664 (3) B1
  |    rewritten(description, parent, content) as eb5a0daa2192 by test (*) (glob)
  |      (No patch available, changesets rebased)
  |
  x  0dec01379d3b (2) B0
       rewritten(description) as b7ea6d14e664 by test (*) (glob)
         diff -r 0dec01379d3b -r b7ea6d14e664 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -B0
         +B1
  
  
Check that obslog on ROOT with all option show everything
  $ hg obslog 1 --hidden --all --patch
  @    eb5a0daa2192 (4) C0
  |\
  x |  471f378eab4c (1) A0
   /     rewritten(description, content) as eb5a0daa2192 by test (*) (glob)
  |        diff -r 471f378eab4c -r eb5a0daa2192 changeset-description
  |        --- a/changeset-description
  |        +++ b/changeset-description
  |        @@ -1,1 +1,1 @@
  |        -A0
  |        +C0
  |
  |        diff -r 471f378eab4c -r eb5a0daa2192 B0
  |        --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  |        +++ b/B0	Thu Jan 01 00:00:00 1970 +0000
  |        @@ -0,0 +1,1 @@
  |        +B0
  |
  |
  x  b7ea6d14e664 (3) B1
  |    rewritten(description, parent, content) as eb5a0daa2192 by test (*) (glob)
  |      (No patch available, changesets rebased)
  |
  x  0dec01379d3b (2) B0
       rewritten(description) as b7ea6d14e664 by test (*) (glob)
         diff -r 0dec01379d3b -r b7ea6d14e664 changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -B0
         +B1
  
  
  $ hg obslog eb5a0daa2192 --no-graph -Tjson | python -m json.tool
  [
      {
          "markers": [],
          "node": "eb5a0daa2192",
          "rev": 4,
          "shortdescription": "C0"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      *, (glob)
                      *, (glob)
                      "content"
                  ],
                  "succnodes": [
                      "eb5a0daa2192"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "b7ea6d14e664",
          "rev": 3,
          "shortdescription": "B1"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description"
                  ],
                  "succnodes": [
                      "b7ea6d14e664"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "0dec01379d3b",
          "rev": 2,
          "shortdescription": "B0"
      },
      {
          "markers": [
              {
                  "date": [
                      *, (glob)
                      0 (glob)
                  ],
                  "effect": [
                      "description",
                      "content"
                  ],
                  "succnodes": [
                      "eb5a0daa2192"
                  ],
                  "user": "test",
                  "verb": "rewritten"
              }
          ],
          "node": "471f378eab4c",
          "rev": 1,
          "shortdescription": "A0"
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
  $ hg update --hidden 'desc(B0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

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
  |    obsolete:    reworded using amend as 3:7a230b46bf61
  |    summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 2:fdf9bde5129a
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
 Actual test
 -----------

  $ hg obslog 7a230b46bf61 --patch
  @  7a230b46bf61 (3) A2
  |
  x  fdf9bde5129a (2) A1
  |    rewritten(description) as 7a230b46bf61 by test (*) (glob)
  |      diff -r fdf9bde5129a -r 7a230b46bf61 changeset-description
  |      --- a/changeset-description
  |      +++ b/changeset-description
  |      @@ -1,1 +1,1 @@
  |      -A1
  |      +A2
  |
  |
  x  471f378eab4c (1) A0
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         diff -r 471f378eab4c -r fdf9bde5129a changeset-description
         --- a/changeset-description
         +++ b/changeset-description
         @@ -1,1 +1,1 @@
         -A0
         +A1
  
  
  $ cd $TESTTMP/local-remote-markers-2
  $ hg pull
  pulling from $TESTTMP/local-remote-markers-1
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 1 files (+1 heads)
  2 new obsolescence markers
  obsoleted 1 changesets
  new changesets 7a230b46bf61
  (run 'hg heads' to see heads, 'hg merge' to merge)
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: 7a230b46bf61)
Check that debugobshistory works with markers pointing to missing local
changectx
  $ hg obslog 7a230b46bf61 --patch
  o  7a230b46bf61 (2) A2
  |
  x  fdf9bde5129a
  |    rewritten(description) as 7a230b46bf61 by test (*) (glob)
  |      (No patch available, context is not local)
  |
  @  471f378eab4c (1) A0
       rewritten(description) as fdf9bde5129a by test (*) (glob)
         (No patch available, successor is unknown locally)
  
  $ hg obslog 7a230b46bf61 --color=debug --patch
  o  [evolve.node|7a230b46bf61] [evolve.rev|(2)] [evolve.short_description|A2]
  |
  x  [evolve.node evolve.missing_change_ctx|fdf9bde5129a]
  |    [evolve.verb|rewritten](description) as [evolve.node|7a230b46bf61] by [evolve.user|test] [evolve.date|(*)] (glob)
  |      (No patch available, context is not local)
  |
  @  [evolve.node|471f378eab4c] [evolve.rev|(1)] [evolve.short_description|A0]
       [evolve.verb|rewritten](description) as [evolve.node|fdf9bde5129a] by [evolve.user|test] [evolve.date|(*)] (glob)
         (No patch available, successor is unknown locally)
  
