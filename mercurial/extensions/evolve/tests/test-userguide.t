ensure that all the scenarios in the user guide work as documented

basic repo
  $ hg init t
  $ cd t
  $ touch file1.c file2.c
  $ hg -q commit -A -m init

example 1: commit creates a changeset in draft phase
(this is nothing to do with evolve, but it's mentioned in the user guide)
  $ echo 'feature Y' >> file1.c
  $ hg commit -u alice -d '0 0' -m 'implement feature X'
  $ hg phase -r .
  1: draft
  $ hg identify -in
  6e725fd2be6f 1

example 2: unsafe amend with plain vanilla Mercurial: the original
commit is stripped
  $ hg commit --amend -u alice -d '1 0' -m 'implement feature Y'
  saved backup bundle to $TESTTMP/t/.hg/strip-backup/6e725fd2be6f-42cc74d4-amend.hg (glob)
  $ hg log -r 23fe4ac6d3f1
  abort: unknown revision '23fe4ac6d3f1'!
  [255]
  $ hg identify -in
  fe0ecd3bd2a4 1

enable evolve for safe history modification
  $ cat >> $HGRCPATH <<EOF
  > [alias]
  > shortlog = log --template '{rev}:{node|short}  {phase}  {desc|firstline}\n'
  > [extensions]
  > rebase =
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

example 3: safe amend with "hg commit --amend" (figure 2)
  $ echo 'tweak feature Y' >> file1.c
  $ hg commit --amend -u alice -d '2 0' -m 'implement feature Y'
  $ hg shortlog -q -r fe0ecd3bd2a4
  abort: hidden revision 'fe0ecd3bd2a4'!
  (use --hidden to access hidden revisions; successor: 934359450037)
  [255]
  $ hg --hidden shortlog -G
  @  2:934359450037  draft  implement feature Y
  |
  | x  1:fe0ecd3bd2a4  draft  implement feature Y
  |/
  o  0:08c4b6f4efc8  draft  init
  
example 3 redux: repeat safe amend, this time with "hg amend"
  $ hg rollback -q
  $ hg amend -u alice -d '2 0' -m 'implement feature Y'
  $ hg --hidden shortlog -G
  @  2:934359450037  draft  implement feature Y
  |
  | x  1:fe0ecd3bd2a4  draft  implement feature Y
  |/
  o  0:08c4b6f4efc8  draft  init
  
example 4: prune at head (figure 3)
  $ echo 'debug hack' >> file1.c
  $ hg commit -m 'debug hack'
  $ hg prune .
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory now at 934359450037
  1 changesets pruned
  $ hg parents --template '{rev}:{node|short}  {desc|firstline}\n'
  2:934359450037  implement feature Y
  $ hg --hidden shortlog -G -r 934359450037:
  x  3:a3e0ef24aaf0  draft  debug hack
  |
  @  2:934359450037  draft  implement feature Y
  |
  ~

example 5: uncommit files at head (figure 4)
  $ echo 'relevant' >> file1.c
  $ echo 'irrelevant' >> file2.c
  $ hg commit -u dan -d '10 0' -m 'fix bug 234'
  $ hg uncommit file2.c
  $ hg status
  M file2.c
  $ hg --hidden shortlog -G -r 'descendants(934359450037) - a3e0ef24aaf0'
  @  5:c8defeecf7a4  draft  fix bug 234
  |
  | x  4:da4331967f5f  draft  fix bug 234
  |/
  o  2:934359450037  draft  implement feature Y
  |
  ~
  $ hg parents --template '{rev}:{node|short}  {desc|firstline}\n{files}\n'
  5:c8defeecf7a4  fix bug 234
  file1.c
  $ hg revert --no-backup file2.c

example 6: fold multiple changesets together into one (figure 5)
  $ echo step1 >> file1.c
  $ hg commit -m 'step 1'
  $ echo step2 >> file1.c
  $ hg commit -m 'step 2'
  $ echo step3 >> file2.c
  $ hg commit -m 'step 3'
  $ hg log --template '{rev}:{node|short}  {desc|firstline}\n' -r 05e61aab8294::
  6:05e61aab8294  step 1
  7:be6d5bc8e4cc  step 2
  8:35f432d9f7c1  step 3
  $ hg fold -d '0 0' -m 'fix bug 64' --from -r 05e61aab8294::
  3 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg --hidden shortlog -G -r c8defeecf7a4::
  @  9:171c6a79a27b  draft  fix bug 64
  |
  | x  8:35f432d9f7c1  draft  step 3
  | |
  | x  7:be6d5bc8e4cc  draft  step 2
  | |
  | x  6:05e61aab8294  draft  step 1
  |/
  o  5:c8defeecf7a4  draft  fix bug 234
  |
  ~
  $ hg --hidden log -q -r 'successors(05e61aab8294) | successors(be6d5bc8e4cc) | successors(35f432d9f7c1)'
  9:171c6a79a27b
  $ hg --hidden log -q -r 'precursors(171c6a79a27b)'
  6:05e61aab8294
  7:be6d5bc8e4cc
  8:35f432d9f7c1
  $ hg diff -c 171c6a79a27b -U 0
  diff -r c8defeecf7a4 -r 171c6a79a27b file1.c
  --- a/file1.c	Thu Jan 01 00:00:10 1970 +0000
  +++ b/file1.c	Thu Jan 01 00:00:00 1970 +0000
  @@ -3,0 +4,2 @@
  +step1
  +step2
  diff -r c8defeecf7a4 -r 171c6a79a27b file2.c
  --- a/file2.c	Thu Jan 01 00:00:10 1970 +0000
  +++ b/file2.c	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +step3

setup for example 7: amend an older changeset
  $ echo 'fix fix oops fix' > file2.c
  $ hg commit -u bob -d '3 0' -m 'fix bug 17'
  $ echo 'cleanup' >> file1.c
  $ hg commit -u bob -d '4 0' -m 'cleanup'
  $ echo 'new feature' >> file1.c
  $ hg commit -u bob -d '5 0' -m 'feature 23'
  $ hg --hidden shortlog -G -r 171c6a79a27b::
  @  12:dadcbba2d606  draft  feature 23
  |
  o  11:debd46bb29dc  draft  cleanup
  |
  o  10:3e1cb8f70c02  draft  fix bug 17
  |
  o  9:171c6a79a27b  draft  fix bug 64
  |
  ~

example 7: amend an older changeset (figures 6, 7)
  $ hg update -q -r 3e1cb8f70c02
  $ echo 'fix fix fix fix' > file2.c
  $ hg amend -u bob -d '6 0'
  2 new orphan changesets
  $ hg shortlog -r 'obsolete()'
  10:3e1cb8f70c02  draft  fix bug 17
  $ hg shortlog -r "orphan()"
  11:debd46bb29dc  draft  cleanup
  12:dadcbba2d606  draft  feature 23
  $ hg --hidden shortlog -G -r 171c6a79a27b::
  @  13:395cbeda3a06  draft  fix bug 17
  |
  | o  12:dadcbba2d606  draft  feature 23
  | |
  | o  11:debd46bb29dc  draft  cleanup
  | |
  | x  10:3e1cb8f70c02  draft  fix bug 17
  |/
  o  9:171c6a79a27b  draft  fix bug 64
  |
  ~
  $ hg evolve -q --all
  $ hg shortlog -G -r 171c6a79a27b::
  @  15:91b4b0f8b5c5  draft  feature 23
  |
  o  14:fe8858bd9bc2  draft  cleanup
  |
  o  13:395cbeda3a06  draft  fix bug 17
  |
  o  9:171c6a79a27b  draft  fix bug 64
  |
  ~

setup for example 8: prune an older changeset (figure 8)
  $ echo 'useful' >> file1.c
  $ hg commit -u carl -d '7 0' -m 'useful work'
  $ echo 'debug' >> file2.c
  $ hg commit -u carl -d '8 0' -m 'debug hack'
  $ echo 'more useful' >> file1.c
  $ hg commit -u carl -d '9 0' -m 'more work'
  $ hg shortlog -G -r 91b4b0f8b5c5::
  @  18:ea8fafca914b  draft  more work
  |
  o  17:b23d06b457a8  draft  debug hack
  |
  o  16:1f33e68b18b9  draft  useful work
  |
  o  15:91b4b0f8b5c5  draft  feature 23
  |
  ~

example 8: prune an older changeset (figures 8, 9)
  $ hg prune b23d06b457a8
  1 changesets pruned
  1 new orphan changesets
  $ hg --hidden shortlog -G -r b23d06b457a8::
  @  18:ea8fafca914b  draft  more work
  |
  x  17:b23d06b457a8  draft  debug hack
  |
  ~
  $ hg evolve -q --all --any
  $ hg --hidden shortlog -G -r 1f33e68b18b9::
  @  19:4393e5877437  draft  more work
  |
  | x  18:ea8fafca914b  draft  more work
  | |
  | x  17:b23d06b457a8  draft  debug hack
  |/
  o  16:1f33e68b18b9  draft  useful work
  |
  ~

example 9: uncommit files from an older changeset (discard changes)
(figure 10)
  $ echo 'this fixes bug 53' >> file1.c
  $ echo 'debug hack' >> file2.c
  $ hg commit -u dan -d '11 0' -m 'fix bug 53'
  $ echo 'and this handles bug 67' >> file1.c
  $ hg commit -u dan -d '12 0' -m 'fix bug 67'
  $ hg update -r f84357446753
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg shortlog -G -r 4393e5877437::
  o  21:4db2428c8ae3  draft  fix bug 67
  |
  @  20:f84357446753  draft  fix bug 53
  |
  o  19:4393e5877437  draft  more work
  |
  ~
  $ hg uncommit file2.c
  1 new orphan changesets
  $ hg status
  M file2.c
  $ hg revert file2.c
  $ hg evolve --all --any
  move:[21] fix bug 67
  atop:[22] fix bug 53
  working directory is now at 0d972d6888e6
  $ hg --hidden shortlog -G -r 4393e5877437::
  @  23:0d972d6888e6  draft  fix bug 67
  |
  o  22:71bb83d674c5  draft  fix bug 53
  |
  | x  21:4db2428c8ae3  draft  fix bug 67
  | |
  | x  20:f84357446753  draft  fix bug 53
  |/
  o  19:4393e5877437  draft  more work
  |
  ~
  $ rm file2.c.orig

example 10: uncommit files from an older changeset (keep changes)
(figures 11, 12)
  $ echo 'fix a bug' >> file1.c
  $ echo 'useful but unrelated' >> file2.c
  $ hg commit -u dan -d '11 0' -m 'fix a bug'
  $ echo 'new feature' >> file1.c
  $ hg commit -u dan -d '12 0' -m 'new feature'
  $ hg update 5b31a1239ab9
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg --hidden shortlog -G -r 0d972d6888e6::
  o  25:fbb3c6d50427  draft  new feature
  |
  @  24:5b31a1239ab9  draft  fix a bug
  |
  o  23:0d972d6888e6  draft  fix bug 67
  |
  ~
  $ hg uncommit file2.c
  1 new orphan changesets
  $ hg status
  M file2.c
  $ hg commit -m 'useful tweak'
  $ hg --hidden shortlog -G -r 0d972d6888e6::
  @  27:51e0d8c0a922  draft  useful tweak
  |
  o  26:2594e98553a9  draft  fix a bug
  |
  | o  25:fbb3c6d50427  draft  new feature
  | |
  | x  24:5b31a1239ab9  draft  fix a bug
  |/
  o  23:0d972d6888e6  draft  fix bug 67
  |
  ~
  $ hg evolve --all --any
  move:[25] new feature
  atop:[26] fix a bug
  working directory is now at 166c1c368ab6
  $ hg --hidden shortlog -G -r 0d972d6888e6::
  @  28:166c1c368ab6  draft  new feature
  |
  | o  27:51e0d8c0a922  draft  useful tweak
  |/
  o  26:2594e98553a9  draft  fix a bug
  |
  | x  25:fbb3c6d50427  draft  new feature
  | |
  | x  24:5b31a1239ab9  draft  fix a bug
  |/
  o  23:0d972d6888e6  draft  fix bug 67
  |
  ~
