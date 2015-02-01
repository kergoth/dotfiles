  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> $HGRCPATH

  $ glog() {
  >   hg glog --template '{rev}:{node|short}@{branch}({phase}) {desc|firstline}\n' "$@"
  > }

  $ hg init repo
  $ cd repo
  $ echo root > root
  $ hg ci -Am addroot
  adding root
  $ echo a > a
  $ hg ci -Am adda
  adding a
  $ echo b > b
  $ hg ci -Am addb
  adding b
  $ echo c > c
  $ hg ci -Am addc
  adding c
  $ glog
  @  3:7a7552255fb5@default(draft) addc
  |
  o  2:ef23d6ef94d6@default(draft) addb
  |
  o  1:93418d2c0979@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg gdown
  gdown have been deprecated in favor of previous
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [2] addb
  $ echo b >> b
  $ hg amend
  1 new unstable changesets
  $ hg gdown
  gdown have been deprecated in favor of previous
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] adda
  $ echo a >> a
  $ hg amend
  1 new unstable changesets
  $ glog
  @  7:005fe5914f78@default(draft) adda
  |
  | o  5:22619daeed78@default(draft) addb
  | |
  | | o  3:7a7552255fb5@default(draft) addc
  | | |
  | | x  2:ef23d6ef94d6@default(draft) addb
  | |/
  | x  1:93418d2c0979@default(draft) adda
  |/
  o  0:c471ef929e6a@default(draft) addroot
  

Test stabilizing a predecessor child

  $ hg evolve -v
  move:[5] addb
  atop:[7] adda
  hg rebase -r 22619daeed78 -d 005fe5914f78
  resolving manifests
  getting b
  committing files:
  b
  committing manifest
  committing changelog
  working directory is now at bede829dd2d3
  $ glog
  @  8:bede829dd2d3@default(draft) addb
  |
  o  7:005fe5914f78@default(draft) adda
  |
  | o  3:7a7552255fb5@default(draft) addc
  | |
  | x  2:ef23d6ef94d6@default(draft) addb
  | |
  | x  1:93418d2c0979@default(draft) adda
  |/
  o  0:c471ef929e6a@default(draft) addroot
  

Test stabilizing a descendant predecessor's child

  $ hg up 7
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg debugobsolete > successors.old
  $ hg evolve -v
  move:[3] addc
  atop:[8] addb
  hg rebase -r 7a7552255fb5 -d bede829dd2d3
  resolving manifests
  getting b
  resolving manifests
  getting c
  committing files:
  c
  committing manifest
  committing changelog
  working directory is now at 65095d7d0dd5
  $ hg debugobsolete > successors.new
  $ diff -u successors.old successors.new
  --- successors.old* (glob)
  +++ successors.new* (glob)
  @@ -3,3 +3,4 @@
   93418d2c0979643ad446f621195e78720edb05b4 005fe5914f78e8bc64c7eba28117b0b1fa210d0d 0 (*) {'user': 'test'} (glob)
   7a7d76dc97c57751de9e80f61ed2a639bd03cd24 0 {93418d2c0979643ad446f621195e78720edb05b4} (*) {'user': 'test'} (glob)
   22619daeed78036f80fbd326b6852519c4f0c25e bede829dd2d3b2ae9bf198c23432b250dc964458 0 (*) {'user': 'test'} (glob)
  +7a7552255fb5f8bd745e46fba6f0ca633a4dd716 65095d7d0dd5e4f15503bb7b1f433a5fe9bac052 0 (*) {'user': 'test'} (glob)
  [1]



  $ glog
  @  9:65095d7d0dd5@default(draft) addc
  |
  o  8:bede829dd2d3@default(draft) addb
  |
  o  7:005fe5914f78@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg evolve -v
  no troubled changesets
  [1]

Test behaviour with --any

  $ hg up 8
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo b >> b
  $ hg amend
  1 new unstable changesets
  $ glog
  @  11:036cf654e942@default(draft) addb
  |
  | o  9:65095d7d0dd5@default(draft) addc
  | |
  | x  8:bede829dd2d3@default(draft) addb
  |/
  o  7:005fe5914f78@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg up 9
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg evolve -v
  nothing to evolve here
  (1 troubled changesets, do you want --any ?)
  [2]
  $ hg evolve --any -v
  move:[9] addc
  atop:[11] addb
  hg rebase -r 65095d7d0dd5 -d 036cf654e942
  resolving manifests
  removing c
  getting b
  resolving manifests
  getting c
  committing files:
  c
  committing manifest
  committing changelog
  working directory is now at e99ecf51c867
  $ glog
  @  12:e99ecf51c867@default(draft) addc
  |
  o  11:036cf654e942@default(draft) addb
  |
  o  7:005fe5914f78@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg evolve --any -v
  no troubled changesets
  [1]
