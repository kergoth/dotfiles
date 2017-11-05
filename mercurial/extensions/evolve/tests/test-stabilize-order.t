  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ glog() {
  >   hg log -G --template '{rev}:{node|short}@{branch}({phase}) {desc|firstline}\n' "$@"
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
  1 new orphan changesets
  $ hg gdown
  gdown have been deprecated in favor of previous
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] adda
  $ echo a >> a
  $ hg amend
  1 new orphan changesets
  $ glog
  @  5:005fe5914f78@default(draft) adda
  |
  | o  4:22619daeed78@default(draft) addb
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
  move:[4] addb
  atop:[5] adda
  hg rebase -r 22619daeed78 -d 005fe5914f78
  resolving manifests
  getting b
  committing files:
  b
  committing manifest
  committing changelog
  working directory is now at 81b8bbcd5892
  $ glog
  @  6:81b8bbcd5892@default(draft) addb
  |
  o  5:005fe5914f78@default(draft) adda
  |
  | o  3:7a7552255fb5@default(draft) addc
  | |
  | x  2:ef23d6ef94d6@default(draft) addb
  | |
  | x  1:93418d2c0979@default(draft) adda
  |/
  o  0:c471ef929e6a@default(draft) addroot
  

Test stabilizing a descendant predecessor's child

  $ hg up -r 005fe5914f78
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg debugobsolete > successors.old
  $ hg evolve -v
  move:[3] addc
  atop:[6] addb
  hg rebase -r 7a7552255fb5 -d 81b8bbcd5892
  resolving manifests
  getting b
  resolving manifests
  getting c
  committing files:
  c
  committing manifest
  committing changelog
  working directory is now at 0f691739f917
  $ hg debugobsolete > successors.new
  $ diff -u successors.old successors.new
  --- successors.old* (glob)
  +++ successors.new* (glob)
  @@ -1,3 +1,4 @@
   ef23d6ef94d68dea65d20587dfecc8b33d165617 22619daeed78036f80fbd326b6852519c4f0c25e 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}
   93418d2c0979643ad446f621195e78720edb05b4 005fe5914f78e8bc64c7eba28117b0b1fa210d0d 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}
   22619daeed78036f80fbd326b6852519c4f0c25e 81b8bbcd5892841efed41433d7a5e9df922396cb 0 (*) {'ef1': '4', 'user': 'test'} (glob)
  +7a7552255fb5f8bd745e46fba6f0ca633a4dd716 0f691739f91762462bf8ba21f35fdf71fe64310e 0 (*) {'ef1': '4', 'user': 'test'} (glob)
  [1]



  $ glog
  @  7:0f691739f917@default(draft) addc
  |
  o  6:81b8bbcd5892@default(draft) addb
  |
  o  5:005fe5914f78@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg evolve -v
  no troubled changesets
  [1]

Test behavior with --any

  $ hg up 81b8bbcd5892
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo b >> b
  $ hg amend
  1 new orphan changesets
  $ glog
  @  8:7a68bc4596ea@default(draft) addb
  |
  | o  7:0f691739f917@default(draft) addc
  | |
  | x  6:81b8bbcd5892@default(draft) addb
  |/
  o  5:005fe5914f78@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg up 0f691739f917
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg evolve -v
  nothing to evolve on current working copy parent
  (1 other orphan in the repository, do you want --any or --rev)
  [2]
  $ hg evolve --any -v
  move:[7] addc
  atop:[8] addb
  hg rebase -r 0f691739f917 -d 7a68bc4596ea
  resolving manifests
  removing c
  getting b
  resolving manifests
  getting c
  committing files:
  c
  committing manifest
  committing changelog
  working directory is now at 2256dae6521f
  $ glog
  @  9:2256dae6521f@default(draft) addc
  |
  o  8:7a68bc4596ea@default(draft) addb
  |
  o  5:005fe5914f78@default(draft) adda
  |
  o  0:c471ef929e6a@default(draft) addroot
  
  $ hg evolve --any -v
  no orphan changesets to evolve
  [1]

Ambiguous evolution
  $ echo a > k
  $ hg add k
  $ hg ci -m firstambiguous
  $ hg up .^
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo a > l
  $ hg add l
  $ hg ci -m secondambiguous
  created new head
  $ hg up .^
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg commit --amend -m "newmessage"
  2 new orphan changesets
  $ hg log -G
  @  changeset:   12:f83a0bce03e4
  |  tag:         tip
  |  parent:      8:7a68bc4596ea
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     newmessage
  |
  | o  changeset:   11:fa68011f392e
  | |  parent:      9:2256dae6521f
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     secondambiguous
  | |
  | | o  changeset:   10:bdc003b6eec2
  | |/   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    instability: orphan
  | |    summary:     firstambiguous
  | |
  | x  changeset:   9:2256dae6521f
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 12:f83a0bce03e4
  |    summary:     addc
  |
  o  changeset:   8:7a68bc4596ea
  |  parent:      5:005fe5914f78
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     addb
  |
  o  changeset:   5:005fe5914f78
  |  parent:      0:c471ef929e6a
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adda
  |
  o  changeset:   0:c471ef929e6a
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     addroot
  
  $ hg evolve
  abort: multiple evolve candidates
  (select one of *, * with --rev) (glob)
  [255]



