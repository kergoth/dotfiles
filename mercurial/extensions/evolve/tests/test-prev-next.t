  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = True
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

hg prev & next move to parent/child
  $ hg init test-repo
  $ cd test-repo
  $ touch a
  $ hg add a
  $ hg commit -m 'added a'
  $ touch b
  $ hg add b
  $ hg commit -m 'added b'
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [0] added a
  $ hg next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] added b

hg prev & next respect --quiet
  $ hg prev -q
  $ hg next -q

hg prev -B should move active bookmark
  $ hg bookmark mark
  $ hg bookmarks
   * mark                      1:6e742c9127b3
  $ hg prev -B
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [0] added a
  $ hg bookmarks
   * mark                      0:a154386e50d1

hg next -B should move active bookmark
  $ hg next -B --dry-run
  hg update 6e742c9127b3;
  hg bookmark mark -r 6e742c9127b3;
  [1] added b
  $ hg next -B
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] added b
  $ hg bookmarks
   * mark                      1:6e742c9127b3

hg prev should unset active bookmark
  $ hg prev --dry-run
  hg update a154386e50d1;
  [0] added a
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [0] added a
  $ hg bookmarks
     mark                      1:6e742c9127b3

hg next should move active bookmark
  $ hg bookmark mark2
  $ hg bookmarks
     mark                      1:6e742c9127b3
   * mark2                     0:a154386e50d1
  $ hg next --dry-run --color=debug
  hg update 6e742c9127b3;
  [[evolve.rev|1]] added b
  $ hg next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] added b
  $ hg bookmarks
     mark                      1:6e742c9127b3
     mark2                     0:a154386e50d1

  $ hg bookmark -d mark2
  $ hg bookmark mark

hg next/prev should not interfere with inactive bookmarks
  $ touch c
  $ hg add c
  $ hg commit -m 'added c'
  $ hg bookmark -r2 no-move
  $ hg prev -B
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] added b
  $ hg bookmarks
   * mark                      1:6e742c9127b3
     no-move                   2:4e26ef31f919
  $ hg next -B
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [2] added c
  $ hg bookmarks
   * mark                      2:4e26ef31f919
     no-move                   2:4e26ef31f919
  $ hg up 1
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  (leaving bookmark mark)
  $ hg next -B
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [2] added c
  $ hg bookmarks
     mark                      2:4e26ef31f919
     no-move                   2:4e26ef31f919
  $ hg prev -B
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] added b
  $ hg bookmarks
     mark                      2:4e26ef31f919
     no-move                   2:4e26ef31f919

test prev on root

  $ hg up null
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg prev
  already at repository root
  [1]
  $ hg up 1
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

Behavior with local modification
--------------------------------

  $ echo foo > modified-bar
  $ hg add modified-bar
  $ hg prev
  abort: uncommitted changes
  (do you want --merge?)
  [255]
  $ hg prev --merge
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [0] added a
  $ hg next
  abort: uncommitted changes
  (do you want --merge?)
  [255]
  $ hg next --merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] added b

Behavior with aspiring children
-------------------------------

  $ hg revert --all
  forgetting modified-bar
  $ hg log -G
  o  changeset:   2:4e26ef31f919
  |  bookmark:    mark
  |  bookmark:    no-move
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     added c
  |
  @  changeset:   1:6e742c9127b3
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     added b
  |
  o  changeset:   0:a154386e50d1
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     added a
  

no children of any kind

  $ hg next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [2] added c
  $ hg next
  no children
  [1]
  $ hg next --evolve
  no children
  [1]
  $ hg prev --dry-run --color=debug
  hg update 6e742c9127b3;
  [[evolve.rev|1]] added b
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] added b

some aspiring children

  $ hg amend -m 'added b (2)'
  1 new orphan changesets
  $ hg next
  no children
  (1 unstable changesets to be evolved here, do you want --evolve?)
  [1]
  $ hg next --evolve --dry-run
  move:[2] added c
  atop:[3] added b (2)
  hg rebase -r 4e26ef31f919 -d 9ad178109a19

