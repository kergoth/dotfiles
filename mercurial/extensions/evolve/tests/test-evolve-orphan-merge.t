** Testing resolution of orphans by `hg evolve` when merges are involved **

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

An orphan merge changeset with one of the parent obsoleted
==========================================================

1) When merging both the parents does not result in conflicts
-------------------------------------------------------------

  $ echo foo > a
  $ hg ci -Aqm "added a"
  $ hg up .^
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo foo > b
  $ hg ci -Aqm "added b"
  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m "merging a and b"

  $ hg glog
  @    3:3b2b6f4652ee merging a and b
  |\    () draft
  | o  2:d76850646258 added b
  | |   () draft
  o |  1:c7586e2a9264 added a
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Testing with obsoleting the second parent

  $ hg up d76850646258
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo bar > b
  $ hg amend
  1 new orphan changesets

  $ hg glog
  @  4:64370c9805e7 added b
  |   () draft
  | *    3:3b2b6f4652ee merging a and b
  | |\    () draft
  +---x  2:d76850646258 added b
  | |     () draft
  | o  1:c7586e2a9264 added a
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --all
  move:[3] merging a and b
  atop:[4] added b
  working directory is now at 91fd62122a4b

  $ hg glog
  @    5:91fd62122a4b merging a and b
  |\    () draft
  | o  4:64370c9805e7 added b
  | |   () draft
  o |  1:c7586e2a9264 added a
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg parents
  changeset:   5:91fd62122a4b
  tag:         tip
  parent:      4:64370c9805e7
  parent:      1:c7586e2a9264
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     merging a and b
  

Testing with obsoleting the first parent

  $ hg up c7586e2a9264
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo bar > a
  $ hg amend
  1 new orphan changesets

  $ hg glog
  @  6:3d41537b44ca added a
  |   () draft
  | *    5:91fd62122a4b merging a and b
  | |\    () draft
  +---o  4:64370c9805e7 added b
  | |     () draft
  | x  1:c7586e2a9264 added a
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --all
  move:[5] merging a and b
  atop:[6] added a
  working directory is now at 968d205ba4d8

  $ hg glog
  @    7:968d205ba4d8 merging a and b
  |\    () draft
  | o  6:3d41537b44ca added a
  | |   () draft
  o |  4:64370c9805e7 added b
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg parents
  changeset:   7:968d205ba4d8
  tag:         tip
  parent:      6:3d41537b44ca
  parent:      4:64370c9805e7
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     merging a and b
  
2) When merging both the parents resulted in conflicts
------------------------------------------------------

  $ hg up 8fa14d15e168
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo foo > c
  $ hg ci -Aqm "foo to c"
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [0] added hgignore
  $ echo bar > c
  $ hg ci -Aqm "bar to c"

  $ hg glog
  @  9:d0f84b25d4e3 bar to c
  |   () draft
  | o  8:1c165c673853 foo to c
  |/    () draft
  | o    7:968d205ba4d8 merging a and b
  | |\    () draft
  +---o  6:3d41537b44ca added a
  | |     () draft
  | o  4:64370c9805e7 added b
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Prune old test changesets to have clear graph view
  $ hg prune -r 64370c9805e7 -r 3d41537b44ca -r 968d205ba4d8
  3 changesets pruned

  $ hg glog
  @  9:d0f84b25d4e3 bar to c
  |   () draft
  | o  8:1c165c673853 foo to c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg merge
  merging c
  warning: conflicts while merging c! (edit, then use 'hg resolve --mark')
  0 files updated, 0 files merged, 0 files removed, 1 files unresolved
  use 'hg resolve' to retry unresolved file merges or 'hg merge --abort' to abandon
  [1]
  $ echo foobar > c
  $ hg resolve -m
  (no more unresolved files)
  $ hg ci -m "foobar to c"

  $ hg glog
  @    10:fd41d25a3e90 foobar to c
  |\    () draft
  | o  9:d0f84b25d4e3 bar to c
  | |   () draft
  o |  8:1c165c673853 foo to c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Testing with first parent obsoleted

  $ hg up 1c165c673853
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo FOO > c
  $ hg amend
  1 new orphan changesets

  $ hg glog
  @  11:31c317b7bdb1 foo to c
  |   () draft
  | *    10:fd41d25a3e90 foobar to c
  | |\    () draft
  +---o  9:d0f84b25d4e3 bar to c
  | |     () draft
  | x  8:1c165c673853 foo to c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --all
  move:[10] foobar to c
  atop:[11] foo to c
  merging c
  warning: conflicts while merging c! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo FOObar > c
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue
  $ hg evolve --continue
  evolving 10:fd41d25a3e90 "foobar to c"
  working directory is now at c5405d2da7a1

  $ hg glog
  @    12:c5405d2da7a1 foobar to c
  |\    () draft
  | o  11:31c317b7bdb1 foo to c
  | |   () draft
  o |  9:d0f84b25d4e3 bar to c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg parents
  changeset:   12:c5405d2da7a1
  tag:         tip
  parent:      9:d0f84b25d4e3
  parent:      11:31c317b7bdb1
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     foobar to c
  
