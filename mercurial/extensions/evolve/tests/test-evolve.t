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
  >   hg log -G --template '{rev}:{node|short}@{branch}({phase}) {desc|firstline}\n' "$@"
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
  
      Instability ==========
  
      (note: the vocabulary is in the process of being updated)
  
      Rewriting changesets might introduce instability (currently 'trouble').
  
      There are two main kinds of instability: orphaning and diverging.
  
      Orphans are changesets left behind when their ancestors are rewritten,
      (currently: 'unstable'). Divergence has two variants:
  
      * Content-divergence occurs when independent rewrites of the same
        changesets lead to different results. (currently: 'divergent')
      * Phase-divergence occurs when the old (obsolete) version of a changeset
        becomes public. (currently: 'bumped')
  
      If it possible to prevent local creation of orphans by using the following
      config:
  
        [experimental]
        evolution=createmarkers,allnewcommands,exchange
  
      You can also enable that option explicitly:
  
        [experimental]
        evolution=createmarkers,allnewcommands,allowunstable,exchange
  
      or simply:
  
        [experimental]
        evolution=all

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
  abort: cannot touch public changesets: 7c3bad9141dc
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
  3	feature-B: another feature (child of 568a468b60fc) - test
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
  1 new orphan changesets
  $ hg log
  4	feature-A: a nifty feature - test
  3	feature-B: another feature (child of 568a468b60fc) - test
  1	: a nifty feature - test
  0	: base - test
  $ hg up -q 0
  $ glog --hidden
  o  4:ba0ec09b1bab@default(draft) a nifty feature
  |
  | o  3:6992c59c6b06@default(draft) another feature (child of 568a468b60fc)
  | |
  | | x  2:73296a82292a@default(draft) another feature (child of 568a468b60fc)
  | |/
  | x  1:568a468b60fc@default(draft) a nifty feature
  |/
  @  0:e55e0562ee93@default(public) base
  
  $ hg debugobsolete
  73296a82292a76fb8a7061969d2489ec0d84cd5e 6992c59c6b06a1b4a92e24ff884829ae026d018b 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}
  568a468b60fc99a42d5d4ddbe181caff1eef308d ba0ec09b1babf3489b567853807f452edd46704f 0 (Thu Jan 01 00:00:00 1970 +0000) {'ef1': '8', 'operation': 'amend', 'user': 'test'}
  $ hg evolve
  move:[3] another feature (child of 568a468b60fc)
  atop:[4] a nifty feature
  merging main-file-1
  working directory is now at 99833d22b0c6
  $ hg log
  5	feature-B: another feature (child of ba0ec09b1bab) - test
  4	feature-A: a nifty feature - test
  0	: base - test

Test commit -o options

  $ hg up -r "desc('a nifty feature')"
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg revert -r "desc('another feature')" --all
  adding file-from-B
  reverting main-file-1
  $ sed -i'' -e s/Zwei/deux/ main-file-1
  $ hg commit -m 'another feature that rox' -o 5
  created new head
  $ hg log
  6	feature-B: another feature that rox - test
  4	feature-A: a nifty feature - test
  0	: base - test

phase change turning obsolete changeset public issue a bumped warning

  $ hg phase --hidden --public 99833d22b0c6
  1 new phase-divergent changesets

all solving bumped troubled

  $ glog
  @  6:47d52a103155@default(draft) another feature that rox
  |
  | o  5:99833d22b0c6@default(public) another feature (child of ba0ec09b1bab)
  |/
  o  4:ba0ec09b1bab@default(public) a nifty feature
  |
  o  0:e55e0562ee93@default(public) base
  
  $ hg evolve --any --traceback --phase-divergent
  recreate:[6] another feature that rox
  atop:[5] another feature (child of ba0ec09b1bab)
  computing new diff
  committed as aca219761afb
  working directory is now at aca219761afb
  $ glog
  @  7:aca219761afb@default(draft) phase-divergent update to 99833d22b0c6:
  |
  o  5:99833d22b0c6@default(public) another feature (child of ba0ec09b1bab)
  |
  o  4:ba0ec09b1bab@default(public) a nifty feature
  |
  o  0:e55e0562ee93@default(public) base
  
  $ hg diff --hidden -r aca219761afb -r 47d52a103155
  $ hg diff -r aca219761afb^ -r aca219761afb
  diff --git a/main-file-1 b/main-file-1
  --- a/main-file-1
  +++ b/main-file-1
  @@ -3,1 +3,1 @@
  -Zwei
  +deux
  $ hg log -r 'phasedivergent()' # no more bumped