(add color output for smoke testing)

  $ hg next --evolve --color debug
  [evolve.operation|move:][[evolve.rev|2]] added c
  atop:[[evolve.rev|3]] added b (2)
  [ ui.status|working directory now at [evolve.node|e3b6d5df389b]]

next with ambiguity

  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [3] added b (2)
  $ echo d > d
  $ hg add d
  $ hg commit -m 'added d'
  created new head
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [3] added b (2)
  $ hg next <<EOF
  > 1
  > EOF
  ambiguous next changeset, choose one to update:
  0: [e3b6d5df389b] added c
  1: [9df671ccd2c7] added d
  q: quit the prompt
  enter the index of the revision you want to select: 1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [5] added d

  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [3] added b (2)

next with ambiguity in aspiring children

  $ hg am -m 'added b (3)'
  2 new orphan changesets
  $ hg next
  no children
  (2 unstable changesets to be evolved here, do you want --evolve?)
  [1]
  $ hg next --evolve <<EOF
  > 0
  > EOF
  ambiguous next (unstable) changeset, choose one to evolve and update:
  0: [e3b6d5df389b] added c
  1: [9df671ccd2c7] added d
  q: quit the prompt
  enter the index of the revision you want to select: 0
  move:[4] added c
  atop:[6] added b (3)
  working directory now at 5ce67c2407b0

  $ hg log -GT "{rev}:{node|short} {desc}\n"
  @  7:5ce67c2407b0 added c
  |
  o  6:d7f119adc759 added b (3)
  |
  | *  5:9df671ccd2c7 added d
  | |
  | x  3:9ad178109a19 added b (2)
  |/
  o  0:a154386e50d1 added a
  

  $ hg evolve -r 5
  move:[5] added d
  atop:[6] added b (3)
  working directory is now at 47ea25be8aea

prev with multiple parents

  $ hg log -GT "{rev}:{node|short} {desc}\n"
  @  8:47ea25be8aea added d
  |
  | o  7:5ce67c2407b0 added c
  |/
  o  6:d7f119adc759 added b (3)
  |
  o  0:a154386e50d1 added a
  
  $ hg merge -r 5ce67c2407b0
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m "merge commit"

  $ hg prev <<EOF
  > q
  > EOF
  multiple parents, choose one to update:
  0: [47ea25be8aea] added d
  1: [5ce67c2407b0] added c
  q: quit the prompt
  enter the index of the revision you want to select: q
  [8] added d
  [7] added c
  multiple parents, explicitly update to one
  [1]

  $ hg prev --config ui.interactive=False
  [8] added d
  [7] added c
  multiple parents, explicitly update to one
  [1]

  $ hg prev <<EOF
  > 1
  > EOF
  multiple parents, choose one to update:
  0: [47ea25be8aea] added d
  1: [5ce67c2407b0] added c
  q: quit the prompt
  enter the index of the revision you want to select: 1
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [7] added c

  $ hg log -GT "{rev}:{node|short} {desc}\n"
  o    9:a4b8c25a87d3 merge commit
  |\
  | o  8:47ea25be8aea added d
  | |
  @ |  7:5ce67c2407b0 added c
  |/
  o  6:d7f119adc759 added b (3)
  |
  o  0:a154386e50d1 added a
  

  $ cd ..

prev and next should lock properly against other commands

  $ hg init repo
  $ cd repo
  $ HGEDITOR="sh ${TESTDIR}/fake-editor.sh"
  $ echo hi > foo
  $ hg ci -Am 'one'
  adding foo
  $ echo bye > foo
  $ hg ci -Am 'two'

  $ hg amend --edit &
  $ sleep 1
  $ hg prev
  waiting for lock on working directory of $TESTTMP/repo held by process '*' on host '*' (glob)
  got lock after [4-6] seconds (re)
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [0] one
  $ wait

  $ hg amend --edit &
  $ sleep 1
  $ hg next --evolve
  waiting for lock on working directory of $TESTTMP/repo held by process '*' on host '*' (glob)
  1 new orphan changesets
  got lock after [4-6] seconds (re)
  move:[2] two
  atop:[3] one
  working directory now at a7d885c75614
  $ wait
