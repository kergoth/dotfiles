=====================
Evolve/Topic Training
=====================

.. Various setup

  $ . $TESTDIR/testlib/common.sh
  $ cat >> $HGRCPATH << EOF
  > [ui]
  > interactive = true
  > [extensions]
  > rebase=
  > evolve=
  > topic=
  > docgraph=
  > histedit=
  > 
  > EOF

Create the base repo
--------------------

  $ hg init $TESTTMP/base
  $ cd $TESTTMP/base

Setup the hgrc
  $ cat > .hg/hgrc << EOF
  > [paths]
  > default = https://bitbucket.org/octobus/evolve_training_repo
  > [ui]
  > interactive = true
  > interface = text
  > username = Boris Feld <boris.feld@octobus.net>
  > tweakdefault = true
  > [extensions]
  > rebase=
  > evolve=
  > topic=
  > histedit=
  > [phases]
  > publish = False
  > 
  > EOF

0:ROOT

  $ touch README
  $ cp .hg/hgrc hgrc
  $ hg add README hgrc
  $ hg commit -m "ROOT" -d "Thu Dec 07 11:26:05 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"
  $ hg phase -p .

1:amend

  $ hg branch typo
  marked working directory as branch typo
  (branches are permanent and global, did you want a bookmark?)
  $ touch fix-bug
  $ hg add fix-bug
  $ hg commit -m "Fx bug" -d "Thu Dec 07 11:26:53 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

2-6:rebase
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ hg branch build/v2
  marked working directory as branch build/v2
  $ mkdir v2
  $ touch v2/README
  $ hg add v2/README
  $ hg commit -m "First commit on build/v2" -d "Thu Dec 07 16:45:07 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ hg branch build/linuxsupport-v2
  marked working directory as branch build/linuxsupport-v2
  $ touch v2/LINUX
  $ hg add v2/LINUX
  $ hg commit -m "First commit on build/linuxsupport-v2" -d "Thu Dec 07 16:46:32 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ echo "Instructions for linux" > v2/LINUX
  $ hg commit -m "Second commit on build/linuxsupport-v2." -d "Mon Dec 11 11:20:24 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ touch v2/Makefile.linux
  $ hg add v2/Makefile.linux
  $ hg commit -m "Third commit on build/linuxsupport-v2" -d "Mon Dec 11 11:21:02 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ hg up "build/v2"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ touch v2/WINDOWS
  $ hg add v2/WINDOWS
  $ hg commit -m "New commit on build/v2" -d "Mon Dec 11 11:22:16 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

7-8:amend-extract

  $ hg up 0
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg branch amend-extract
  marked working directory as branch amend-extract
  $ cat >> fileextract << EOF
  > # The file dedicated to be extracted
  > 
  > 1
  > 2
  > 3
  > 4
  > 5
  > 6
  > 7
  > 8
  > 9
  > 10
  > 
  > EOF
  $ hg add fileextract
  $ hg commit -m "Base file" -d "Fri Dec 08 15:04:09 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ echo "badbadfile" > badfile
  $ hg add badfile
  $ cat > fileextract << EOF
  > # The file dedicated to be extracted
  > 
  > 0
  > 1
  > 2
  > 3
  > 4
  > 5
  > 6
  > 7
  > 8
  > 9
  > 10
  > 42
  > 
  > EOF
  $ hg commit -m "Commit to be extracted" -d "Fri Dec 08 15:28:46 2017 +0100" -u "Bad User"

9: prune

  $ hg up 0
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg branch prune
  marked working directory as branch prune
  $ touch filetoprune
  $ hg add filetoprune
  $ hg commit -m "Commit to prune" -d "Fri Dec 08 16:12:23 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ hg export
  # HG changeset patch
  # User Boris Feld <boris.feld@octobus.net>
  # Date 1512745943 -3600
  #      Fri Dec 08 16:12:23 2017 +0100
  # Branch prune
  # Node ID 324b72ebbb217eb34975c65c794a7d9408a88675
  # Parent  d2eb2ac6a5bd73b2cc78fca3489488b2b0fdf8b1
  Commit to prune
  
10-12: fold

  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg branch fold
  marked working directory as branch fold
  $ mkdir test
  $ echo "assert 42 = 0" > test/unit
  $ hg add test/unit
  $ hg commit -m "add a test" -d "Fri Dec 08 16:49:45 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ echo "assert 42 = 43" > test/unit
  $ hg commit -m "Fix the test" -d "Fri Dec 08 16:50:17 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ echo "assert 42 = 42" > test/unit
  $ hg commit -m "Really fix the test" -d "Fri Dec 08 16:50:38 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"  

  $ hg export 
  # HG changeset patch
  # User Boris Feld <boris.feld@octobus.net>
  # Date 1512748238 -3600
  #      Fri Dec 08 16:50:38 2017 +0100
  # Branch fold
  # Node ID 966df9f031c13cd37c685b6c2a2e7423935cef56
  # Parent  b316dc02bddce9fa1f8676a0feeccdeb1bea03ae
  Really fix the test
  
  diff -r b316dc02bddc -r 966df9f031c1 test/unit
  --- a/test/unit	Fri Dec 08 16:50:17 2017 +0100
  +++ b/test/unit	Fri Dec 08 16:50:38 2017 +0100
  @@ -1,1 +1,1 @@
  -assert 42 = 43
  +assert 42 = 42

