
  $ . $TESTDIR/testlib/common.sh
  $ cat >> $HGRCPATH <<EOF
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish=False
  > [alias]
  > debugobsolete=debugobsolete -d '0 0'
  > [extensions]
  > hgext.rebase=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }
  $ alias qlog="hg log --template='{rev}\n- {node|short}\n'"
  $ hg init local
  $ cd local
  $ mkcommit a # 0
  $ hg phase -p .
  $ mkcommit b # 1
  $ mkcommit c # 2
  $ hg up 1
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit obsol_c # 3
  created new head
  $ getid 2
  4538525df7e2b9f09423636c61ef63a4cb872a2d
  $ getid 3
  0d3f46688ccc6e756c7e96cf64c391c411309597
  $ hg debugobsolete 4538525df7e2b9f09423636c61ef63a4cb872a2d 0d3f46688ccc6e756c7e96cf64c391c411309597
  $ hg debugobsolete
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0d3f46688ccc6e756c7e96cf64c391c411309597 0 (*) {'user': 'test'} (glob)


Test hidden() revset

  $ qlog -r 'hidden()' --hidden
  2
  - 4538525df7e2

Test that obsolete changeset are hidden

  $ qlog
  3
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ qlog --hidden
  3
  - 0d3f46688ccc
  2
  - 4538525df7e2
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ qlog -r 'obsolete()' --hidden
  2
  - 4538525df7e2

Test that obsolete precursors are properly computed

  $ qlog -r 'precursors(.)' --hidden
  2
  - 4538525df7e2
  $ qlog -r .
  3
  - 0d3f46688ccc
  $ hg odiff
  diff -r 4538525df7e2 -r 0d3f46688ccc c
  --- a/c	Thu Jan 01 00:00:00 1970 +0000
  +++ /dev/null	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,1 +0,0 @@
  -c
  diff -r 4538525df7e2 -r 0d3f46688ccc obsol_c
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/obsol_c	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +obsol_c

Test that obsolete successors are properly computed

  $ qlog -r 'successors(2)' --hidden
  3
  - 0d3f46688ccc

test obsolete changeset with non-obsolete descendant
  $ hg up 1 -q
  $ mkcommit "obsol_c'" # 4 (on 1)
  created new head
  $ hg debugobsolete `getid 3` `getid 4`
  $ qlog
  4
  - 725c380fe99b
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ qlog -r 'obsolete()' --hidden
  2
  - 4538525df7e2
  3
  - 0d3f46688ccc
  $ qlog -r 'allprecursors(4)' --hidden
  2
  - 4538525df7e2
  3
  - 0d3f46688ccc
  $ qlog -r 'allsuccessors(2)' --hidden
  3
  - 0d3f46688ccc
  4
  - 725c380fe99b
  $ hg up --hidden 3 -q
  working directory parent is obsolete! (0d3f46688ccc)
(reported by parents too)
  $ hg parents
  changeset:   3:0d3f46688ccc
  parent:      1:7c3bad9141dc
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add obsol_c
  
  working directory parent is obsolete! (0d3f46688ccc)
  (use 'hg evolve' to update to its successor: 725c380fe99b)
  $ mkcommit d # 5 (on 3)
  1 new unstable changesets
  $ qlog -r 'obsolete()'
  3
  - 0d3f46688ccc

  $ qlog -r 'extinct()' --hidden
  2
  - 4538525df7e2
  $ qlog -r 'suspended()'
  3
  - 0d3f46688ccc
  $ qlog -r 'unstable()'
  5
  - a7a6f2b5d8a5

Test obsolete keyword

  $ hg --hidden log -G \
  >  --template '{rev}:{node|short}@{branch}({separate("/", obsolete, phase)}) {desc|firstline}\n'
  @  5:a7a6f2b5d8a5@default(draft) add d
  |
  | o  4:725c380fe99b@default(draft) add obsol_c'
  | |
  x |  3:0d3f46688ccc@default(obsolete/draft) add obsol_c
  |/
  | x  2:4538525df7e2@default(obsolete/draft) add c
  |/
  o  1:7c3bad9141dc@default(draft) add b
  |
  o  0:1f0dee641bb7@default(public) add a
  

