  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > metaedit=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [alias]
  > qlog = log --template='{rev} - {node|short} {desc} ({phase})\n'
  > [diff]
  > git = 1
  > unified = 0
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ mkstack() {
  >    # Creates a stack of commit based on $1 with messages from $2, $3 ..
  >    hg update $1 -C
  >    shift
  >    mkcommits $*
  > }

  $ glog() {
  >   hg glog --template '{rev}:{node|short}@{branch}({phase}) {desc|firstline}\n' "$@"
  > }

  $ shaof() {
  >   hg log -T {node} -r "first(desc($1))"
  > }

  $ mkcommits() {
  >   for i in $@; do mkcommit $i ; done
  > }

Test the evolution test topic is installed

  $ hg help evolution
  Safely Rewriting History
  """"""""""""""""""""""""
  
      Obsolescence markers make it possible to mark changesets that have been
      deleted or superset in a new version of the changeset.
  
      Unlike the previous way of handling such changes, by stripping the old
      changesets from the repository, obsolescence markers can be propagated
      between repositories. This allows for a safe and simple way of exchanging
      mutable history and altering it after the fact. Changeset phases are
      respected, such that only draft and secret changesets can be altered (see
      'hg help phases' for details).
  
      Obsolescence is tracked using "obsolete markers", a piece of metadata
      tracking which changesets have been made obsolete, potential successors
      for a given changeset, the moment the changeset was marked as obsolete,
      and the user who performed the rewriting operation. The markers are stored
      separately from standard changeset data can be exchanged without any of
      the precursor changesets, preventing unnecessary exchange of obsolescence
      data.
  
      The complete set of obsolescence markers describes a history of changeset
      modifications that is orthogonal to the repository history of file
      modifications. This changeset history allows for detection and automatic
      resolution of edge cases arising from multiple users rewriting the same
      part of history concurrently.
  
      Current feature status
      ======================
  
      This feature is still in development.  If you see this help, you have
      enabled an extension that turned this feature on.
  
      Obsolescence markers will be exchanged between repositories that
      explicitly assert support for the obsolescence feature (this can currently
      only be done via an extension).

various init

  $ hg init local
  $ cd local
  $ mkcommit a
  $ mkcommit b
  $ cat >> .hg/hgrc << EOF
  > [phases]
  > publish = True
  > EOF
  $ hg pull -q . # make 1 public
  $ rm .hg/hgrc
  $ mkcommit c
  $ mkcommit d
  $ hg up 1
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit e -q
  created new head
  $ mkcommit f
  $ hg qlog
  5 - e44648563c73 add f (draft)
  4 - fbb94e3a0ecf add e (draft)
  3 - 47d2a3944de8 add d (draft)
  2 - 4538525df7e2 add c (draft)
  1 - 7c3bad9141dc add b (public)
  0 - 1f0dee641bb7 add a (public)

test kill and immutable changeset

  $ hg log -r 1 --template '{rev} {phase} {obsolete}\n'
  1 public 
  $ hg prune 1
  abort: cannot prune immutable changeset: 7c3bad9141dc
  (see 'hg help phases' for details)
  [255]
  $ hg log -r 1 --template '{rev} {phase} {obsolete}\n'
  1 public 

test simple kill

  $ hg id -n
  5
  $ hg prune .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at fbb94e3a0ecf
  1 changesets pruned
  $ hg qlog
  4 - fbb94e3a0ecf add e (draft)
  3 - 47d2a3944de8 add d (draft)
  2 - 4538525df7e2 add c (draft)
  1 - 7c3bad9141dc add b (public)
  0 - 1f0dee641bb7 add a (public)

test multiple kill

  $ hg prune 4 -r 3
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 7c3bad9141dc
  2 changesets pruned
  $ hg qlog
  2 - 4538525df7e2 add c (draft)
  1 - 7c3bad9141dc add b (public)
  0 - 1f0dee641bb7 add a (public)

test kill with dirty changes

  $ hg up 2
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo 4 > g
  $ hg add g
  $ hg prune .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 7c3bad9141dc
  1 changesets pruned
  $ hg st
  A g

Smoketest debugobsrelsethashtree:

  $ hg debugobsrelsethashtree
  1f0dee641bb7258c56bd60e93edfa2405381c41e 0000000000000000000000000000000000000000
  7c3bad9141dcb46ff89abf5f61856facd56e476c * (glob)
  4538525df7e2b9f09423636c61ef63a4cb872a2d * (glob)
  47d2a3944de8b013de3be9578e8e344ea2e6c097 * (glob)
  fbb94e3a0ecf6d20c2cc31152ef162ce45af982f * (glob)
  e44648563c73f75950076031c6fdf06629de95f1 * (glob)

Smoketest stablerange.obshash:

  $ hg debugobshashrange --subranges --rev 'head()'
           rev         node        index         size        depth      obshash
             1 7c3bad9141dc            0            2            2 * (glob)
             0 1f0dee641bb7            0            1            1 000000000000
             1 7c3bad9141dc            1            1            2 * (glob)

  $ cd ..