Testing a conlficting merge with second parent obsoleted

  $ hg up 31c317b7bdb1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo foo > c
  $ hg amend
  1 new orphan changesets

  $ hg glog
  @  13:928097d0b5b5 foo to c
  |   () draft
  | *    12:c5405d2da7a1 foobar to c
  | |\    () draft
  +---x  11:31c317b7bdb1 foo to c
  | |     () draft
  | o  9:d0f84b25d4e3 bar to c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --all
  move:[12] foobar to c
  atop:[13] foo to c
  merging c
  warning: conflicts while merging c! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo foobar > c
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue

  $ hg evolve --continue
  evolving 12:c5405d2da7a1 "foobar to c"
  working directory is now at dc1948a6eeab

  $ hg glog
  @    14:dc1948a6eeab foobar to c
  |\    () draft
  | o  13:928097d0b5b5 foo to c
  | |   () draft
  o |  9:d0f84b25d4e3 bar to c
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

3) When stabilizing other changesets resulted in orphan merge changeset
-----------------------------------------------------------------------

  $ hg prune -r d0f84b25d4e3 -r 928097d0b5b5 -r dc1948a6eeab
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 8fa14d15e168
  3 changesets pruned

  $ for ch in l m; do echo foo > $ch; hg ci -Aqm "added "$ch; done;
  $ hg up 8fa14d15e168
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ for ch in x y; do echo foo > $ch; hg ci -Aqm "added "$ch; done;
  $ hg glog
  @  18:863d11043c67 added y
  |   () draft
  o  17:3f2247835c1d added x
  |   () draft
  | o  16:e44dc179e7f5 added m
  | |   () draft
  | o  15:8634bee7bf1e added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg merge
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m "merge commit"

  $ hg up 8634bee7bf1e
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ echo bar > l
  $ hg amend
  2 new orphan changesets

  $ hg glog
  @  20:fccc9de66799 added l
  |   () draft
  | *    19:190763373d8b merge commit
  | |\    () draft
  | | o  18:863d11043c67 added y
  | | |   () draft
  +---o  17:3f2247835c1d added x
  | |     () draft
  | *  16:e44dc179e7f5 added m
  | |   () draft
  | x  15:8634bee7bf1e added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft
  $ hg evolve --all
  move:[16] added m
  atop:[20] added l
  move:[19] merge commit
  atop:[21] added m
  working directory is now at a446ad3e6700

  $ hg glog
  @    22:a446ad3e6700 merge commit
  |\    () draft
  | o  21:495d2039f8f1 added m
  | |   () draft
  | o  20:fccc9de66799 added l
  | |   () draft
  o |  18:863d11043c67 added y
  | |   () draft
  o |  17:3f2247835c1d added x
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

4) When both the parents of the merge changeset are obsolete with a succ
------------------------------------------------------------------------

  $ hg prune -r a446ad3e6700 -r 495d2039f8f1 -r 863d11043c67
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  working directory now at fccc9de66799
  3 changesets pruned

  $ hg glog
  @  20:fccc9de66799 added l
  |   () draft
  | o  17:3f2247835c1d added x
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m "merged l and x"

  $ hg up fccc9de66799
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo foobar > l
  $ hg amend
  1 new orphan changesets
  $ hg up 3f2247835c1d
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo bar > x
  $ hg amend
  $ hg glog
  @  25:cdf6547da25f added x
  |   () draft
  | o  24:3f371171d767 added l
  |/    () draft
  | *    23:7b78a9784f3e merged l and x
  | |\    () draft
  +---x  20:fccc9de66799 added l
  | |     () draft
  | x  17:3f2247835c1d added x
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

