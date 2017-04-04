  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [diff]
  > git = 1
  > unified = 0
  > [ui]
  > logtemplate = {rev}:{node|short}@{branch}({phase}) {desc|firstline}\n
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
  >    hg update "$1" -C
  >    shift
  >    mkcommits $*
  > }

  $ mkcommits() {
  >   for i in $@; do mkcommit $i ; done
  > }

==============================================================================
Test instability resolution for a changeset unstable because its parent
is obsolete with one successor
==============================================================================
  $ hg init test1
  $ cd test1
  $ mkcommits _a _b _c
  $ hg up "desc(_b)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg amend -m "bprime"
  1 new unstable changesets
  $ hg log -G
  @  3:36050226a9b9@default(draft) bprime
  |
  | o  2:102002290587@default(draft) add _c
  | |
  | x  1:37445b16603b@default(draft) add _b
  |/
  o  0:135f39f4bd78@default(draft) add _a
  

  $ hg evo --all --any --unstable
  move:[2] add _c
  atop:[3] bprime
  working directory is now at fdcf3523a74d
  $ hg log -G
  @  4:fdcf3523a74d@default(draft) add _c
  |
  o  3:36050226a9b9@default(draft) bprime
  |
  o  0:135f39f4bd78@default(draft) add _a
  

  $ cd ..

===============================================================================
Test instability resolution for a merge changeset unstable because one
of its parent is obsolete
Not supported yet
==============================================================================

  $ hg init test2
  $ cd test2
  $ mkcommit base
  $ mkcommits _a
  $ hg up "desc(base)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit _c
  created new head
  $ hg merge "desc(_a)" >/dev/null
  $ hg commit -m "merge"
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg amend -m "aprime"
  1 new unstable changesets
  $ hg log -G
  @  4:47127ea62e5f@default(draft) aprime
  |
  | o    3:6b4280e33286@default(draft) merge
  | |\
  +---o  2:474da87dd33b@default(draft) add _c
  | |
  | x  1:b3264cec9506@default(draft) add _a
  |/
  o  0:b4952fcf48cf@default(draft) add base
  

  $ hg evo --all --any --unstable
  move:[3] merge
  atop:[4] aprime
  working directory is now at 0bf3f3a59c8c
  $ hg log -G
  @    5:0bf3f3a59c8c@default(draft) merge
  |\
  | o  4:47127ea62e5f@default(draft) aprime
  | |
  o |  2:474da87dd33b@default(draft) add _c
  |/
  o  0:b4952fcf48cf@default(draft) add base
  

  $ cd ..

===============================================================================
Test instability resolution for a merge changeset unstable because both
of its parent are obsolete
Not supported yet
==============================================================================

  $ hg init test3
  $ cd test3
  $ mkcommit base
  $ mkcommits _a
  $ hg up "desc(base)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit _c
  created new head
  $ hg merge "desc(_a)" >/dev/null
  $ hg commit -m "merge"
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg amend -m "aprime"
  1 new unstable changesets
  $ hg up "desc(_c)"
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg amend -m "cprime"
  $ hg log -G
  @  5:2db39fda7e2f@default(draft) cprime
  |
  | o  4:47127ea62e5f@default(draft) aprime
  |/
  | o    3:6b4280e33286@default(draft) merge
  | |\
  +---x  2:474da87dd33b@default(draft) add _c
  | |
  | x  1:b3264cec9506@default(draft) add _a
  |/
  o  0:b4952fcf48cf@default(draft) add base
  

  $ hg evo --all --any --unstable
  warning: no support for evolving merge changesets with two obsolete parents yet
  (Redo the merge (6b4280e33286) and use `hg prune <old> --succ <new>` to obsolete the old one)
  $ hg log -G
  @  5:2db39fda7e2f@default(draft) cprime
  |
  | o  4:47127ea62e5f@default(draft) aprime
  |/
  | o    3:6b4280e33286@default(draft) merge
  | |\
  +---x  2:474da87dd33b@default(draft) add _c
  | |
  | x  1:b3264cec9506@default(draft) add _a
  |/
  o  0:b4952fcf48cf@default(draft) add base
  

  $ cd ..

