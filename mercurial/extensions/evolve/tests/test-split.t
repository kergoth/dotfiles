test of the split command
-----------------------

  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > split=-d "0 0"
  > amend=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [diff]
  > git = 1
  > unified = 0
  > [ui]
  > interactive = true
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }


Basic case, split a head
  $ hg init testsplit
  $ cd testsplit
  $ mkcommit _a
  $ mkcommit _b
  $ mkcommit _c
  $ mkcommit _d
  $ echo "change to a" >> _a
  $ hg amend
  $ hg debugobsolete
  9e84a109b8eb081ad754681ee4b1380d17a3741f aa8f656bb307022172d2648be6fb65322f801225 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  f002b57772d7f09b180c407213ae16d92996a988 0 {9e84a109b8eb081ad754681ee4b1380d17a3741f} (*) {'ef1': '*', 'user': 'test'} (glob)

To create commits with the number of split
  $ echo 0 > num
  $ cat > editor.sh << '__EOF__'
  > NUM=$(cat num)
  > NUM=`expr "$NUM" + 1`
  > echo "$NUM" > num
  > echo "split$NUM" > "$1"
  > __EOF__
  $ export HGEDITOR="\"sh\" \"editor.sh\""
  $ hg split << EOF
  > y
  > y
  > y
  > n
  > N
  > y
  > y
  > EOF
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  reverting _a
  adding _d
  diff --git a/_a b/_a
  1 hunks, 1 lines changed
  examine changes to '_a'? [Ynesfdaq?] y
  
  @@ -1,0 +2,1 @@
  +change to a
  record change 1/2 to '_a'? [Ynesfdaq?] y
  
  diff --git a/_d b/_d
  new file mode 100644
  examine changes to '_d'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +_d
  record change 2/2 to '_d'? [Ynesfdaq?] n
  
  created new head
  Done splitting? [yN] N
  diff --git a/_d b/_d
  new file mode 100644
  examine changes to '_d'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +_d
  record this change to '_d'? [Ynesfdaq?] y
  
  no more change to split

  $ hg debugobsolete
  9e84a109b8eb081ad754681ee4b1380d17a3741f aa8f656bb307022172d2648be6fb65322f801225 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  f002b57772d7f09b180c407213ae16d92996a988 0 {9e84a109b8eb081ad754681ee4b1380d17a3741f} (*) {'ef1': '*', 'user': 'test'} (glob)
  aa8f656bb307022172d2648be6fb65322f801225 a98b35e86cae589b61892127c5ec1c868e41d910 5410a2352fa3114883327beee89e3085eefac25c 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg glog
  @  changeset:   7:5410a2352fa3
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split2
  |
  o  changeset:   6:a98b35e86cae
  |  parent:      2:102002290587
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split1
  |
  o  changeset:   2:102002290587
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add _c
  |
  o  changeset:   1:37445b16603b
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add _b
  |
  o  changeset:   0:135f39f4bd78
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add _a
  

Cannot split a commit with uncommitted changes
  $ hg up "desc(_c)"
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo "_cd" > _c
  $ hg split
  abort: uncommitted changes
  [255]

Split a revision specified with -r
  $ hg up "desc(_c)" -C
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo "change to b" >> _b
  $ hg amend -m "_cprim"
  2 new unstable changesets
  $ hg evolve --all
  move:[6] split1
  atop:[9] _cprim
  move:[7] split2
  atop:[10] split1
  working directory is now at * (glob)
  $ hg log -r "desc(_cprim)" -v -p
  changeset:   9:719157b217ac
  parent:      1:37445b16603b
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  files:       _b _c
  description:
  _cprim
  
  
  diff --git a/_b b/_b
  --- a/_b
  +++ b/_b
  @@ -1,0 +2,1 @@
  +change to b
  diff --git a/_c b/_c
  new file mode 100644
  --- /dev/null
  +++ b/_c
  @@ -0,0 +1,1 @@
  +_c
  
  $ hg split -r "desc(_cprim)" <<EOF
  > y
  > y
  > y
  > n
  > y
  > EOF
  2 files updated, 0 files merged, 2 files removed, 0 files unresolved
  reverting _b
  adding _c
  diff --git a/_b b/_b
  1 hunks, 1 lines changed
  examine changes to '_b'? [Ynesfdaq?] y
  
  @@ -1,0 +2,1 @@
  +change to b
  record change 1/2 to '_b'? [Ynesfdaq?] y
  
  diff --git a/_c b/_c
  new file mode 100644
  examine changes to '_c'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +_c
  record change 2/2 to '_c'? [Ynesfdaq?] n
  
  created new head
  Done splitting? [yN] y

