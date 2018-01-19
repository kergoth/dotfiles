This test file test the various templates for precursors and successors.

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
  > [alias]
  > tlog = log -G -T '{node|short}\
  >     {if(precursors, "\n  Precursors: {precursors}")}\
  >     {if(precursors, "\n  semi-colon: {join(precursors, "; ")}")}\
  >     {if(successors, "\n  Successors: {successors}")}\
  >     {if(successors, "\n  semi-colon: {join(successors, "; ")}")}\
  >     {if(obsfate, "\n  Fate: {join(obsfate, "\n  Fate: ")}\n")}\n'
  > fatelog = log -G -T '{node|short}\n{if(obsfate, "  Obsfate: {join(obsfate, "; ")}\n\n")}'
  > fatelogjson = log -G -T '{node|short} {obsfatedata|json}\n'
  > EOF

Test templates on amended commit
================================

Test setup
----------

  $ hg init $TESTTMP/templates-local-amend
  $ cd $TESTTMP/templates-local-amend
  $ mkcommit ROOT
  $ mkcommit A0
  $ echo 42 >> A0
  $ HGUSER=test hg amend -m "A1" --config devel.default-date="1234567890 0"
  $ HGUSER=test2 hg amend -m "A2" --config devel.default-date="987654321 0"
  $ hg log --hidden -G
  @  changeset:   3:d004c8f274b9
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A2
  |
  | x  changeset:   2:a468dc9b3633
  |/   parent:      0:ea207398892e
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 3:d004c8f274b9 by test2
  |    summary:     A1
  |
  | x  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten using amend as 2:a468dc9b3633
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Check templates
---------------
  $ hg up 'desc(A0)' --hidden
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: d004c8f274b9)

Precursors template should show current revision as it is the working copy
  $ hg olog tip
  o  d004c8f274b9 (3) A2
  |
  x  a468dc9b3633 (2) A1
  |    rewritten(description) as d004c8f274b9 by test2 (Thu Apr 19 04:25:21 2001 +0000)
  |
  @  471f378eab4c (1) A0
       rewritten(description, content) as a468dc9b3633 by test (Fri Feb 13 23:31:30 2009 +0000)
  
  $ hg tlog
  o  d004c8f274b9
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | @  471f378eab4c
  |/     Successors: 3:d004c8f274b9
  |      semi-colon: 3:d004c8f274b9
  |      Fate: rewritten using amend as 3:d004c8f274b9 by test, test2
  |
  o  ea207398892e
  

  $ hg log -G
  o  changeset:   3:d004c8f274b9
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A2
  |
  | @  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten using amend as 3:d004c8f274b9 by test, test2
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

  $ hg fatelog -q
  o  d004c8f274b9
  |
  | @  471f378eab4c
  |/     Obsfate: rewritten using amend as 3:d004c8f274b9
  |
  o  ea207398892e
  

  $ hg fatelog
  o  d004c8f274b9
  |
  | @  471f378eab4c
  |/     Obsfate: rewritten using amend as 3:d004c8f274b9 by test, test2
  |
  o  ea207398892e
  
  $ hg fatelog -v
  o  d004c8f274b9
  |
  | @  471f378eab4c
  |/     Obsfate: rewritten using amend as 3:d004c8f274b9 by test, test2 (between 2001-04-19 04:25 +0000 and 2009-02-13 23:31 +0000)
  |
  o  ea207398892e
  

(check json)

  $ hg log -GT '{precursors|json}\n'
  o  ["471f378eab4c5e25f6c77f785b27c936efb22874"]
  |
  | @  []
  |/
  o  []
  

  $ hg log -GT '{successors|json}\n'
  o  ""
  |
  | @  [["d004c8f274b9ec480a47a93c10dac5eee63adb78"]]
  |/
  o  ""
  

  $ hg up 'desc(A1)' --hidden
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (a468dc9b3633)
  (use 'hg evolve' to update to its successor: d004c8f274b9)

Precursors template should show current revision as it is the working copy
  $ hg tlog
  o  d004c8f274b9
  |    Precursors: 2:a468dc9b3633
  |    semi-colon: 2:a468dc9b3633
  | @  a468dc9b3633
  |/     Successors: 3:d004c8f274b9
  |      semi-colon: 3:d004c8f274b9
  |      Fate: reworded using amend as 3:d004c8f274b9 by test2
  |
  o  ea207398892e
  