Test communication of obsolete relation with a compatible client

  $ hg init ../other-new
  $ hg phase --draft 'secret() - extinct()' # until we fix exclusion
  abort: empty revision set
  [255]
  $ hg push ../other-new
  pushing to ../other-new
  searching for changes
  abort: push includes unstable changeset: a7a6f2b5d8a5!
  (use 'hg evolve' to get a stable history or --force to ignore warnings)
  [255]
  $ hg push -f ../other-new
  pushing to ../other-new
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 5 changes to 5 files (+1 heads)
  2 new obsolescence markers
  $ hg -R ../other-new verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  5 files, 5 changesets, 5 total revisions
  $ qlog -R ../other-new -r 'obsolete()'
  2
  - 0d3f46688ccc
  $ qlog -R ../other-new
  4
  - a7a6f2b5d8a5
  3
  - 725c380fe99b
  2
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ hg up --hidden 3 -q
  working directory parent is obsolete! (0d3f46688ccc)
  $ mkcommit obsol_d # 6
  created new head
  1 new unstable changesets
  $ hg debugobsolete `getid 5` `getid 6`
  $ qlog
  6
  - 95de7fc6918d
  4
  - 725c380fe99b
  3
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ qlog -r 'obsolete()'
  3
  - 0d3f46688ccc
  $ hg push ../other-new
  pushing to ../other-new
  searching for changes
  abort: push includes unstable changeset: 95de7fc6918d!
  (use 'hg evolve' to get a stable history or --force to ignore warnings)
  [255]
  $ hg push ../other-new -f # use f because there is unstability
  pushing to ../other-new
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  1 new obsolescence markers
  $ qlog -R ../other-new
  5
  - 95de7fc6918d
  3
  - 725c380fe99b
  2
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ qlog -R ../other-new -r 'obsolete()'
  2
  - 0d3f46688ccc

Pushing again does not advertise extinct changesets

  $ hg push ../other-new
  pushing to ../other-new
  searching for changes
  no changes found
  [1]

  $ hg up --hidden -q .^ # 3
  working directory parent is obsolete! (0d3f46688ccc)
  $ mkcommit "obsol_d'" # 7
  created new head
  1 new unstable changesets
  $ hg debugobsolete `getid 6` `getid 7`
  $ hg pull -R ../other-new .
  pulling from .
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to [12] files \(\+1 heads\) (re)
  1 new obsolescence markers
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ qlog -R ../other-new
  6
  - 909a0fb57e5d
  3
  - 725c380fe99b
  2
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7

pushing to stuff that doesn't support obsolescence

DISABLED. the _enable switch is global :-/

..  $ hg init ../other-old
..  > # XXX I don't like this but changeset get published otherwise
..  > # remove it when we will get a --keep-state flag for push
..  $ echo '[extensions]'  > ../other-old/.hg/hgrc
..  $ echo "obsolete=!$(echo $(dirname $TESTDIR))/obsolete.py" >> ../other-old/.hg/hgrc
..  $ hg push ../other-old
..  pushing to ../other-old
..  searching for changes
..  abort: push includes an unstable changeset: 909a0fb57e5d!
..  (use 'hg evolve' to get a stable history or --force to ignore warnings)
..  [255]
..  $ hg push -f ../other-old
..  pushing to ../other-old
..  searching for changes
..  adding changesets
..  adding manifests
..  adding file changes
..  added 5 changesets with 5 changes to 5 files (+1 heads)
..  $ qlog -R ../other-ol
..  4
..  - 909a0fb57e5d
..  3
..  - 725c380fe99b
..  2
..  - 0d3f46688ccc
..  1
..  - 7c3bad9141dc
..  0
..  - 1f0dee641bb7