XXX: We should handle this case too
  $ hg evolve --all
  move:[23] merged l and x
  atop:[25] added x
  move:[26] merged l and x
  atop:[24] added l
  working directory is now at adb665a78e08

  $ hg glog
  @    27:adb665a78e08 merged l and x
  |\    () draft
  | o  25:cdf6547da25f added x
  | |   () draft
  o |  24:3f371171d767 added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg exp
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID adb665a78e08b962cff415301058d782086c0f33
  # Parent  3f371171d767ef79cf85d156cf46d4035960fcf0
  # Parent  cdf6547da25f1ca5d01102302ad713f444547b48
  merged l and x
  
  diff -r 3f371171d767 -r adb665a78e08 x
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/x	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +bar

  $ hg parents
  changeset:   27:adb665a78e08
  tag:         tip
  parent:      24:3f371171d767
  parent:      25:cdf6547da25f
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     merged l and x
  

5) When one of the merge parent is pruned without a successor
-------------------------------------------------------------

  $ hg prune -r cdf6547da25f
  1 changesets pruned
  1 new orphan changesets
  $ hg glog
  @    27:adb665a78e08 merged l and x
  |\    () draft
  | x  25:cdf6547da25f added x
  | |   () draft
  o |  24:3f371171d767 added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --rev .
  move:[27] merged l and x
  atop:[0] added hgignore
  working directory is now at fb8fe870ae7d

  $ hg glog
  @    28:fb8fe870ae7d merged l and x
  |\    () draft
  | o  24:3f371171d767 added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

6) When one parent is pruned without successor and the other parent of merge is
the parent of the pruned commit
--------------------------------------------------------------------------------

  $ hg glog
  @    28:fb8fe870ae7d merged l and x
  |\    () draft
  | o  24:3f371171d767 added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg prune -r 3f371171d767
  1 changesets pruned
  1 new orphan changesets

  $ hg glog
  @    28:fb8fe870ae7d merged l and x
  |\    () draft
  | x  24:3f371171d767 added l
  |/    () draft
  o  0:8fa14d15e168 added hgignore
      () draft

This is the right thing to do here. When you have a merge changeset, and one
parent is pruned and parent of that pruned parent is same as another parent of
the merge changeset, that should lead to merge changeset being a non-merge
changeset and non-pruned changeset as its only parent

If you look at the above graph, the side part:

\
 x
/

is redundant now as the changeset is pruned and we should remove this chain
while evolving.

This case can occur a lot of times in workflows where people make branches and
merge them again. After getting their work done, they may want to get rid of
that branch and they prune all their changeset, which will result in this
case where merge commit becomes orphan with its ancestors pruned up until a
point where the other parent of merge is the first non-pruned ancestor.

  $ hg evolve -r .
  move:[28] merged l and x
  atop:[0] added hgignore
  working directory is now at b61ba77b924a

  $ hg glog
  @  29:b61ba77b924a merged l and x
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

7) When one parent is pruned without successor and has no parent
----------------------------------------------------------------

  $ hg prune -r .
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory now at 8fa14d15e168
  1 changesets pruned
  $ hg up null
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ echo foo > foo
  $ hg add foo
  $ hg ci -m "added foo"
  created new head

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m "merge commit"
  $ hg glog
  @    31:32beb84b9dbc merge commit
  |\    () draft
  | o  30:f3ba8b99bb6f added foo
  |     () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg prune -r f3ba8b99bb6f
  1 changesets pruned
  1 new orphan changesets

  $ hg glog
  @    31:32beb84b9dbc merge commit
  |\    () draft
  | x  30:f3ba8b99bb6f added foo
  |     () draft
  o  0:8fa14d15e168 added hgignore
      () draft

The current behavior seems to be the correct behavior in the above case. This is
also another case which can arise flow merge workflow where people start a
branch from null changeset and merge it and then prune it or get rid of it.

Also if you look at the above graph, the side part:

\
 x

becomes redundant as the changeset is pruned without successor and we should
just remove that chain.

  $ hg evolve -r .
  move:[31] merge commit
  atop:[-1] 
  working directory is now at d2a03dd8c951

  $ hg glog
  @  32:d2a03dd8c951 merge commit
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft
