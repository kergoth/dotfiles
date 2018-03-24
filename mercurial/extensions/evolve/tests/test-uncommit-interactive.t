================================================
||  The test for `hg uncommit --interactive`  ||
================================================

Repo Setup
============

  $ . $TESTDIR/testlib/common.sh
  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = true
  > [extensions]
  > evolve =
  > EOF

  $ glog() {
  >   hg log -G --template '{rev}:{node|short}@{branch}({separate("/", obsolete, phase)}) {desc|firstline}\n' "$@"
  > }

  $ hg init repo
  $ cd repo

  $ touch a
  $ cat >> a << EOF
  > 1
  > 2
  > 3
  > 4
  > 5
  > EOF

  $ hg add a
  $ hg ci -m "The base commit"

Make sure aborting the interactive selection does no magic
----------------------------------------------------------

  $ hg status
  $ hg uncommit -i<<EOF
  > q
  > EOF
  diff --git a/a b/a
  new file mode 100644
  examine changes to 'a'? [Ynesfdaq?] q
  
  abort: user quit
  [255]
  $ hg status

Make a commit with multiple hunks
---------------------------------

  $ cat > a << EOF
  > -2
  > -1
  > 0
  > 1
  > 2
  > 3
  > foo
  > bar
  > 4
  > 5
  > babar
  > EOF

  $ hg diff
  diff -r 7733902a8d94 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,5 +1,11 @@
  +-2
  +-1
  +0
   1
   2
   3
  +foo
  +bar
   4
   5
  +babar

  $ hg ci -m "another one"

Not selecting anything to uncommit
==================================

  $ hg uncommit -i<<EOF
  > y
  > n
  > n
  > n
  > EOF
  diff --git a/a b/a
  3 hunks, 6 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3
  discard change 1/3 to 'a'? [Ynesfdaq?] n
  
  @@ -1,5 +4,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5
  discard change 2/3 to 'a'? [Ynesfdaq?] n
  
  @@ -4,2 +9,3 @@
   4
   5
  +babar
  discard change 3/3 to 'a'? [Ynesfdaq?] n
  
  abort: nothing selected to uncommit
  [255]
  $ hg status

Uncommit a chunk
================

  $ hg amend --extract -n "note on amend --extract" -i<<EOF
  > y
  > y
  > n
  > n
  > EOF
  diff --git a/a b/a
  3 hunks, 6 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3
  discard change 1/3 to 'a'? [Ynesfdaq?] y
  
  @@ -1,5 +4,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5
  discard change 2/3 to 'a'? [Ynesfdaq?] n
  
  @@ -4,2 +9,3 @@
   4
   5
  +babar
  discard change 3/3 to 'a'? [Ynesfdaq?] n
  

  $ hg obslog
  @  678a59e5ff90 (3) another one
  |
  x  f70fb463d5bf (1) another one
       rewritten(content) as 678a59e5ff90 using uncommit by test (Thu Jan 01 00:00:00 1970 +0000)
         note: note on amend --extract
  
The unselected part should be in the diff
-----------------------------------------

  $ hg diff
  diff -r 678a59e5ff90 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3

The commit should contain the rest of part
------------------------------------------

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 678a59e5ff90754d5e94719bd82ad169be773c21
  # Parent  7733902a8d94c789ca81d866bea1893d79442db6
  another one
  
  diff -r 7733902a8d94 -r 678a59e5ff90 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,5 +1,8 @@
   1
   2
   3
  +foo
  +bar
   4
   5
  +babar

Uncommiting on dirty working directory
======================================

  $ hg status
  M a
  $ hg diff
  diff -r 678a59e5ff90 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3

  $ hg uncommit -n "testing uncommit on dirty wdir" -i<<EOF
  > y
  > n
  > y
  > EOF
  diff --git a/a b/a
  2 hunks, 3 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -1,5 +1,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5
  discard change 1/2 to 'a'? [Ynesfdaq?] n
  
  @@ -4,2 +6,3 @@
   4
   5
  +babar
  discard change 2/2 to 'a'? [Ynesfdaq?] y
  
  patching file a
  Hunk #1 succeeded at 2 with fuzz 1 (offset 0 lines).

  $ hg diff
  diff -r 46e35360be47 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3
  @@ -5,3 +8,4 @@
   bar
   4
   5
  +babar

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 46e35360be473bf761bedf3d05de4a68ffd9d9f8
  # Parent  7733902a8d94c789ca81d866bea1893d79442db6
  another one
  
  diff -r 7733902a8d94 -r 46e35360be47 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,5 +1,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5

