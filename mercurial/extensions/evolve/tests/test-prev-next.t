  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

hg prev -B should move active bookmark
  $ hg init
  $ touch a
  $ hg add a
  $ hg commit -m 'added a'
  $ touch b
  $ hg add b
  $ hg commit -m 'added b'
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
  hg update 1;
  hg bookmark mark -r 1;
  [1] added b
  $ hg next -B
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] added b
  $ hg bookmarks
   * mark                      1:6e742c9127b3

hg prev should unset active bookmark
  $ hg prev --dry-run
  hg update 0;
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
  hg update 1;
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
  hg update 1;
  [[evolve.rev|1]] added b
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [1] added b

some aspiring children

  $ hg amend -m 'added b (2)'
  1 new unstable changesets
  $ hg next
  no children
  (1 unstable changesets to be evolved here, do you want --evolve?)
  [1]
  $ hg next --evolve --dry-run
  move:[2] added c
  atop:[3] added b (2)
  hg rebase -r 4e26ef31f919 -d 9ad178109a19
  working directory now at 9ad178109a19

(add color output for smoke testing)

  $ hg next --evolve --color debug
  move:[[evolve.rev|2]] added c
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
  $ hg next
  ambigious next changeset:
  [4] added c
  [5] added d
  explicitly update to one of them
  [1]

next with ambiguity in aspiring children

  $ hg am -m 'added b (3)'
  2 new unstable changesets
  $ hg next
  no children
  (2 unstable changesets to be evolved here, do you want --evolve?)
  [1]
  $ hg next --evolve
  ambigious next (unstable) changeset:
  [4] added c
  [5] added d
  (run 'hg evolve --rev REV' on one of them)
  [1]
  $ hg evolve -r 5
  move:[5] added d
  atop:[6] added b (3)
  working directory is now at 47ea25be8aea

prev and next should lock properly against other commands

  $ hg init repo
  $ cd repo
  $ HGEDITOR=${TESTDIR}/fake-editor.sh
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
  1 new unstable changesets
  got lock after [4-6] seconds (re)
  move:[2] two
  atop:[3] one
  working directory now at a7d885c75614
  $ wait
