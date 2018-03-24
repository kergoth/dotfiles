test of the split command
-----------------------

  $ . $TESTDIR/testlib/common.sh

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
  > evolve =
  > EOF
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1" $2 $3
  > }


Basic case, split a head
  $ hg init testsplit
  $ cd testsplit
  $ mkcommit _a
  $ mkcommit _b
  $ mkcommit _c --user other-test-user
  $ mkcommit _d
  $ echo "change to a" >> _a
  $ hg amend
  $ hg debugobsolete
  1334a80b33c3f9873edab728fbbcf500eab61d2e d2fe56e71366c2c5376c89960c281395062c0619 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}

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
  1334a80b33c3f9873edab728fbbcf500eab61d2e d2fe56e71366c2c5376c89960c281395062c0619 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}
  d2fe56e71366c2c5376c89960c281395062c0619 2d8abdb827cdf71ca477ef6985d7ceb257c53c1b 033b3f5ae73db67c10de938fb6f26b949aaef172 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '13', 'operation': 'split', 'user': 'test'}
  $ hg log -G
  @  changeset:   6:033b3f5ae73d
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split2
  |
  o  changeset:   5:2d8abdb827cd
  |  parent:      2:52149352b372
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split1
  |
  o  changeset:   2:52149352b372
  |  user:        other-test-user
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
  $ hg up "desc(_c)" -C
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

Cannot split public changeset

  $ hg phase --rev 'desc("_a")'
  0: draft
  $ hg phase --rev 'desc("_a")' --public
  $ hg split --rev 'desc("_a")'
  abort: cannot split public changesets: 135f39f4bd78
  (see 'hg help phases' for details)
  [255]
  $ hg phase --rev 'desc("_a")' --draft --force

Split a revision specified with -r
  $ echo "change to b" >> _b
  $ hg amend -m "_cprim"
  2 new orphan changesets
  $ hg evolve --all
  move:[5] split1
  atop:[7] _cprim
  move:[6] split2
  atop:[8] split1
  working directory is now at * (glob)
  $ hg log -r "desc(_cprim)" -v -p
  changeset:   7:b434287e665c
  parent:      1:37445b16603b
  user:        other-test-user
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
  2 new orphan changesets

Stop before splitting the commit completely creates a commit with all the
remaining changes

  $ hg debugobsolete
  1334a80b33c3f9873edab728fbbcf500eab61d2e d2fe56e71366c2c5376c89960c281395062c0619 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}
  d2fe56e71366c2c5376c89960c281395062c0619 2d8abdb827cdf71ca477ef6985d7ceb257c53c1b 033b3f5ae73db67c10de938fb6f26b949aaef172 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '13', 'operation': 'split', 'user': 'test'}
  52149352b372d39b19127d5bd2d488b1b63f9f85 b434287e665ce757ee5463a965cb3d119ca9e893 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '9', 'operation': 'amend', 'user': 'test'}
  2d8abdb827cdf71ca477ef6985d7ceb257c53c1b e2b4afde39803bd42bb1374b230fca1b1e8cc868 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '4', 'operation': 'evolve', 'user': 'test'}
  033b3f5ae73db67c10de938fb6f26b949aaef172 bb5e4f6020c74e7961a51fda635ea9df9b04dda8 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '4', 'operation': 'evolve', 'user': 'test'}
  b434287e665ce757ee5463a965cb3d119ca9e893 ead2066d1dbf14833fe1069df1b735e4e9468c40 1188c4216eba37f18a1de6558564601d00ff2143 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '13', 'operation': 'split', 'user': 'test'}
  $ hg evolve --all
  move:[8] split1
  atop:[11] split4
  move:[9] split2
  atop:[12] split1
  working directory is now at d74c6715e706
  $ hg log -G
  @  changeset:   13:d74c6715e706
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split2
  |
  o  changeset:   12:3f134f739075
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split1
  |
  o  changeset:   11:1188c4216eba
  |  user:        other-test-user
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split4
  |
  o  changeset:   10:ead2066d1dbf
  |  parent:      1:37445b16603b
  |  user:        other-test-user
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
     bookA                     14:7a6b35779b85
   * bookB                     14:7a6b35779b85
  $ hg log -G -r "3f134f739075::"
  @  changeset:   14:7a6b35779b85
  |  bookmark:    bookA
  |  bookmark:    bookB
  |  tag:         tip
  |  parent:      12:3f134f739075
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split2
  |
  o  changeset:   12:3f134f739075
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split1
  
  $ hg split --user victor <<EOF
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
  $ hg log -G -r "3f134f739075::"
  @  changeset:   16:452a26648478
  |  bookmark:    bookA
  |  bookmark:    bookB
  |  tag:         tip
  |  user:        victor
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split6
  |
  o  changeset:   15:1315679b77dc
  |  parent:      12:3f134f739075
  |  user:        victor
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split5
  |
  o  changeset:   12:3f134f739075
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split1
  
  $ hg book
     bookA                     16:452a26648478
   * bookB                     16:452a26648478
 
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
  abort: split will orphan 4 descendants
  (see 'hg help evolution.instability')
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

Check that split keeps the right topic

  $ hg up -r tip
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