Checking the obsolescence history

  $ hg obslog
  @  46e35360be47 (5) another one
  |
  x  678a59e5ff90 (3) another one
  |    rewritten(content) as 46e35360be47 using uncommit by test (Thu Jan 01 00:00:00 1970 +0000)
  |      note: testing uncommit on dirty wdir
  |
  x  f70fb463d5bf (1) another one
       rewritten(content) as 678a59e5ff90 using uncommit by test (Thu Jan 01 00:00:00 1970 +0000)
         note: note on amend --extract
  

Push the changes back to the commit and more commits for more testing

  $ hg amend
  $ glog
  @  6:905eb2a23ea2@default(draft) another one
  |
  o  0:7733902a8d94@default(draft) The base commit
  
  $ touch foo
  $ echo "hey" >> foo
  $ hg ci -Am "Added foo"
  adding foo

Testing uncommiting a whole changeset and also for a file addition
==================================================================

  $ hg uncommit -i<<EOF
  > y
  > y
  > EOF
  diff --git a/foo b/foo
  new file mode 100644
  examine changes to 'foo'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +hey
  discard this change to 'foo'? [Ynesfdaq?] y
  
  new changeset is empty
  (use 'hg prune .' to remove it)

  $ hg status
  A foo
  $ hg diff
  diff -r 857367499298 foo
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/foo	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +hey

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 857367499298e999b5841bb01df65f73088b5d3b
  # Parent  905eb2a23ea2d92073419d0e19165b90d36ea223
  Added foo
  
  $ hg amend

Testing to uncommit removed files completely
============================================

  $ hg rm a
  $ hg ci -m "Removed a"
  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 219cfe20964e93f8bb9bd82ceaa54d3b776046db
  # Parent  42cc15efbec26c14d96d805dee2766ba91d1fd31
  Removed a
  
  diff -r 42cc15efbec2 -r 219cfe20964e a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ /dev/null	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,11 +0,0 @@
  --2
  --1
  -0
  -1
  -2
  -3
  -foo
  -bar
  -4
  -5
  -babar

Not examining the file
----------------------

  $ hg uncommit -i<<EOF
  > n
  > EOF
  diff --git a/a b/a
  deleted file mode 100644
  examine changes to 'a'? [Ynesfdaq?] n
  
  abort: nothing selected to uncommit
  [255]

Examining the file
------------------
XXX: there is a bug in interactive selection as it is not letting to examine the
file. Tried with curses too. In the curses UI, if you just unselect the hunks
and the not file mod thing at the top, it will show the same "nothing unselected
to uncommit" message which is a bug in interactive selection.

  $ hg uncommit -i<<EOF
  > y
  > EOF
  diff --git a/a b/a
  deleted file mode 100644
  examine changes to 'a'? [Ynesfdaq?] y
  
  new changeset is empty
  (use 'hg prune .' to remove it)

  $ hg diff
  diff -r 737487f1e5f8 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ /dev/null	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,11 +0,0 @@
  --2
  --1
  -0
  -1
  -2
  -3
  -foo
  -bar
  -4
  -5
  -babar
  $ hg status
  R a
  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 737487f1e5f853e55decb73ea31522c63e7f5980
  # Parent  42cc15efbec26c14d96d805dee2766ba91d1fd31
  Removed a
  

  $ hg prune .
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory now at 42cc15efbec2
  1 changesets pruned
  $ hg revert --all
  undeleting a

  $ glog
  @  10:42cc15efbec2@default(draft) Added foo
  |
  o  6:905eb2a23ea2@default(draft) another one
  |
  o  0:7733902a8d94@default(draft) The base commit
  