##########################
importing Parren test
##########################

  $ cat << EOF >> $HGRCPATH
  > [ui]
  > logtemplate = "{rev}\t{bookmarks}: {desc|firstline} - {author|user}\n"
  > EOF

Creating And Updating Changeset
===============================

Setup the Base Repo
-------------------

We start with a plain base repo::

  $ hg init main; cd main
  $ cat >main-file-1 <<-EOF
  > One
  > 
  > Two
  > 
  > Three
  > EOF
  $ echo Two >main-file-2
  $ hg add
  adding main-file-1
  adding main-file-2
  $ hg commit --message base
  $ cd ..

and clone this into a new repo where we do our work::

  $ hg clone main work
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd work


Create First Patch
------------------

To begin with, we just do the changes that will be the initial version of the changeset::

  $ echo One >file-from-A
  $ sed -i'' -e s/One/Eins/ main-file-1
  $ hg add file-from-A

So this is what we would like our changeset to be::

  $ hg diff
  diff --git a/file-from-A b/file-from-A
  new file mode 100644
  --- /dev/null
  +++ b/file-from-A
  @@ -0,0 +1,1 @@
  +One
  diff --git a/main-file-1 b/main-file-1
  --- a/main-file-1
  +++ b/main-file-1
  @@ -1,1 +1,1 @@
  -One
  +Eins

To commit it we just - commit it::

  $ hg commit --message "a nifty feature"

and place a bookmark so we can easily refer to it again (which we could have done before the commit)::

  $ hg book feature-A


Create Second Patch
-------------------

Let's do this again for the second changeset::

  $ echo Two >file-from-B
  $ sed -i'' -e s/Two/Zwie/ main-file-1
  $ hg add file-from-B

Before committing, however, we need to switch to a new bookmark for the second
changeset. Otherwise we would inadvertently move the bookmark for our first changeset.
It is therefore advisable to always set the bookmark before committing::

  $ hg book feature-B
  $ hg commit --message "another feature (child of $(hg log -r . -T '{node|short}'))"

So here we are::

  $ hg book
     feature-A                 1:568a468b60fc
   * feature-B                 2:73296a82292a


Fix The Second Patch
--------------------

There's a typo in feature-B. We spelled *Zwie* instead of *Zwei*::

  $ hg diff --change tip | grep -F Zwie
  +Zwie

Fixing this is very easy. Just change::

  $ sed -i'' -e s/Zwie/Zwei/ main-file-1

and **amend**::

  $ hg amend

This results in a new single changeset for our amended changeset, and the old
changeset plus the updating changeset are hidden from view by default::

  $ hg log
  4	feature-B: another feature (child of 568a468b60fc) - test
  1	feature-A: a nifty feature - test
  0	: base - test

  $ hg up feature-A -q
  $ hg bookmark -i feature-A
  $ sed -i'' -e s/Eins/Un/ main-file-1

(amend of public changeset denied)

  $ hg phase --public 0 -v
  phase changed for 1 changesets


(amend of on ancestors)

  $ hg amend
  1 new unstable changesets
  $ hg log
  6	feature-A: a nifty feature - test
  4	feature-B: another feature (child of 568a468b60fc) - test
  1	: a nifty feature - test
  0	: base - test
  $ hg up -q 0
  $ glog --hidden
  o  6:ba0ec09b1bab@default(draft) a nifty feature
  |
  | x  5:c296b79833d1@default(draft) temporary amend commit for 568a468b60fc
  | |
  | | o  4:6992c59c6b06@default(draft) another feature (child of 568a468b60fc)
  | |/
  | | x  3:c97947cdc7a2@default(draft) temporary amend commit for 73296a82292a
  | | |
  | | x  2:73296a82292a@default(draft) another feature (child of 568a468b60fc)
  | |/
  | x  1:568a468b60fc@default(draft) a nifty feature
  |/
  @  0:e55e0562ee93@default(public) base
  
  $ hg debugobsolete
  73296a82292a76fb8a7061969d2489ec0d84cd5e 6992c59c6b06a1b4a92e24ff884829ae026d018b 0 (*) {'ef1': '8', 'user': 'test'} (glob)
  c97947cdc7a2a11cf78419f5c2c3dd3944ec79e8 0 {73296a82292a76fb8a7061969d2489ec0d84cd5e} (*) {'ef1': '0', 'user': 'test'} (glob)
  568a468b60fc99a42d5d4ddbe181caff1eef308d ba0ec09b1babf3489b567853807f452edd46704f 0 (*) {'ef1': '8', 'user': 'test'} (glob)
  c296b79833d1d497f33144786174bf35e04e44a3 0 {568a468b60fc99a42d5d4ddbe181caff1eef308d} (*) {'ef1': '0', 'user': 'test'} (glob)
  $ hg evolve
  move:[4] another feature (child of 568a468b60fc)
  atop:[6] a nifty feature
  merging main-file-1
  working directory is now at 99833d22b0c6
  $ hg log
  7	feature-B: another feature (child of ba0ec09b1bab) - test
  6	feature-A: a nifty feature - test
  0	: base - test

