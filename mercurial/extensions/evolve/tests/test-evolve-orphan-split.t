** Testing resolution of orphans by `hg evolve` where an obsolete changeset has
multiple successors **

  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = True
  > [alias]
  > glog = log -GT "{rev}:{node|short} {desc}\n ({bookmarks}) {phase}"
  > [extensions]
  > rebase =
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

Repo Setup

  $ hg init repo
  $ cd repo
  $ echo ".*\.orig" > .hgignore
  $ hg add .hgignore
  $ hg ci -m "added hgignore"

An orphan changeset with parent got splitted
--------------------------------------------

  $ for ch in a b c; do echo foo > $ch; done;

  $ hg add a b
  $ hg ci -m "added a and b"
  $ hg add c
  $ hg ci -m "added c"

  $ hg glog
  @  2:86e1ebf1ca61 added c
  |   () draft
  o  1:d0ddb614efbd added a and b
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg split -r 1 <<EOF
  > y
  > y
  > n
  > y
  > EOF
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  adding a
  adding b
  diff --git a/a b/a
  new file mode 100644
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +foo
  record change 1/2 to 'a'? [Ynesfdaq?] y
  
  diff --git a/b b/b
  new file mode 100644
  examine changes to 'b'? [Ynesfdaq?] n
  
  created new head
  Done splitting? [yN] y
  1 new orphan changesets

  $ hg glog
  @  4:8b179cffc81c added a and b
  |   () draft
  o  3:bd3735d4dab0 added a and b
  |   () draft
  | *  2:86e1ebf1ca61 added c
  | |   () draft
  | x  1:d0ddb614efbd added a and b
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve
  move:[2] added c
  atop:[4] added a and b
  working directory is now at af13f0560b31

  $ hg glog
  @  5:af13f0560b31 added c
  |   () draft
  o  4:8b179cffc81c added a and b
  |   () draft
  o  3:bd3735d4dab0 added a and b
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

When the successors does not form a linear chain and are multiple heads
-----------------------------------------------------------------------

  $ hg fold -r .^^::. --exact -m "added a b c"
  3 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg glog
  @  6:f89e4764f2ed added a b c
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft
  $ echo foo > d
  $ hg ci -Aqm "added d"

  $ hg glog
  @  7:d48a30875f01 added d
  |   () draft
  o  6:f89e4764f2ed added a b c
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [6] added a b c
  $ hg split -r . <<EOF
  > y
  > n
  > y
  > y
  > y
  > y
  > y
  > EOF
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  adding a
  adding b
  adding c
  diff --git a/a b/a
  new file mode 100644
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +foo
  record change 1/3 to 'a'? [Ynesfdaq?] n
  
  diff --git a/b b/b
  new file mode 100644
  examine changes to 'b'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +foo
  record change 2/3 to 'b'? [Ynesfdaq?] y
  
  diff --git a/c b/c
  new file mode 100644
  examine changes to 'c'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +foo
  record change 3/3 to 'c'? [Ynesfdaq?] y
  
  created new head
  Done splitting? [yN] y
  1 new orphan changesets

  $ hg glog
  @  9:c0fbf8aaf6c4 added a b c
  |   () draft
  o  8:f2632392aefe added a b c
  |   () draft
  | *  7:d48a30875f01 added d
  | |   () draft
  | x  6:f89e4764f2ed added a b c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg rebase -r . -d 8fa14d15e168
  rebasing 9:c0fbf8aaf6c4 "added a b c" (tip)
  $ hg glog
  @  10:7f87764e5b64 added a b c
  |   () draft
  | o  8:f2632392aefe added a b c
  |/    () draft
  | *  7:d48a30875f01 added d
  | |   () draft
  | x  6:f89e4764f2ed added a b c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --dry-run <<EOF
  > 0
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: 0
  move:[7] added d
  atop:[8] added a b c
  hg rebase -r d48a30875f01 -d f2632392aefe

  $ hg evolve --dry-run <<EOF
  > 1
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: 1
  move:[7] added d
  atop:[10] added a b c
  hg rebase -r d48a30875f01 -d 7f87764e5b64

Testing the interactive prompt with invalid values first
(this should move its own test file when we use it at multiple places)

  $ hg evolve --all <<EOF
  > foo
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: foo
  invalid value 'foo' entered for index
  could not solve instability, ambiguous destination: parent split across two branches

  $ hg evolve --all <<EOF
  > 4
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: 4
  invalid value '4' entered for index
  could not solve instability, ambiguous destination: parent split across two branches

  $ hg evolve --all <<EOF
  > -1
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: -1
  invalid value '-1' entered for index
  could not solve instability, ambiguous destination: parent split across two branches

  $ hg evolve --all <<EOF
  > q
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: q
  could not solve instability, ambiguous destination: parent split across two branches

Doing the evolve with the interactive prompt

  $ hg evolve --all <<EOF
  > 1
  > EOF
  ancestor 'd48a30875f01' split over multiple topological branches.
  choose an evolve destination:
  0: [f2632392aefe] added a b c
  1: [7f87764e5b64] added a b c
  q: quit the prompt
  enter the index of the revision you want to select: 1
  move:[7] added d
  atop:[10] added a b c
  working directory is now at 1c6caa7c902a