test evolve --all
  $ sed -i'' -e s/deux/to/ main-file-1
  $ hg commit -m 'dansk 2!'
  $ sed -i'' -e s/Three/tre/ main-file-1
  $ hg commit -m 'dansk 3!'
  $ hg update aca219761afb
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ sed -i'' -e s/Un/Én/ main-file-1
  $ hg commit --amend -m 'dansk!'
  2 new orphan changesets

(ninja test for the {trouble} template:

  $ hg log -G --template '{rev} {troubles}\n'
  @  10
  |
  | o  9 orphan
  | |
  | o  8 orphan
  | |
  | x  7
  |/
  o  5
  |
  o  4
  |
  o  0
  


(/ninja)

  $ hg evolve --all --traceback
  move:[8] dansk 2!
  atop:[10] dansk!
  merging main-file-1
  move:[9] dansk 3!
  atop:[11] dansk 2!
  merging main-file-1
  working directory is now at 96abb1319a47
  $ hg log -G
  @  12	: dansk 3! - test
  |
  o  11	: dansk 2! - test
  |
  o  10	feature-B: dansk! - test
  |
  o  5	: another feature (child of ba0ec09b1bab) - test
  |
  o  4	feature-A: a nifty feature - test
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
  new changesets 702e4d0a6d86
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
  3 files, 3 changesets, 3 total revisions
  $ hg --config extensions.hgext.mq= strip 'extinct()'
  abort: empty revision set
  [255]
(do some garbare collection)
  $ hg --config extensions.hgext.mq= strip --hidden 'extinct()'  --config devel.strip-obsmarkers=no
  saved backup bundle to $TESTTMP/alpha/.hg/strip-backup/e87767087a57-a365b072-backup.hg (glob)
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
  1 new obsolescence markers
  new changesets c6dda801837c
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
(most of the testing have been moved to test-fold

  $ rm *.orig
  $ hg phase --public 0
  $ hg fold --from -r 5
  3 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
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
  |\ \     rewritten(description, user, parent, content) as d26d339c513f by test (*) (glob)
  | | |
  | \ \
  | |\ \
  | | | x  ce341209337f (4) add 4
  | | |      rewritten(description, user, content) as d26d339c513f by test (*) (glob)
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
  1 new orphan changesets
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
  @  13:284c0d45770d@default(draft) Folding with custom commit message
  |
  o  10:9975c016fe7b@default(draft) dansk!
  |
  o  5:99833d22b0c6@default(public) another feature (child of ba0ec09b1bab)
  |
  o  4:ba0ec09b1bab@default(public) a nifty feature
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
  14 - 8693d0f277b8 A longer
                    commit message (draft)
  5 - 99833d22b0c6 another feature (child of ba0ec09b1bab) (public)
  4 - ba0ec09b1bab a nifty feature (public)
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
  1 new orphan changesets

  $ hg evolve
  move:[3] a3
  atop:[4] a2
  working directory is now at 7c5649f73d11

  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  @  5 [mybranch] a3
  |
  o  4 [mybranch] a2
  |
  o  1 [default] a1
  |
  o  0 [default] a0
  

branch change preserved

  $ hg up 'desc(a1)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg amend -m 'a1_'
  2 new orphan changesets
  $ hg evolve
  move:[4] a2
  atop:[6] a1_
  working directory is now at eb07e22a0e63
  $ hg evolve
  move:[5] a3
  atop:[7] a2
  working directory is now at 777c26ca5e78
  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  @  8 [mybranch] a3
  |
  o  7 [mybranch] a2
  |
  o  6 [default] a1_
  |
  o  0 [default] a0
  

Evolve from the middle of a stack pick the right changesets.

  $ hg up -r "desc('a1_')"
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg ci --amend -m 'a1__'
  2 new orphan changesets

  $ hg up -r "desc('a2')"
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  o  9 [default] a1__
  |
  | o  8 [mybranch] a3
  | |
  | @  7 [mybranch] a2
  | |
  | x  6 [default] a1_
  |/
  o  0 [default] a0
  
  $ hg evolve
  nothing to evolve on current working copy parent
  (2 other orphan in the repository, do you want --any or --rev)
  [2]


Evolve disables active bookmarks.

  $ hg up -r "desc('a1__')"
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg bookmark testbookmark
  $ ls .hg/bookmarks*
  .hg/bookmarks
  .hg/bookmarks.* (glob)
  $ hg evolve
  move:[7] a2
  atop:[9] a1__
  (leaving bookmark testbookmark)
  working directory is now at d952e93add6f
  $ ls .hg/bookmarks*
  .hg/bookmarks
  $ glog
  @  10:d952e93add6f@mybranch(draft) a2
  |
  o  9:9f8b83c2e7f3@default(draft) a1__
  |
  | o  8:777c26ca5e78@mybranch(draft) a3
  | |
  | x  7:eb07e22a0e63@mybranch(draft) a2
  | |
  | x  6:faafc6cea0ba@default(draft) a1_
  |/
  o  0:07c1c36d9ef0@default(draft) a0
  

Possibility to select what trouble to solve first, asking for bumped before
divergent
  $ hg up -r "desc('a1__')"
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg revert -r d952e93add6f --all
  reverting a
  $ hg log -G --template '{rev} [{branch}] {desc|firstline}\n'
  o  10 [mybranch] a2
  |
  @  9 [default] a1__
  |
  | o  8 [mybranch] a3
  | |
  | x  7 [mybranch] a2
  | |
  | x  6 [default] a1_
  |/
  o  0 [default] a0
  
  $ echo "hello world" > newfile
  $ hg add newfile
  $ hg commit -m "add new file bumped" -o 10
  $ hg phase --public --hidden d952e93add6f
  1 new phase-divergent changesets
  $ hg log -G
  @  11	: add new file bumped - test
  |
  | o  10	: a2 - test
  |/
  o  9	testbookmark: a1__ - test
  |
  | o  8	: a3 - test
  | |
  | x  7	: a2 - test
  | |
  | x  6	: a1_ - test
  |/
  o  0	: a0 - test
  

Now we have a bumped and an unstable changeset, we solve the bumped first
normally the unstable changeset would be solve first

  $ hg log -G
  @  11	: add new file bumped - test
  |
  | o  10	: a2 - test
  |/
  o  9	testbookmark: a1__ - test
  |
  | o  8	: a3 - test
  | |
  | x  7	: a2 - test
  | |
  | x  6	: a1_ - test
  |/
  o  0	: a0 - test
  
  $ hg evolve -r "desc('add new file bumped')" --phase-divergent
  recreate:[11] add new file bumped
  atop:[10] a2
  computing new diff
  committed as a8bb31d4b7f2
  working directory is now at a8bb31d4b7f2
  $ hg evolve --any
  move:[8] a3
  atop:[12] phase-divergent update to d952e93add6f:
  working directory is now at b88539ad24d7
  $ glog
  @  13:b88539ad24d7@default(draft) a3
  |
  o  12:a8bb31d4b7f2@default(draft) phase-divergent update to d952e93add6f:
  |
  o  10:d952e93add6f@mybranch(public) a2
  |
  o  9:9f8b83c2e7f3@default(public) a1__
  |
  o  0:07c1c36d9ef0@default(public) a0
  

Check that we can resolve troubles in a revset with more than one commit
  $ hg up b88539ad24d7 -C
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ mkcommit gg
  $ hg up b88539ad24d7
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit gh
  created new head
  $ hg up b88539ad24d7
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ printf "newline\nnewline\n" >> a
  $ hg log -G
  o  15	: add gh - test
  |
  | o  14	: add gg - test
  |/
  @  13	: a3 - test
  |
  o  12	: phase-divergent update to d952e93add6f: - test
  |
  o  10	: a2 - test
  |
  o  9	testbookmark: a1__ - test
  |
  o  0	: a0 - test
  
  $ hg amend
  2 new orphan changesets
  $ glog
  @  16:0cf3707e8971@default(draft) a3
  |
  | o  15:daa1ff1c7fbd@default(draft) add gh
  | |
  | | o  14:484fb3cfa7f2@default(draft) add gg
  | |/
  | x  13:b88539ad24d7@default(draft) a3
  |/
  o  12:a8bb31d4b7f2@default(draft) phase-divergent update to d952e93add6f:
  |
  o  10:d952e93add6f@mybranch(public) a2
  |
  o  9:9f8b83c2e7f3@default(public) a1__
  |
  o  0:07c1c36d9ef0@default(public) a0
  

Evolving an empty revset should do nothing
  $ hg evolve --rev "daa1ff1c7fbd and 484fb3cfa7f2"
  set of specified revisions is empty
  [1]

  $ hg evolve --rev "b88539ad24d7::" --phase-divergent
  no phasedivergent changesets in specified revisions
  (do you want to use --orphan)
  [2]
  $ hg evolve --rev "b88539ad24d7::" --orphan
  move:[14] add gg
  atop:[16] a3
  move:[15] add gh
  atop:[16] a3
  working directory is now at 0c049e4e5422
  $ glog
  @  18:0c049e4e5422@default(draft) add gh
  |
  | o  17:98e171e2f272@default(draft) add gg
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  o  12:a8bb31d4b7f2@default(draft) phase-divergent update to d952e93add6f:
  |
  o  10:d952e93add6f@mybranch(public) a2
  |
  o  9:9f8b83c2e7f3@default(public) a1__
  |
  o  0:07c1c36d9ef0@default(public) a0
  
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
  $ hg up 98e171e2f272 -C
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit j1
  $ mkcommit j2
  $ mkcommit j3
  $ hg up .^^
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo "hello" > j4
  $ hg add j4
  $ hg amend
  2 new orphan changesets
  $ glog -r "0cf3707e8971::"
  @  22:274b6cd0c101@default(draft) add j1
  |
  | o  21:89e4f7e8feb5@default(draft) add j3
  | |
  | o  20:4cd61236beca@default(draft) add j2
  | |
  | x  19:0fd8bfb02de4@default(draft) add j1
  |/
  | o  18:0c049e4e5422@default(draft) add gh
  | |
  o |  17:98e171e2f272@default(draft) add gg
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~

  $ hg evolve --rev 89e4f7e8feb5 --any
  abort: cannot specify both "--rev" and "--any"
  [255]
  $ hg evolve --rev 89e4f7e8feb5
  cannot solve instability of 89e4f7e8feb5, skipping

Check that uncommit respects the allowunstable option
With only createmarkers we can only uncommit on a head
  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=createmarkers, allnewcommands
  > EOF
  $ hg up 274b6cd0c101^
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg uncommit --all
  abort: uncommit will orphan 4 descendants
  (see 'hg help evolution.instability')
  [255]
  $ hg up 274b6cd0c101
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg uncommit --all
  new changeset is empty
  (use 'hg prune .' to remove it)
  $ glog -r "0cf3707e8971::"
  @  23:0ef9ff75f8e2@default(draft) add j1
  |
  | o  21:89e4f7e8feb5@default(draft) add j3
  | |
  | o  20:4cd61236beca@default(draft) add j2
  | |
  | x  19:0fd8bfb02de4@default(draft) add j1
  |/
  | o  18:0c049e4e5422@default(draft) add gh
  | |
  o |  17:98e171e2f272@default(draft) add gg
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~

Check that prune respects the allowunstable option
  $ hg up -C .
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up 0c049e4e5422
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg evolve --all
  nothing to evolve on current working copy parent
  (2 other orphan in the repository, do you want --any or --rev)
  [2]
  $ hg evolve --all --any
  move:[20] add j2
  atop:[23] add j1
  move:[21] add j3
  atop:[24] add j2
  working directory is now at 0d9203b74542
  $ glog -r "0cf3707e8971::"
  @  25:0d9203b74542@default(draft) add j3
  |
  o  24:f1b85956c48c@default(draft) add j2
  |
  o  23:0ef9ff75f8e2@default(draft) add j1
  |
  | o  18:0c049e4e5422@default(draft) add gh
  | |
  o |  17:98e171e2f272@default(draft) add gg
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~
  $ hg up 98e171e2f272
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit c5_
  created new head
  $ hg prune '0ef9ff75f8e2 + f1b85956c48c'
  abort: touch will orphan 1 descendants
  (see 'hg help evolution.instability')
  [255]
  $ hg prune '98e171e2f272::0d9203b74542'
  abort: touch will orphan 1 descendants
  (see 'hg help evolution.instability')
  [255]
  $ hg prune '0ef9ff75f8e2::'
  3 changesets pruned
  $ glog -r "0cf3707e8971::"
  @  26:4c6f6f6d1976@default(draft) add c5_
  |
  | o  18:0c049e4e5422@default(draft) add gh
  | |
  o |  17:98e171e2f272@default(draft) add gg
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~

Check that fold respects the allowunstable option

(most of this has been moved to test-fold.t)

  $ hg up 0cf3707e8971
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit unstableifparentisfolded
  created new head
  $ glog -r "0cf3707e8971::"
  @  27:2d1b55e10be9@default(draft) add unstableifparentisfolded
  |
  | o  26:4c6f6f6d1976@default(draft) add c5_
  | |
  +---o  18:0c049e4e5422@default(draft) add gh
  | |
  | o  17:98e171e2f272@default(draft) add gg
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~

  $ hg fold --exact "98e171e2f272::"
  2 changesets folded

Check that evolve shows error while handling split commits
--------------------------------------

  $ cat >> $HGRCPATH <<EOF
  > [experimental]
  > evolution=all
  > EOF

  $ glog -r "0cf3707e8971::"
  o  28:92ca6f3984de@default(draft) add gg
  |
  | @  27:2d1b55e10be9@default(draft) add unstableifparentisfolded
  |/
  | o  18:0c049e4e5422@default(draft) add gh
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~

Create a split commit
  $ printf "oo" > oo;
  $ printf "pp" > pp;
  $ hg add oo pp
  $ hg commit -m "oo+pp"
  $ mkcommit uu
  $ hg up 2d1b55e10be9
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
  1 new orphan changesets
  $ glog -r "0cf3707e8971::"
  @  32:c7dbf668e9d5@default(draft) _pp
  |
  o  31:2b5a32114b3d@default(draft) _oo
  |
  | o  30:4d122571f3b6@default(draft) add uu
  | |
  | x  29:7da3e73df8a5@default(draft) oo+pp
  |/
  | o  28:92ca6f3984de@default(draft) add gg
  | |
  o |  27:2d1b55e10be9@default(draft) add unstableifparentisfolded
  |/
  | o  18:0c049e4e5422@default(draft) add gh
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~
  $ hg evolve --rev "0cf3707e8971::"
  move:[30] add uu
  atop:[32] _pp
  working directory is now at be23044af550


Check that dirstate changes are kept at failure for conflicts (issue4966)
----------------------------------------

  $ echo "will be amended" > newfile
  $ hg commit -m "will be amended"
  $ hg parents
  34	: will be amended - test

  $ echo "will be evolved safely" >> a
  $ hg commit -m "will be evolved safely"

  $ echo "will cause conflict at evolve" > newfile
  $ echo "newly added" > newlyadded
  $ hg add newlyadded
  $ hg commit -m "will cause conflict at evolve"

  $ glog -r "0cf3707e8971::"
  @  36:59c37c5bebd1@default(draft) will cause conflict at evolve
  |
  o  35:7cc12c6c7862@default(draft) will be evolved safely
  |
  o  34:98c7ab460e6b@default(draft) will be amended
  |
  o  33:be23044af550@default(draft) add uu
  |
  o  32:c7dbf668e9d5@default(draft) _pp
  |
  o  31:2b5a32114b3d@default(draft) _oo
  |
  | o  28:92ca6f3984de@default(draft) add gg
  | |
  o |  27:2d1b55e10be9@default(draft) add unstableifparentisfolded
  |/
  | o  18:0c049e4e5422@default(draft) add gh
  |/
  o  16:0cf3707e8971@default(draft) a3
  |
  ~

  $ hg update -q 98c7ab460e6b
  $ echo "amended" > newfile
  $ hg amend -m "amended"
  2 new orphan changesets

  $ hg evolve --rev "98c7ab460e6b::"
  move:[35] will be evolved safely
  atop:[37] amended
  move:[36] will cause conflict at evolve
  atop:[38] will be evolved safely
  merging newfile
  warning: conflicts while merging newfile! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ glog -r "be23044af550::" --hidden
  @  38:61abd81de026@default(draft) will be evolved safely
  |
  o  37:df89d30f23e2@default(draft) amended
  |
  | o  36:59c37c5bebd1@default(draft) will cause conflict at evolve
  | |
  | x  35:7cc12c6c7862@default(draft) will be evolved safely
  | |
  | x  34:98c7ab460e6b@default(draft) will be amended
  |/
  o  33:be23044af550@default(draft) add uu
  |
  ~

  $ hg status newlyadded
  A newlyadded