13: split

  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg branch split
  marked working directory as branch split
  $ mkdir src
  $ touch src/A src/B src/C
  $ hg add src/*
  $ hg commit -m "To be splitted" -d "Fri Dec 08 17:33:15 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"  

14-16: histedit

  $ hg up 0
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg branch histedit
  marked working directory as branch histedit

  $ hg commit -m "First commit on histedit branch" -d "Fri Dec 09 17:33:15 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ mkdir myfeature
  $ touch myfeature/code
  $ hg add myfeature/code
  $ hg commit -m "Add code for myfeature" -d "Fri Dec 09 17:35:15 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ touch myfeature/test
  $ hg add myfeature/test
  $ hg commit -m "Add test for myfeature" -d "Fri Dec 09 17:37:15 2017 +0100" -u "Boris Feld <boris.feld@octobus.net>"

  $ cp -R $TESTTMP/base $TESTDIR/base-repos/init

  $ hg log -G
  @  changeset:   16:1b1e58a9ed27
  |  branch:      histedit
  |  tag:         tip
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Sat Dec 09 17:37:15 2017 +0100
  |  summary:     Add test for myfeature
  |
  o  changeset:   15:23eb6f9e4c51
  |  branch:      histedit
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Sat Dec 09 17:35:15 2017 +0100
  |  summary:     Add code for myfeature
  |
  o  changeset:   14:d102c718e607
  |  branch:      histedit
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Sat Dec 09 17:33:15 2017 +0100
  |  summary:     First commit on histedit branch
  |
  | o  changeset:   13:5d5029b9daed
  |/   branch:      split
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Fri Dec 08 17:33:15 2017 +0100
  |    summary:     To be splitted
  |
  | o  changeset:   12:966df9f031c1
  | |  branch:      fold
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Fri Dec 08 16:50:38 2017 +0100
  | |  summary:     Really fix the test
  | |
  | o  changeset:   11:b316dc02bddc
  | |  branch:      fold
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Fri Dec 08 16:50:17 2017 +0100
  | |  summary:     Fix the test
  | |
  | o  changeset:   10:03174536bb2a
  |/   branch:      fold
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Fri Dec 08 16:49:45 2017 +0100
  |    summary:     add a test
  |
  | o  changeset:   9:324b72ebbb21
  |/   branch:      prune
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Fri Dec 08 16:12:23 2017 +0100
  |    summary:     Commit to prune
  |
  | o  changeset:   8:e288d12d5e96
  | |  branch:      amend-extract
  | |  user:        Bad User
  | |  date:        Fri Dec 08 15:28:46 2017 +0100
  | |  summary:     Commit to be extracted
  | |
  | o  changeset:   7:4ae0d1de7a58
  |/   branch:      amend-extract
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Fri Dec 08 15:04:09 2017 +0100
  |    summary:     Base file
  |
  | o  changeset:   6:0e694460372e
  | |  branch:      build/v2
  | |  parent:      2:f3bd0ab4ee87
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Mon Dec 11 11:22:16 2017 +0100
  | |  summary:     New commit on build/v2
  | |
  | | o  changeset:   5:39e9774ab30b
  | | |  branch:      build/linuxsupport-v2
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | | |  summary:     Third commit on build/linuxsupport-v2
  | | |
  | | o  changeset:   4:5ad93176b041
  | | |  branch:      build/linuxsupport-v2
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Mon Dec 11 11:20:24 2017 +0100
  | | |  summary:     Second commit on build/linuxsupport-v2.
  | | |
  | | o  changeset:   3:424916b62f4c
  | |/   branch:      build/linuxsupport-v2
  | |    user:        Boris Feld <boris.feld@octobus.net>
  | |    date:        Thu Dec 07 16:46:32 2017 +0100
  | |    summary:     First commit on build/linuxsupport-v2
  | |
  | o  changeset:   2:f3bd0ab4ee87
  |/   branch:      build/v2
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Thu Dec 07 16:45:07 2017 +0100
  |    summary:     First commit on build/v2
  |
  | o  changeset:   1:5d48a444aba7
  |/   branch:      typo
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Thu Dec 07 11:26:53 2017 +0100
  |    summary:     Fx bug
  |
  o  changeset:   0:d2eb2ac6a5bd
     user:        Boris Feld <boris.feld@octobus.net>
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

Amend
-----

  $ cp -R $TESTTMP/base $TESTTMP/evolve_training_repo
  $ cd $TESTTMP/evolve_training_repo

  $ hg update typo
  1 files updated, 0 files merged, 2 files removed, 0 files unresolved

BEFORE
  $ hg log -G -v -r "::typo" -T "{rev} {phase}\n"
  @  1 draft
  |
  o  0 public
  
  $ graph $TESTDIR/graphs/fix-bug-1.dot -r '::typo' -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/fix-bug-1.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	1	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=typo,
      		height=1,
      		label="5d48a444",
      		pin=true,
      		pos="2,1!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 1	 [penwidth=2.0];
      }

  $ html_output $TESTDIR/output/fix-a-bug-base.log log -G -r "::typo"
  @  <span style="color:olive;">changeset:   1:5d48a444aba7</span>
  |  branch:      typo
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  summary:     Fx bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ html_output $TESTDIR/output/fix-a-bug-base-summary.log summary
  <span style="color:olive;">parent: 1:5d48a444aba7 </span>
   Fx bug
  branch: typo
  commit: (clean)
  update: (current)
  phases: 16 draft

Commit with Evolve
  $ hg commit --amend --message "Fix bug"

  $ html_output $TESTDIR/output/amend-after.log log -G -r "::typo"
  @  <span style="color:olive;">changeset:   17:708369dc1bfe</span>
  |  branch:      typo
  |  tag:         tip
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  summary:     Fix bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ html_output $TESTDIR/output/fix-a-bug-with-evolve-2.log log -G -r "::branch(typo)" --hidden
  @  <span style="color:olive;">changeset:   17:708369dc1bfe</span>
  |  branch:      typo
  |  tag:         tip
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  summary:     Fix bug
  |
  | x  <span style="color:olive;">changeset:   1:5d48a444aba7</span>
  |/   branch:      typo
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Thu Dec 07 11:26:53 2017 +0100
  |    obsolete:    reworded using amend as 17:708369dc1bfe
  |    summary:     Fx bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
Mark everything as public for the graph

  $ graph $TESTDIR/graphs/fix-bug-2.dot -r '::typo' -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/fix-bug-2.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	17	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=typo,
      		height=1,
      		label="708369dc",
      		pin=true,
      		pos="2,17!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 17	 [penwidth=2.0];
      }

  $ graph $TESTDIR/graphs/fix-bug-3.dot -r '::branch(typo)' --hidden -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/fix-bug-3.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	1	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=typo_extinct,
      		height=1,
      		label="5d48a444",
      		pin=true,
      		pos="2,1!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	0 -> 1	 [penwidth=2.0];
      	17	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=typo,
      		height=1,
      		label="708369dc",
      		pin=true,
      		pos="3,17!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 17	 [penwidth=2.0];
      	1 -> 17	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      }

  $ html_output $TESTDIR/output/amend-after.log log -G -r "::typo"
  @  <span style="color:olive;">changeset:   17:708369dc1bfe</span>
  |  branch:      typo
  |  tag:         tip
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  summary:     Fix bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/amend-obslog-after.log obslog -G -r "typo"
  @  <span style="color:olive;">708369dc1bfe</span> <span style="color:blue;">(17)</span> Fix bug
  |
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ html_output $TESTDIR/output/amend-obslog-patch-after.log obslog -G -r "typo" --patch
  @  <span style="color:olive;">708369dc1bfe</span> <span style="color:blue;">(17)</span> Fix bug
  |
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
         --- a/5d48a444aba7-changeset-description
         +++ b/708369dc1bfe-changeset-description
         @@ -1,1 +1,1 @@
         -Fx bug
         +Fix bug
  
  
  $ html_output $TESTDIR/output/amend-obslog-all-after.log obslog --all -G -r "precursors(typo)" --hidden
  @  <span style="color:olive;">708369dc1bfe</span> <span style="color:blue;">(17)</span> Fix bug
  |
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  

Rebase
------

Before
  $ hg up build/linuxsupport-v2
  3 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/rebase-before.log log -G -r '::desc(v2)'
  o  <span style="color:olive;">changeset:   6:0e694460372e</span>
  |  branch:      build/v2
  |  parent:      2:f3bd0ab4ee87
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:22:16 2017 +0100
  |  summary:     New commit on build/v2
  |
  | @  <span style="color:olive;">changeset:   5:39e9774ab30b</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | |  summary:     Third commit on build/linuxsupport-v2
  | |
  | o  <span style="color:olive;">changeset:   4:5ad93176b041</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:20:24 2017 +0100
  | |  summary:     Second commit on build/linuxsupport-v2.
  | |
  | o  <span style="color:olive;">changeset:   3:424916b62f4c</span>
  |/   branch:      build/linuxsupport-v2
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Thu Dec 07 16:46:32 2017 +0100
  |    summary:     First commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   2:f3bd0ab4ee87</span>
  |  branch:      build/v2
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:45:07 2017 +0100
  |  summary:     First commit on build/v2
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ graph $TESTDIR/graphs/rebase-before.dot -r '::desc(v2)' -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/rebase-before.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/v2",
      		height=1,
      		label=f3bd0ab4,
      		pin=true,
      		pos="2,2!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 2	 [penwidth=2.0];
      	3	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="424916b6",
      		pin=true,
      		pos="3,3!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2 -> 3	 [penwidth=2.0];
      	6	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/v2",
      		height=1,
      		label="0e694460",
      		pin=true,
      		pos="2,6!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2 -> 6	 [penwidth=2.0];
      	4	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="5ad93176",
      		pin=true,
      		pos="3,4!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3 -> 4	 [penwidth=2.0];
      	5	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="39e9774a",
      		pin=true,
      		pos="3,5!",
      		shape=circle,
      		style=filled,
      		width=1];
      	4 -> 5	 [penwidth=2.0];
      }

Do the rebase

  $ html_output $TESTDIR/output/rebase.log rebase -r "branch(build/linuxsupport-v2)" --dest build/v2 --keepbranches
  rebasing 3:424916b62f4c &quot;First commit on build/linuxsupport-v2&quot;
  rebasing 4:5ad93176b041 &quot;Second commit on build/linuxsupport-v2.&quot;
  rebasing 5:39e9774ab30b &quot;Third commit on build/linuxsupport-v2&quot;

After the rebase

  $ html_output $TESTDIR/output/rebase-after.log log -G -r '::desc(v2)'
  @  <span style="color:olive;">changeset:   20:3d2c8a2356a2</span>
  |  branch:      build/linuxsupport-v2
  |  tag:         tip
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:21:02 2017 +0100
  |  summary:     Third commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   19:4686378320d7</span>
  |  branch:      build/linuxsupport-v2
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:20:24 2017 +0100
  |  summary:     Second commit on build/linuxsupport-v2.
  |
  o  <span style="color:olive;">changeset:   18:7b62ce2c283e</span>
  |  branch:      build/linuxsupport-v2
  |  parent:      6:0e694460372e
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:46:32 2017 +0100
  |  summary:     First commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   6:0e694460372e</span>
  |  branch:      build/v2
  |  parent:      2:f3bd0ab4ee87
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:22:16 2017 +0100
  |  summary:     New commit on build/v2
  |
  o  <span style="color:olive;">changeset:   2:f3bd0ab4ee87</span>
  |  branch:      build/v2
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:45:07 2017 +0100
  |  summary:     First commit on build/v2
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ html_output $TESTDIR/output/rebase-after-hidden.log log -G -r '::desc(v2)' --hidden
  @  <span style="color:olive;">changeset:   20:3d2c8a2356a2</span>
  |  branch:      build/linuxsupport-v2
  |  tag:         tip
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:21:02 2017 +0100
  |  summary:     Third commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   19:4686378320d7</span>
  |  branch:      build/linuxsupport-v2
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:20:24 2017 +0100
  |  summary:     Second commit on build/linuxsupport-v2.
  |
  o  <span style="color:olive;">changeset:   18:7b62ce2c283e</span>
  |  branch:      build/linuxsupport-v2
  |  parent:      6:0e694460372e
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:46:32 2017 +0100
  |  summary:     First commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   6:0e694460372e</span>
  |  branch:      build/v2
  |  parent:      2:f3bd0ab4ee87
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:22:16 2017 +0100
  |  summary:     New commit on build/v2
  |
  | x  <span style="color:olive;">changeset:   5:39e9774ab30b</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | |  obsolete:    rebased using rebase as 20:3d2c8a2356a2
  | |  summary:     Third commit on build/linuxsupport-v2
  | |
  | x  <span style="color:olive;">changeset:   4:5ad93176b041</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:20:24 2017 +0100
  | |  obsolete:    rebased using rebase as 19:4686378320d7
  | |  summary:     Second commit on build/linuxsupport-v2.
  | |
  | x  <span style="color:olive;">changeset:   3:424916b62f4c</span>
  |/   branch:      build/linuxsupport-v2
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Thu Dec 07 16:46:32 2017 +0100
  |    obsolete:    rebased using rebase as 18:7b62ce2c283e
  |    summary:     First commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   2:f3bd0ab4ee87</span>
  |  branch:      build/v2
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:45:07 2017 +0100
  |  summary:     First commit on build/v2
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/rebase-obslog-after.log obslog -r "build/linuxsupport-v2"
  @  <span style="color:olive;">3d2c8a2356a2</span> <span style="color:blue;">(20)</span> Third commit on build/linuxsupport-v2
  |
  x  <span style="color:olive;">39e9774ab30b</span> <span style="color:blue;">(5)</span> Third commit on build/linuxsupport-v2
       rewritten(parent) as <span style="color:olive;">3d2c8a2356a2</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ graph $TESTDIR/graphs/rebase-after.dot -r '::desc(v2)' -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/rebase-after.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/v2",
      		height=1,
      		label=f3bd0ab4,
      		pin=true,
      		pos="2,2!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 2	 [penwidth=2.0];
      	6	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/v2",
      		height=1,
      		label="0e694460",
      		pin=true,
      		pos="2,6!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2 -> 6	 [penwidth=2.0];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="7b62ce2c",
      		pin=true,
      		pos="3,18!",
      		shape=circle,
      		style=filled,
      		width=1];
      	6 -> 18	 [penwidth=2.0];
      	19	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label=46863783,
      		pin=true,
      		pos="3,19!",
      		shape=circle,
      		style=filled,
      		width=1];
      	18 -> 19	 [penwidth=2.0];
      	20	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="3d2c8a23",
      		pin=true,
      		pos="3,20!",
      		shape=circle,
      		style=filled,
      		width=1];
      	19 -> 20	 [penwidth=2.0];
      }

  $ graph $TESTDIR/graphs/rebase-after-hidden.dot -r '::desc(v2)' -T "{shortest(node, 8)}" --hidden --public=yes
  Wrote */graphs/rebase-after-hidden.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/v2",
      		height=1,
      		label=f3bd0ab4,
      		pin=true,
      		pos="2,2!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 2	 [penwidth=2.0];
      	3	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2_extinct",
      		height=1,
      		label="424916b6",
      		pin=true,
      		pos="3,3!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	2 -> 3	 [penwidth=2.0];
      	6	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/v2",
      		height=1,
      		label="0e694460",
      		pin=true,
      		pos="2,6!",
      		shape=circle,
      		style=filled,
      		width=1];
      	2 -> 6	 [penwidth=2.0];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="7b62ce2c",
      		pin=true,
      		pos="4,18!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3 -> 18	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	4	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2_extinct",
      		height=1,
      		label="5ad93176",
      		pin=true,
      		pos="3,4!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	3 -> 4	 [penwidth=2.0];
      	19	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label=46863783,
      		pin=true,
      		pos="4,19!",
      		shape=circle,
      		style=filled,
      		width=1];
      	18 -> 19	 [penwidth=2.0];
      	4 -> 19	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	5	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2_extinct",
      		height=1,
      		label="39e9774a",
      		pin=true,
      		pos="3,5!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	4 -> 5	 [penwidth=2.0];
      	20	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="3d2c8a23",
      		pin=true,
      		pos="4,20!",
      		shape=circle,
      		style=filled,
      		width=1];
      	19 -> 20	 [penwidth=2.0];
      	5 -> 20	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	6 -> 18	 [penwidth=2.0];
      }