Test commit -o options

  $ hg up 6
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg revert -r 7 --all
  adding file-from-B
  reverting main-file-1
  $ sed -i'' -e s/Zwei/deux/ main-file-1
  $ hg commit -m 'another feature that rox' -o 7
  created new head
  $ hg log
  8	feature-B: another feature that rox - test
  6	feature-A: a nifty feature - test
  0	: base - test

phase change turning obsolete changeset public issue a bumped warning

  $ hg phase --hidden --public 7
  1 new bumped changesets

all solving bumped troubled

  $ hg glog
  @  8	feature-B: another feature that rox - test
  |
  | o  7	: another feature (child of ba0ec09b1bab) - test
  |/
  o  6	feature-A: a nifty feature - test
  |
  o  0	: base - test
  
  $ hg evolve --any --traceback --bumped
  recreate:[8] another feature that rox
  atop:[7] another feature (child of ba0ec09b1bab)
  computing new diff
  committed as 6707c5e1c49d
  working directory is now at 6707c5e1c49d
  $ hg glog
  @  9	feature-B: bumped update to 99833d22b0c6: - test
  |
  o  7	: another feature (child of ba0ec09b1bab) - test
  |
  o  6	feature-A: a nifty feature - test
  |
  o  0	: base - test
  
  $ hg diff --hidden -r 9 -r 8
  $ hg diff -r 9^ -r 9
  diff --git a/main-file-1 b/main-file-1
  --- a/main-file-1
  +++ b/main-file-1
  @@ -3,1 +3,1 @@
  -Zwei
  +deux
  $ hg log -r 'bumped()' # no more bumped

test evolve --all
  $ sed -i'' -e s/deux/to/ main-file-1
  $ hg commit -m 'dansk 2!'
  $ sed -i'' -e s/Three/tre/ main-file-1
  $ hg commit -m 'dansk 3!'
  $ hg update 9
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ sed -i'' -e s/Un/Én/ main-file-1
  $ hg commit --amend -m 'dansk!'
  2 new unstable changesets

