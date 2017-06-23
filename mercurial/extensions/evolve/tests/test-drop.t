
  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ echo "drophack=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/hack/drophack.py" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }
  $ summary() {
  > echo ============ graph ==============
  > hg log -G
  > echo ============ hidden =============
  > hg log --hidden -G
  > echo ============ obsmark ============
  > hg debugobsolete
  > }


  $ hg init repo
  $ cd repo
  $ mkcommit base

drop a single changeset without any rewrite
================================================


  $ mkcommit simple-single
  $ summary
  ============ graph ==============
  @  changeset:   1:d4e7845543ff
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add simple-single
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ hidden =============
  @  changeset:   1:d4e7845543ff
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add simple-single
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ obsmark ============
  $ hg drop .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at b4952fcf48cf
  search obsmarker: wall * comb * user * sys * (glob)
  0 obsmarkers found
  search nodes: wall * comb * user * sys * (glob)
  1 nodes found
  saved backup bundle to $TESTTMP/repo/.hg/strip-backup/d4e7845543ff-8ad8efe0-drophack.hg (glob)
  strip nodes: wall * comb * user * sys * (glob)
  $ summary
  ============ graph ==============
  @  changeset:   0:b4952fcf48cf
     tag:         tip
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ hidden =============
  @  changeset:   0:b4952fcf48cf
     tag:         tip
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ obsmark ============

Try to drop a changeset with children
================================================

  $ mkcommit parent
  $ mkcommit child
  $ summary
  ============ graph ==============
  @  changeset:   2:34b6c051bf1f
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add child
  |
  o  changeset:   1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ hidden =============
  @  changeset:   2:34b6c051bf1f
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add child
  |
  o  changeset:   1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ obsmark ============
  $ hg drop 1
  cannot drop revision with children (no-eol)
  [1]
  $ summary
  ============ graph ==============
  @  changeset:   2:34b6c051bf1f
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add child
  |
  o  changeset:   1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ hidden =============
  @  changeset:   2:34b6c051bf1f
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add child
  |
  o  changeset:   1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ obsmark ============

Try to drop a public changeset
================================================

  $ hg phase --public 2
  $ hg drop 2
  cannot drop public revision (no-eol)
  [1]


Try to drop a changeset with rewrite
================================================

  $ hg phase --force --draft 2
  $ echo babar >> child
  $ hg commit --amend
  $ summary
  ============ graph ==============
  @  changeset:   4:a2c06c884bfe
  |  tag:         tip
  |  parent:      1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add child
  |
  o  changeset:   1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ hidden =============
  @  changeset:   4:a2c06c884bfe
  |  tag:         tip
  |  parent:      1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add child
  |
  | x  changeset:   3:87ea30a976fd
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     temporary amend commit for 34b6c051bf1f
  | |
  | x  changeset:   2:34b6c051bf1f
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     add child
  |
  o  changeset:   1:19509a42b0d0
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ obsmark ============
  34b6c051bf1f78db6aef400776de5cb964470207 a2c06c884bfe53d3840026248bd8a7eafa152df8 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  87ea30a976fdf235bf096f04899cb02a903873e2 0 {34b6c051bf1f78db6aef400776de5cb964470207} (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg drop .
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  working directory now at 19509a42b0d0
  search obsmarker: wall * comb * user * sys * (glob)
  1 obsmarkers found
  search nodes: wall * comb * user * sys * (glob)
  2 nodes found
  strip obsmarker: wall * comb * user * sys * (glob)
  saved backup bundle to $TESTTMP/repo/.hg/strip-backup/*-drophack.hg (glob)
  strip nodes: wall * comb * user * sys * (glob)
  $ summary
  ============ graph ==============
  @  changeset:   1:19509a42b0d0
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ hidden =============
  @  changeset:   1:19509a42b0d0
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add parent
  |
  o  changeset:   0:b4952fcf48cf
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add base
  
  ============ obsmark ============
  87ea30a976fdf235bf096f04899cb02a903873e2 0 {34b6c051bf1f78db6aef400776de5cb964470207} (*) {'ef1': '0', 'user': 'test'} (glob)
