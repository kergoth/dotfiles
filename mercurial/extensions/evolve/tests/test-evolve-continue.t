Testing the continue functionality of `hg evolve`

  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = True
  > [alias]
  > glog = log -GT "{rev}:{node|short} {desc}\n ({bookmarks}) {phase}"
  > [extensions]
  > rebase =
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

Setting up the repo

  $ hg init repo
  $ cd repo
  $ echo ".*\.orig" > .hgignore
  $ hg add .hgignore
  $ hg ci -m "added hgignore"
  $ for ch in a b c d; do echo foo>$ch; hg add $ch; hg ci -qm "added "$ch; done

  $ hg glog
  @  4:c41c793e0ef1 added d
  |   () draft
  o  3:ca1b80f7960a added c
  |   () draft
  o  2:b1661037fa25 added b
  |   () draft
  o  1:c7586e2a9264 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Simple case of evolve --continue

  $ hg up ca1b80f7960a
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo bar > d
  $ hg add d
  $ hg amend
  1 new orphan changesets
  $ hg glog
  @  5:cb6a2ab625bb added c
  |   () draft
  | *  4:c41c793e0ef1 added d
  | |   () draft
  | x  3:ca1b80f7960a added c
  |/    () draft
  o  2:b1661037fa25 added b
  |   () draft
  o  1:c7586e2a9264 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --all
  move:[4] added d
  atop:[5] added c
  merging d
  warning: conflicts while merging d! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo foo > d
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue

  $ hg evolve --continue
  evolving 4:c41c793e0ef1 "added d"
  working directory is now at 2a4e03d422e2

  $ hg glog
  @  6:2a4e03d422e2 added d
  |   () draft
  o  5:cb6a2ab625bb added c
  |   () draft
  o  2:b1661037fa25 added b
  |   () draft
  o  1:c7586e2a9264 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Case when conflicts resolution lead to empty wdir in evolve --continue

  $ echo foo > e
  $ hg ci -Aqm "added e"
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [6] added d
  $ echo bar > e
  $ hg add e
  $ hg amend
  1 new orphan changesets

  $ hg glog
  @  8:00a5c774cc37 added d
  |   () draft
  | *  7:ad0a59d83efe added e
  | |   () draft
  | x  6:2a4e03d422e2 added d
  |/    () draft
  o  5:cb6a2ab625bb added c
  |   () draft
  o  2:b1661037fa25 added b
  |   () draft
  o  1:c7586e2a9264 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve
  move:[7] added e
  atop:[8] added d
  merging e
  warning: conflicts while merging e! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo bar > e
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue
  $ hg diff

XXX: maybe we should add a message here about evolve resulting in no commit
  $ hg evolve --continue
  evolving 7:ad0a59d83efe "added e"

  $ hg glog
  @  8:00a5c774cc37 added d
  |   () draft
  o  5:cb6a2ab625bb added c
  |   () draft
  o  2:b1661037fa25 added b
  |   () draft
  o  1:c7586e2a9264 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Case when there are a lot of revision to continue

  $ hg up c7586e2a9264
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ echo bar > b
  $ hg add b
  $ hg amend
  3 new orphan changesets

  $ hg evolve --all
  move:[2] added b
  atop:[9] added a
  merging b
  warning: conflicts while merging b! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo foo > b
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue
  $ hg evolve --continue
  evolving 2:b1661037fa25 "added b"
  move:[5] added c
  atop:[10] added b
  move:[8] added d
  atop:[11] added c
  working directory is now at 6642d2c9176e

  $ hg glog
  @  12:6642d2c9176e added d
  |   () draft
  o  11:95665a2de664 added c
  |   () draft
  o  10:87f748868183 added b
  |   () draft
  o  9:53b632d203d8 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Conlicts -> resolve -> continue -> conflicts -> resolve -> continue
Test multiple conflicts in one evolve

  $ for ch in f g h; do echo foo > $ch; hg add $ch; hg ci -m "added "$ch; done;

  $ hg glog
  @  15:09becba8f97d added h
  |   () draft
  o  14:5aa7b2bbd944 added g
  |   () draft
  o  13:be88f889b6dc added f
  |   () draft
  o  12:6642d2c9176e added d
  |   () draft
  o  11:95665a2de664 added c
  |   () draft
  o  10:87f748868183 added b
  |   () draft
  o  9:53b632d203d8 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg up 95665a2de664
  1 files updated, 0 files merged, 4 files removed, 0 files unresolved

  $ echo bar > f
  $ echo bar > h
  $ hg add f h
  $ hg amend
  4 new orphan changesets

  $ hg glog
  @  16:645135c5caa4 added c
  |   () draft
  | *  15:09becba8f97d added h
  | |   () draft
  | *  14:5aa7b2bbd944 added g
  | |   () draft
  | *  13:be88f889b6dc added f
  | |   () draft
  | *  12:6642d2c9176e added d
  | |   () draft
  | x  11:95665a2de664 added c
  |/    () draft
  o  10:87f748868183 added b
  |   () draft
  o  9:53b632d203d8 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg evolve --all
  move:[12] added d
  atop:[16] added c
  move:[13] added f
  atop:[17] added d
  merging f
  warning: conflicts while merging f! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo foo > f
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue
  $ hg evolve --continue
  evolving 13:be88f889b6dc "added f"
  move:[14] added g
  atop:[18] added f
  move:[15] added h
  atop:[19] added g
  merging h
  warning: conflicts while merging h! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo foo > h
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue
  $ hg evolve --continue
  evolving 15:09becba8f97d "added h"
  working directory is now at 3ba9d3d1b089

Make sure, confirmopt is respected while continue

  $ hg glog
  @  20:3ba9d3d1b089 added h
  |   () draft
  o  19:981e615b14ca added g
  |   () draft
  o  18:5794f1a3cbb2 added f
  |   () draft
  o  17:e47537da02b3 added d
  |   () draft
  o  16:645135c5caa4 added c
  |   () draft
  o  10:87f748868183 added b
  |   () draft
  o  9:53b632d203d8 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

  $ hg up 5794f1a3cbb2
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo bar > g
  $ hg add g
  $ hg amend
  2 new orphan changesets

  $ hg evolve --all --confirm<<EOF
  > y
  > EOF
  move:[19] added g
  atop:[21] added f
  perform evolve? [Ny] y
  merging g
  warning: conflicts while merging g! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

  $ echo foo > g
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue

XXX: this should have asked for confirmation

  $ hg evolve --continue<<EOF
  > y
  > EOF
  evolving 19:981e615b14ca "added g"
  move:[20] added h
  atop:[22] added g
  perform evolve? [Ny] y
  working directory is now at af6bd002a48d

  $ hg glog
  @  23:af6bd002a48d added h
  |   () draft
  o  22:d2c94a8f44bd added g
  |   () draft
  o  21:9849fa96c885 added f
  |   () draft
  o  17:e47537da02b3 added d
  |   () draft
  o  16:645135c5caa4 added c
  |   () draft
  o  10:87f748868183 added b
  |   () draft
  o  9:53b632d203d8 added a
  |   () draft
  o  0:8fa14d15e168 added hgignore
      () draft

Testing `evolve --continue` after `hg next --evolve`

  $ hg up .^^
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo foobar > g
  $ hg amend
  2 new orphan changesets

  $ hg next --evolve
  move:[22] added g
  atop:[24] added f
  merging g
  warning: conflicts while merging g! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]
  $ echo foo > g
  $ hg resolve -m
  (no more unresolved files)
  continue: hg evolve --continue
  $ hg evolve --continue
  evolving 22:d2c94a8f44bd "added g"