Under the hood
--------------

  $ cp -R $TESTTMP/evolve_training_repo $TESTDIR/base-repos/behind-the-hoods/

Amend

  $ html_output $TESTDIR/output/behind-the-hood-amend-before-hash-hidden.log log -G -r "::precursors(typo)" --hidden
  x  <span style="color:olive;">changeset:   1:5d48a444aba7</span>
  |  branch:      typo
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  obsolete:    reworded using amend as 17:708369dc1bfe
  |  summary:     Fx bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

XXX Remove the command line to avoid showing precursors and hidden revset

  $ tail -n +2 $TESTDIR/output/behind-the-hood-amend-before-hash-hidden.log | tee $TESTDIR/output/behind-the-hood-amend-before-hash-hidden.log
  x  <span style="color:olive;">changeset:   1:5d48a444aba7</span>
  |  branch:      typo
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  obsolete:    reworded using amend as 17:708369dc1bfe
  |  summary:     Fx bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/behind-the-hood-amend-after.log log -G -r "::typo"
  o  <span style="color:olive;">changeset:   17:708369dc1bfe</span>
  |  branch:      typo
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  summary:     Fix bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ html_output $TESTDIR/output/under-the-hood-amend-after-log-hidden.log log -G -r "::branch(typo)" --hidden
  o  <span style="color:olive;">changeset:   17:708369dc1bfe</span>
  |  branch:      typo
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 11:26:53 2017 +0100
  |  summary:     Fix bug
  |
  | x  <span style="color:olive;">changeset:   1:5d48a444aba7</span>
  |/   branch:      typo
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Thu Dec 07 11:26:53 2017 +0100
  |    obsolete:    reworded using amend as 17:708369dc1bfe
  |    summary:     Fx bug
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/under-the-hood-amend-after-obslog-patch.log obslog -G -r typo --patch
  o  <span style="color:olive;">708369dc1bfe</span> <span style="color:blue;">(17)</span> Fix bug
  |
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
         --- a/5d48a444aba7-changeset-description
         +++ b/708369dc1bfe-changeset-description
         @@ -1,1 +1,1 @@
         -Fx bug
         +Fix bug
  
  
  $ html_output $TESTDIR/output/under-the-hood-amend-after-obslog.log obslog -G -r typo
  o  <span style="color:olive;">708369dc1bfe</span> <span style="color:blue;">(17)</span> Fix bug
  |
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ html_output $TESTDIR/output/under-the-hood-amend-after-obslog-no-all.log obslog -G -r "5d48a444aba7" --hidden
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ html_output $TESTDIR/output/under-the-hood-amend-after-obslog-all.log obslog -G -r "5d48a444aba7" --hidden --all
  o  <span style="color:olive;">708369dc1bfe</span> <span style="color:blue;">(17)</span> Fix bug
  |
  x  <span style="color:olive;">5d48a444aba7</span> <span style="color:blue;">(1)</span> Fx bug
       rewritten(description) as <span style="color:olive;">708369dc1bfe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  

  $ html_output $TESTDIR/output/under-the-hood-rebase-after-obslog.log obslog -r build/linuxsupport-v2
  @  <span style="color:olive;">3d2c8a2356a2</span> <span style="color:blue;">(20)</span> Third commit on build/linuxsupport-v2
  |
  x  <span style="color:olive;">39e9774ab30b</span> <span style="color:blue;">(5)</span> Third commit on build/linuxsupport-v2
       rewritten(parent) as <span style="color:olive;">3d2c8a2356a2</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ html_output $TESTDIR/output/under-the-hood-rebase-after-obslog-branch.log obslog -r "branch('build/linuxsupport-v2')"
  @  <span style="color:olive;">3d2c8a2356a2</span> <span style="color:blue;">(20)</span> Third commit on build/linuxsupport-v2
  |
  | o  <span style="color:olive;">4686378320d7</span> <span style="color:blue;">(19)</span> Second commit on build/linuxsupport-v2.
  | |
  | | o  <span style="color:olive;">7b62ce2c283e</span> <span style="color:blue;">(18)</span> First commit on build/linuxsupport-v2
  | | |
  x | |  <span style="color:olive;">39e9774ab30b</span> <span style="color:blue;">(5)</span> Third commit on build/linuxsupport-v2
   / /     rewritten(parent) as <span style="color:olive;">3d2c8a2356a2</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  | |
  | x  <span style="color:olive;">424916b62f4c</span> <span style="color:blue;">(3)</span> First commit on build/linuxsupport-v2
  |      rewritten(parent) as <span style="color:olive;">7b62ce2c283e</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  |
  x  <span style="color:olive;">5ad93176b041</span> <span style="color:blue;">(4)</span> Second commit on build/linuxsupport-v2.
       rewritten(parent) as <span style="color:olive;">4686378320d7</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  


Rebase  

  $ html_output $TESTDIR/output/behind-the-hood-rebase-before-hash-hidden.log log -G -r "::branch(build/v2) or ::precursors('build/linuxsupport-v2')" --hidden
  o  <span style="color:olive;">changeset:   6:0e694460372e</span>
  |  branch:      build/v2
  |  parent:      2:f3bd0ab4ee87
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:22:16 2017 +0100
  |  summary:     New commit on build/v2
  |
  | x  <span style="color:olive;">changeset:   5:39e9774ab30b</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | |  obsolete:    rebased using rebase as 20:3d2c8a2356a2
  | |  summary:     Third commit on build/linuxsupport-v2
  | |
  | x  <span style="color:olive;">changeset:   4:5ad93176b041</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:20:24 2017 +0100
  | |  obsolete:    rebased using rebase as 19:4686378320d7
  | |  summary:     Second commit on build/linuxsupport-v2.
  | |
  | x  <span style="color:olive;">changeset:   3:424916b62f4c</span>
  |/   branch:      build/linuxsupport-v2
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Thu Dec 07 16:46:32 2017 +0100
  |    obsolete:    rebased using rebase as 18:7b62ce2c283e
  |    summary:     First commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   2:f3bd0ab4ee87</span>
  |  branch:      build/v2
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:45:07 2017 +0100
  |  summary:     First commit on build/v2
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/behind-the-hood-rebase-after.log log -G -r "::desc(v2)"
  @  <span style="color:olive;">changeset:   20:3d2c8a2356a2</span>
  |  branch:      build/linuxsupport-v2
  |  tag:         tip
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:21:02 2017 +0100
  |  summary:     Third commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   19:4686378320d7</span>
  |  branch:      build/linuxsupport-v2
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:20:24 2017 +0100
  |  summary:     Second commit on build/linuxsupport-v2.
  |
  o  <span style="color:olive;">changeset:   18:7b62ce2c283e</span>
  |  branch:      build/linuxsupport-v2
  |  parent:      6:0e694460372e
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:46:32 2017 +0100
  |  summary:     First commit on build/linuxsupport-v2
  |
  o  <span style="color:olive;">changeset:   6:0e694460372e</span>
  |  branch:      build/v2
  |  parent:      2:f3bd0ab4ee87
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:22:16 2017 +0100
  |  summary:     New commit on build/v2
  |
  o  <span style="color:olive;">changeset:   2:f3bd0ab4ee87</span>
  |  branch:      build/v2
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Dec 07 16:45:07 2017 +0100
  |  summary:     First commit on build/v2
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

Amend-extract
-------------

  $ hg update amend-extract
  2 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ cp -R $TESTTMP/evolve_training_repo $TESTDIR/base-repos/amend-evolve-command/

  $ html_output $TESTDIR/output/amend-extract-before.log log -G -r "::amend-extract"
  @  <span style="color:olive;">changeset:   8:e288d12d5e96</span>
  |  branch:      amend-extract
  |  user:        Bad User
  |  date:        Fri Dec 08 15:28:46 2017 +0100
  |  summary:     Commit to be extracted
  |
  o  <span style="color:olive;">changeset:   7:4ae0d1de7a58</span>
  |  branch:      amend-extract
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Fri Dec 08 15:04:09 2017 +0100
  |  summary:     Base file
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ graph $TESTDIR/graphs/amend-extract-before.dot -r '::amend-extract' -T "{shortest(node, 8)}" --hidden --public=yes
  Wrote */graphs/amend-extract-before.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	7	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="amend-extract",
      		height=1,
      		label="4ae0d1de",
      		pin=true,
      		pos="2,7!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 7	 [penwidth=2.0];
      	8	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="amend-extract",
      		height=1,
      		label=e288d12d,
      		pin=true,
      		pos="2,8!",
      		shape=circle,
      		style=filled,
      		width=1];
      	7 -> 8	 [penwidth=2.0];
      }

Amend User

  $ html_output $TESTDIR/output/amend-user.log amend --user "Good User"