===============================================================================
Test instability resolution for a changeset unstable because its parent
is obsolete with multiple successors all in one chain (simple split)
==============================================================================

  $ hg init test4
  $ cd test4
  $ mkcommits _a _b _c
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommits bprimesplit1 bprimesplit2
  created new head
  $ hg prune "desc(_b)" -s "desc(bprimesplit1) + desc(bprimesplit2)" --split
  1 changesets pruned
  1 new unstable changesets
  $ hg log -G
  @  4:2a4ccc0bb20c@default(draft) add bprimesplit2
  |
  o  3:8b87864bd0f4@default(draft) add bprimesplit1
  |
  | o  2:102002290587@default(draft) add _c
  | |
  | x  1:37445b16603b@default(draft) add _b
  |/
  o  0:135f39f4bd78@default(draft) add _a
  

  $ hg evo --all --any --unstable
  move:[2] add _c
  atop:[4] add bprimesplit2
  working directory is now at 387cc1e837d7
  $ hg log -G
  @  5:387cc1e837d7@default(draft) add _c
  |
  o  4:2a4ccc0bb20c@default(draft) add bprimesplit2
  |
  o  3:8b87864bd0f4@default(draft) add bprimesplit1
  |
  o  0:135f39f4bd78@default(draft) add _a
  


  $ cd ..

===============================================================================
Test instability resolution for a changeset unstable because its parent
is obsolete with multiple successors on one branches but in reverse
order (cross-split).
==============================================================================

  $ hg init test5
  $ cd test5
  $ mkcommits _a _b _c
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommits bprimesplit1 bprimesplit2
  created new head
  $ hg prune "desc(_b)" -s "desc(bprimesplit1) + desc(bprimesplit2)" --split
  1 changesets pruned
  1 new unstable changesets
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommits bsecondsplit1 bsecondsplit2
  created new head
  $ hg prune "desc(bprimesplit1)" -s "desc(bsecondsplit2)"
  1 changesets pruned
  1 new unstable changesets
  $ hg prune "desc(bprimesplit2)" -s "desc(bsecondsplit1)"
  1 changesets pruned
  $ hg log -G
  @  6:59b942dbda14@default(draft) add bsecondsplit2
  |
  o  5:8ffdae67d696@default(draft) add bsecondsplit1
  |
  | o  2:102002290587@default(draft) add _c
  | |
  | x  1:37445b16603b@default(draft) add _b
  |/
  o  0:135f39f4bd78@default(draft) add _a
  

  $ hg evo --all --any --unstable
  move:[2] add _c
  atop:[6] add bsecondsplit2
  working directory is now at 98e3f21461ff
  $ hg log -G
  @  7:98e3f21461ff@default(draft) add _c
  |
  o  6:59b942dbda14@default(draft) add bsecondsplit2
  |
  o  5:8ffdae67d696@default(draft) add bsecondsplit1
  |
  o  0:135f39f4bd78@default(draft) add _a
  


  $ cd ..

===============================================================================
Test instability resolution for a changeset unstable because its parent
is obsolete with multiple successors on two branches.
Not supported yet
==============================================================================

  $ hg init test6
  $ cd test6
  $ mkcommits _a _b _c
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit bprimesplit1
  created new head
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bprimesplit2
  created new head
  $ hg prune "desc(_b)" -s "desc(bprimesplit1) + desc(bprimesplit2)" --split
  1 changesets pruned
  1 new unstable changesets
  $ hg log -G
  @  4:3c69ea6aa93e@default(draft) add bprimesplit2
  |
  | o  3:8b87864bd0f4@default(draft) add bprimesplit1
  |/
  | o  2:102002290587@default(draft) add _c
  | |
  | x  1:37445b16603b@default(draft) add _b
  |/
  o  0:135f39f4bd78@default(draft) add _a
  

  $ hg evo --all --any --unstable
  cannot solve split accross two branches
  $ hg log -G
  @  4:3c69ea6aa93e@default(draft) add bprimesplit2
  |
  | o  3:8b87864bd0f4@default(draft) add bprimesplit1
  |/
  | o  2:102002290587@default(draft) add _c
  | |
  | x  1:37445b16603b@default(draft) add _b
  |/
  o  0:135f39f4bd78@default(draft) add _a
  


  $ cd ..

