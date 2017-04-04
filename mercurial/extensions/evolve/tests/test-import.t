
This feature requires mercurial 3.0
(and the `only()` revset is 3.0 specific)

  $ (hg help revset | grep '"only(' > /dev/null) || exit 80

Test creation of obsolescence marker by path import

  $ hg init auto-obsolete
  $ cd auto-obsolete
  $ echo '[extensions]' >> $HGRCPATH
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ echo A > a
  $ hg commit -Am A
  adding a
  $ echo B > b
  $ hg commit -Am B
  adding b
  $ hg up '.^'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo C > c
  $ hg commit -Am C
  adding c
  created new head
  $ hg log -G
  @  changeset:   2:eb8dd0f31b51
  |  tag:         tip
  |  parent:      0:f2bbf19cf96d
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C
  |
  | o  changeset:   1:95b760afef3c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     B
  |
  o  changeset:   0:f2bbf19cf96d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     A
  

(actual test)

  $ hg export 'desc(B)' | hg import - --obsolete
  applying patch from stdin
  $ hg log -G
  @  changeset:   3:00c49133f17e
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     B
  |
  o  changeset:   2:eb8dd0f31b51
  |  parent:      0:f2bbf19cf96d
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C
  |
  o  changeset:   0:f2bbf19cf96d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     A
  
  $ hg debugobsolete
  95b760afef3c234ffb3f9fd391edcb36e60921a4 00c49133f17e5e5a52b6ef1b6d516c0e90b56d8a 0 (*) {'user': 'test'} (glob)

  $ hg rollback
  repository tip rolled back to revision 2 (undo import)
  working directory now based on revision 2
  $ hg log -G
  @  changeset:   2:eb8dd0f31b51
  |  tag:         tip
  |  parent:      0:f2bbf19cf96d
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     C
  |
  | o  changeset:   1:95b760afef3c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     B
  |
  o  changeset:   0:f2bbf19cf96d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     A
  
  $ hg debugobsolete