Testing when a new file is added in the last commit
===================================================

  $ echo "foo" >> foo
  $ touch x
  $ echo "abcd" >> x
  $ hg add x
  $ hg ci -m "Added x"
  $ hg uncommit -i<<EOF
  > y
  > y
  > y
  > n
  > EOF
  diff --git a/foo b/foo
  1 hunks, 1 lines changed
  examine changes to 'foo'? [Ynesfdaq?] y
  
  @@ -1,1 +1,2 @@
   hey
  +foo
  discard change 1/2 to 'foo'? [Ynesfdaq?] y
  
  diff --git a/x b/x
  new file mode 100644
  examine changes to 'x'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +abcd
  discard change 2/2 to 'x'? [Ynesfdaq?] n
  

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 25a080d13cb23dbd014839f54d99a96e57ba7e9b
  # Parent  42cc15efbec26c14d96d805dee2766ba91d1fd31
  Added x
  
  diff -r 42cc15efbec2 -r 25a080d13cb2 x
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/x	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +abcd

  $ hg diff
  diff -r 25a080d13cb2 foo
  --- a/foo	Thu Jan 01 00:00:00 1970 +0000
  +++ b/foo	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,1 +1,2 @@
   hey
  +foo

  $ hg status
  M foo

  $ hg revert --all
  reverting foo

Testing between the stack and with dirty working copy
=====================================================

  $ glog
  @  16:25a080d13cb2@default(draft) Added x
  |
  o  10:42cc15efbec2@default(draft) Added foo
  |
  o  6:905eb2a23ea2@default(draft) another one
  |
  o  0:7733902a8d94@default(draft) The base commit
  
  $ hg up 905eb2a23ea2
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved

  $ touch bar
  $ echo "foo" >> bar
  $ hg add bar
  $ hg status
  A bar
  ? foo.orig

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 905eb2a23ea2d92073419d0e19165b90d36ea223
  # Parent  7733902a8d94c789ca81d866bea1893d79442db6
  another one
  
  diff -r 7733902a8d94 -r 905eb2a23ea2 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,5 +1,11 @@
  +-2
  +-1
  +0
   1
   2
   3
  +foo
  +bar
   4
   5
  +babar

  $ hg uncommit -i<<EOF
  > y
  > n
  > n
  > y
  > EOF
  diff --git a/a b/a
  3 hunks, 6 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3
  discard change 1/3 to 'a'? [Ynesfdaq?] n
  
  @@ -1,5 +4,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5
  discard change 2/3 to 'a'? [Ynesfdaq?] n
  
  @@ -4,2 +9,3 @@
   4
   5
  +babar
  discard change 3/3 to 'a'? [Ynesfdaq?] y
  
  patching file a
  Hunk #1 succeeded at 1 with fuzz 1 (offset -1 lines).
  2 new orphan changesets

  $ hg diff
  diff -r 676366511f95 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -8,3 +8,4 @@
   bar
   4
   5
  +babar
  diff -r 676366511f95 bar
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/bar	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +foo

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 676366511f95ca4122413dcf79b45eaab61fb387
  # Parent  7733902a8d94c789ca81d866bea1893d79442db6
  another one
  
  diff -r 7733902a8d94 -r 676366511f95 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,5 +1,10 @@
  +-2
  +-1
  +0
   1
   2
   3
  +foo
  +bar
   4
   5
  $ hg status
  M a
  A bar
  ? foo.orig

More uncommit on the same dirty working copy
=============================================

  $ hg uncommit -i<<EOF
  > y
  > y
  > n
  > EOF
  diff --git a/a b/a
  2 hunks, 5 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3
  discard change 1/2 to 'a'? [Ynesfdaq?] y
  
  @@ -1,5 +4,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5
  discard change 2/2 to 'a'? [Ynesfdaq?] n
  

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 62d907d0c4fa13b4b8bfeed05f13751035daf963
  # Parent  7733902a8d94c789ca81d866bea1893d79442db6
  another one
  
  diff -r 7733902a8d94 -r 62d907d0c4fa a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,5 +1,7 @@
   1
   2
   3
  +foo
  +bar
   4
   5

  $ hg diff
  diff -r 62d907d0c4fa a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,3 +1,6 @@
  +-2
  +-1
  +0
   1
   2
   3
  @@ -5,3 +8,4 @@
   bar
   4
   5
  +babar
  diff -r 62d907d0c4fa bar
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/bar	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +foo

  $ hg status
  M a
  A bar
  ? foo.orig