Stop before splitting the commit completely creates a commit with all the
remaining changes

  $ hg debugobsolete
  9e84a109b8eb081ad754681ee4b1380d17a3741f aa8f656bb307022172d2648be6fb65322f801225 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  f002b57772d7f09b180c407213ae16d92996a988 0 {9e84a109b8eb081ad754681ee4b1380d17a3741f} (*) {'ef1': '*', 'user': 'test'} (glob)
  aa8f656bb307022172d2648be6fb65322f801225 a98b35e86cae589b61892127c5ec1c868e41d910 5410a2352fa3114883327beee89e3085eefac25c 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  10200229058723ce8d67f6612c1f6b4f73b1fe73 719157b217acc43d397369a448824ed4c7a302f2 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5d0c8b0f2d3e5e1ff95f93d7da2ba06650605ab5 0 {10200229058723ce8d67f6612c1f6b4f73b1fe73} (*) {'ef1': '*', 'user': 'test'} (glob)
  a98b35e86cae589b61892127c5ec1c868e41d910 286887947725085e03455d79649197feaef1eb9d 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  5410a2352fa3114883327beee89e3085eefac25c 0b67cee46a7f2ad664f994027e7af95b36ae25fe 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  719157b217acc43d397369a448824ed4c7a302f2 ced8fbcce3a7cd33f0e454d2cd63882ce1b6006b 73309fb98db840ba4ec5ad528346dc6ee0b39dcb 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg evolve --all
  move:[10] split1
  atop:[13] split4
  move:[11] split2
  atop:[14] split1
  working directory is now at f200e612ac86
  $ hg glog
  @  changeset:   15:f200e612ac86
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split2
  |
  o  changeset:   14:aec57822a8ff
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split1
  |
  o  changeset:   13:73309fb98db8
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split4
  |
  o  changeset:   12:ced8fbcce3a7
  |  parent:      1:37445b16603b
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split3
  |
  o  changeset:   1:37445b16603b
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add _b
  |
  o  changeset:   0:135f39f4bd78
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add _a
  

Split should move bookmarks on the last split successor and preserve the
active bookmark as active
  $ hg book bookA
  $ hg book bookB
  $ echo "changetofilea" > _a
  $ hg amend
  $ hg book
     bookA                     17:39d16b69c75d
   * bookB                     17:39d16b69c75d
  $ hg glog -r "14::"
  @  changeset:   17:39d16b69c75d
  |  bookmark:    bookA
  |  bookmark:    bookB
  |  tag:         tip
  |  parent:      14:aec57822a8ff
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split2
  |
  o  changeset:   14:aec57822a8ff
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split1
  
  $ hg split <<EOF
  > y
  > y
  > n
  > y
  > EOF
  (leaving bookmark bookB)
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  reverting _a
  adding _d
  diff --git a/_a b/_a
  1 hunks, 2 lines changed
  examine changes to '_a'? [Ynesfdaq?] y
  
  @@ -1,2 +1,1 @@
  -_a
  -change to a
  +changetofilea
  record change 1/2 to '_a'? [Ynesfdaq?] y
  
  diff --git a/_d b/_d
  new file mode 100644
  examine changes to '_d'? [Ynesfdaq?] n
  
  created new head
  Done splitting? [yN] y
  $ hg glog -r "14::"
  @  changeset:   19:a2b5c9d9b362
  |  bookmark:    bookA
  |  bookmark:    bookB
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split6
  |
  o  changeset:   18:bf3402785e72
  |  parent:      14:aec57822a8ff
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split5
  |
  o  changeset:   14:aec57822a8ff
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split1
  
  $ hg book
     bookA                     19:a2b5c9d9b362
   * bookB                     19:a2b5c9d9b362
 
Lastest revision is selected if multiple are given to -r
  $ hg split -r "desc(_a)::"
  (leaving bookmark bookB)
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  adding _d
  diff --git a/_d b/_d
  new file mode 100644
  examine changes to '_d'? [Ynesfdaq?] abort: response expected
  [255]

Cannot split a commit that is not a head if instability is not allowed
  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=createmarkers
  > evolutioncommands=split
  > EOF
  $ hg split -r "desc(split3)"
  abort: cannot split commit: ced8fbcce3a7 not a head
  [255]

Changing evolution level to createmarkers
  $ echo "[experimental]" >> $HGRCPATH
  $ echo "evolution=createmarkers" >> $HGRCPATH

Running split without any revision operates on the parent of the working copy
  $ hg split << EOF
  > q
  > EOF
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  adding _d
  diff --git a/_d b/_d
  new file mode 100644
  examine changes to '_d'? [Ynesfdaq?] q
  
  abort: user quit
  [255]

Running split with tip revision, specified as unnamed argument
  $ hg split . << EOF
  > q
  > EOF
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  adding _d
  diff --git a/_d b/_d
  new file mode 100644
  examine changes to '_d'? [Ynesfdaq?] q
  
  abort: user quit
  [255]

Running split with both unnamed and named revision arguments shows an error msg
  $ hg split . --rev .^ << EOF
  > q
  > EOF
  abort: more than one revset is given
  (use either `hg split <rs>` or `hg split --rev <rs>`, not both)
  [255]

Split empty commit (issue5191)
  $ hg branch new-branch
  marked working directory as branch new-branch
  (branches are permanent and global, did you want a bookmark?)
  $ hg commit -m "empty"
  $ hg split
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
