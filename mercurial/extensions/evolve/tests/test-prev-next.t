  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> $HGRCPATH

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
  $ hg next -B
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] added b
  $ hg bookmarks
   * mark                      1:6e742c9127b3

hg prev should unset active bookmark
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