After amend user

  $ html_output $TESTDIR/output/amend-user-after-export.log export .
  # HG changeset patch
  # User Good User
  # Date 1512743326 -3600
  #      Fri Dec 08 15:28:46 2017 +0100
  # Branch amend-extract
  # Node ID 5935c1c3ad24c4d3338d94473261eb89a73ef0d5
  # Parent  4ae0d1de7a58916e6f24fdc42e890a71fccbd931
  Commit to be extracted
  
  <span style="font-weight:bold;">diff -r 4ae0d1de7a58 -r 5935c1c3ad24 badfile</span>
  <span style="color:red;font-weight:bold;">--- /dev/null	Thu Jan 01 00:00:00 1970 +0000</span>
  <span style="color:green;font-weight:bold;">+++ b/badfile	Fri Dec 08 15:28:46 2017 +0100</span>
  <span style="color:purple;">@@ -0,0 +1,1 @@</span>
  <span style="color:green;">+badbadfile</span>
  <span style="font-weight:bold;">diff -r 4ae0d1de7a58 -r 5935c1c3ad24 fileextract</span>
  <span style="color:red;font-weight:bold;">--- a/fileextract	Fri Dec 08 15:04:09 2017 +0100</span>
  <span style="color:green;font-weight:bold;">+++ b/fileextract	Fri Dec 08 15:28:46 2017 +0100</span>
  <span style="color:purple;">@@ -1,5 +1,6 @@</span>
   # The file dedicated to be extracted
   
  <span style="color:green;">+0</span>
   1
   2
   3
  <span style="color:purple;">@@ -10,4 +11,5 @@</span>
   8
   9
   10
  <span style="color:green;">+42</span>
   

Amend extract the bad file

  $ html_output $TESTDIR/output/amend-extract-badfile.log amend --extract badfile

After extract the bad file

  $ html_output $TESTDIR/output/amend-extract-badfile-after-export.log export -r .
  # HG changeset patch
  # User Good User
  # Date 1512743326 -3600
  #      Fri Dec 08 15:28:46 2017 +0100
  # Branch amend-extract
  # Node ID 1e04751ef00ae76e357fe083f08e3f2234c3b26b
  # Parent  4ae0d1de7a58916e6f24fdc42e890a71fccbd931
  Commit to be extracted
  
  <span style="font-weight:bold;">diff -r 4ae0d1de7a58 -r 1e04751ef00a fileextract</span>
  <span style="color:red;font-weight:bold;">--- a/fileextract	Fri Dec 08 15:04:09 2017 +0100</span>
  <span style="color:green;font-weight:bold;">+++ b/fileextract	Fri Dec 08 15:28:46 2017 +0100</span>
  <span style="color:purple;">@@ -1,5 +1,6 @@</span>
   # The file dedicated to be extracted
   
  <span style="color:green;">+0</span>
   1
   2
   3
  <span style="color:purple;">@@ -10,4 +11,5 @@</span>
   8
   9
   10
  <span style="color:green;">+42</span>
   

  $ html_output $TESTDIR/output/amend-extract-badfile-after-status.log status
  <span style="color:green;font-weight:bold;">A </span><span style="color:green;font-weight:bold;">badfile</span>

  $ html_output $TESTDIR/output/amend-extract-badfile-after-revert.log revert --all --no-backup
  forgetting badfile

  $ rm badfile

Amend extract the line

  $ html_output $TESTDIR/output/amend-extract.log amend --extract --interactive <<EOF
  > y
  > n
  > y
  > EOF
  <span style="font-weight:bold;">diff --git a/fileextract b/fileextract</span>
  2 hunks, 2 lines changed
  <span style="color:olive;">examine changes to 'fileextract'? [Ynesfdaq?]</span> y
  
  <span style="color:purple;">@@ -1,5 +1,6 @@</span>
   # The file dedicated to be extracted
   
  <span style="color:green;">+0</span>
   1
   2
   3
  <span style="color:olive;">discard change 1/2 to 'fileextract'? [Ynesfdaq?]</span> n
  
  <span style="color:purple;">@@ -10,4 +11,5 @@</span>
   8
   9
   10
  <span style="color:green;">+42</span>
   
  <span style="color:olive;">discard change 2/2 to 'fileextract'? [Ynesfdaq?]</span> y
  

  $ html_output $TESTDIR/output/amend-extract-after-status.log status
  <span style="color:blue;font-weight:bold;">M </span><span style="color:blue;font-weight:bold;">fileextract</span>

  $ html_output $TESTDIR/output/amend-extract-after-diff.log diff
  <span style="font-weight:bold;">diff -r 76ace846a3f9 fileextract</span>
  <span style="color:red;font-weight:bold;">--- a/fileextract	Fri Dec 08 15:28:46 2017 +0100</span>
  <span style="color:green;font-weight:bold;">+++ b/fileextract	Thu Jan 01 00:00:00 1970 +0000</span>
  <span style="color:purple;">@@ -11,4 +11,5 @@</span>
   8
   9
   10
  <span style="color:green;">+42</span>
   

  $ html_output $TESTDIR/output/amend-extract-after-revert.log revert --all --no-backup
  reverting fileextract

  $ html_output $TESTDIR/output/amend-extract-after-obslog.log obslog -p -r .
  @  <span style="color:olive;">76ace846a3f9</span> <span style="color:blue;">(24)</span> Commit to be extracted
  |
  x  <span style="color:olive;">1e04751ef00a</span> <span style="color:blue;">(22)</span> Commit to be extracted
  |    rewritten(content) as <span style="color:olive;">76ace846a3f9</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  |      diff -r 1e04751ef00a -r 76ace846a3f9 fileextract
  |      --- a/fileextract	Fri Dec 08 15:28:46 2017 +0100
  |      +++ b/fileextract	Fri Dec 08 15:28:46 2017 +0100
  |      @@ -11,5 +11,4 @@
  |       8
  |       9
  |       10
  |      -42
  |
  |
  |
  x  <span style="color:olive;">5935c1c3ad24</span> <span style="color:blue;">(21)</span> Commit to be extracted
  |    rewritten(content) as <span style="color:olive;">1e04751ef00a</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  |      diff -r 5935c1c3ad24 -r 1e04751ef00a badfile
  |      --- a/badfile	Fri Dec 08 15:28:46 2017 +0100
  |      +++ /dev/null	Thu Jan 01 00:00:00 1970 +0000
  |      @@ -1,1 +0,0 @@
  |      -badbadfile
  |
  |
  x  <span style="color:olive;">e288d12d5e96</span> <span style="color:blue;">(8)</span> Commit to be extracted
       rewritten(user) as <span style="color:olive;">5935c1c3ad24</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  

  $ graph $TESTDIR/graphs/amend-extract-after-hidden.dot -r "::desc(extracted)" -T "{shortest(node, 8)}" --hidden --public=yes
  Wrote */graphs/amend-extract-after-hidden.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	7	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="amend-extract",
      		height=1,
      		label="4ae0d1de",
      		pin=true,
      		pos="2,7!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 7	 [penwidth=2.0];
      	8	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="amend-extract_extinct",
      		height=1,
      		label=e288d12d,
      		pin=true,
      		pos="3,8!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	7 -> 8	 [penwidth=2.0];
      	21	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="amend-extract_extinct",
      		height=1,
      		label="5935c1c3",
      		pin=true,
      		pos="3,21!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	7 -> 21	 [penwidth=2.0];
      	22	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="amend-extract_extinct",
      		height=1,
      		label="1e04751e",
      		pin=true,
      		pos="3,22!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	7 -> 22	 [penwidth=2.0];
      	24	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="amend-extract",
      		height=1,
      		label="76ace846",
      		pin=true,
      		pos="2,24!",
      		shape=circle,
      		style=filled,
      		width=1];
      	7 -> 24	 [penwidth=2.0];
      	8 -> 21	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	21 -> 22	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	22 -> 24	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      }