clone support

  $ hg clone . ../cloned
  > # The warning should go away once we have default value to set ready before we pull
  updating to branch default
  4 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ qlog -R ../cloned --hidden
  7
  - 909a0fb57e5d
  6
  - 95de7fc6918d
  5
  - a7a6f2b5d8a5
  4
  - 725c380fe99b
  3
  - 0d3f46688ccc
  2
  - 4538525df7e2
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7

Test rollback support

  $ hg up --hidden .^ -q # 3
  working directory parent is obsolete! (0d3f46688ccc)
  $ mkcommit "obsol_d''"
  created new head
  1 new unstable changesets
  $ hg debugobsolete `getid 7` `getid 8`
  $ cd ../other-new
  $ hg up -q 3
  $ hg pull ../local/
  pulling from ../local/
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to [12] files \(\+1 heads\) (re)
  1 new obsolescence markers
  (run 'hg heads' to see heads, 'hg merge' to merge)

  $ hg up -q 7 # to check rollback update behavior
  $ qlog
  7
  - 159dfc9fa5d3
  3
  - 725c380fe99b
  2
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ hg rollback
  repository tip rolled back to revision 6 (undo pull)
  working directory now based on revision 3
  $ hg summary
  parent: 3:725c380fe99b 
   add obsol_c'
  branch: default
  commit: 1 deleted, 2 unknown (clean)
  update: 2 new changesets, 2 branch heads (merge)
  phases: 4 draft
  unstable: 1 changesets
  $ qlog
  6
  - 909a0fb57e5d
  3
  - 725c380fe99b
  2
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7
  $ cd ../local

obsolete public changeset

# move draft boundary from 0 to 1
  $ sed -e 's/1f0dee641bb7258c56bd60e93edfa2405381c41e/7c3bad9141dcb46ff89abf5f61856facd56e476c/' -i'.back' .hg/store/phaseroots

  $ hg up null
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ mkcommit toto # 9
  created new head
  $ hg id -n
  9
  $ hg debugobsolete `getid 0` `getid 9`
83b5778897ad try to obsolete immutable changeset 1f0dee641bb7
# at core level the warning is not issued
# this is now a big issue now that we have bumped warning
  $ qlog -r 'obsolete()'
  3
  - 0d3f46688ccc
allow to just kill changeset

  $ qlog
  9
  - 83b5778897ad
  8
  - 159dfc9fa5d3
  4
  - 725c380fe99b
  3
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7

  $ hg debugobsolete `getid 9` #kill
  $ hg up null -q # to be not based on 9 anymore
  $ qlog
  8
  - 159dfc9fa5d3
  4
  - 725c380fe99b
  3
  - 0d3f46688ccc
  1
  - 7c3bad9141dc
  0
  - 1f0dee641bb7

Check that auto update ignores hidden changeset
  $ hg up 0
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up 
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
  1 other heads for branch "default"
  $ hg id -n
  8

Check that named update does too

  $ hg update default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg id -n
  8

  $ hg up null -q # to be not based on 9 anymore

check rebase compat

  $ hg log -G  --template='{rev} - {node|short} {desc}\n'
  o  8 - 159dfc9fa5d3 add obsol_d''
  |
  | o  4 - 725c380fe99b add obsol_c'
  | |
  x |  3 - 0d3f46688ccc add obsol_c
  |/
  o  1 - 7c3bad9141dc add b
  |
  o  0 - 1f0dee641bb7 add a
  

  $ hg log -G  --template='{rev} - {node|short} {desc}\n' --hidden
  x  9 - 83b5778897ad add toto
  
  o  8 - 159dfc9fa5d3 add obsol_d''
  |
  | x  7 - 909a0fb57e5d add obsol_d'
  |/
  | x  6 - 95de7fc6918d add obsol_d
  |/
  | x  5 - a7a6f2b5d8a5 add d
  |/
  | o  4 - 725c380fe99b add obsol_c'
  | |
  x |  3 - 0d3f46688ccc add obsol_c
  |/
  | x  2 - 4538525df7e2 add c
  |/
  o  1 - 7c3bad9141dc add b
  |
  o  0 - 1f0dee641bb7 add a
  

