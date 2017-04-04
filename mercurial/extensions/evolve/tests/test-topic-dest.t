  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ hg init jungle
  $ cd jungle
  $ cat <<EOF >> .hg/hgrc
  > [extensions]
  > rebase=
  > histedit=
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [ui]
  > logtemplate = '{rev} ({topics}) {desc}\n'
  > EOF

  $ for x in alpha beta gamma delta ; do
  >   echo file $x >> $x
  >   hg add $x
  >   hg ci -m "c_$x"
  > done

Test NGTip feature
==================

Simple linear case

  $ echo babar >> jungle
  $ hg add jungle
  $ hg ci -t elephant -m babar

  $ hg log -G
  @  4 (elephant) babar
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ hg log -r 'ngtip(.)'
  3 () c_delta
  $ hg log -r 'default'
  3 () c_delta


multiple heads with topic

  $ hg up "desc('c_beta')"
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ echo zephir >> jungle
  $ hg add jungle
  $ hg ci -t monkey -m zephir
  $ hg log -G
  @  5 (monkey) zephir
  |
  | o  4 (elephant) babar
  | |
  | o  3 () c_delta
  | |
  | o  2 () c_gamma
  |/
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ hg log -r 'ngtip(.)'
  3 () c_delta
  $ hg log -r 'default'
  3 () c_delta

one of the head is a valid tip

  $ hg up "desc('c_delta')"
  2 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo epsilon >> epsilon
  $ hg add epsilon
  $ hg ci -m "c_epsilon"
  $ hg log -G
  @  6 () c_epsilon
  |
  | o  5 (monkey) zephir
  | |
  +---o  4 (elephant) babar
  | |
  o |  3 () c_delta
  | |
  o |  2 () c_gamma
  |/
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ hg log -r 'ngtip(.)'
  6 () c_epsilon
  $ hg log -r 'default'
  6 () c_epsilon

rebase destination
==================

rebase on branch ngtip

  $ hg up elephant
  switching to topic elephant
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg rebase
  rebasing 4:cb7ae72f4a80 "babar"
  $ hg log -G
  @  7 (elephant) babar
  |
  o  6 () c_epsilon
  |
  | o  5 (monkey) zephir
  | |
  o |  3 () c_delta
  | |
  o |  2 () c_gamma
  |/
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ hg up monkey
  switching to topic monkey
  1 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg rebase
  rebasing 5:d832ddc604ec "zephir"
  $ hg log -G
  @  8 (monkey) zephir
  |
  | o  7 (elephant) babar
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  

Rebase on other topic heads if any

  $ hg up 'desc(c_delta)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo "General Huc" >> monkeyville
  $ hg add monkeyville
  $ hg ci -t monkey -m Huc
  $ hg log -G
  @  9 (monkey) Huc
  |
  | o  8 (monkey) zephir
  | |
  | | o  7 (elephant) babar
  | |/
  | o  6 () c_epsilon
  |/
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ hg rebase
  rebasing 9:d79a104e2902 "Huc" (tip)
  $ hg log -G
  @  10 (monkey) Huc
  |
  o  8 (monkey) zephir
  |
  | o  7 (elephant) babar
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  

merge destination
=================

  $ hg up 'ngtip(default)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg up default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo zeta >> zeta
  $ hg add zeta
  $ hg ci -m "c_zeta"
  $ hg log -G
  @  11 () c_zeta
  |
  | o  10 (monkey) Huc
  | |
  | o  8 (monkey) zephir
  |/
  | o  7 (elephant) babar
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ hg up elephant
  switching to topic elephant
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg rebase -d 'desc(c_zeta)' # make sure tip is elsewhere
  rebasing 7:8d0b77140b05 "babar"
  $ hg up monkey
  switching to topic monkey
  2 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg topic
     elephant
   * monkey
  $ hg ci -m 'merge with default'
  $ hg topic
     elephant
   * monkey
  $ hg log -G
  @    13 (monkey) merge with default
  |\
  | | o  12 (elephant) babar
  | |/
  | o  11 () c_zeta
  | |
  o |  10 (monkey) Huc
  | |
  o |  8 (monkey) zephir
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  