Fold
----

  $ hg update fold
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ cp -R $TESTTMP/evolve_training_repo $TESTDIR/base-repos/fold/

  $ html_output $TESTDIR/output/fold-before.log log -r "branch(fold)" -G -p
  @  <span style="color:olive;">changeset:   12:966df9f031c1</span>
  |  branch:      fold
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Fri Dec 08 16:50:38 2017 +0100
  |  summary:     Really fix the test
  |
  |  <span style="font-weight:bold;">diff -r b316dc02bddc -r 966df9f031c1 test/unit</span>
  |  <span style="color:red;font-weight:bold;">--- a/test/unit	Fri Dec 08 16:50:17 2017 +0100</span>
  |  <span style="color:green;font-weight:bold;">+++ b/test/unit	Fri Dec 08 16:50:38 2017 +0100</span>
  |  <span style="color:purple;">@@ -1,1 +1,1 @@</span>
  |  <span style="color:red;">-assert 42 = 43</span>
  |  <span style="color:green;">+assert 42 = 42</span>
  |
  o  <span style="color:olive;">changeset:   11:b316dc02bddc</span>
  |  branch:      fold
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Fri Dec 08 16:50:17 2017 +0100
  |  summary:     Fix the test
  |
  |  <span style="font-weight:bold;">diff -r 03174536bb2a -r b316dc02bddc test/unit</span>
  |  <span style="color:red;font-weight:bold;">--- a/test/unit	Fri Dec 08 16:49:45 2017 +0100</span>
  |  <span style="color:green;font-weight:bold;">+++ b/test/unit	Fri Dec 08 16:50:17 2017 +0100</span>
  |  <span style="color:purple;">@@ -1,1 +1,1 @@</span>
  |  <span style="color:red;">-assert 42 = 0</span>
  |  <span style="color:green;">+assert 42 = 43</span>
  |
  o  <span style="color:olive;">changeset:   10:03174536bb2a</span>
  |  branch:      fold
  ~  parent:      0:d2eb2ac6a5bd
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Fri Dec 08 16:49:45 2017 +0100
     summary:     add a test
  
     <span style="font-weight:bold;">diff -r d2eb2ac6a5bd -r 03174536bb2a test/unit</span>
     <span style="color:red;font-weight:bold;">--- /dev/null	Thu Jan 01 00:00:00 1970 +0000</span>
     <span style="color:green;font-weight:bold;">+++ b/test/unit	Fri Dec 08 16:49:45 2017 +0100</span>
     <span style="color:purple;">@@ -0,0 +1,1 @@</span>
     <span style="color:green;">+assert 42 = 0</span>
  

  $ graph $TESTDIR/graphs/fold-before.dot -r "::fold" -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/fold-before.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	10	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=fold,
      		height=1,
      		label=03174536,
      		pin=true,
      		pos="2,10!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 10	 [penwidth=2.0];
      	11	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=fold,
      		height=1,
      		label=b316dc02,
      		pin=true,
      		pos="2,11!",
      		shape=circle,
      		style=filled,
      		width=1];
      	10 -> 11	 [penwidth=2.0];
      	12	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=fold,
      		height=1,
      		label="966df9f0",
      		pin=true,
      		pos="2,12!",
      		shape=circle,
      		style=filled,
      		width=1];
      	11 -> 12	 [penwidth=2.0];
      }

  $ html_output $TESTDIR/output/fold.log fold --from -r "branch(fold)" -m "add a test"
  3 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/fold-after.log log -r "::fold" -G
  @  <span style="color:olive;">changeset:   25:dab6ed4b3c75</span>
  |  branch:      fold
  |  tag:         tip
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add a test
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/fold-after-hidden.log log -r "::branch(fold)" -G --hidden
  @  <span style="color:olive;">changeset:   25:dab6ed4b3c75</span>
  |  branch:      fold
  |  tag:         tip
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add a test
  |
  | x  <span style="color:olive;">changeset:   12:966df9f031c1</span>
  | |  branch:      fold
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Fri Dec 08 16:50:38 2017 +0100
  | |  obsolete:    rewritten as 25:dab6ed4b3c75
  | |  summary:     Really fix the test
  | |
  | x  <span style="color:olive;">changeset:   11:b316dc02bddc</span>
  | |  branch:      fold
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Fri Dec 08 16:50:17 2017 +0100
  | |  obsolete:    rewritten as 25:dab6ed4b3c75
  | |  summary:     Fix the test
  | |
  | x  <span style="color:olive;">changeset:   10:03174536bb2a</span>
  |/   branch:      fold
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Fri Dec 08 16:49:45 2017 +0100
  |    obsolete:    rewritten as 25:dab6ed4b3c75
  |    summary:     add a test
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/fold-after-hidden-obslog.log obslog -r "."
  @    <span style="color:olive;">dab6ed4b3c75</span> <span style="color:blue;">(25)</span> add a test
  |\
  | \
  | |\
  x | |  <span style="color:olive;">03174536bb2a</span> <span style="color:blue;">(10)</span> add a test
   / /     rewritten(date, content) as <span style="color:olive;">dab6ed4b3c75</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  | |
  x |  <span style="color:olive;">966df9f031c1</span> <span style="color:blue;">(12)</span> Really fix the test
   /     rewritten(description, date, parent, content) as <span style="color:olive;">dab6ed4b3c75</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  |
  x  <span style="color:olive;">b316dc02bddc</span> <span style="color:blue;">(11)</span> Fix the test
       rewritten(description, date, parent, content) as <span style="color:olive;">dab6ed4b3c75</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  

  $ graph $TESTDIR/graphs/fold-after-hidden.log -r "::branch(fold)" -T "{shortest(node, 8)}" --hidden --public=yes
  Wrote */graphs/fold-after-hidden.log (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	10	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=fold_extinct,
      		height=1,
      		label=03174536,
      		pin=true,
      		pos="2,10!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	0 -> 10	 [penwidth=2.0];
      	25	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=fold,
      		height=1,
      		label=dab6ed4b,
      		pin=true,
      		pos="3,25!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 25	 [penwidth=2.0];
      	10 -> 25	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	11	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=fold_extinct,
      		height=1,
      		label=b316dc02,
      		pin=true,
      		pos="2,11!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	10 -> 11	 [penwidth=2.0];
      	11 -> 25	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	12	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=fold_extinct,
      		height=1,
      		label="966df9f0",
      		pin=true,
      		pos="2,12!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	11 -> 12	 [penwidth=2.0];
      	12 -> 25	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      }

Split
-----

  $ hg up split
  3 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/split-before.log log -r "::split" -G
  @  <span style="color:olive;">changeset:   13:5d5029b9daed</span>
  |  branch:      split
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Fri Dec 08 17:33:15 2017 +0100
  |  summary:     To be splitted
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ graph $TESTDIR/graphs/split-before.dot -r "::split" -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/split-before.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	13	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=split,
      		height=1,
      		label="5d5029b9",
      		pin=true,
      		pos="2,13!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 13	 [penwidth=2.0];
      }


  $ html_output $TESTDIR/output/split.log split -r .<< EOF
  > Y
  > N
  > N
  > N
  > Y
  > N
  > N
  > Y
  > EOF
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  adding src/A
  adding src/B
  adding src/C
  <span style="font-weight:bold;">diff --git a/src/A b/src/A</span>
  <span style="color:teal;font-weight:bold;">new file mode 100644</span>
  <span style="color:olive;">examine changes to 'src/A'? [Ynesfdaq?]</span> Y
  
  <span style="font-weight:bold;">diff --git a/src/B b/src/B</span>
  <span style="color:teal;font-weight:bold;">new file mode 100644</span>
  <span style="color:olive;">examine changes to 'src/B'? [Ynesfdaq?]</span> N
  
  <span style="font-weight:bold;">diff --git a/src/C b/src/C</span>
  <span style="color:teal;font-weight:bold;">new file mode 100644</span>
  <span style="color:olive;">examine changes to 'src/C'? [Ynesfdaq?]</span> N
  
  created new head
  <span style="color:olive;">Done splitting? [yN]</span> N
  <span style="font-weight:bold;">diff --git a/src/B b/src/B</span>
  <span style="color:teal;font-weight:bold;">new file mode 100644</span>
  <span style="color:olive;">examine changes to 'src/B'? [Ynesfdaq?]</span> Y
  
  <span style="font-weight:bold;">diff --git a/src/C b/src/C</span>
  <span style="color:teal;font-weight:bold;">new file mode 100644</span>
  <span style="color:olive;">examine changes to 'src/C'? [Ynesfdaq?]</span> N
  
  <span style="color:olive;">Done splitting? [yN]</span> N
  <span style="font-weight:bold;">diff --git a/src/C b/src/C</span>
  <span style="color:teal;font-weight:bold;">new file mode 100644</span>
  <span style="color:olive;">examine changes to 'src/C'? [Ynesfdaq?]</span> Y
  
  no more change to split

  $ html_output $TESTDIR/output/split-before-after.log log -r "::split" -G
  @  <span style="color:olive;">changeset:   28:1b7281b1e052</span>
  |  branch:      split
  |  tag:         tip
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     To be splitted
  |
  o  <span style="color:olive;">changeset:   27:6fb7bfb44ffe</span>
  |  branch:      split
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     To be splitted
  |
  o  <span style="color:olive;">changeset:   26:59f0ddc4bd4b</span>
  |  branch:      split
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     To be splitted
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ graph $TESTDIR/graphs/split-before-after-hidden.dot -r "::branch(split)" -T "{shortest(node, 8)}" --hidden --public=yes
  Wrote */graphs/split-before-after-hidden.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	13	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=split_extinct,
      		height=1,
      		label="5d5029b9",
      		pin=true,
      		pos="2,13!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	0 -> 13	 [penwidth=2.0];
      	26	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=split,
      		height=1,
      		label="59f0ddc4",
      		pin=true,
      		pos="3,26!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 26	 [penwidth=2.0];
      	13 -> 26	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	27	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=split,
      		height=1,
      		label="6fb7bfb4",
      		pin=true,
      		pos="3,27!",
      		shape=circle,
      		style=filled,
      		width=1];
      	13 -> 27	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	28	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=split,
      		height=1,
      		label="1b7281b1",
      		pin=true,
      		pos="3,28!",
      		shape=circle,
      		style=filled,
      		width=1];
      	13 -> 28	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	26 -> 27	 [penwidth=2.0];
      	27 -> 28	 [penwidth=2.0];
      }

  $ html_output $TESTDIR/output/split-after-obslog.log obslog -r .
  @  <span style="color:olive;">1b7281b1e052</span> <span style="color:blue;">(28)</span> To be splitted
  |
  x  <span style="color:olive;">5d5029b9daed</span> <span style="color:blue;">(13)</span> To be splitted
       rewritten(date, parent, content) as <span style="color:olive;">1b7281b1e052, 59f0ddc4bd4b, 6fb7bfb44ffe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ html_output $TESTDIR/output/split-after-obslog-all.log obslog --all -r .
  @  <span style="color:olive;">1b7281b1e052</span> <span style="color:blue;">(28)</span> To be splitted
  |
  | o  <span style="color:olive;">59f0ddc4bd4b</span> <span style="color:blue;">(26)</span> To be splitted
  |/
  | o  <span style="color:olive;">6fb7bfb44ffe</span> <span style="color:blue;">(27)</span> To be splitted
  |/
  x  <span style="color:olive;">5d5029b9daed</span> <span style="color:blue;">(13)</span> To be splitted
       rewritten(date, parent, content) as <span style="color:olive;">1b7281b1e052, 59f0ddc4bd4b, 6fb7bfb44ffe</span> by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ html_output $TESTDIR/output/split-after-log-phase.log log -G -r "::split" --template "{rev} {phase}\n" 
  @  28 draft
  |
  o  27 draft
  |
  o  26 draft
  |
  o  0 public
  

  $ html_output $TESTDIR/output/split-after-phase.log phase -r "::split"
  0: public
  26: draft
  27: draft
  28: draft

Prune
-----

  $ hg update prune
  1 files updated, 0 files merged, 3 files removed, 0 files unresolved


  $ html_output $TESTDIR/output/prune-before.log log -G -r "::prune"
  @  <span style="color:olive;">changeset:   9:324b72ebbb21</span>
  |  branch:      prune
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Fri Dec 08 16:12:23 2017 +0100
  |  summary:     Commit to prune
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ graph $TESTDIR/graphs/prune-before.dot -r '::prune' -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/prune-before.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	9	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=prune,
      		height=1,
      		label="324b72eb",
      		pin=true,
      		pos="2,9!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 9	 [penwidth=2.0];
      }

  $ html_output $TESTDIR/output/prune.log prune -r .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at <span style="color:olive;">d2eb2ac6a5bd</span>
  1 changesets pruned

  $ html_output $TESTDIR/output/prune-after.log log -G -r "::prune"
  abort: unknown revision 'prune'!

  $ html_output $TESTDIR/output/prune-after-hidden.log log -G -r "::prune" --hidden
  x  <span style="color:olive;">changeset:   9:324b72ebbb21</span>
  |  branch:      prune
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Fri Dec 08 16:12:23 2017 +0100
  |  obsolete:    pruned
  |  summary:     Commit to prune
  |
  @  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/prune-after-obslog.log obslog -r "prune" --hidden
  x  <span style="color:olive;">324b72ebbb21</span> <span style="color:blue;">(9)</span> Commit to prune
       pruned by <span style="color:green;">test</span> <span style="color:teal;">(Thu Jan 01 00:00:00 1970 +0000)</span>
  
  $ graph $TESTDIR/graphs/prune-after-hidden.dot -r '::prune' -T "{shortest(node, 8)}" --hidden --public=yes
  Wrote */graphs/prune-after-hidden.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	9	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=prune_extinct,
      		height=1,
      		label="324b72eb",
      		pin=true,
      		pos="2,9!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	0 -> 9	 [penwidth=2.0];
      }