Precursors template should show the precursor as we force its display with
--hidden  
  $ hg tlog --hidden
  o  d004c8f274b9
  |    Precursors: 2:a468dc9b3633
  |    semi-colon: 2:a468dc9b3633
  | @  a468dc9b3633
  |/     Precursors: 1:471f378eab4c
  |      semi-colon: 1:471f378eab4c
  |      Successors: 3:d004c8f274b9
  |      semi-colon: 3:d004c8f274b9
  |      Fate: reworded using amend as 3:d004c8f274b9 by test2
  |
  | x  471f378eab4c
  |/     Successors: 2:a468dc9b3633
  |      semi-colon: 2:a468dc9b3633
  |      Fate: rewritten using amend as 2:a468dc9b3633
  |
  o  ea207398892e
  
  $ hg fatelog -v
  o  d004c8f274b9
  |
  | @  a468dc9b3633
  |/     Obsfate: reworded using amend as 3:d004c8f274b9 by test2 (at 2001-04-19 04:25 +0000)
  |
  o  ea207398892e
  
  $ hg up 'desc(A2)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg tlog
  @  d004c8f274b9
  |
  o  ea207398892e
  
  $ hg tlog --hidden
  @  d004c8f274b9
  |    Precursors: 2:a468dc9b3633
  |    semi-colon: 2:a468dc9b3633
  | x  a468dc9b3633
  |/     Precursors: 1:471f378eab4c
  |      semi-colon: 1:471f378eab4c
  |      Successors: 3:d004c8f274b9
  |      semi-colon: 3:d004c8f274b9
  |      Fate: reworded using amend as 3:d004c8f274b9 by test2
  |
  | x  471f378eab4c
  |/     Successors: 2:a468dc9b3633
  |      semi-colon: 2:a468dc9b3633
  |      Fate: rewritten using amend as 2:a468dc9b3633
  |
  o  ea207398892e
  
  $ hg fatelog -v
  @  d004c8f274b9
  |
  o  ea207398892e
  

  $ hg fatelog -v --hidden
  @  d004c8f274b9
  |
  | x  a468dc9b3633
  |/     Obsfate: reworded using amend as 3:d004c8f274b9 by test2 (at 2001-04-19 04:25 +0000)
  |
  | x  471f378eab4c
  |/     Obsfate: rewritten using amend as 2:a468dc9b3633 by test (at 2009-02-13 23:31 +0000)
  |
  o  ea207398892e
  

  $ hg fatelogjson --hidden
  @  d004c8f274b9 []
  |
  | x  a468dc9b3633 [{"markers": [["a468dc9b36338b14fdb7825f55ce3df4e71517ad", ["d004c8f274b9ec480a47a93c10dac5eee63adb78"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test2"]], [987654321.0, 0], null]], "max_date": [987654321.0, 0], "min_date": [987654321.0, 0], "successors": ["d004c8f274b9ec480a47a93c10dac5eee63adb78"], "users": ["test2"], "verb": "reworded"}]
  |/
  | x  471f378eab4c [{"markers": [["471f378eab4c5e25f6c77f785b27c936efb22874", ["a468dc9b36338b14fdb7825f55ce3df4e71517ad"], 0, [["ef1", "9"], ["operation", "amend"], ["user", "test"]], [1234567890.0, 0], null]], "max_date": [1234567890.0, 0], "min_date": [1234567890.0, 0], "successors": ["a468dc9b36338b14fdb7825f55ce3df4e71517ad"], "users": ["test"], "verb": "rewritten"}]
  |/
  o  ea207398892e []
  

Test templates with splitted commit
===================================

  $ hg init $TESTTMP/templates-local-split
  $ cd $TESTTMP/templates-local-split
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
  |    obsolete:    split as 2:337fec4d2edc, 3:f257fde29c7a
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

Check templates
---------------

  $ hg up 'obsolete()' --hidden
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471597cad322)
  (use 'hg evolve' to update to its tipmost successor: 337fec4d2edc, f257fde29c7a)

Precursors template should show current revision as it is the working copy
  $ hg tlog
  o  f257fde29c7a
  |    Precursors: 1:471597cad322
  |    semi-colon: 1:471597cad322
  o  337fec4d2edc
  |    Precursors: 1:471597cad322
  |    semi-colon: 1:471597cad322
  | @  471597cad322
  |/     Successors: 2:337fec4d2edc 3:f257fde29c7a
  |      semi-colon: 2:337fec4d2edc 3:f257fde29c7a
  |      Fate: split as 2:337fec4d2edc, 3:f257fde29c7a
  |
  o  ea207398892e
  
  $ hg fatelog
  o  f257fde29c7a
  |
  o  337fec4d2edc
  |
  | @  471597cad322
  |/     Obsfate: split as 2:337fec4d2edc, 3:f257fde29c7a
  |
  o  ea207398892e
  

  $ hg up f257fde29c7a
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

Precursors template should not show a precursor as it's not displayed in the
log
  $ hg tlog
  @  f257fde29c7a
  |
  o  337fec4d2edc
  |
  o  ea207398892e
  
Precursors template should show the precursor as we force its display with
--hidden
  $ hg tlog --hidden
  @  f257fde29c7a
  |    Precursors: 1:471597cad322
  |    semi-colon: 1:471597cad322
  o  337fec4d2edc
  |    Precursors: 1:471597cad322
  |    semi-colon: 1:471597cad322
  | x  471597cad322
  |/     Successors: 2:337fec4d2edc 3:f257fde29c7a
  |      semi-colon: 2:337fec4d2edc 3:f257fde29c7a
  |      Fate: split as 2:337fec4d2edc, 3:f257fde29c7a
  |
  o  ea207398892e
  
  $ hg fatelog --hidden
  @  f257fde29c7a
  |
  o  337fec4d2edc
  |
  | x  471597cad322
  |/     Obsfate: split as 2:337fec4d2edc, 3:f257fde29c7a
  |
  o  ea207398892e
  

  $ hg fatelogjson --hidden
  @  f257fde29c7a []
  |
  o  337fec4d2edc []
  |
  | x  471597cad322 [{"markers": [["471597cad322d1f659bb169751be9133dad92ef3", ["337fec4d2edcf0e7a467e35f818234bc620068b5", "f257fde29c7a847c9b607f6e958656d0df0fb15c"], 0, [["ef1", "12"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["337fec4d2edcf0e7a467e35f818234bc620068b5", "f257fde29c7a847c9b607f6e958656d0df0fb15c"], "users": ["test"], "verb": "split"}]
  |/
  o  ea207398892e []
  

Test templates with folded commit
==============================

Test setup
----------

  $ hg init $TESTTMP/templates-local-fold
  $ cd $TESTTMP/templates-local-fold
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
  
Check templates
---------------

  $ hg up 'desc(A0)' --hidden
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)

Precursors template should show current revision as it is the working copy
  $ hg tlog
  o  eb5a0daa2192
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | @  471f378eab4c
  |/     Successors: 3:eb5a0daa2192
  |      semi-colon: 3:eb5a0daa2192
  |      Fate: rewritten as 3:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog
  o  eb5a0daa2192
  |
  | @  471f378eab4c
  |/     Obsfate: rewritten as 3:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg up 'desc(B0)' --hidden
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)

Precursors template should show both precursors as they should be both
displayed
  $ hg tlog
  o  eb5a0daa2192
  |    Precursors: 2:0dec01379d3b 1:471f378eab4c
  |    semi-colon: 2:0dec01379d3b; 1:471f378eab4c
  | @  0dec01379d3b
  | |    Successors: 3:eb5a0daa2192
  | |    semi-colon: 3:eb5a0daa2192
  | |    Fate: rewritten as 3:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Successors: 3:eb5a0daa2192
  |      semi-colon: 3:eb5a0daa2192
  |      Fate: rewritten as 3:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog
  o  eb5a0daa2192
  |
  | @  0dec01379d3b
  | |    Obsfate: rewritten as 3:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 3:eb5a0daa2192
  |
  o  ea207398892e
  

  $ hg up 'desc(C0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

Precursors template should not show precursors as it's not displayed in the
log
  $ hg tlog
  @  eb5a0daa2192
  |
  o  ea207398892e
  
Precursors template should show both precursors as we force its display with
--hidden
  $ hg tlog --hidden
  @  eb5a0daa2192
  |    Precursors: 2:0dec01379d3b 1:471f378eab4c
  |    semi-colon: 2:0dec01379d3b; 1:471f378eab4c
  | x  0dec01379d3b
  | |    Successors: 3:eb5a0daa2192
  | |    semi-colon: 3:eb5a0daa2192
  | |    Fate: rewritten as 3:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Successors: 3:eb5a0daa2192
  |      semi-colon: 3:eb5a0daa2192
  |      Fate: rewritten as 3:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog --hidden
  @  eb5a0daa2192
  |
  | x  0dec01379d3b
  | |    Obsfate: rewritten as 3:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 3:eb5a0daa2192
  |
  o  ea207398892e
  

  $ hg fatelogjson --hidden
  @  eb5a0daa2192 []
  |
  | x  0dec01379d3b [{"markers": [["0dec01379d3be6318c470ead31b1fe7ae7cb53d5", ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], 0, [["ef1", "13"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], "users": ["test"], "verb": "rewritten"}]
  | |
  | x  471f378eab4c [{"markers": [["471f378eab4c5e25f6c77f785b27c936efb22874", ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], 0, [["ef1", "9"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], "users": ["test"], "verb": "rewritten"}]
  |/
  o  ea207398892e []
  

Test templates with divergence
==============================

Test setup
----------

  $ hg init $TESTTMP/templates-local-divergence
  $ cd $TESTTMP/templates-local-divergence
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
  
  $ hg amend -m 'A3'

Check templates
---------------

  $ hg up 'desc(A0)' --hidden
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (471f378eab4c has diverged, use 'hg evolve --list --content-divergent' to resolve the issue)

Precursors template should show current revision as it is the working copy
  $ hg tlog
  o  019fadeab383
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | o  fdf9bde5129a
  |/     Precursors: 1:471f378eab4c
  |      semi-colon: 1:471f378eab4c
  | @  471f378eab4c
  |/     Successors: 2:fdf9bde5129a; 4:019fadeab383
  |      semi-colon: 2:fdf9bde5129a; 4:019fadeab383
  |      Fate: reworded using amend as 2:fdf9bde5129a
  |      Fate: reworded using amend as 4:019fadeab383
  |
  o  ea207398892e
  
  $ hg fatelog
  o  019fadeab383
  |
  | o  fdf9bde5129a
  |/
  | @  471f378eab4c
  |/     Obsfate: reworded using amend as 2:fdf9bde5129a; reworded using amend as 4:019fadeab383
  |
  o  ea207398892e
  

  $ hg up 'desc(A1)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
Precursors template should not show precursors as it's not displayed in the
log
  $ hg tlog
  o  019fadeab383
  |
  | @  fdf9bde5129a
  |/
  o  ea207398892e
  

  $ hg fatelog
  o  019fadeab383
  |
  | @  fdf9bde5129a
  |/
  o  ea207398892e
  
Precursors template should a precursor as we force its display with --hidden
  $ hg tlog --hidden
  o  019fadeab383
  |    Precursors: 3:65b757b745b9
  |    semi-colon: 3:65b757b745b9
  | x  65b757b745b9
  |/     Precursors: 1:471f378eab4c
  |      semi-colon: 1:471f378eab4c
  |      Successors: 4:019fadeab383
  |      semi-colon: 4:019fadeab383
  |      Fate: reworded using amend as 4:019fadeab383
  |
  | @  fdf9bde5129a
  |/     Precursors: 1:471f378eab4c
  |      semi-colon: 1:471f378eab4c
  | x  471f378eab4c
  |/     Successors: 2:fdf9bde5129a; 3:65b757b745b9
  |      semi-colon: 2:fdf9bde5129a; 3:65b757b745b9
  |      Fate: reworded using amend as 2:fdf9bde5129a
  |      Fate: reworded using amend as 3:65b757b745b9
  |
  o  ea207398892e
  
  $ hg fatelog --hidden
  o  019fadeab383
  |
  | x  65b757b745b9
  |/     Obsfate: reworded using amend as 4:019fadeab383
  |
  | @  fdf9bde5129a
  |/
  | x  471f378eab4c
  |/     Obsfate: reworded using amend as 2:fdf9bde5129a; reworded using amend as 3:65b757b745b9
  |
  o  ea207398892e
  

  $ hg fatelogjson --hidden
  o  019fadeab383 []
  |
  | x  65b757b745b9 [{"markers": [["65b757b745b935093c87a2bccd877521cccffcbd", ["019fadeab383f6699fa83ad7bdb4d82ed2c0e5ab"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["019fadeab383f6699fa83ad7bdb4d82ed2c0e5ab"], "users": ["test"], "verb": "reworded"}]
  |/
  | @  fdf9bde5129a []
  |/
  | x  471f378eab4c [{"markers": [["471f378eab4c5e25f6c77f785b27c936efb22874", ["fdf9bde5129a28d4548fadd3f62b265cdd3b7a2e"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["fdf9bde5129a28d4548fadd3f62b265cdd3b7a2e"], "users": ["test"], "verb": "reworded"}, {"markers": [["471f378eab4c5e25f6c77f785b27c936efb22874", ["65b757b745b935093c87a2bccd877521cccffcbd"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["65b757b745b935093c87a2bccd877521cccffcbd"], "users": ["test"], "verb": "reworded"}]
  |/
  o  ea207398892e []
  

Test templates with amended + folded commit
===========================================

Test setup
----------

  $ hg init $TESTTMP/templates-local-amend-fold
  $ cd $TESTTMP/templates-local-amend-fold
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
  
Check templates
---------------

  $ hg up 'desc(A0)' --hidden
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg tlog
  o  eb5a0daa2192
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | @  471f378eab4c
  |/     Successors: 4:eb5a0daa2192
  |      semi-colon: 4:eb5a0daa2192
  |      Fate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog
  o  eb5a0daa2192
  |
  | @  471f378eab4c
  |/     Obsfate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg up 'desc(B0)' --hidden
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg tlog
  o  eb5a0daa2192
  |    Precursors: 2:0dec01379d3b 1:471f378eab4c
  |    semi-colon: 2:0dec01379d3b; 1:471f378eab4c
  | @  0dec01379d3b
  | |    Successors: 4:eb5a0daa2192
  | |    semi-colon: 4:eb5a0daa2192
  | |    Fate: rewritten using amend as 4:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Successors: 4:eb5a0daa2192
  |      semi-colon: 4:eb5a0daa2192
  |      Fate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog
  o  eb5a0daa2192
  |
  | @  0dec01379d3b
  | |    Obsfate: rewritten using amend as 4:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  

  $ hg up 'desc(B1)' --hidden
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (b7ea6d14e664)
  (use 'hg evolve' to update to its successor: eb5a0daa2192)
  $ hg tlog
  o  eb5a0daa2192
  |    Precursors: 1:471f378eab4c 3:b7ea6d14e664
  |    semi-colon: 1:471f378eab4c; 3:b7ea6d14e664
  | @  b7ea6d14e664
  | |    Successors: 4:eb5a0daa2192
  | |    semi-colon: 4:eb5a0daa2192
  | |    Fate: rewritten as 4:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Successors: 4:eb5a0daa2192
  |      semi-colon: 4:eb5a0daa2192
  |      Fate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog
  o  eb5a0daa2192
  |
  | @  b7ea6d14e664
  | |    Obsfate: rewritten as 4:eb5a0daa2192
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  

  $ hg up 'desc(C0)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg tlog
  @  eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg tlog --hidden
  @  eb5a0daa2192
  |    Precursors: 1:471f378eab4c 3:b7ea6d14e664
  |    semi-colon: 1:471f378eab4c; 3:b7ea6d14e664
  | x  b7ea6d14e664
  | |    Precursors: 2:0dec01379d3b
  | |    semi-colon: 2:0dec01379d3b
  | |    Successors: 4:eb5a0daa2192
  | |    semi-colon: 4:eb5a0daa2192
  | |    Fate: rewritten as 4:eb5a0daa2192
  | |
  | | x  0dec01379d3b
  | |/     Successors: 3:b7ea6d14e664
  | |      semi-colon: 3:b7ea6d14e664
  | |      Fate: reworded using amend as 3:b7ea6d14e664
  | |
  | x  471f378eab4c
  |/     Successors: 4:eb5a0daa2192
  |      semi-colon: 4:eb5a0daa2192
  |      Fate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelog --hidden
  @  eb5a0daa2192
  |
  | x  b7ea6d14e664
  | |    Obsfate: rewritten as 4:eb5a0daa2192
  | |
  | | x  0dec01379d3b
  | |/     Obsfate: reworded using amend as 3:b7ea6d14e664
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 4:eb5a0daa2192
  |
  o  ea207398892e
  
  $ hg fatelogjson --hidden
  @  eb5a0daa2192 []
  |
  | x  b7ea6d14e664 [{"markers": [["b7ea6d14e664bdc8922221f7992631b50da3fb07", ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], 0, [["ef1", "13"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], "users": ["test"], "verb": "rewritten"}]
  | |
  | | x  0dec01379d3b [{"markers": [["0dec01379d3be6318c470ead31b1fe7ae7cb53d5", ["b7ea6d14e664bdc8922221f7992631b50da3fb07"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["b7ea6d14e664bdc8922221f7992631b50da3fb07"], "users": ["test"], "verb": "reworded"}]
  | |/
  | x  471f378eab4c [{"markers": [["471f378eab4c5e25f6c77f785b27c936efb22874", ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], 0, [["ef1", "9"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["eb5a0daa21923bbf8caeb2c42085b9e463861fd0"], "users": ["test"], "verb": "rewritten"}]
  |/
  o  ea207398892e []
  

Test template with pushed and pulled obs markers
==============================================

Test setup
----------

  $ hg init $TESTTMP/templates-local-remote-markers-1
  $ cd $TESTTMP/templates-local-remote-markers-1
  $ mkcommit ROOT
  $ mkcommit A0  
  $ hg clone $TESTTMP/templates-local-remote-markers-1 $TESTTMP/templates-local-remote-markers-2
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd $TESTTMP/templates-local-remote-markers-2
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
  
  $ cd $TESTTMP/templates-local-remote-markers-1
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
  
  $ cd $TESTTMP/templates-local-remote-markers-2
  $ hg pull
  pulling from $TESTTMP/templates-local-remote-markers-1
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
  $ hg log --hidden -G
  o  changeset:   2:7a230b46bf61
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     A2
  |
  | @  changeset:   1:471f378eab4c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 2:7a230b46bf61
  |    summary:     A0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Check templates
---------------

  $ hg tlog
  o  7a230b46bf61
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | @  471f378eab4c
  |/     Successors: 2:7a230b46bf61
  |      semi-colon: 2:7a230b46bf61
  |      Fate: reworded using amend as 2:7a230b46bf61
  |
  o  ea207398892e
  
  $ hg fatelog --hidden -v
  o  7a230b46bf61
  |
  | @  471f378eab4c
  |/     Obsfate: reworded using amend as 2:7a230b46bf61 by test (at 1970-01-01 00:00 +0000)
  |
  o  ea207398892e
  
  $ hg up 'desc(A2)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg tlog
  @  7a230b46bf61
  |
  o  ea207398892e
  
  $ hg fatelog -v
  @  7a230b46bf61
  |
  o  ea207398892e
  
  $ hg tlog --hidden
  @  7a230b46bf61
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | x  471f378eab4c
  |/     Successors: 2:7a230b46bf61
  |      semi-colon: 2:7a230b46bf61
  |      Fate: reworded using amend as 2:7a230b46bf61
  |
  o  ea207398892e
  
  $ hg fatelog --hidden -v
  @  7a230b46bf61
  |
  | x  471f378eab4c
  |/     Obsfate: reworded using amend as 2:7a230b46bf61 by test (at 1970-01-01 00:00 +0000)
  |
  o  ea207398892e
  

  $ hg fatelogjson --hidden
  @  7a230b46bf61 []
  |
  | x  471f378eab4c [{"markers": [["471f378eab4c5e25f6c77f785b27c936efb22874", ["fdf9bde5129a28d4548fadd3f62b265cdd3b7a2e"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test"]], [0.0, 0], null], ["fdf9bde5129a28d4548fadd3f62b265cdd3b7a2e", ["7a230b46bf61e50b30308c6cfd7bd1269ef54702"], 0, [["ef1", "1"], ["operation", "amend"], ["user", "test"]], [0.0, 0], null]], "max_date": [0.0, 0], "min_date": [0.0, 0], "successors": ["7a230b46bf61e50b30308c6cfd7bd1269ef54702"], "users": ["test"], "verb": "reworded"}]
  |/
  o  ea207398892e []
  
 
Test template with obsmarkers cycle
===================================

Test setup
----------

  $ hg init $TESTTMP/templates-local-cycle
  $ cd $TESTTMP/templates-local-cycle
  $ mkcommit ROOT
  $ mkcommit A0
  $ mkcommit B0
  $ hg up -r 0
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit C0
  created new head

Create the cycle

  $ hg debugobsolete `getid "desc(A0)"` `getid "desc(B0)"`
  obsoleted 1 changesets
  $ hg debugobsolete `getid "desc(B0)"` `getid "desc(C0)"`
  obsoleted 1 changesets
  $ hg debugobsolete `getid "desc(B0)"` `getid "desc(A0)"`

Check templates
---------------

  $ hg tlog
  @  f897c6137566
  |
  o  ea207398892e
  
  $ hg fatelog
  @  f897c6137566
  |
  o  ea207398892e
  
  $ hg up -r "desc(B0)" --hidden
  2 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (0dec01379d3b)
  (use 'hg evolve' to update to its parent successor)
  $ hg tlog
  o  f897c6137566
  |    Precursors: 2:0dec01379d3b
  |    semi-colon: 2:0dec01379d3b
  | @  0dec01379d3b
  | |    Precursors: 1:471f378eab4c
  | |    semi-colon: 1:471f378eab4c
  | |    Successors: 3:f897c6137566; 1:471f378eab4c
  | |    semi-colon: 3:f897c6137566; 1:471f378eab4c
  | |    Fate: rewritten as 3:f897c6137566
  | |    Fate: rewritten as 1:471f378eab4c
  | |
  | x  471f378eab4c
  |/     Precursors: 2:0dec01379d3b
  |      semi-colon: 2:0dec01379d3b
  |      Successors: 2:0dec01379d3b
  |      semi-colon: 2:0dec01379d3b
  |      Fate: rewritten as 2:0dec01379d3b
  |
  o  ea207398892e
  
  $ hg fatelog
  o  f897c6137566
  |
  | @  0dec01379d3b
  | |    Obsfate: rewritten as 3:f897c6137566; rewritten as 1:471f378eab4c
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 2:0dec01379d3b
  |
  o  ea207398892e
  
  $ hg up -r "desc(A0)" --hidden
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its parent successor)
  $ hg tlog
  o  f897c6137566
  |    Precursors: 1:471f378eab4c
  |    semi-colon: 1:471f378eab4c
  | @  471f378eab4c
  |/     Fate: pruned
  |
  o  ea207398892e
  
  $ hg fatelog
  o  f897c6137566
  |
  | @  471f378eab4c
  |/     Obsfate: pruned
  |
  o  ea207398892e
  

  $ hg up -r "desc(ROOT)" --hidden
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg tlog
  o  f897c6137566
  |
  @  ea207398892e
  
  $ hg fatelog
  o  f897c6137566
  |
  @  ea207398892e
  
  $ hg tlog --hidden
  o  f897c6137566
  |    Precursors: 2:0dec01379d3b
  |    semi-colon: 2:0dec01379d3b
  | x  0dec01379d3b
  | |    Precursors: 1:471f378eab4c
  | |    semi-colon: 1:471f378eab4c
  | |    Successors: 3:f897c6137566; 1:471f378eab4c
  | |    semi-colon: 3:f897c6137566; 1:471f378eab4c
  | |    Fate: rewritten as 3:f897c6137566
  | |    Fate: rewritten as 1:471f378eab4c
  | |
  | x  471f378eab4c
  |/     Precursors: 2:0dec01379d3b
  |      semi-colon: 2:0dec01379d3b
  |      Successors: 2:0dec01379d3b
  |      semi-colon: 2:0dec01379d3b
  |      Fate: rewritten as 2:0dec01379d3b
  |
  @  ea207398892e
  
Test template with split + divergence with cycles
=================================================

  $ hg log -G
  o  changeset:   3:f897c6137566
  |  tag:         tip
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C0
  |
  @  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg up
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

Create a commit with three files
  $ touch A B C
  $ hg commit -A -m "Add A,B,C" A B C

Split it
  $ hg up 3
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ touch A
  $ hg commit -A -m "Add A,B,C" A
  created new head

  $ touch B
  $ hg commit -A -m "Add A,B,C" B

  $ touch C
  $ hg commit -A -m "Add A,B,C" C

  $ hg log -G
  @  changeset:   7:ba2ed02b0c9a
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add A,B,C
  |
  o  changeset:   6:4a004186e638
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add A,B,C
  |
  o  changeset:   5:dd800401bd8c
  |  parent:      3:f897c6137566
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add A,B,C
  |
  | o  changeset:   4:9bd10a0775e4
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Add A,B,C
  |
  o  changeset:   3:f897c6137566
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg debugobsolete `getid "4"` `getid "5"` `getid "6"` `getid "7"`
  obsoleted 1 changesets
  $ hg log -G
  @  changeset:   7:ba2ed02b0c9a
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add A,B,C
  |
  o  changeset:   6:4a004186e638
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add A,B,C
  |
  o  changeset:   5:dd800401bd8c
  |  parent:      3:f897c6137566
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add A,B,C
  |
  o  changeset:   3:f897c6137566
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Diverge one of the splitted commit

  $ hg up 6
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg commit --amend -m "Add only B"
  1 new orphan changesets

  $ hg up 6 --hidden
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (4a004186e638)
  (use 'hg evolve' to update to its successor: b18bc8331526)
  $ hg commit --amend -m "Add B only"
  4 new content-divergent changesets

  $ hg log -G
  @  changeset:   9:0b997eb7ceee
  |  tag:         tip
  |  parent:      5:dd800401bd8c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: content-divergent
  |  summary:     Add B only
  |
  | o  changeset:   8:b18bc8331526
  |/   parent:      5:dd800401bd8c
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    instability: content-divergent
  |    summary:     Add only B
  |
  | o  changeset:   7:ba2ed02b0c9a
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan, content-divergent
  | |  summary:     Add A,B,C
  | |
  | x  changeset:   6:4a004186e638
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 8:b18bc8331526
  |    obsolete:    reworded using amend as 9:0b997eb7ceee
  |    summary:     Add A,B,C
  |
  o  changeset:   5:dd800401bd8c
  |  parent:      3:f897c6137566
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  instability: content-divergent
  |  summary:     Add A,B,C
  |
  o  changeset:   3:f897c6137566
  |  parent:      0:ea207398892e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C0
  |
  o  changeset:   0:ea207398892e
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Check templates
---------------

  $ hg tlog
  @  0b997eb7ceee
  |    Precursors: 6:4a004186e638
  |    semi-colon: 6:4a004186e638
  | o  b18bc8331526
  |/     Precursors: 6:4a004186e638
  |      semi-colon: 6:4a004186e638
  | o  ba2ed02b0c9a
  | |
  | x  4a004186e638
  |/     Successors: 8:b18bc8331526; 9:0b997eb7ceee
  |      semi-colon: 8:b18bc8331526; 9:0b997eb7ceee
  |      Fate: reworded using amend as 8:b18bc8331526
  |      Fate: reworded using amend as 9:0b997eb7ceee
  |
  o  dd800401bd8c
  |
  o  f897c6137566
  |
  o  ea207398892e
  
  $ hg fatelog
  @  0b997eb7ceee
  |
  | o  b18bc8331526
  |/
  | o  ba2ed02b0c9a
  | |
  | x  4a004186e638
  |/     Obsfate: reworded using amend as 8:b18bc8331526; reworded using amend as 9:0b997eb7ceee
  |
  o  dd800401bd8c
  |
  o  f897c6137566
  |
  o  ea207398892e
  
  $ hg tlog --hidden
  @  0b997eb7ceee
  |    Precursors: 6:4a004186e638
  |    semi-colon: 6:4a004186e638
  | o  b18bc8331526
  |/     Precursors: 6:4a004186e638
  |      semi-colon: 6:4a004186e638
  | o  ba2ed02b0c9a
  | |    Precursors: 4:9bd10a0775e4
  | |    semi-colon: 4:9bd10a0775e4
  | x  4a004186e638
  |/     Precursors: 4:9bd10a0775e4
  |      semi-colon: 4:9bd10a0775e4
  |      Successors: 8:b18bc8331526; 9:0b997eb7ceee
  |      semi-colon: 8:b18bc8331526; 9:0b997eb7ceee
  |      Fate: reworded using amend as 8:b18bc8331526
  |      Fate: reworded using amend as 9:0b997eb7ceee
  |
  o  dd800401bd8c
  |    Precursors: 4:9bd10a0775e4
  |    semi-colon: 4:9bd10a0775e4
  | x  9bd10a0775e4
  |/     Successors: 5:dd800401bd8c 6:4a004186e638 7:ba2ed02b0c9a
  |      semi-colon: 5:dd800401bd8c 6:4a004186e638 7:ba2ed02b0c9a
  |      Fate: split as 5:dd800401bd8c, 6:4a004186e638, 7:ba2ed02b0c9a
  |
  o  f897c6137566
  |    Precursors: 2:0dec01379d3b
  |    semi-colon: 2:0dec01379d3b
  | x  0dec01379d3b
  | |    Precursors: 1:471f378eab4c
  | |    semi-colon: 1:471f378eab4c
  | |    Successors: 3:f897c6137566; 1:471f378eab4c
  | |    semi-colon: 3:f897c6137566; 1:471f378eab4c
  | |    Fate: rewritten as 3:f897c6137566
  | |    Fate: rewritten as 1:471f378eab4c
  | |
  | x  471f378eab4c
  |/     Precursors: 2:0dec01379d3b
  |      semi-colon: 2:0dec01379d3b
  |      Successors: 2:0dec01379d3b
  |      semi-colon: 2:0dec01379d3b
  |      Fate: rewritten as 2:0dec01379d3b
  |
  o  ea207398892e
  
  $ hg fatelog --hidden
  @  0b997eb7ceee
  |
  | o  b18bc8331526
  |/
  | o  ba2ed02b0c9a
  | |
  | x  4a004186e638
  |/     Obsfate: reworded using amend as 8:b18bc8331526; reworded using amend as 9:0b997eb7ceee
  |
  o  dd800401bd8c
  |
  | x  9bd10a0775e4
  |/     Obsfate: split as 5:dd800401bd8c, 6:4a004186e638, 7:ba2ed02b0c9a
  |
  o  f897c6137566
  |
  | x  0dec01379d3b
  | |    Obsfate: rewritten as 3:f897c6137566; rewritten as 1:471f378eab4c
  | |
  | x  471f378eab4c
  |/     Obsfate: rewritten as 2:0dec01379d3b
  |
  o  ea207398892e
  
  $ hg up --hidden 4
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (9bd10a0775e4)
  (9bd10a0775e4 has diverged, use 'hg evolve --list --content-divergent' to resolve the issue)
  $ hg rebase -r 7 -d 8 --config extensions.rebase=
  rebasing 7:ba2ed02b0c9a "Add A,B,C"
  $ hg tlog
  o  eceed8f98ffc
  |    Precursors: 4:9bd10a0775e4
  |    semi-colon: 4:9bd10a0775e4
  | o  0b997eb7ceee
  | |    Precursors: 4:9bd10a0775e4
  | |    semi-colon: 4:9bd10a0775e4
  o |  b18bc8331526
  |/     Precursors: 4:9bd10a0775e4
  |      semi-colon: 4:9bd10a0775e4
  o  dd800401bd8c
  |    Precursors: 4:9bd10a0775e4
  |    semi-colon: 4:9bd10a0775e4
  | @  9bd10a0775e4
  |/     Successors: 5:dd800401bd8c 9:0b997eb7ceee 10:eceed8f98ffc; 5:dd800401bd8c 8:b18bc8331526 10:eceed8f98ffc
  |      semi-colon: 5:dd800401bd8c 9:0b997eb7ceee 10:eceed8f98ffc; 5:dd800401bd8c 8:b18bc8331526 10:eceed8f98ffc
  |      Fate: split using amend, rebase as 5:dd800401bd8c, 9:0b997eb7ceee, 10:eceed8f98ffc
  |      Fate: split using amend, rebase as 5:dd800401bd8c, 8:b18bc8331526, 10:eceed8f98ffc
  |
  o  f897c6137566
  |
  o  ea207398892e
  
  $ hg fatelog
  o  eceed8f98ffc
  |
  | o  0b997eb7ceee
  | |
  o |  b18bc8331526
  |/
  o  dd800401bd8c
  |
  | @  9bd10a0775e4
  |/     Obsfate: split using amend, rebase as 5:dd800401bd8c, 9:0b997eb7ceee, 10:eceed8f98ffc; split using amend, rebase as 5:dd800401bd8c, 8:b18bc8331526, 10:eceed8f98ffc
  |
  o  f897c6137566
  |
  o  ea207398892e
  
Test templates with pruned commits
==================================

Test setup
----------

  $ hg init $TESTTMP/templates-local-prune
  $ cd $TESTTMP/templates-local-prune
  $ mkcommit ROOT
  $ mkcommit A0
  $ hg prune .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at ea207398892e
  1 changesets pruned

Check output
------------

  $ hg up "desc(A0)" --hidden
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory parent is obsolete! (471f378eab4c)
  (use 'hg evolve' to update to its parent successor)
  $ hg tlog
  @  471f378eab4c
  |    Fate: pruned
  |
  o  ea207398892e
  
  $ hg fatelog -v
  @  471f378eab4c
  |    Obsfate: pruned by test (at 1970-01-01 00:00 +0000)
  |
  o  ea207398892e
  