Check pull --rebase
-------------------

(we broke it a some point)

  $ cd ..
  $ hg clone jungle other --rev '2'
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files
  updating to branch default
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd other
  $ echo other > other
  $ hg add other
  $ hg ci -m 'c_other'
  $ hg pull -r default --rebase
  pulling from $TESTTMP/jungle (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files (+1 heads)
  rebasing 3:dbc48dd9e743 "c_other"
  $ hg log -G
  @  7 () c_other
  |
  o  6 () c_zeta
  |
  o  5 () c_epsilon
  |
  o  4 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  
  $ cd ../jungle


Default destination for update
===============================

initial setup

  $ hg up elephant
  switching to topic elephant
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo arthur >> jungle
  $ hg ci -m arthur
  $ echo pompadour >> jungle
  $ hg ci -m pompadour
  $ hg up 'roots(all())'
  0 files updated, 0 files merged, 6 files removed, 0 files unresolved
  $ hg log -G
  o  15 (elephant) pompadour
  |
  o  14 (elephant) arthur
  |
  | o    13 (monkey) merge with default
  | |\
  o---+  12 (elephant) babar
   / /
  | o  11 () c_zeta
  | |
  o |  10 (monkey) Huc
  | |
  o |  8 (monkey) zephir
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  @  0 () c_alpha
  

testing default destination on a branch

  $ hg up
  5 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  o  15 (elephant) pompadour
  |
  o  14 (elephant) arthur
  |
  | o    13 (monkey) merge with default
  | |\
  o---+  12 (elephant) babar
   / /
  | @  11 () c_zeta
  | |
  o |  10 (monkey) Huc
  | |
  o |  8 (monkey) zephir
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  

extra setup for topic
(making sure tip is not the topic)

  $ hg up 'desc(c_zeta)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo 'eta' >> 'eta'
  $ hg add 'eta'
  $ hg commit -m 'c_eta'
  $ hg log -G
  @  16 () c_eta
  |
  | o  15 (elephant) pompadour
  | |
  | o  14 (elephant) arthur
  | |
  +---o  13 (monkey) merge with default
  | | |
  | o |  12 (elephant) babar
  |/ /
  o |  11 () c_zeta
  | |
  | o  10 (monkey) Huc
  | |
  | o  8 (monkey) zephir
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  

Testing default destination for topic

  $ hg up 'roots(topic(elephant))'
  switching to topic elephant
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg up
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  o  16 () c_eta
  |
  | @  15 (elephant) pompadour
  | |
  | o  14 (elephant) arthur
  | |
  +---o  13 (monkey) merge with default
  | | |
  | o |  12 (elephant) babar
  |/ /
  o |  11 () c_zeta
  | |
  | o  10 (monkey) Huc
  | |
  | o  8 (monkey) zephir
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  

Testing default destination for topic

  $ hg up 'p1(roots(topic(elephant)))'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic elephant
  $ hg up
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  o  16 () c_eta
  |
  | @  15 (elephant) pompadour
  | |
  | o  14 (elephant) arthur
  | |
  +---o  13 (monkey) merge with default
  | | |
  | o |  12 (elephant) babar
  |/ /
  o |  11 () c_zeta
  | |
  | o  10 (monkey) Huc
  | |
  | o  8 (monkey) zephir
  |/
  o  6 () c_epsilon
  |
  o  3 () c_delta
  |
  o  2 () c_gamma
  |
  o  1 () c_beta
  |
  o  0 () c_alpha
  

Default destination for histedit
================================

By default histedit should edit with the current topic only
(even when based on other draft

  $ hg phase 'desc(c_zeta)'
  11: draft
  $ HGEDITOR=cat hg histedit | grep pick
  pick e44744d9ad73 12 babar
  pick 38eea8439aee 14 arthur
  pick 411315c48bdc 15 pompadour
  #  p, pick = use commit