Histedit
--------

  $ hg up histedit
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/histedit-before-log.log log -G -r "::histedit"
  @  <span style="color:olive;">changeset:   16:1b1e58a9ed27</span>
  |  branch:      histedit
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:37:15 2017 +0100
  |  summary:     Add test for myfeature
  |
  o  <span style="color:olive;">changeset:   15:23eb6f9e4c51</span>
  |  branch:      histedit
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:35:15 2017 +0100
  |  summary:     Add code for myfeature
  |
  o  <span style="color:olive;">changeset:   14:d102c718e607</span>
  |  branch:      histedit
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:33:15 2017 +0100
  |  summary:     First commit on histedit branch
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
  $ graph $TESTDIR/graphs/histedit-before.dot -r "::histedit" -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/histedit-before.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	14	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=histedit,
      		height=1,
      		label=d102c718,
      		pin=true,
      		pos="2,14!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 14	 [penwidth=2.0];
      	15	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=histedit,
      		height=1,
      		label="23eb6f9e",
      		pin=true,
      		pos="2,15!",
      		shape=circle,
      		style=filled,
      		width=1];
      	14 -> 15	 [penwidth=2.0];
      	16	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=histedit,
      		height=1,
      		label="1b1e58a9",
      		pin=true,
      		pos="2,16!",
      		shape=circle,
      		style=filled,
      		width=1];
      	15 -> 16	 [penwidth=2.0];
      }

  $ HGEDITOR=cat html_output $TESTDIR/output/histedit-no-edit.log histedit -r ".~1"
  pick 23eb6f9e4c51 15 Add code for myfeature
  pick 1b1e58a9ed27 16 Add test for myfeature
  
  # Edit history between 23eb6f9e4c51 and 1b1e58a9ed27
  #
  # Commits are listed from least to most recent
  #
  # You can reorder changesets by reordering the lines
  #
  # Commands:
  #
  #  e, edit = use commit, but stop for amending
  #  m, mess = edit commit message without changing commit content
  #  p, pick = use commit
  #  b, base = checkout changeset and apply further changesets from there
  #  d, drop = remove commit from history
  #  f, fold = use commit, but combine it with the one above
  #  r, roll = like fold, but discard this commit's description and date
  #

Format the commands the best way we can

  $ HGEDITOR=cat hg histedit -r ".~1" | head -n 2 | tail -n 1 > commands
  $ HGEDITOR=cat hg histedit -r ".~1" | head -n 1 >> commands

  $ html_raw_output $TESTDIR/output/histedit-commands.log cat commands
  pick 1b1e58a9ed27 16 Add test for myfeature
  pick 23eb6f9e4c51 15 Add code for myfeature

  $ HGEDITOR=cat html_output $TESTDIR/output/histedit.log histedit -r ".~1" --commands commands

  $ html_output $TESTDIR/output/histedit-after-log.log log -G -r ""::histedit""
  @  <span style="color:olive;">changeset:   30:27cb89067c43</span>
  |  branch:      histedit
  |  tag:         tip
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:35:15 2017 +0100
  |  summary:     Add code for myfeature
  |
  o  <span style="color:olive;">changeset:   29:a2082e406c4f</span>
  |  branch:      histedit
  |  parent:      14:d102c718e607
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:37:15 2017 +0100
  |  summary:     Add test for myfeature
  |
  o  <span style="color:olive;">changeset:   14:d102c718e607</span>
  |  branch:      histedit
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:33:15 2017 +0100
  |  summary:     First commit on histedit branch
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ html_output $TESTDIR/output/histedit-after-log-hidden.log log -G -r "::branch(histedit)" --hidden
  @  <span style="color:olive;">changeset:   30:27cb89067c43</span>
  |  branch:      histedit
  |  tag:         tip
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:35:15 2017 +0100
  |  summary:     Add code for myfeature
  |
  o  <span style="color:olive;">changeset:   29:a2082e406c4f</span>
  |  branch:      histedit
  |  parent:      14:d102c718e607
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:37:15 2017 +0100
  |  summary:     Add test for myfeature
  |
  | x  <span style="color:olive;">changeset:   16:1b1e58a9ed27</span>
  | |  branch:      histedit
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Sat Dec 09 17:37:15 2017 +0100
  | |  obsolete:    rebased using histedit as 29:a2082e406c4f
  | |  summary:     Add test for myfeature
  | |
  | x  <span style="color:olive;">changeset:   15:23eb6f9e4c51</span>
  |/   branch:      histedit
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Sat Dec 09 17:35:15 2017 +0100
  |    obsolete:    rebased using histedit as 30:27cb89067c43
  |    summary:     Add code for myfeature
  |
  o  <span style="color:olive;">changeset:   14:d102c718e607</span>
  |  branch:      histedit
  |  parent:      0:d2eb2ac6a5bd
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Sat Dec 09 17:33:15 2017 +0100
  |  summary:     First commit on histedit branch
  |
  o  <span style="color:olive;">changeset:   0:d2eb2ac6a5bd</span>
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  

  $ graph $TESTDIR/graphs/histedit-after-hidden.dot -r "::branch(histedit)" -T "{shortest(node, 8)}" --public=yes --hidden
  Wrote */graphs/histedit-after-hidden.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=d2eb2ac6,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	14	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=histedit,
      		height=1,
      		label=d102c718,
      		pin=true,
      		pos="2,14!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 14	 [penwidth=2.0];
      	15	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=histedit_extinct,
      		height=1,
      		label="23eb6f9e",
      		pin=true,
      		pos="3,15!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	14 -> 15	 [penwidth=2.0];
      	29	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=histedit,
      		height=1,
      		label=a2082e40,
      		pin=true,
      		pos="2,29!",
      		shape=circle,
      		style=filled,
      		width=1];
      	14 -> 29	 [penwidth=2.0];
      	30	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=histedit,
      		height=1,
      		label="27cb8906",
      		pin=true,
      		pos="2,30!",
      		shape=circle,
      		style=filled,
      		width=1];
      	15 -> 30	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	16	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=histedit_extinct,
      		height=1,
      		label="1b1e58a9",
      		pin=true,
      		pos="3,16!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	15 -> 16	 [penwidth=2.0];
      	16 -> 29	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	29 -> 30	 [penwidth=2.0];
      }

Stack
-----

  $ hg update typo
  1 files updated, 0 files merged, 2 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/stack-typo.log stack
  ### target: typo (branch)
  <span style="color:teal;">b1</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Fix bug</span><span style="color:teal;font-weight:bold;"> (current)</span>
  b0^ ROOT (base)

  $ hg update build/linuxsupport-v2
  4 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/stack-rebase.log stack
  ### target: build/linuxsupport-v2 (branch)
  <span style="color:teal;">b3</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Third commit on build/linuxsupport-v2</span><span style="color:teal;font-weight:bold;"> (current)</span>
  <span style="color:olive;">b2</span><span style="color:green;">:</span> Second commit on build/linuxsupport-v2.
  <span style="color:olive;">b1</span><span style="color:green;">:</span> First commit on build/linuxsupport-v2
  b0^ New commit on build/v2 (base)

  $ html_output $TESTDIR/output/stack-rebase-prev-from-b3.log prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [<span style="color:blue;">19</span>] Second commit on build/linuxsupport-v2.

  $ html_output $TESTDIR/output/stack-rebase-stack-b2.log stack
  ### target: build/linuxsupport-v2 (branch)
  <span style="color:olive;">b3</span><span style="color:green;">:</span> Third commit on build/linuxsupport-v2
  <span style="color:teal;">b2</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Second commit on build/linuxsupport-v2.</span><span style="color:teal;font-weight:bold;"> (current)</span>
  <span style="color:olive;">b1</span><span style="color:green;">:</span> First commit on build/linuxsupport-v2
  b0^ New commit on build/v2 (base)

  $ html_output $TESTDIR/output/stack-rebase-next-from-b2.log next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [<span style="color:blue;">20</span>] Third commit on build/linuxsupport-v2

  $ html_output $TESTDIR/output/stack-rebase-export-b1.log export -r b1
  # HG changeset patch
  # User Boris Feld &lt;boris.feld@octobus.net&gt;
  # Date 1512661592 -3600
  #      Thu Dec 07 16:46:32 2017 +0100
  # Branch build/linuxsupport-v2
  # Node ID 7b62ce2c283e6fa23af1811efea529c30620196a
  # Parent  0e694460372ee8e9ca759c90f05a31f11eee34ac
  First commit on build/linuxsupport-v2
  
  $ html_output $TESTDIR/output/stack-rebase-update-b2.log update -r b2
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ html_output $TESTDIR/output/stack-rebase-stack-b2.log stack
  ### target: build/linuxsupport-v2 (branch)
  <span style="color:olive;">b3</span><span style="color:green;">:</span> Third commit on build/linuxsupport-v2
  <span style="color:teal;">b2</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Second commit on build/linuxsupport-v2.</span><span style="color:teal;font-weight:bold;"> (current)</span>
  <span style="color:olive;">b1</span><span style="color:green;">:</span> First commit on build/linuxsupport-v2
  b0^ New commit on build/v2 (base)