should not rebase extinct changesets

#excluded 'whole rebase set is extinct and ignored.' message not in core
  $ hg rebase -b '3' -d 4 --traceback --config experimental.rebaseskipobsolete=0
  rebasing 3:0d3f46688ccc "add obsol_c"
  rebasing 8:159dfc9fa5d3 "add obsol_d''" (tip)
  2 new divergent changesets
  $ hg --hidden log -q -r 'successors(3)'
  4:725c380fe99b
  10:2033b4e49474
  $ hg up tip
  ? files updated, 0 files merged, 0 files removed, 0 files unresolved (glob)
  $ hg log -G --template='{rev} - {node|short} {desc}\n'
  @  11 - 9468a5f5d8b2 add obsol_d''
  |
  o  10 - 2033b4e49474 add obsol_c
  |
  o  4 - 725c380fe99b add obsol_c'
  |
  o  1 - 7c3bad9141dc add b
  |
  o  0 - 1f0dee641bb7 add a
  

Does not complain about new head if you obsolete the old one
(re necessary when we start running discovery on unfiltered repo in core)

  $ hg push ../other-new --traceback
  pushing to ../other-new
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 1 changes to [12] files (re)
  3 new obsolescence markers
  $ hg up -q 10
  $ mkcommit "obsol_d'''"
  created new head
  $ hg debugobsolete `getid 11` `getid 12`
  $ hg push ../other-new --traceback
  pushing to ../other-new
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  1 new obsolescence markers
  $ cd ..

check bumped detection
(make an obsolete changeset public)

  $ cd local
  $ hg phase --hidden --public 11
  1 new bumped changesets
  $ hg log -G --template='{rev} - ({phase}) {node|short} {desc}\n'
  @  12 - (draft) 6db5e282cb91 add obsol_d'''
  |
  | o  11 - (public) 9468a5f5d8b2 add obsol_d''
  |/
  o  10 - (public) 2033b4e49474 add obsol_c
  |
  o  4 - (public) 725c380fe99b add obsol_c'
  |
  o  1 - (public) 7c3bad9141dc add b
  |
  o  0 - (public) 1f0dee641bb7 add a
  
  $ hg log -r 'bumped()'
  changeset:   12:6db5e282cb91
  tag:         tip
  parent:      10:2033b4e49474
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  trouble:     bumped
  summary:     add obsol_d'''
  
  $ hg push ../other-new/
  pushing to ../other-new/
  searching for changes
  abort: push includes bumped changeset: 6db5e282cb91!
  (use 'hg evolve' to get a stable history or --force to ignore warnings)
  [255]

