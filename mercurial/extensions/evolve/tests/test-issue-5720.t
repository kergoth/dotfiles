This test file test the #5720 issue

Check that `hg evolve --continue` doesn't change changeset phase from secret
to draft after a merge conflict.

https://bz.mercurial-scm.org/show_bug.cgi?id=5720

Global setup
============

  $ . $TESTDIR/testlib/common.sh
  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = true
  > [phases]
  > publish=False
  > [extensions]
  > evolve =
  > EOF

Test
====

  $ hg init $TESTTMP/issue-5720
  $ cd $TESTTMP/issue-5720

Create two drafts commits and one secret
  $ echo a > a
  $ hg commit -Am a
  adding a
  $ echo b > a
  $ hg commit -m b
  $ echo c > a
  $ hg commit --secret -m c
  $ hg log -G -T "{rev}: {phase}"
  @  2: secret
  |
  o  1: draft
  |
  o  0: draft
  
Amend the second draft with new content
  $ hg prev
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [1] b
  $ echo b2 > a
  $ hg amend
  1 new orphan changesets
  $ hg log -G -T "{rev}: {phase}"
  @  3: draft
  |
  | o  2: secret
  | |
  | x  1: draft
  |/
  o  0: draft
  
Evolve which triggers a conflict
  $ hg evolve
  move:[2] c
  atop:[3] b
  merging a
  warning: conflicts while merging a! (edit, then use 'hg resolve --mark')
  evolve failed!
  fix conflict and run 'hg evolve --continue' or use 'hg update -C .' to abort
  abort: unresolved merge conflicts (see hg help resolve)
  [255]

Fix the conflict
  $ echo c2 > a
  $ hg resolve -m
  (no more unresolved files)

Continue the evolution
  $ hg evolve --continue
  evolving 2:13833940840c "c"

Tip should stay in secret phase
  $ hg log -G -T "{rev}: {phase}"
  @  4: secret
  |
  o  3: draft
  |
  o  0: draft
  
  $ hg log -r . -T '{phase}\n'
  secret
