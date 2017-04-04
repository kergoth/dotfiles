Setup
=====

  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ hg init test-list
  $ cd test-list
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > # disable the new graph style until we drop 3.7 support
  > graphstyle.missing = |
  > # turn evolution on
  > evolution=all
  > EOF


  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

Build some basic graph
----------------------

  $ for x in base_a base_b base_c base_d base_e ; do
  >   mkcommit $x
  > done

Add another branch with two heads

  $ hg up 'desc(base_a)'
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ hg branch lake
  marked working directory as branch lake
  (branches are permanent and global, did you want a bookmark?)
  $ mkcommit lake_a
  $ mkcommit lake_b
  $ hg up 'desc(lake_a)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit lake_c
  created new head


Add some topics
---------------

A simple topic that need rebasing

  $ hg up 'desc(base_c)'
  2 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg topic baz
  $ mkcommit baz_a
  $ mkcommit baz_b

A simple topic with unstability

  $ hg up 'desc(base_d)'
  1 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg topic fuz
  $ mkcommit fuz_a
  $ mkcommit fuz_b
  $ mkcommit fuz_c
  $ hg up 'desc(fuz_a)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg commit --amend --message 'fuz1_a'

A topic with multiple heads

  $ hg up 'desc(base_e)'
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic bar
  $ mkcommit bar_a
  $ mkcommit bar_b
  $ mkcommit bar_c
  $ hg up 'desc(bar_b)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bar_d
  $ mkcommit bar_e
  $ hg up 'desc(bar_d)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg commit --amend --message 'bar1_d'

topic 'foo' on the multi headed branch

  $ hg up 'desc(lake_a)'
  1 files updated, 0 files merged, 7 files removed, 0 files unresolved
  $ hg topic foo
  $ mkcommit foo_a
  $ mkcommit foo_b

Summary
-------

  $ hg summary
  parent: 21:3e54b49a3113 tip
   add foo_b
  branch: lake
  commit: (clean)
  update: 2 new changesets (update)
  phases: 22 draft
  unstable: 3 changesets
  topic:  foo
  $ hg log --graph -T '{desc} ({branch}) [{topic}]'
  @  add foo_b (lake) []
  |
  o  add foo_a (lake) []
  |
  | o  bar1_d (default) []
  | |
  | | o  add bar_e (default) []
  | | |
  | | x  add bar_d (default) []
  | |/
  | | o  add bar_c (default) []
  | |/
  | o  add bar_b (default) []
  | |
  | o  add bar_a (default) []
  | |
  | | o  fuz1_a (default) []
  | | |
  | | | o  add fuz_c (default) []
  | | | |
  | | | o  add fuz_b (default) []
  | | | |
  | | | x  add fuz_a (default) []
  | | |/
  | | | o  add baz_b (default) []
  | | | |
  | | | o  add baz_a (default) []
  | | | |
  +-------o  add lake_c (lake) []
  | | | |
  +-------o  add lake_b (lake) []
  | | | |
  o | | |  add lake_a (lake) []
  | | | |
  | o | |  add base_e (default) []
  | |/ /
  | o /  add base_d (default) []
  | |/
  | o  add base_c (default) []
  | |
  | o  add base_b (default) []
  |/
  o  add base_a (default) []
  

Actual Testing
==============

basic output

  $ hg topic
     bar
     baz
   * foo
     fuz

quiet version

  $ hg topic --quiet
  bar
  baz
  foo
  fuz

verbose

  $ hg topic --verbose
     bar (on branch: default, 5 changesets, 1 troubled, 2 heads)
     baz (on branch: default, 2 changesets, 2 behind)
   * foo (on branch: lake, 2 changesets, ambiguous destination)
     fuz (on branch: default, 3 changesets, 2 troubled, 1 behind)

json

  $ hg topic -T json
  [
   {
    "active": false,
    "topic": "bar"
   },
   {
    "active": false,
    "topic": "baz"
   },
   {
    "active": true,
    "topic": "foo"
   },
   {
    "active": false,
    "topic": "fuz"
   }
  ]

json --verbose

  $ hg topic -T json --verbose
  [
   {
    "active": false,
    "branches+": "default",
    "changesetcount": 5,
    "headcount": 2,
    "topic": "bar",
    "troubledcount": 1
   },
   {
    "active": false,
    "behindcount": 2,
    "branches+": "default",
    "changesetcount": 2,
    "topic": "baz"
   },
   {
    "active": true,
    "behinderror": "ambiguous destination",
    "branches+": "lake",
    "changesetcount": 2,
    "topic": "foo"
   },
   {
    "active": false,
    "behindcount": 1,
    "branches+": "default",
    "changesetcount": 3,
    "topic": "fuz",
    "troubledcount": 2
   }
  ]

Also test this situation with 'hg stack'
=======================================

  $ hg stack bar
  ### topic: bar (2 heads)
  ### branch: default
  t5: add bar_c
  t2^ add bar_b (base)
  t4$ add bar_e (unstable)
  t3: bar1_d
  t2: add bar_b
  t1: add bar_a
    ^ add base_e
  $ hg stack baz
  ### topic: baz
  ### branch: default, 2 behind
  t2: add baz_b
  t1: add baz_a
    ^ add base_c
  $ hg stack foo
  ### topic: foo
  ### branch: lake, ambigious rebase destination
  t2@ add foo_b (current)
  t1: add foo_a
    ^ add lake_a
  $ hg stack fuz
  ### topic: fuz
  ### branch: default, 1 behind
  t3$ add fuz_c (unstable)
  t2$ add fuz_b (unstable)
  t1: fuz1_a
    ^ add base_d