Edit mid-stack
--------------

  $ html_output $TESTDIR/output/edit-mid-stack.log amend -m "Second commit on build/linuxsupport-v2"
  1 new orphan changesets

  $ html_output $TESTDIR/output/edit-mid-stack-after-stack.log stack
  ### target: build/linuxsupport-v2 (branch)
  <span style="color:olive;">b3</span><span style="color:red;">$</span> Third commit on build/linuxsupport-v2<span style="color:red;"> (unstable)</span>
  <span style="color:teal;">b2</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Second commit on build/linuxsupport-v2</span><span style="color:teal;font-weight:bold;"> (current)</span>
  <span style="color:olive;">b1</span><span style="color:green;">:</span> First commit on build/linuxsupport-v2
  b0^ New commit on build/v2 (base)

  $ html_output $TESTDIR/output/edit-mid-stack-after-log.log log -r "branch(build/linuxsupport-v2)" -G
  @  <span style="color:olive;">changeset:   31:5c069dd03e05</span>
  |  branch:      build/linuxsupport-v2
  |  tag:         tip
  |  parent:      18:7b62ce2c283e
  |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |  date:        Mon Dec 11 11:20:24 2017 +0100
  |  summary:     Second commit on build/linuxsupport-v2
  |
  | o  <span style="color:olive;">changeset:   20:3d2c8a2356a2</span>
  | |  branch:      build/linuxsupport-v2
  | |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | |  instability: orphan
  | |  summary:     Third commit on build/linuxsupport-v2
  | |
  | x  <span style="color:olive;">changeset:   19:4686378320d7</span>
  |/   branch:      build/linuxsupport-v2
  |    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
  |    date:        Mon Dec 11 11:20:24 2017 +0100
  |    obsolete:    reworded using amend as 31:5c069dd03e05
  |    summary:     Second commit on build/linuxsupport-v2.
  |
  o  <span style="color:olive;">changeset:   18:7b62ce2c283e</span>
  |  branch:      build/linuxsupport-v2
  ~  parent:      6:0e694460372e
     user:        Boris Feld &lt;boris.feld@octobus.net&gt;
     date:        Thu Dec 07 16:46:32 2017 +0100
     summary:     First commit on build/linuxsupport-v2
  

  $ graph $TESTDIR/graphs/edit-mid-stack-after.dot -r "branch(build/linuxsupport-v2)" -T "{shortest(node, 8)}" --public=yes
  Wrote */graphs/edit-mid-stack-after.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="7b62ce2c",
      		pin=true,
      		pos="1,18!",
      		shape=circle,
      		style=filled,
      		width=1];
      	19	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2_alt",
      		height=1,
      		label=46863783,
      		pin=true,
      		pos="2,19!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	18 -> 19	 [penwidth=2.0];
      	31	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="5c069dd0",
      		pin=true,
      		pos="1,31!",
      		shape=circle,
      		style=filled,
      		width=1];
      	18 -> 31	 [penwidth=2.0];
      	19 -> 31	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	20	 [fillcolor="#FF4F4F",
      		fixedsize=true,
      		group="build/linuxsupport-v2_alt",
      		height=1,
      		label="3d2c8a23",
      		pin=true,
      		pos="2,20!",
      		shape=circle,
      		style=filled,
      		width=1];
      	19 -> 20	 [penwidth=2.0];
      }

Basic troubles + stabilization
------------------------------

  $ cp -R $TESTTMP/evolve_training_repo $TESTDIR/base-repos/edit-mid-stack/

  $ html_output $TESTDIR/output/basic-stabilize-before-log-obsolete.log log -r "branch(build/linuxsupport-v2)" -G -T "{node|short}: {obsolete}\n"
  @  5c069dd03e05:
  |
  | o  3d2c8a2356a2:
  | |
  | x  4686378320d7: obsolete
  |/
  o  7b62ce2c283e:
  |
  ~

  $ html_output $TESTDIR/output/basic-stabilize-before-log-instabilities.log log -r "branch(build/linuxsupport-v2)" -G -T "{node|short}: {instabilities}\n"
  @  5c069dd03e05:
  |
  | o  3d2c8a2356a2: orphan
  | |
  | x  4686378320d7:
  |/
  o  7b62ce2c283e:
  |
  ~

  $ html_output $TESTDIR/output/basic-stabilize-before-evolve-list.log evolve --list
  3d2c8a2356a2: Third commit on build/linuxsupport-v2
    unstable: 4686378320d7 (obsolete parent)
  
  $ html_output $TESTDIR/output/basic-stabilize-next-evolve.log next --evolve
  move:[<span style="color:blue;">20</span>] Third commit on build/linuxsupport-v2
  atop:[<span style="color:blue;">31</span>] Second commit on build/linuxsupport-v2
  working directory now at <span style="color:olive;">52e790f9d4c3</span>

  $ html_output $TESTDIR/output/basic-stabilize-after-stack.log stack
  ### target: build/linuxsupport-v2 (branch)
  <span style="color:teal;">b3</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Third commit on build/linuxsupport-v2</span><span style="color:teal;font-weight:bold;"> (current)</span>
  <span style="color:olive;">b2</span><span style="color:green;">:</span> Second commit on build/linuxsupport-v2
  <span style="color:olive;">b1</span><span style="color:green;">:</span> First commit on build/linuxsupport-v2
  b0^ New commit on build/v2 (base)

  $ graph $TESTDIR/graphs/basic-stabilize-after-stack.dot -T "{shortest(node, 8)}" -r "(::. + ::precursors(.)) and branch(build/linuxsupport-v2)" --hidden --public=yes
  Wrote */graphs/basic-stabilize-after-stack.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="7b62ce2c",
      		pin=true,
      		pos="1,18!",
      		shape=circle,
      		style=filled,
      		width=1];
      	31	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="5c069dd0",
      		pin=true,
      		pos="1,31!",
      		shape=circle,
      		style=filled,
      		width=1];
      	18 -> 31	 [penwidth=2.0];
      	19	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2_extinct",
      		height=1,
      		label=46863783,
      		pin=true,
      		pos="2,19!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	18 -> 19	 [penwidth=2.0];
      	32	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2",
      		height=1,
      		label="52e790f9",
      		pin=true,
      		pos="1,32!",
      		shape=circle,
      		style=filled,
      		width=1];
      	31 -> 32	 [penwidth=2.0];
      	19 -> 31	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	20	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group="build/linuxsupport-v2_extinct",
      		height=1,
      		label="3d2c8a23",
      		pin=true,
      		pos="2,20!",
      		shape=circle,
      		style="dotted, filled",
      		width=1];
      	19 -> 20	 [penwidth=2.0];
      	20 -> 32	 [arrowtail=dot,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      }
Basic exchange
--------------

  $ html_output $TESTDIR/output/basic-exchange-clone.log clone . ../evolve_training_repo_server/
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ cd ../evolve_training_repo_server

  $ hg log -G
  o  changeset:   32:52e790f9d4c3
  |  branch:      build/linuxsupport-v2
  |  tag:         tip
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Mon Dec 11 11:21:02 2017 +0100
  |  summary:     Third commit on build/linuxsupport-v2
  |
  o  changeset:   31:5c069dd03e05
  |  branch:      build/linuxsupport-v2
  |  parent:      18:7b62ce2c283e
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Mon Dec 11 11:20:24 2017 +0100
  |  summary:     Second commit on build/linuxsupport-v2
  |
  | o  changeset:   30:27cb89067c43
  | |  branch:      histedit
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Sat Dec 09 17:35:15 2017 +0100
  | |  summary:     Add code for myfeature
  | |
  | o  changeset:   29:a2082e406c4f
  | |  branch:      histedit
  | |  parent:      14:d102c718e607
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Sat Dec 09 17:37:15 2017 +0100
  | |  summary:     Add test for myfeature
  | |
  | | o  changeset:   28:1b7281b1e052
  | | |  branch:      split
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     To be splitted
  | | |
  | | o  changeset:   27:6fb7bfb44ffe
  | | |  branch:      split
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     To be splitted
  | | |
  | | o  changeset:   26:59f0ddc4bd4b
  | | |  branch:      split
  | | |  parent:      0:d2eb2ac6a5bd
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     To be splitted
  | | |
  | | | o  changeset:   25:dab6ed4b3c75
  | | |/   branch:      fold
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    summary:     add a test
  | | |
  | | | o  changeset:   24:76ace846a3f9
  | | | |  branch:      amend-extract
  | | | |  parent:      7:4ae0d1de7a58
  | | | |  user:        Good User
  | | | |  date:        Fri Dec 08 15:28:46 2017 +0100
  | | | |  summary:     Commit to be extracted
  | | | |
  o | | |  changeset:   18:7b62ce2c283e
  | | | |  branch:      build/linuxsupport-v2
  | | | |  parent:      6:0e694460372e
  | | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | | |  date:        Thu Dec 07 16:46:32 2017 +0100
  | | | |  summary:     First commit on build/linuxsupport-v2
  | | | |
  | | +---o  changeset:   17:708369dc1bfe
  | | | |    branch:      typo
  | | | |    parent:      0:d2eb2ac6a5bd
  | | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | | |    date:        Thu Dec 07 11:26:53 2017 +0100
  | | | |    summary:     Fix bug
  | | | |
  | o | |  changeset:   14:d102c718e607
  | |/ /   branch:      histedit
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Sat Dec 09 17:33:15 2017 +0100
  | | |    summary:     First commit on histedit branch
  | | |
  | | o  changeset:   7:4ae0d1de7a58
  | |/   branch:      amend-extract
  | |    parent:      0:d2eb2ac6a5bd
  | |    user:        Boris Feld <boris.feld@octobus.net>
  | |    date:        Fri Dec 08 15:04:09 2017 +0100
  | |    summary:     Base file
  | |
  o |  changeset:   6:0e694460372e
  | |  branch:      build/v2
  | |  parent:      2:f3bd0ab4ee87
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Mon Dec 11 11:22:16 2017 +0100
  | |  summary:     New commit on build/v2
  | |
  o |  changeset:   2:f3bd0ab4ee87
  |/   branch:      build/v2
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Thu Dec 07 16:45:07 2017 +0100
  |    summary:     First commit on build/v2
  |
  @  changeset:   0:d2eb2ac6a5bd
     user:        Boris Feld <boris.feld@octobus.net>
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  