Interactive uncommit with a pattern
-----------------------------------

(more setup)

  $ hg ci -m 'roaming changes'
  $ cat > b << EOF
  > a
  > b
  > c
  > d
  > e
  > f
  > h
  > EOF
  $ hg add b
  $ hg ci -m 'add b'
  $ echo 'celeste' >> a
  $ echo 'i' >> b
  $ hg ci -m 'some more changes'
  $ hg export
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID be5c67225e80b050867862bbd9f4755c4e9207c5
  # Parent  c280a907fddcef2ffe9fadcc2d87f29998e22b2f
  some more changes
  
  diff -r c280a907fddc -r be5c67225e80 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -9,3 +9,4 @@
   4
   5
   babar
  +celeste
  diff -r c280a907fddc -r be5c67225e80 b
  --- a/b	Thu Jan 01 00:00:00 1970 +0000
  +++ b/b	Thu Jan 01 00:00:00 1970 +0000
  @@ -5,3 +5,4 @@
   e
   f
   h
  +i

  $ hg uncommit -i a << DONE
  > y
  > y
  > DONE
  diff --git a/a b/a
  1 hunks, 1 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -9,3 +9,4 @@
   4
   5
   babar
  +celeste
  discard this change to 'a'? [Ynesfdaq?] y
  
  $ hg status
  M a
  ? foo.orig
  $ hg diff
  diff -r c701d7c8d18b a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -9,3 +9,4 @@
   4
   5
   babar
  +celeste
  $ hg export
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID c701d7c8d18be55a92688f4458c26bd74fb1f525
  # Parent  c280a907fddcef2ffe9fadcc2d87f29998e22b2f
  some more changes
  
  diff -r c280a907fddc -r c701d7c8d18b b
  --- a/b	Thu Jan 01 00:00:00 1970 +0000
  +++ b/b	Thu Jan 01 00:00:00 1970 +0000
  @@ -5,3 +5,4 @@
   e
   f
   h
  +i

(reset)

  $ cat << EOF  > a
  > -3
  > -2
  > -1
  > 0
  > 1
  > 2
  > 3
  > foo
  > bar
  > 4
  > 5
  > babar
  > celeste
  > EOF
  $ hg amend 

Same but do not select some change in 'a'

  $ hg uncommit -i a << DONE
  > y
  > y
  > n
  > DONE
  diff --git a/a b/a
  2 hunks, 2 lines changed
  examine changes to 'a'? [Ynesfdaq?] y
  
  @@ -1,3 +1,4 @@
  +-3
   -2
   -1
   0
  discard change 1/2 to 'a'? [Ynesfdaq?] y
  
  @@ -9,3 +10,4 @@
   4
   5
   babar
  +celeste
  discard change 2/2 to 'a'? [Ynesfdaq?] n
  
  $ hg status
  M a
  ? foo.orig

  $ hg diff
  diff -r 28d5de12b225 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,3 +1,4 @@
  +-3
   -2
   -1
   0

  $ hg export
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 28d5de12b225d1e0951110cced8d8994227be026
  # Parent  c280a907fddcef2ffe9fadcc2d87f29998e22b2f
  some more changes
  
  diff -r c280a907fddc -r 28d5de12b225 a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -9,3 +9,4 @@
   4
   5
   babar
  +celeste
  diff -r c280a907fddc -r 28d5de12b225 b
  --- a/b	Thu Jan 01 00:00:00 1970 +0000
  +++ b/b	Thu Jan 01 00:00:00 1970 +0000
  @@ -5,3 +5,4 @@
   e
   f
   h
  +i

  $ cat b
  a
  b
  c
  d
  e
  f
  h
  i
