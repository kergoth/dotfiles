  $ . "$TESTDIR/histedit-helpers.sh"

  $  cat >> $HGRCPATH <<EOF
  > [extensions]
  > hgext.graphlog=
  > EOF

  $ echo "histedit=$(echo $(dirname $TESTDIR))/hg_histedit.py" >> $HGRCPATH
  $ hg init r
  $ cd r
See if bookmarks are in core. If not, then we don't support bookmark
motion on this version of hg.
  $ hg bookmarks || exit 80
  no bookmarks set
  $ for x in a b c d e f ; do
  >     echo $x > $x
  >     hg add $x
  >     hg ci -m $x
  > done

  $ hg book -r 1 will-move-backwards
  $ hg book -r 2 two
  $ hg book -r 2 also-two
  $ hg book -r 3 three
  $ hg book -r 4 four
  $ hg book -r tip five
  $ hg log --graph
  @  changeset:   5:652413bf663e
  |  bookmark:    five
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     f
  |
  o  changeset:   4:e860deea161a
  |  bookmark:    four
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     e
  |
  o  changeset:   3:055a42cdd887
  |  bookmark:    three
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     d
  |
  o  changeset:   2:177f92b77385
  |  bookmark:    also-two
  |  bookmark:    two
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     c
  |
  o  changeset:   1:d2ae7f538514
  |  bookmark:    will-move-backwards
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     b
  |
  o  changeset:   0:cb9a9f314b8b
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     a
  
  $ HGEDITOR=cat hg histedit 1
  pick d2ae7f538514 1 b
  pick 177f92b77385 2 c
  pick 055a42cdd887 3 d
  pick e860deea161a 4 e
  pick 652413bf663e 5 f
  
  # Edit history between d2ae7f538514 and 652413bf663e
  #
  # Commands:
  #  p, pick = use commit
  #  e, edit = use commit, but stop for amending
  #  f, fold = use commit, but fold into previous commit (combines N and N-1)
  #  d, drop = remove commit from history
  #  m, mess = edit message without changing commit content
  #
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat >> commands.txt <<EOF
  > pick 177f92b77385 2 c
  > drop d2ae7f538514 1 b
  > pick 055a42cdd887 3 d
  > fold e860deea161a 4 e
  > pick 652413bf663e 5 f
  > EOF
  $ hg histedit 1 --commands commands.txt --verbose | grep histedit
  histedit: Should update metadata for the following changes:
  histedit:  055a42cdd887 to ae467701c500
  histedit:     moving bookmarks three
  histedit:  652413bf663e to 0efacef7cb48
  histedit:     moving bookmarks five
  histedit:  d2ae7f538514 to cb9a9f314b8b
  histedit:     moving bookmarks will-move-backwards
  histedit:  e860deea161a to ae467701c500
  histedit:     moving bookmarks four
  histedit:  177f92b77385 to d36c0562f908
  histedit:     moving bookmarks also-two, two
  saved backup bundle to $TESTTMP/r/.hg/strip-backup/d2ae7f538514-backup.hg
  saved backup bundle to $TESTTMP/r/.hg/strip-backup/34a9919932c1-backup.hg
  $ hg log --graph
  @  changeset:   3:0efacef7cb48
  |  bookmark:    five
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     f
  |
  o  changeset:   2:ae467701c500
  |  bookmark:    four
  |  bookmark:    three
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     d
  |
  o  changeset:   1:d36c0562f908
  |  bookmark:    also-two
  |  bookmark:    two
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     c
  |
  o  changeset:   0:cb9a9f314b8b
     bookmark:    will-move-backwards
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     a
  