FINAL STAY AT THE END

  $ cd $TESTTMP/evolve_training_repo

  $ hg log -G --hidden
  @  changeset:   32:52e790f9d4c3
  |  branch:      build/linuxsupport-v2
  |  tag:         tip
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Mon Dec 11 11:21:02 2017 +0100
  |  summary:     Third commit on build/linuxsupport-v2
  |
  o  changeset:   31:5c069dd03e05
  |  branch:      build/linuxsupport-v2
  |  parent:      18:7b62ce2c283e
  |  user:        Boris Feld <boris.feld@octobus.net>
  |  date:        Mon Dec 11 11:20:24 2017 +0100
  |  summary:     Second commit on build/linuxsupport-v2
  |
  | o  changeset:   30:27cb89067c43
  | |  branch:      histedit
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Sat Dec 09 17:35:15 2017 +0100
  | |  summary:     Add code for myfeature
  | |
  | o  changeset:   29:a2082e406c4f
  | |  branch:      histedit
  | |  parent:      14:d102c718e607
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Sat Dec 09 17:37:15 2017 +0100
  | |  summary:     Add test for myfeature
  | |
  | | o  changeset:   28:1b7281b1e052
  | | |  branch:      split
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     To be splitted
  | | |
  | | o  changeset:   27:6fb7bfb44ffe
  | | |  branch:      split
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     To be splitted
  | | |
  | | o  changeset:   26:59f0ddc4bd4b
  | | |  branch:      split
  | | |  parent:      0:d2eb2ac6a5bd
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     To be splitted
  | | |
  | | | o  changeset:   25:dab6ed4b3c75
  | | |/   branch:      fold
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    summary:     add a test
  | | |
  | | | o  changeset:   24:76ace846a3f9
  | | | |  branch:      amend-extract
  | | | |  parent:      7:4ae0d1de7a58
  | | | |  user:        Good User
  | | | |  date:        Fri Dec 08 15:28:46 2017 +0100
  | | | |  summary:     Commit to be extracted
  | | | |
  | | | | x  changeset:   23:008eb7da195a
  | | | |/   branch:      amend-extract
  | | | |    parent:      7:4ae0d1de7a58
  | | | |    user:        Good User
  | | | |    date:        Fri Dec 08 15:28:46 2017 +0100
  | | | |    obsolete:    pruned
  | | | |    summary:     temporary commit for uncommiting 1e04751ef00a
  | | | |
  | | | | x  changeset:   22:1e04751ef00a
  | | | |/   branch:      amend-extract
  | | | |    parent:      7:4ae0d1de7a58
  | | | |    user:        Good User
  | | | |    date:        Fri Dec 08 15:28:46 2017 +0100
  | | | |    obsolete:    amended as 24:76ace846a3f9
  | | | |    summary:     Commit to be extracted
  | | | |
  | | | | x  changeset:   21:5935c1c3ad24
  | | | |/   branch:      amend-extract
  | | | |    parent:      7:4ae0d1de7a58
  | | | |    user:        Good User
  | | | |    date:        Fri Dec 08 15:28:46 2017 +0100
  | | | |    obsolete:    amended as 22:1e04751ef00a
  | | | |    summary:     Commit to be extracted
  | | | |
  | | | | x  changeset:   20:3d2c8a2356a2
  | | | | |  branch:      build/linuxsupport-v2
  | | | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | | | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | | | | |  obsolete:    rebased as 32:52e790f9d4c3
  | | | | |  summary:     Third commit on build/linuxsupport-v2
  | | | | |
  +-------x  changeset:   19:4686378320d7
  | | | |    branch:      build/linuxsupport-v2
  | | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | | |    date:        Mon Dec 11 11:20:24 2017 +0100
  | | | |    obsolete:    reworded using amend as 31:5c069dd03e05
  | | | |    summary:     Second commit on build/linuxsupport-v2.
  | | | |
  o | | |  changeset:   18:7b62ce2c283e
  | | | |  branch:      build/linuxsupport-v2
  | | | |  parent:      6:0e694460372e
  | | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | | |  date:        Thu Dec 07 16:46:32 2017 +0100
  | | | |  summary:     First commit on build/linuxsupport-v2
  | | | |
  | | +---o  changeset:   17:708369dc1bfe
  | | | |    branch:      typo
  | | | |    parent:      0:d2eb2ac6a5bd
  | | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | | |    date:        Thu Dec 07 11:26:53 2017 +0100
  | | | |    summary:     Fix bug
  | | | |
  | | | | x  changeset:   16:1b1e58a9ed27
  | | | | |  branch:      histedit
  | | | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | | | |  date:        Sat Dec 09 17:37:15 2017 +0100
  | | | | |  obsolete:    rebased using histedit as 29:a2082e406c4f
  | | | | |  summary:     Add test for myfeature
  | | | | |
  | +-----x  changeset:   15:23eb6f9e4c51
  | | | |    branch:      histedit
  | | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | | |    date:        Sat Dec 09 17:35:15 2017 +0100
  | | | |    obsolete:    rebased using histedit as 30:27cb89067c43
  | | | |    summary:     Add code for myfeature
  | | | |
  | o | |  changeset:   14:d102c718e607
  | |/ /   branch:      histedit
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Sat Dec 09 17:33:15 2017 +0100
  | | |    summary:     First commit on histedit branch
  | | |
  | +---x  changeset:   13:5d5029b9daed
  | | |    branch:      split
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Fri Dec 08 17:33:15 2017 +0100
  | | |    obsolete:    split as 26:59f0ddc4bd4b, 27:6fb7bfb44ffe, 28:1b7281b1e052
  | | |    summary:     To be splitted
  | | |
  | | | x  changeset:   12:966df9f031c1
  | | | |  branch:      fold
  | | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | | |  date:        Fri Dec 08 16:50:38 2017 +0100
  | | | |  obsolete:    rewritten as 25:dab6ed4b3c75
  | | | |  summary:     Really fix the test
  | | | |
  | | | x  changeset:   11:b316dc02bddc
  | | | |  branch:      fold
  | | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | | |  date:        Fri Dec 08 16:50:17 2017 +0100
  | | | |  obsolete:    rewritten as 25:dab6ed4b3c75
  | | | |  summary:     Fix the test
  | | | |
  | +---x  changeset:   10:03174536bb2a
  | | |    branch:      fold
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Fri Dec 08 16:49:45 2017 +0100
  | | |    obsolete:    rewritten as 25:dab6ed4b3c75
  | | |    summary:     add a test
  | | |
  | +---x  changeset:   9:324b72ebbb21
  | | |    branch:      prune
  | | |    parent:      0:d2eb2ac6a5bd
  | | |    user:        Boris Feld <boris.feld@octobus.net>
  | | |    date:        Fri Dec 08 16:12:23 2017 +0100
  | | |    obsolete:    pruned
  | | |    summary:     Commit to prune
  | | |
  | | | x  changeset:   8:e288d12d5e96
  | | |/   branch:      amend-extract
  | | |    user:        Bad User
  | | |    date:        Fri Dec 08 15:28:46 2017 +0100
  | | |    obsolete:    reauthored using amend as 21:5935c1c3ad24
  | | |    summary:     Commit to be extracted
  | | |
  | | o  changeset:   7:4ae0d1de7a58
  | |/   branch:      amend-extract
  | |    parent:      0:d2eb2ac6a5bd
  | |    user:        Boris Feld <boris.feld@octobus.net>
  | |    date:        Fri Dec 08 15:04:09 2017 +0100
  | |    summary:     Base file
  | |
  o |  changeset:   6:0e694460372e
  | |  branch:      build/v2
  | |  parent:      2:f3bd0ab4ee87
  | |  user:        Boris Feld <boris.feld@octobus.net>
  | |  date:        Mon Dec 11 11:22:16 2017 +0100
  | |  summary:     New commit on build/v2
  | |
  | | x  changeset:   5:39e9774ab30b
  | | |  branch:      build/linuxsupport-v2
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Mon Dec 11 11:21:02 2017 +0100
  | | |  obsolete:    rebased using rebase as 20:3d2c8a2356a2
  | | |  summary:     Third commit on build/linuxsupport-v2
  | | |
  | | x  changeset:   4:5ad93176b041
  | | |  branch:      build/linuxsupport-v2
  | | |  user:        Boris Feld <boris.feld@octobus.net>
  | | |  date:        Mon Dec 11 11:20:24 2017 +0100
  | | |  obsolete:    rebased using rebase as 19:4686378320d7
  | | |  summary:     Second commit on build/linuxsupport-v2.
  | | |
  +---x  changeset:   3:424916b62f4c
  | |    branch:      build/linuxsupport-v2
  | |    user:        Boris Feld <boris.feld@octobus.net>
  | |    date:        Thu Dec 07 16:46:32 2017 +0100
  | |    obsolete:    rebased using rebase as 18:7b62ce2c283e
  | |    summary:     First commit on build/linuxsupport-v2
  | |
  o |  changeset:   2:f3bd0ab4ee87
  |/   branch:      build/v2
  |    parent:      0:d2eb2ac6a5bd
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Thu Dec 07 16:45:07 2017 +0100
  |    summary:     First commit on build/v2
  |
  | x  changeset:   1:5d48a444aba7
  |/   branch:      typo
  |    user:        Boris Feld <boris.feld@octobus.net>
  |    date:        Thu Dec 07 11:26:53 2017 +0100
  |    obsolete:    reworded using amend as 17:708369dc1bfe
  |    summary:     Fx bug
  |
  o  changeset:   0:d2eb2ac6a5bd
     user:        Boris Feld <boris.feld@octobus.net>
     date:        Thu Dec 07 11:26:05 2017 +0100
     summary:     ROOT
  
Phases graph repository
=======================

  $ hg init $TESTTMP/phases
  $ cd $TESTTMP/phases

  $ hg commit -m "Public" --config ui.allowemptycommit=true
  $ hg phase -p .

  $ hg commit -m "Draft" --config ui.allowemptycommit=true

  $ hg commit -s -m "Secret" --config ui.allowemptycommit=true

  $ hg log -G -T "{rev} {phase}\n"
  @  2 secret
  |
  o  1 draft
  |
  o  0 public
  
  $ graph $TESTDIR/graphs/phases.dot -r "all()" -T "{desc}"
  Wrote */graphs/phases.dot (glob)
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=Public,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	1	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=Draft,
      		pin=true,
      		pos="1,1!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	0 -> 1	 [penwidth=2.0];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=Secret,
      		pin=true,
      		pos="1,2!",
      		shape=square,
      		style=filled,
      		width=1];
      	1 -> 2	 [penwidth=2.0];
      }
