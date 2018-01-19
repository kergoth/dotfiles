Testing the handling of phases for `hg evolve` command

  $ cat >> $HGRCPATH <<EOF
  > [phases]
  > publish = False
  > [alias]
  > glog = log -G --template='{rev} - {node|short} {desc} ({phase})\n'
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

Testing when there are no conflicts during evolve

  $ hg init noconflict
  $ cd noconflict
  $ echo a>a
  $ hg ci -Aqm a
  $ echo b>b
  $ hg ci -Aqm b
  $ echo c>c
  $ hg ci -Aqsm c
  $ hg glog
  @  2 - 177f92b77385 c (secret)
  |
  o  1 - d2ae7f538514 b (draft)
  |
  o  0 - cb9a9f314b8b a (draft)
  

  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] b
  $ echo b2>b
  $ hg amend
  1 new orphan changesets
  $ hg evolve
  move:[2] c
  atop:[3] b
  working directory is now at 813dde83a7f3
  $ hg glog
  @  4 - 813dde83a7f3 c (secret)
  |
  o  3 - fd89d0f19529 b (draft)
  |
  o  0 - cb9a9f314b8b a (draft)
  
  $ cd ..

Testing case when there are conflicts (bug 5720)

  $ hg init conflicts
  $ cd conflicts
  $ echo a > a
  $ hg ci -Am a
  adding a
  $ echo b > a
  $ hg ci -m b
  $ echo c > a
  $ hg ci -sm c
  $ hg glog
  @  2 - 13833940840c c (secret)
  |
  o  1 - 1e6c11564562 b (draft)
  |
  o  0 - cb9a9f314b8b a (draft)
  

  $ hg prev
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] b
  $ echo b2 > a
  $ hg amend
  1 new orphan changesets

  $ hg glog
  @  3 - 87495ea7c9ec b (draft)
  |
  | o  2 - 13833940840c c (secret)
  | |
  | x  1 - 1e6c11564562 b (draft)
  |/
  o  0 - cb9a9f314b8b a (draft)
  
  $ hg evolve
  move:[2] c
  atop:[3] b
  merging a
  warning: conflicts while merging a! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ hg diff
  diff -r 87495ea7c9ec a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,1 +1,5 @@
  +<<<<<<< destination: 87495ea7c9ec - test: b
   b2
  +=======
  +c
  +>>>>>>> evolving:    13833940840c - test: c

  $ hg glog
  @  3 - 87495ea7c9ec b (draft)
  |
  | o  2 - 13833940840c c (secret)
  | |
  | x  1 - 1e6c11564562 b (draft)
  |/
  o  0 - cb9a9f314b8b a (draft)
  

  $ echo c2 > a
  $ hg resolve -m
  (no more unresolved files)
  $ hg evolve -c
  evolving 2:13833940840c "c"

  $ hg glog
  @  4 - 3d2080c198e5 c (secret)
  |
  o  3 - 87495ea7c9ec b (draft)
  |
  o  0 - cb9a9f314b8b a (draft)
  
