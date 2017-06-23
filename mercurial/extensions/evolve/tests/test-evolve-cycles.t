Test that evolve related algorithms don't crash on obs markers cycles

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

Test with cycle
===============

Test setup
----------

  $ hg init $TESTTMP/cycle
  $ cd $TESTTMP/cycle
  $ mkcommit ROOT
  $ mkcommit A
  $ mkcommit B
  $ mkcommit C
  $ hg log -G
  @  changeset:   3:a8df460dbbfe
  |  tag:         tip
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
  
Create a cycle
  $ hg prune -s "desc(B)" "desc(A)"
  1 changesets pruned
  2 new unstable changesets
  $ hg prune -s "desc(C)" "desc(B)"
  1 changesets pruned
  $ hg prune -s "desc(A)" "desc(C)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  working directory now at 2a34000d3544
  1 changesets pruned
  $ hg log --hidden -G
  x  changeset:   3:a8df460dbbfe
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C
  |
  x  changeset:   2:c473644ee0e9
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B
  |
  @  changeset:   1:2a34000d3544
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

Check that debugobshistory never crash on a cycle

  $ hg obslog "desc(A)" --hidden
  @  2a34000d3544 (1) A
  |    rewritten(description, parent, content) by test (*) as c473644ee0e9 (glob)
  |
  x  a8df460dbbfe (3) C
  |    rewritten(description, parent, content) by test (*) as 2a34000d3544 (glob)
  |
  x  c473644ee0e9 (2) B
  |    rewritten(description, parent, content) by test (*) as a8df460dbbfe (glob)
  |

  $ hg obslog "desc(B)" --hidden
  @  2a34000d3544 (1) A
  |    rewritten(description, parent, content) by test (*) as c473644ee0e9 (glob)
  |
  x  a8df460dbbfe (3) C
  |    rewritten(description, parent, content) by test (*) as 2a34000d3544 (glob)
  |
  x  c473644ee0e9 (2) B
  |    rewritten(description, parent, content) by test (*) as a8df460dbbfe (glob)
  |

  $ hg obslog "desc(C)" --hidden
  @  2a34000d3544 (1) A
  |    rewritten(description, parent, content) by test (*) as c473644ee0e9 (glob)
  |
  x  a8df460dbbfe (3) C
  |    rewritten(description, parent, content) by test (*) as 2a34000d3544 (glob)
  |
  x  c473644ee0e9 (2) B
  |    rewritten(description, parent, content) by test (*) as a8df460dbbfe (glob)
  |

Check that all option don't crash on a cycle either

  $ hg obslog "desc(C)" --hidden --all
  @  2a34000d3544 (1) A
  |    rewritten(description, parent, content) by test (*) as c473644ee0e9 (glob)
  |
  x  a8df460dbbfe (3) C
  |    rewritten(description, parent, content) by test (*) as 2a34000d3544 (glob)
  |
  x  c473644ee0e9 (2) B
  |    rewritten(description, parent, content) by test (*) as a8df460dbbfe (glob)
  |

Test with multiple cyles
========================

Test setup
----------

  $ hg init $TESTTMP/multiple-cycle
  $ cd $TESTTMP/multiple-cycle
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
  
Create a first cycle
  $ hg prune -s "desc(B)" "desc(A)"
  1 changesets pruned
  5 new unstable changesets
  $ hg prune -s "desc(C)" "desc(B)"
  1 changesets pruned
  $ hg prune --split -s "desc(A)" -s "desc(D)" "desc(C)"
  1 changesets pruned
And create a second one
  $ hg prune -s "desc(E)" "desc(D)"
  1 changesets pruned
  $ hg prune -s "desc(F)" "desc(E)"
  1 changesets pruned
  $ hg prune -s "desc(D)" "desc(F)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  working directory now at 868d2e0eb19c
  1 changesets pruned
  $ hg log --hidden -G
  x  changeset:   6:d9f908fde1a1
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     F
  |
  x  changeset:   5:0da815c333f6
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     E
  |
  @  changeset:   4:868d2e0eb19c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     D
  |
  x  changeset:   3:a8df460dbbfe
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C
  |
  x  changeset:   2:c473644ee0e9
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B
  |
  x  changeset:   1:2a34000d3544
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Actual test
-----------

Check that debugobshistory never crash on a cycle

  $ hg obslog "desc(D)" --hidden
  x  0da815c333f6 (5) E
  |    rewritten(description, parent, content) by test (*) as d9f908fde1a1 (glob)
  |
  @    868d2e0eb19c (4) D
  |\     rewritten(description, parent, content) by test (*) as 0da815c333f6 (glob)
  | |
  | x  d9f908fde1a1 (6) F
  | |    rewritten(description, parent, content) by test (*) as 868d2e0eb19c (glob)
  | |
  +---x  2a34000d3544 (1) A
  | |      rewritten(description, parent, content) by test (*) as c473644ee0e9 (glob)
  | |
  x |  a8df460dbbfe (3) C
  | |    rewritten(description, parent, content) by test (*) as 2a34000d3544, 868d2e0eb19c (glob)
  | |
  x |  c473644ee0e9 (2) B
  | |    rewritten(description, parent, content) by test (*) as a8df460dbbfe (glob)
  | |
Check that all option don't crash either on a cycle
  $ hg obslog --all --hidden "desc(F)"
  x  0da815c333f6 (5) E
  |    rewritten(description, parent, content) by test (*) as d9f908fde1a1 (glob)
  |
  @    868d2e0eb19c (4) D
  |\     rewritten(description, parent, content) by test (*) as 0da815c333f6 (glob)
  | |
  | x  d9f908fde1a1 (6) F
  | |    rewritten(description, parent, content) by test (*) as 868d2e0eb19c (glob)
  | |
  +---x  2a34000d3544 (1) A
  | |      rewritten(description, parent, content) by test (*) as c473644ee0e9 (glob)
  | |
  x |  a8df460dbbfe (3) C
  | |    rewritten(description, parent, content) by test (*) as 2a34000d3544, 868d2e0eb19c (glob)
  | |
  x |  c473644ee0e9 (2) B
  | |    rewritten(description, parent, content) by test (*) as a8df460dbbfe (glob)
  | |
Check the json output is valid in this case

  $ hg obslog "desc(D)" --hidden --no-graph -Tjson | python -m json.tool
  [
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
                      0
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "0da815c333f6"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "868d2e0eb19c",
          "debugobshistory.rev": 4,
          "debugobshistory.shortdescription": "D"
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
                      0
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "868d2e0eb19c"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "d9f908fde1a1",
          "debugobshistory.rev": 6,
          "debugobshistory.shortdescription": "F"
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
                      0
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "d9f908fde1a1"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "0da815c333f6",
          "debugobshistory.rev": 5,
          "debugobshistory.shortdescription": "E"
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
                      0
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "2a34000d3544",
                      "868d2e0eb19c"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "a8df460dbbfe",
          "debugobshistory.rev": 3,
          "debugobshistory.shortdescription": "C"
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
                      0
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "a8df460dbbfe"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "c473644ee0e9",
          "debugobshistory.rev": 2,
          "debugobshistory.shortdescription": "B"
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
                      0
                  ],
                  "debugobshistory.marker_user": "test",
                  "debugobshistory.succnodes": [
                      "c473644ee0e9"
                  ],
                  "debugobshistory.verb": "rewritten"
              }
          ],
          "debugobshistory.node": "2a34000d3544",
          "debugobshistory.rev": 1,
          "debugobshistory.shortdescription": "A"
      }
  ]