Check hg commit --amend compat

  $ hg up 'desc(obsol_c)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit f
  created new head
  $ echo 42 >> f
  $ hg commit --amend --traceback --quiet
  $ hg log -G
  @  changeset:   15:705ab2a6b72e
  |  tag:         tip
  |  parent:      10:2033b4e49474
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add f
  |
  | o  changeset:   12:6db5e282cb91
  |/   parent:      10:2033b4e49474
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    trouble:     bumped
  |    summary:     add obsol_d'''
  |
  | o  changeset:   11:9468a5f5d8b2
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     add obsol_d''
  |
  o  changeset:   10:2033b4e49474
  |  parent:      4:725c380fe99b
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add obsol_c
  |
  o  changeset:   4:725c380fe99b
  |  parent:      1:7c3bad9141dc
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add obsol_c'
  |
  o  changeset:   1:7c3bad9141dc
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add b
  |
  o  changeset:   0:1f0dee641bb7
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add a
  
  $ hg debugobsolete | grep -v 33d458d86621f3186c40bfccd77652f4a122743e
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0d3f46688ccc6e756c7e96cf64c391c411309597 0 (*) {'user': 'test'} (glob)
  0d3f46688ccc6e756c7e96cf64c391c411309597 725c380fe99b5e76613493f0903e8d11ddc70d54 0 (*) {'user': 'test'} (glob)
  a7a6f2b5d8a54b81bc7aa2fba2934ad6d700a79e 95de7fc6918dea4c9c8d5382f50649794b474c4a 0 (*) {'user': 'test'} (glob)
  95de7fc6918dea4c9c8d5382f50649794b474c4a 909a0fb57e5d909f353d89e394ffd7e0890fec88 0 (*) {'user': 'test'} (glob)
  909a0fb57e5d909f353d89e394ffd7e0890fec88 159dfc9fa5d334d7e03a0aecfc7f7ab4c3431fea 0 (*) {'user': 'test'} (glob)
  1f0dee641bb7258c56bd60e93edfa2405381c41e 83b5778897adafb967ef2f75be3aaa4fce49a4cc 0 (*) {'user': 'test'} (glob)
  83b5778897adafb967ef2f75be3aaa4fce49a4cc 0 (*) {'user': 'test'} (glob)
  0d3f46688ccc6e756c7e96cf64c391c411309597 2033b4e494742365851fac84d276640cbf52833e 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  159dfc9fa5d334d7e03a0aecfc7f7ab4c3431fea 9468a5f5d8b2c5d91e17474e95ae4791e9718fdf 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  9468a5f5d8b2c5d91e17474e95ae4791e9718fdf 6db5e282cb91df5c43ff1f1287c119ff83230d42 0 (*) {'user': 'test'} (glob)
  0b1b6dd009c037985363e2290a0b579819f659db 705ab2a6b72e2cd86edb799ebe15f2695f86143e 0 (*) {'ef1': '*', 'user': 'test'} (glob)
#no produced by 2.3
33d458d86621f3186c40bfccd77652f4a122743e 3734a65252e69ddcced85901647a4f335d40de1e 0 {'date': '* *', 'user': 'test'} (glob)

Check divergence detection (note: multiple successors is sorted by changeset hash)

  $ hg up 9468a5f5d8b2 #  add obsol_d''
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit "obsolet_conflicting_d"
  $ hg summary
  parent: 1[46]:50f11e5e3a63 tip (re)
   add obsolet_conflicting_d
  branch: default
  commit: (clean)
  update: (2|9|11) new changesets, (3|9|10) branch heads \(merge\) (re)
  phases: 3 draft
  bumped: 1 changesets
  $ hg debugobsolete `getid a7a6f2b5d8a5` `getid 50f11e5e3a63`
  $ hg log -r 'divergent()'
  changeset:   12:6db5e282cb91
  parent:      10:2033b4e49474
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  trouble:     bumped, divergent
  summary:     add obsol_d'''
  
  changeset:   16:50f11e5e3a63
  tag:         tip
  parent:      11:9468a5f5d8b2
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  trouble:     divergent
  summary:     add obsolet_conflicting_d
  

  $ hg up --hidden 3 -q
  working directory parent is obsolete! (0d3f46688ccc)
  $ hg evolve
  parent is obsolete with multiple successors:
  [4] add obsol_c'
  [10] add obsol_c
  [2]
  $ hg olog
  @  0d3f46688ccc (3) add obsol_c
  |    rewritten(parent) by test (*) as 2033b4e49474 (glob)
  |    rewritten by test (*) as 725c380fe99b (glob)
  |
  x  4538525df7e2 (2) add c
       rewritten by test (*) as 0d3f46688ccc (glob)
  

Check import reports new unstable changeset:

  $ hg up --hidden 2
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory parent is obsolete! (4538525df7e2)
  (4538525df7e2 has diverged, use 'hg evolve --list --divergent' to resolve the issue)
  $ hg export 9468a5f5d8b2 | hg import -
  applying patch from stdin
  1 new unstable changesets