(ninja test for the {trouble} template:

  $ hg log -G --template '{rev} {troubles}\n'
  @  13
  |
  | o  11 unstable
  | |
  | o  10 unstable
  | |
  | x  9
  |/
  o  7
  |
  o  6
  |
  o  0
  


(/ninja)

  $ hg evolve --all --traceback
  move:[10] dansk 2!
  atop:[13] dansk!
  merging main-file-1
  move:[11] dansk 3!
  atop:[14] dansk 2!
  merging main-file-1
  working directory is now at 68557e4f0048
  $ hg glog
  @  15	: dansk 3! - test
  |
  o  14	: dansk 2! - test
  |
  o  13	feature-B: dansk! - test
  |
  o  7	: another feature (child of ba0ec09b1bab) - test
  |
  o  6	feature-A: a nifty feature - test
  |
  o  0	: base - test
  

  $ cd ..

enable general delta

  $ cat << EOF >> $HGRCPATH
  > [format]
  > generaldelta=1
  > EOF



  $ hg init alpha
  $ cd alpha
  $ echo 'base' > firstfile
  $ hg add firstfile
  $ hg ci -m 'base'

  $ cd ..
  $ hg clone -Ur 0 alpha beta
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ cd alpha

  $ cat << EOF > A
  > We
  > need
  > some
  > kind
  > of 
  > file
  > big
  > enough
  > to
  > prevent
  > snapshot
  > .
  > yes
  > new
  > lines
  > are
  > useless
  > .
  > EOF
  $ hg add A
  $ hg commit -m 'adding A'
  $ hg mv A B
  $ echo '.' >> B
  $ hg amend -m 'add B'
  $ hg verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  3 files, 4 changesets, 4 total revisions
  $ hg --config extensions.hgext.mq= strip 'extinct()'
  abort: empty revision set
  [255]
(do some garbare collection)
  $ hg --config extensions.hgext.mq= strip --hidden 'extinct()'  --config devel.strip-obsmarkers=no
  saved backup bundle to $TESTTMP/alpha/.hg/strip-backup/e87767087a57-d7bd82e9-backup.hg (glob)
  $ hg verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  2 files, 2 changesets, 2 total revisions
  $ cd ..

Clone just this branch

  $ cd beta
  $ hg pull -r tip ../alpha
  pulling from ../alpha
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  2 new obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg up
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ cd ..

Test graft --obsolete/--old-obsolete

  $ hg init test-graft
  $ cd test-graft
  $ mkcommit 0
  $ mkcommit 1
  $ mkcommit 2
  $ mkcommit 3
  $ hg up -qC 0
  $ mkcommit 4
  created new head
  $ glog --hidden
  @  4:ce341209337f@default(draft) add 4
  |
  | o  3:0e84df4912da@default(draft) add 3
  | |
  | o  2:db038628b9e5@default(draft) add 2
  | |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(draft) add 0
  
  $ hg graft -r3 -O
  grafting 3:0e84df4912da "add 3"
  $ hg graft -r1 -o 2
  grafting 1:73d38bb17fd7 "add 1"
  $ glog --hidden
  @  6:acb28cd497b7@default(draft) add 1
  |
  o  5:0b9e50c35132@default(draft) add 3
  |
  o  4:ce341209337f@default(draft) add 4
  |
  | x  3:0e84df4912da@default(draft) add 3
  | |
  | x  2:db038628b9e5@default(draft) add 2
  | |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(draft) add 0
  
  $ hg debugobsolete
  0e84df4912da4c7cad22a3b4fcfd58ddfb7c8ae9 0b9e50c35132ff548ec0065caea6a87e1ebcef32 0 (*) {'ef1': '4', 'user': 'test'} (glob)
  db038628b9e56f51a454c0da0c508df247b41748 acb28cd497b7f8767e01ef70f68697a959573c2d 0 (*) {'ef1': '13', 'user': 'test'} (glob)

Test graft --continue

  $ hg up -qC 0
  $ echo 2 > 1
  $ hg ci -Am conflict 1
  created new head
  $ hg up -qC 6
  $ hg graft -O 7
  grafting 7:a5bfd90a2f29 "conflict" (tip)
  merging 1
  warning: conflicts while merging 1! (edit, then use 'hg resolve --mark')
  abort: unresolved conflicts, can't continue
  (use 'hg resolve' and 'hg graft --continue')
  [255]
  $ hg log -r7 --template '{rev}:{node|short} {obsolete}\n'
  7:a5bfd90a2f29 
  $ echo 3 > 1
  $ hg resolve -m 1
  (no more unresolved files)
  continue: hg graft --continue
  $ hg graft --continue -O
  grafting 7:a5bfd90a2f29 "conflict" (tip)
  $ glog --hidden
  @  8:920e58bb443b@default(draft) conflict
  |
  | x  7:a5bfd90a2f29@default(draft) conflict
  | |
  o |  6:acb28cd497b7@default(draft) add 1
  | |
  o |  5:0b9e50c35132@default(draft) add 3
  | |
  o |  4:ce341209337f@default(draft) add 4
  |/
  | x  3:0e84df4912da@default(draft) add 3
  | |
  | x  2:db038628b9e5@default(draft) add 2
  | |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(draft) add 0
  
  $ hg debugobsolete
  0e84df4912da4c7cad22a3b4fcfd58ddfb7c8ae9 0b9e50c35132ff548ec0065caea6a87e1ebcef32 0 (*) {'ef1': '4', 'user': 'test'} (glob)
  db038628b9e56f51a454c0da0c508df247b41748 acb28cd497b7f8767e01ef70f68697a959573c2d 0 (*) {'ef1': '13', 'user': 'test'} (glob)
  a5bfd90a2f29c7ccb8f917ff4e5013a9053d0a04 920e58bb443b73eea9d6d65570b4241051ea3229 0 (*) {'ef1': '12', 'user': 'test'} (glob)

Test touch

  $ glog
  @  8:920e58bb443b@default(draft) conflict
  |
  o  6:acb28cd497b7@default(draft) add 1
  |
  o  5:0b9e50c35132@default(draft) add 3
  |
  o  4:ce341209337f@default(draft) add 4
  |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(draft) add 0
  
  $ hg touch
  $ glog
  @  9:*@default(draft) conflict (glob)
  |
  o  6:acb28cd497b7@default(draft) add 1
  |
  o  5:0b9e50c35132@default(draft) add 3
  |
  o  4:ce341209337f@default(draft) add 4
  |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(draft) add 0
  
  $ hg touch .
  $ glog
  @  10:*@default(draft) conflict (glob)
  |
  o  6:acb28cd497b7@default(draft) add 1
  |
  o  5:0b9e50c35132@default(draft) add 3
  |
  o  4:ce341209337f@default(draft) add 4
  |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(draft) add 0
  

Test fold

  $ rm *.orig
  $ hg fold
  abort: no revisions specified
  [255]
  $ hg fold --from
  abort: no revisions specified
  [255]
  $ hg fold .
  abort: must specify either --from or --exact
  [255]
  $ hg fold --from . --exact
  abort: cannot use both --from and --exact
  [255]
  $ hg fold --from .
  single revision specified, nothing to fold
  [1]
  $ hg fold 0::10 --rev 1 --exact
  abort: cannot fold non-linear revisions (multiple heads given)
  [255]
  $ hg fold -r 4 -r 6 --exact
  abort: cannot fold non-linear revisions (multiple roots given)
  [255]
  $ hg fold --from 10 1
  abort: cannot fold non-linear revisions
  (given revisions are unrelated to parent of working directory)
  [255]
  $ hg fold --exact -r "4 and not 4"
  abort: specified revisions evaluate to an empty set
  (use different revision arguments)
  [255]
  $ hg phase --public 0
  $ hg fold --from -r 0
  abort: cannot fold public revisions
  [255]
  $ hg fold --from -r 5
  3 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg fold --from 6 # want to run hg fold 6
  abort: hidden revision '6'!
  (use --hidden to access hidden revisions; successor: af636757ce3b)
  [255]
  $ hg log -r 11 --template '{desc}\n'
  add 3
  
  
  add 1
  
  
  conflict
  $ hg debugrebuildstate
  $ hg st

Test fold with wc parent is not the head of the folded revision

  $ hg up 4
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg fold --rev 4::11 --user victor --exact
  2 changesets folded
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ glog
  @  12:d26d339c513f@default(draft) add 4
  |
  | o  1:73d38bb17fd7@default(draft) add 1
  |/
  o  0:8685c6d34325@default(public) add 0
  
  $ hg log --template '{rev}: {author}\n'
  12: victor
  1: test
  0: test
  $ hg log -r 12 --template '{desc}\n'
  add 4
  
  
  add 3
  
  
  add 1
  
  
  conflict
  $ hg debugrebuildstate
  $ hg st

Test olog

  $ hg olog | head -n 10 # hg touch makes the output unstable (fix it with devel option for more stable touch)
  @    d26d339c513f (12) add 4
  |\
  x |    af636757ce3b (11) add 3
  |\ \     rewritten(description, user, parent, content) by test (*) as d26d339c513f (glob)
  | | |
  | \ \
  | |\ \
  | | | x  ce341209337f (4) add 4
  | | |      rewritten(description, user, content) by test (*) as d26d339c513f (glob)
  | | |

Test obsstore stat

  $ hg debugobsstorestat
  markers total:                     10
      for known precursors:          10 (10/13 obsolete changesets)
      with parents data:              0
  markers with no successors:         0
                1 successors:        10
                2 successors:         0
      more than 2 successors:         0
      available  keys:
                  ef1:               10
                 user:               10
  marker size:
      format v1:
          smallest length:           75
          longer length:             76
          median length:             76
          mean length:               75
      format v0:
          smallest length:           * (glob)
          longer length:             * (glob)
          median length:             * (glob)
          mean length:               * (glob)
  disconnected clusters:              1
          any known node:             1
          smallest length:           10
          longer length:             10
          median length:             10
          mean length:               10
      using parents data:             1
          any known node:             1
          smallest length:           10
          longer length:             10
          median length:             10
          mean length:               10


Test evolving renames

  $ hg up null
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ echo a > a
  $ hg ci -Am a
  adding a
  created new head
  $ echo b > b
  $ hg ci -Am b
  adding b
  $ hg mv a c
  $ hg ci -m c
  $ hg prune .^
  1 changesets pruned
  1 new unstable changesets
  $ hg stab --any
  move:[15] c
  atop:[13] a
  working directory is now at 3742bde73477
  $ hg st -C --change=tip
  A c
    a
  R a

Test fold with commit messages

  $ cd ../work
  $ hg fold --from .^ --message "Folding with custom commit message"
  2 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ glog
  @  16:98cb758db56d@default(draft) Folding with custom commit message
  |
  o  13:0a2f9b959bb4@default(draft) dansk!
  |
  o  7:99833d22b0c6@default(public) another feature (child of ba0ec09b1bab)
  |
  o  6:ba0ec09b1bab@default(public) a nifty feature
  |
  o  0:e55e0562ee93@default(public) base
  
  $ cat > commit-message <<EOF
  > A longer
  >                   commit message
  > EOF

  $ hg fold --from .^ --logfile commit-message
  2 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg qlog
  17 - a00182c58888 A longer
                    commit message (draft)
  7 - 99833d22b0c6 another feature (child of ba0ec09b1bab) (public)
  6 - ba0ec09b1bab a nifty feature (public)
  0 - e55e0562ee93 base (public)

  $ cd ..

Test branch preservation:
===========================

  $ hg init evolving-branch
  $ cd evolving-branch
  $ touch a
  $ hg add a
  $ hg ci -m 'a0'
  $ echo 1 > a
  $ hg ci -m 'a1'
  $ echo 2 > a
  $ hg ci -m 'a2'
  $ echo 3 > a
  $ hg ci -m 'a3'

  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  @  3 [default] a3
  |
  o  2 [default] a2
  |
  o  1 [default] a1
  |
  o  0 [default] a0
  

branch change propagated

  $ hg up 'desc(a2)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg branch mybranch
  marked working directory as branch mybranch
  (branches are permanent and global, did you want a bookmark?)
  $ hg amend
  1 new unstable changesets

  $ hg evolve
  move:[3] a3
  atop:[5] a2
  working directory is now at 7c5649f73d11

  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  @  6 [mybranch] a3
  |
  o  5 [mybranch] a2
  |
  o  1 [default] a1
  |
  o  0 [default] a0
  

branch change preserved

  $ hg up 'desc(a1)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg amend -m 'a1_'
  2 new unstable changesets
  $ hg evolve
  move:[5] a2
  atop:[7] a1_
  working directory is now at eb07e22a0e63
  $ hg evolve
  move:[6] a3
  atop:[8] a2
  working directory is now at 777c26ca5e78
  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  @  9 [mybranch] a3
  |
  o  8 [mybranch] a2
  |
  o  7 [default] a1_
  |
  o  0 [default] a0
  

Evolve from the middle of a stack pick the right changesets.

  $ hg up 7
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg ci --amend -m 'a1__'
  2 new unstable changesets

  $ hg up 8
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  o  10 [default] a1__
  |
  | o  9 [mybranch] a3
  | |
  | @  8 [mybranch] a2
  | |
  | x  7 [default] a1_
  |/
  o  0 [default] a0
  
  $ hg evolve
  nothing to evolve on current working copy parent
  (2 other unstable in the repository, do you want --any or --rev)
  [2]


Evolve disables active bookmarks.

  $ hg up 10
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg bookmark testbookmark
  $ ls .hg/bookmarks*
  .hg/bookmarks
  .hg/bookmarks.* (glob)
  $ hg evolve
  move:[8] a2
  atop:[10] a1__
  (leaving bookmark testbookmark)
  working directory is now at d952e93add6f
  $ ls .hg/bookmarks*
  .hg/bookmarks

Possibility to select what trouble to solve first, asking for bumped before
divergent
  $ hg up 10
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg revert -r 11 --all
  reverting a
  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  o  11 [mybranch] a2
  |
  @  10 [default] a1__
  |
  | o  9 [mybranch] a3
  | |
  | x  8 [mybranch] a2
  | |
  | x  7 [default] a1_
  |/
  o  0 [default] a0
  
  $ echo "hello world" > newfile
  $ hg add newfile
  $ hg commit -m "add new file bumped" -o 11
  $ hg phase --public --hidden 11
  1 new bumped changesets
  $ hg glog
  @  12	: add new file bumped - test
  |
  | o  11	: a2 - test
  |/
  o  10	testbookmark: a1__ - test
  |
  | o  9	: a3 - test
  | |
  | x  8	: a2 - test
  | |
  | x  7	: a1_ - test
  |/
  o  0	: a0 - test
  

Now we have a bumped and an unstable changeset, we solve the bumped first
normally the unstable changeset would be solve first

  $ hg glog
  @  12	: add new file bumped - test
  |
  | o  11	: a2 - test
  |/
  o  10	testbookmark: a1__ - test
  |
  | o  9	: a3 - test
  | |
  | x  8	: a2 - test
  | |
  | x  7	: a1_ - test
  |/
  o  0	: a0 - test
  
  $ hg evolve -r 12 --bumped
  recreate:[12] add new file bumped
  atop:[11] a2
  computing new diff
  committed as f15d32934071
  working directory is now at f15d32934071
  $ hg evolve --any
  move:[9] a3
  atop:[13] bumped update to d952e93add6f:
  working directory is now at cce26b684bfe
Check that we can resolve troubles in a revset with more than one commit
  $ hg up 14 -C
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ mkcommit gg
  $ hg up 14 
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit gh
  created new head
  $ hg up 14 
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ printf "newline\nnewline\n" >> a
  $ hg glog
  o  16	: add gh - test
  |
  | o  15	: add gg - test
  |/
  @  14	: a3 - test
  |
  o  13	: bumped update to d952e93add6f: - test
  |
  o  11	: a2 - test
  |
  o  10	testbookmark: a1__ - test
  |
  o  0	: a0 - test
  
  $ hg amend
  2 new unstable changesets
  $ hg glog
  @  18	: a3 - test
  |
  | o  16	: add gh - test
  | |
  | | o  15	: add gg - test
  | |/
  | x  14	: a3 - test
  |/
  o  13	: bumped update to d952e93add6f: - test
  |
  o  11	: a2 - test
  |
  o  10	testbookmark: a1__ - test
  |
  o  0	: a0 - test
  

Evolving an empty revset should do nothing
  $ hg evolve --rev "16 and 15"
  set of specified revisions is empty
  [1]

  $ hg evolve --rev "14::" --bumped
  no bumped changesets in specified revisions
  (do you want to use --unstable)
  [2]
  $ hg evolve --rev "14::" --unstable
  move:[15] add gg
  atop:[18] a3
  move:[16] add gh
  atop:[18] a3
  working directory is now at e02107f98737
  $ hg glog
  @  20	: add gh - test
  |
  | o  19	: add gg - test
  |/
  o  18	: a3 - test
  |
  o  13	: bumped update to d952e93add6f: - test
  |
  o  11	: a2 - test
  |
  o  10	testbookmark: a1__ - test
  |
  o  0	: a0 - test
  
Enabling commands selectively, no command enabled, next and fold and unknown
  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=createmarkers
  > EOF
  $ hg next
  hg: unknown command 'next'
  Mercurial Distributed SCM
  
  basic commands:
  
   add           add the specified files on the next commit
   annotate      show changeset information by line for each file
   clone         make a copy of an existing repository
   commit        commit the specified files or all outstanding changes
   diff          diff repository (or selected files)
   export        dump the header and diffs for one or more changesets
   forget        forget the specified files on the next commit
   init          create a new repository in the given directory
   log           show revision history of entire repository or files
   merge         merge another revision into working directory
   pull          pull changes from the specified source
   push          push changes to the specified destination
   remove        remove the specified files on the next commit
   serve         start stand-alone webserver
   status        show changed files in the working directory
   summary       summarize working directory state
   update        update working directory (or switch revisions)
  
  (use 'hg help' for the full list of commands or 'hg -v' for details)
  [255]
  $ hg fold
  hg: unknown command 'fold'
  Mercurial Distributed SCM
  
  basic commands:
  
   add           add the specified files on the next commit
   annotate      show changeset information by line for each file
   clone         make a copy of an existing repository
   commit        commit the specified files or all outstanding changes
   diff          diff repository (or selected files)
   export        dump the header and diffs for one or more changesets
   forget        forget the specified files on the next commit
   init          create a new repository in the given directory
   log           show revision history of entire repository or files
   merge         merge another revision into working directory
   pull          pull changes from the specified source
   push          push changes to the specified destination
   remove        remove the specified files on the next commit
   serve         start stand-alone webserver
   status        show changed files in the working directory
   summary       summarize working directory state
   update        update working directory (or switch revisions)
  
  (use 'hg help' for the full list of commands or 'hg -v' for details)
  [255]
Enabling commands selectively, only fold enabled, next is still unknown
  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=createmarkers
  > evolutioncommands=fold
  > EOF
  $ hg fold
  abort: no revisions specified
  [255]
  $ hg next
  hg: unknown command 'next'
  Mercurial Distributed SCM
  
  basic commands:
  
   add           add the specified files on the next commit
   annotate      show changeset information by line for each file
   clone         make a copy of an existing repository
   commit        commit the specified files or all outstanding changes
   diff          diff repository (or selected files)
   export        dump the header and diffs for one or more changesets
   fold          fold multiple revisions into a single one
   forget        forget the specified files on the next commit
   init          create a new repository in the given directory
   log           show revision history of entire repository or files
   merge         merge another revision into working directory
   pull          pull changes from the specified source
   push          push changes to the specified destination
   remove        remove the specified files on the next commit
   serve         start stand-alone webserver
   status        show changed files in the working directory
   summary       summarize working directory state
   update        update working directory (or switch revisions)
  
  (use 'hg help' for the full list of commands or 'hg -v' for details)
  [255]

Restore all of the evolution features

  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=all
  > EOF

Check hg evolve --rev on singled out commit
  $ hg up 19 -C
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit j1
  $ mkcommit j2
  $ mkcommit j3
  $ hg up .^^
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo "hello" > j4
  $ hg add j4
  $ hg amend
  2 new unstable changesets
  $ glog -r "18::"
  @  25:8dc373be86d9@default(draft) add j1
  |
  | o  23:d7eadcf6eccd@default(draft) add j3
  | |
  | o  22:2223ea564144@default(draft) add j2
  | |
  | x  21:48490698b269@default(draft) add j1
  |/
  | o  20:e02107f98737@default(draft) add gh
  | |
  o |  19:24e63b319adf@default(draft) add gg
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~

  $ hg evolve --rev 23 --any
  abort: cannot specify both "--rev" and "--any"
  [255]
  $ hg evolve --rev 23
  cannot solve instability of d7eadcf6eccd, skipping

Check that uncommit respects the allowunstable option
With only createmarkers we can only uncommit on a head
  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=createmarkers, allnewcommands
  > EOF
  $ hg up 8dc373be86d9^
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg uncommit --all
  abort: cannot uncommit in the middle of a stack
  [255]
  $ hg up 8dc373be86d9
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg uncommit --all
  new changeset is empty
  (use 'hg prune .' to remove it)
  $ glog -r "18::"
  @  26:044804d0c10d@default(draft) add j1
  |
  | o  23:d7eadcf6eccd@default(draft) add j3
  | |
  | o  22:2223ea564144@default(draft) add j2
  | |
  | x  21:48490698b269@default(draft) add j1
  |/
  | o  20:e02107f98737@default(draft) add gh
  | |
  o |  19:24e63b319adf@default(draft) add gg
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~

Check that prune respects the allowunstable option
  $ hg up -C .
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up 20
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg evolve --all
  nothing to evolve on current working copy parent
  (2 other unstable in the repository, do you want --any or --rev)
  [2]
  $ hg evolve --all --any
  move:[22] add j2
  atop:[26] add j1
  move:[23] add j3
  atop:[27] add j2
  working directory is now at c9a20e2d74aa
  $ glog -r "18::"
  @  28:c9a20e2d74aa@default(draft) add j3
  |
  o  27:b0e3066231e2@default(draft) add j2
  |
  o  26:044804d0c10d@default(draft) add j1
  |
  | o  20:e02107f98737@default(draft) add gh
  | |
  o |  19:24e63b319adf@default(draft) add gg
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~
  $ hg up 19
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit c5_
  created new head
  $ hg prune '26 + 27'
  abort: cannot prune in the middle of a stack
  (new unstable changesets are not allowed)
  [255]
  $ hg prune '19::28'
  abort: cannot prune in the middle of a stack
  (new unstable changesets are not allowed)
  [255]
  $ hg prune '26::'
  3 changesets pruned
  $ glog -r "18::"
  @  29:2251801b6c91@default(draft) add c5_
  |
  | o  20:e02107f98737@default(draft) add gh
  | |
  o |  19:24e63b319adf@default(draft) add gg
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~

Check that fold respects the allowunstable option
  $ hg up edc3c9de504e
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit unstableifparentisfolded
  created new head
  $ glog -r "18::"
  @  30:68330ac625b8@default(draft) add unstableifparentisfolded
  |
  | o  29:2251801b6c91@default(draft) add c5_
  | |
  +---o  20:e02107f98737@default(draft) add gh
  | |
  | o  19:24e63b319adf@default(draft) add gg
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~

  $ hg fold --exact "19 + 18"
  abort: cannot fold chain not ending with a head or with branching
  (new unstable changesets are not allowed)
  [255]
  $ hg fold --exact "18::29"
  abort: cannot fold chain not ending with a head or with branching
  (new unstable changesets are not allowed)
  [255]
  $ hg fold --exact "19::"
  2 changesets folded

Check that evolve shows error while handling split commits
--------------------------------------

  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=all
  > EOF

  $ glog -r "18::"
  o  31:580886d07058@default(draft) add gg
  |
  | @  30:68330ac625b8@default(draft) add unstableifparentisfolded
  |/
  | o  20:e02107f98737@default(draft) add gh
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~

Create a split commit
  $ printf "oo" > oo;
  $ printf "pp" > pp;
  $ hg add oo pp
  $ hg commit -m "oo+pp"
  $ mkcommit uu
  $ hg up 30
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ printf "oo" > oo;
  $ hg add oo
  $ hg commit -m "_oo"
  created new head
  $ printf "pp" > pp;
  $ hg add pp
  $ hg commit -m "_pp"
  $ hg prune --succ "desc(_oo) + desc(_pp)" -r "desc('oo+pp')" --split
  1 changesets pruned
  1 new unstable changesets
  $ glog -r "18::"
  @  35:7a555adf2b4a@default(draft) _pp
  |
  o  34:2be4d2d5bf34@default(draft) _oo
  |
  | o  33:53f0c003e03e@default(draft) add uu
  | |
  | x  32:1bf2152f4f82@default(draft) oo+pp
  |/
  | o  31:580886d07058@default(draft) add gg
  | |
  o |  30:68330ac625b8@default(draft) add unstableifparentisfolded
  |/
  | o  20:e02107f98737@default(draft) add gh
  |/
  o  18:edc3c9de504e@default(draft) a3
  |
  ~
  $ hg evolve --rev "18::"
  move:[33] add uu
  atop:[35] _pp
  working directory is now at 43c3f5ef149f


Check that dirstate changes are kept at failure for conflicts (issue4966)
----------------------------------------

  $ echo "will be amended" > newfile
  $ hg commit -m "will be amended"
  $ hg parents
  37	: will be amended - test

  $ echo "will be evolved safely" >> a
  $ hg commit -m "will be evolved safely"

  $ echo "will cause conflict at evolve" > newfile
  $ echo "newly added" > newlyadded
  $ hg add newlyadded
  $ hg commit -m "will cause conflict at evolve"

  $ hg update -q 37
  $ echo "amended" > newfile
  $ hg amend -m "amended"
  2 new unstable changesets

  $ hg evolve --rev "37::"
  move:[38] will be evolved safely
  atop:[41] amended
  move:[39] will cause conflict at evolve
  atop:[42] will be evolved safely
  merging newfile
  warning: conflicts while merging newfile! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ glog -r "36::" --hidden
  @  42:c904da5245b0@default(draft) will be evolved safely
  |
  o  41:34ae045ec400@default(draft) amended
  |
  | x  40:e88bee38ffc2@default(draft) temporary amend commit for 36030b147271
  | |
  | | o  39:02e943732647@default(draft) will cause conflict at evolve
  | | |
  | | x  38:f8e30e9317aa@default(draft) will be evolved safely
  | |/
  | x  37:36030b147271@default(draft) will be amended
  |/
  o  36:43c3f5ef149f@default(draft) add uu
  |
  ~

  $ hg status newlyadded
  A newlyadded
