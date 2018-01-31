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
  (consider using topic for lightweight branches. See 'hg help topic')


Add some topics
---------------

A simple topic that need rebasing

  $ hg up 'desc(base_c)'
  2 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg topic baz
  marked working directory as topic: baz
  $ mkcommit baz_a
  active topic 'baz' grew its first changeset
  $ mkcommit baz_b

A simple topic with unstability

  $ hg up 'desc(base_d)'
  1 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg topic fuz
  marked working directory as topic: fuz
  $ mkcommit fuz_a
  active topic 'fuz' grew its first changeset
  $ mkcommit fuz_b
  $ mkcommit fuz_c
  $ hg up 'desc(fuz_a)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg commit --amend --message 'fuz1_a'
  2 new orphan changesets

A topic with multiple heads

  $ hg up 'desc(base_e)'
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic bar
  marked working directory as topic: bar
  $ mkcommit bar_a
  active topic 'bar' grew its first changeset
  $ mkcommit bar_b
  $ mkcommit bar_c
  $ hg up 'desc(bar_b)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bar_d
  $ mkcommit bar_e
  $ hg up 'desc(bar_d)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg commit --amend --message 'bar1_d'
  1 new orphan changesets

topic 'foo' on the multi headed branch

  $ hg up 'desc(lake_a)'
  1 files updated, 0 files merged, 7 files removed, 0 files unresolved
  $ hg topic foo
  marked working directory as topic: foo
  $ mkcommit foo_a
  active topic 'foo' grew its first changeset
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
  orphan: 3 changesets
  topic:  foo
  $ hg log --graph -T '{desc} ({branch}) [{topic}]'
  @  add foo_b (lake) [foo]
  |
  o  add foo_a (lake) [foo]
  |
  | o  bar1_d (default) [bar]
  | |
  | | *  add bar_e (default) [bar]
  | | |
  | | x  add bar_d (default) [bar]
  | |/
  | | o  add bar_c (default) [bar]
  | |/
  | o  add bar_b (default) [bar]
  | |
  | o  add bar_a (default) [bar]
  | |
  | | o  fuz1_a (default) [fuz]
  | | |
  | | | *  add fuz_c (default) [fuz]
  | | | |
  | | | *  add fuz_b (default) [fuz]
  | | | |
  | | | x  add fuz_a (default) [fuz]
  | | |/
  | | | o  add baz_b (default) [baz]
  | | | |
  | | | o  add baz_a (default) [baz]
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
     bar (5 changesets, 1 troubled, 2 heads)
     baz (2 changesets)
   * foo (2 changesets)
     fuz (3 changesets, 2 troubled)

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
   * foo (on branch: lake, 2 changesets, ambiguous destination: branch 'lake' has 2 heads)
     fuz (on branch: default, 3 changesets, 2 troubled, 1 behind)

json

  $ hg topic -T json
  [
   {
    "active": false,
    "changesetcount": 5,
    "headcount": 2,
    "topic": "bar",
    "troubledcount": 1
   },
   {
    "active": false,
    "changesetcount": 2,
    "topic": "baz"
   },
   {
    "active": true,
    "changesetcount": 2,
    "topic": "foo"
   },
   {
    "active": false,
    "changesetcount": 3,
    "topic": "fuz",
    "troubledcount": 2
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
    "behinderror": "ambiguous destination: branch 'lake' has 2 heads",
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
  ### target: default (branch)
  t5: add bar_c
  t2^ add bar_b (base)
  t4$ add bar_e (unstable)
  t3: bar1_d
  t2: add bar_b
  t1: add bar_a
  t0^ add base_e (base)
  $ hg stack bar -v
  ### topic: bar (2 heads)
  ### target: default (branch)
  t5(9cbadf11b44d): add bar_c
  t2(e555c7e8c767)^ add bar_b (base)
  t4(a920412b5a05)$ add bar_e (unstable)
  t3(6915989374b1): bar1_d
  t2(e555c7e8c767): add bar_b
  t1(a5c2b4e00bbf): add bar_a
  t0(92f489a6251f)^ add base_e (base)
  $ hg stack baz
  ### topic: baz
  ### target: default (branch), 2 behind
  t2: add baz_b
  t1: add baz_a
  t0^ add base_c (base)
  $ hg stack foo
  ### topic: foo
  ### target: lake (branch), ambiguous rebase destination - branch 'lake' has 2 heads
  t2@ add foo_b (current)
  t1: add foo_a
  t0^ add lake_a (base)
  $ hg stack fuz
  ### topic: fuz
  ### target: default (branch), 1 behind
  t3$ add fuz_c (unstable)
  t2$ add fuz_b (unstable)
  t1: fuz1_a
  t0^ add base_d (base)