Relevant marker computation
==============================

  $ hg log -G --hidden
  @  changeset:   17:a5f7a21fe7bc
  |  tag:         tip
  |  parent:      2:4538525df7e2
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  trouble:     unstable
  |  summary:     add obsol_d''
  |
  | o  changeset:   16:50f11e5e3a63
  | |  parent:      11:9468a5f5d8b2
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  trouble:     divergent
  | |  summary:     add obsolet_conflicting_d
  | |
  | | o  changeset:   15:705ab2a6b72e
  | | |  parent:      10:2033b4e49474
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     add f
  | | |
  | | | x  changeset:   14:33d458d86621
  | | | |  user:        test
  | | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | | |  summary:     temporary amend commit for 0b1b6dd009c0
  | | | |
  | | | x  changeset:   13:0b1b6dd009c0
  | | |/   parent:      10:2033b4e49474
  | | |    user:        test
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    summary:     add f
  | | |
  | | | o  changeset:   12:6db5e282cb91
  | | |/   parent:      10:2033b4e49474
  | | |    user:        test
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    trouble:     bumped, divergent
  | | |    summary:     add obsol_d'''
  | | |
  | o |  changeset:   11:9468a5f5d8b2
  | |/   user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    summary:     add obsol_d''
  | |
  | o  changeset:   10:2033b4e49474
  | |  parent:      4:725c380fe99b
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     add obsol_c
  | |
  | | x  changeset:   9:83b5778897ad
  | |    parent:      -1:000000000000
  | |    user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    summary:     add toto
  | |
  | | x  changeset:   8:159dfc9fa5d3
  | | |  parent:      3:0d3f46688ccc
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     add obsol_d''
  | | |
  | | | x  changeset:   7:909a0fb57e5d
  | | |/   parent:      3:0d3f46688ccc
  | | |    user:        test
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    summary:     add obsol_d'
  | | |
  | | | x  changeset:   6:95de7fc6918d
  | | |/   parent:      3:0d3f46688ccc
  | | |    user:        test
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    summary:     add obsol_d
  | | |
  | | | x  changeset:   5:a7a6f2b5d8a5
  | | |/   parent:      3:0d3f46688ccc
  | | |    user:        test
  | | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | | |    summary:     add d
  | | |
  | o |  changeset:   4:725c380fe99b
  | | |  parent:      1:7c3bad9141dc
  | | |  user:        test
  | | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | | |  summary:     add obsol_c'
  | | |
  | | x  changeset:   3:0d3f46688ccc
  | |/   parent:      1:7c3bad9141dc
  | |    user:        test
  | |    date:        Thu Jan 01 00:00:00 1970 +0000
  | |    summary:     add obsol_c
  | |
  x |  changeset:   2:4538525df7e2
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     add c
  |
  o  changeset:   1:7c3bad9141dc
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add b
  |
  o  changeset:   0:1f0dee641bb7
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add a
  

Simple rewrite

  $ hg  --hidden debugobsolete --rev 3
  4538525df7e2b9f09423636c61ef63a4cb872a2d 0d3f46688ccc6e756c7e96cf64c391c411309597 0 (*) {'user': 'test'} (glob)

simple rewrite with a prune attached to it

  $ hg debugobsolete --rev 15
  0b1b6dd009c037985363e2290a0b579819f659db 705ab2a6b72e2cd86edb799ebe15f2695f86143e 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  33d458d86621f3186c40bfccd77652f4a122743e 0 {0b1b6dd009c037985363e2290a0b579819f659db} (*) {'ef1': '*', 'user': 'test'} (glob)

Transitive rewrite

  $ hg --hidden debugobsolete --rev 8
  909a0fb57e5d909f353d89e394ffd7e0890fec88 159dfc9fa5d334d7e03a0aecfc7f7ab4c3431fea 0 (*) {'user': 'test'} (glob)
  95de7fc6918dea4c9c8d5382f50649794b474c4a 909a0fb57e5d909f353d89e394ffd7e0890fec88 0 (*) {'user': 'test'} (glob)
  a7a6f2b5d8a54b81bc7aa2fba2934ad6d700a79e 95de7fc6918dea4c9c8d5382f50649794b474c4a 0 (*) {'user': 'test'} (glob)