Add topic to the hgrc

  $ echo "[extensions]" >> $HGRCPATH
  $ echo "topic=$(echo $(dirname $TESTDIR))/hgext3rd/topic/" >> $HGRCPATH
  $ hg topic mytopic
  marked working directory as topic: mytopic
  $ echo babar > babar
  $ echo celeste > celeste
  $ hg add babar celeste
  $ hg commit -m "Works on mytopic" babar celeste --user victor
  active topic 'mytopic' grew its first changeset
  $ hg log -r . 
  changeset:   18:26f72cfaf036
  branch:      new-branch
  tag:         tip
  topic:       mytopic
  user:        victor
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     Works on mytopic
  
  $ hg summary
  parent: 18:26f72cfaf036 tip
   Works on mytopic
  branch: new-branch
  commit: 2 unknown (clean)
  update: (current)
  phases: 9 draft
  topic:  mytopic

Split it

  $ hg split -U << EOF
  > Y
  > Y
  > N
  > Y
  > Y
  > Y
  > EOF
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  adding babar
  adding celeste
  diff --git a/babar b/babar
  new file mode 100644
  examine changes to 'babar'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +babar
  record change 1/2 to 'babar'? [Ynesfdaq?] Y
  
  diff --git a/celeste b/celeste
  new file mode 100644
  examine changes to 'celeste'? [Ynesfdaq?] N
  
  Done splitting? [yN] Y
  diff --git a/celeste b/celeste
  new file mode 100644
  examine changes to 'celeste'? [Ynesfdaq?] Y
  
  @@ -0,0 +1,1 @@
  +celeste
  record this change to 'celeste'? [Ynesfdaq?] Y
  
  no more change to split

Check that the topic is still here

  $ hg log -r "tip~1::"
  changeset:   19:addcf498f19e
  branch:      new-branch
  topic:       mytopic
  parent:      17:fdb403258632
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     split7
  
  changeset:   20:2532b288af61
  branch:      new-branch
  tag:         tip
  topic:       mytopic
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     split8
  
  $ hg topic
   * mytopic (2 changesets)

Test split the first commit on a branch

  $ touch SPLIT1 SPLIT2
  $ hg add SPLIT1 SPLIT2
  $ hg branch another-branch
  marked working directory as branch another-branch
  $ hg commit -m "To be splitted"
  $ hg log -G -l 3
  @  changeset:   21:8dad923bdb9b
  |  branch:      another-branch
  |  tag:         tip
  |  topic:       mytopic
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     To be splitted
  |
  o  changeset:   20:2532b288af61
  |  branch:      new-branch
  |  topic:       mytopic
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split8
  |
  o  changeset:   19:addcf498f19e
  |  branch:      new-branch
  ~  topic:       mytopic
     parent:      17:fdb403258632
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split7
  
  $ hg export .
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Branch another-branch
  # Node ID 8dad923bdb9bb3b99291caa5baeb03bbc30dfd33
  # Parent  2532b288af61bd19239a95ae2a3ecb9b0ad4b8e1
  # EXP-Topic mytopic
  To be splitted
  
  diff --git a/SPLIT1 b/SPLIT1
  new file mode 100644
  diff --git a/SPLIT2 b/SPLIT2
  new file mode 100644

  $ hg split -r . << EOF
  > Y
  > N
  > N
  > Y
  > EOF
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  adding SPLIT1
  adding SPLIT2
  diff --git a/SPLIT1 b/SPLIT1
  new file mode 100644
  examine changes to 'SPLIT1'? [Ynesfdaq?] Y
  
  diff --git a/SPLIT2 b/SPLIT2
  new file mode 100644
  examine changes to 'SPLIT2'? [Ynesfdaq?] N
  
  Done splitting? [yN] N
  diff --git a/SPLIT2 b/SPLIT2
  new file mode 100644
  examine changes to 'SPLIT2'? [Ynesfdaq?] Y
  
  no more change to split

The splitted changesets should be on the 'another-branch'
  $ hg log -G -l 3
  @  changeset:   23:56a59faa8af7
  |  branch:      another-branch
  |  tag:         tip
  |  topic:       mytopic
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split10
  |
  o  changeset:   22:75695e3e2300
  |  branch:      another-branch
  |  topic:       mytopic
  |  parent:      20:2532b288af61
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     split9
  |
  o  changeset:   20:2532b288af61
  |  branch:      new-branch
  ~  topic:       mytopic
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split8
  

Try splitting the first changeset of a branch then cancel

  $ hg branch yet-another-branch
  marked working directory as branch yet-another-branch
  $ touch SPLIT3 SPLIT4
  $ hg add SPLIT3 SPLIT4
  $ hg commit -m "To be splitted again"

  $ hg up "tip~1"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved

  $ hg log -G -l 2
  o  changeset:   24:b1020d17c364
  |  branch:      yet-another-branch
  |  tag:         tip
  |  topic:       mytopic
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     To be splitted again
  |
  @  changeset:   23:56a59faa8af7
  |  branch:      another-branch
  ~  topic:       mytopic
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split10
  
  $ hg branch
  another-branch

  $ hg split -r tip << EOF
  > Y
  > q
  > EOF
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  adding SPLIT3
  adding SPLIT4
  diff --git a/SPLIT3 b/SPLIT3
  new file mode 100644
  examine changes to 'SPLIT3'? [Ynesfdaq?] Y
  
  diff --git a/SPLIT4 b/SPLIT4
  new file mode 100644
  examine changes to 'SPLIT4'? [Ynesfdaq?] q
  
  abort: user quit
  [255]

  $ hg branch
  another-branch

  $ hg log -G -l 2
  o  changeset:   24:b1020d17c364
  |  branch:      yet-another-branch
  |  tag:         tip
  |  topic:       mytopic
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     To be splitted again
  |
  @  changeset:   23:56a59faa8af7
  |  branch:      another-branch
  ~  topic:       mytopic
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     split10
  
