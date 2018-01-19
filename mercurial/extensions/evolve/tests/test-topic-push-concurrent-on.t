# same as test-topic-push but with the concurrent push feature on

  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ cat << EOF >> $HGRCPATH
  > [ui]
  > logtemplate = {rev} {branch} {get(namespaces, "topics")} {phase} {desc|firstline}\n
  > ssh =python "$RUNTESTDIR/dummyssh"
  > [server]
  > concurrent-push-mode=check-related
  > EOF

  $ hg init main
  $ hg init draft
  $ cat << EOF >> draft/.hg/hgrc
  > [phases]
  > publish=False
  > EOF
  $ hg clone main client
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat << EOF >> client/.hg/hgrc
  > [paths]
  > draft=../draft
  > EOF


Testing core behavior to make sure we did not break anything
============================================================

Pushing a first changeset

  $ cd client
  $ echo aaa > aaa
  $ hg add aaa
  $ hg commit -m 'CA'
  $ hg outgoing -G
  comparing with $TESTTMP/main (glob)
  searching for changes
  @  0 default  draft CA
  
  $ hg push
  pushing to $TESTTMP/main (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

Pushing two heads

  $ echo aaa > bbb
  $ hg add bbb
  $ hg commit -m 'CB'
  $ echo aaa > ccc
  $ hg up 'desc(CA)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg add ccc
  $ hg commit -m 'CC'
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg outgoing -G
  comparing with $TESTTMP/main (glob)
  searching for changes
  @  2 default  draft CC
  
  o  1 default  draft CB
  
  $ hg push
  pushing to $TESTTMP/main (glob)
  searching for changes
  abort: push creates new remote head 9fe81b7f425d!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg outgoing -r 'desc(CB)' -G
  comparing with $TESTTMP/main (glob)
  searching for changes
  o  1 default  draft CB
  
  $ hg push -r 'desc(CB)'
  pushing to $TESTTMP/main (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

Pushing a new branch

  $ hg branch mountain
  marked working directory as branch mountain
  (branches are permanent and global, did you want a bookmark?)
  $ hg commit --amend
  $ hg outgoing -G
  comparing with $TESTTMP/main (glob)
  searching for changes
  @  3 mountain  draft CC
  
  $ hg push 
  pushing to $TESTTMP/main (glob)
  searching for changes
  abort: push creates new remote branches: mountain!
  (use 'hg push --new-branch' to create new remote branches)
  [255]
  $ hg push --new-branch
  pushing to $TESTTMP/main (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  1 new obsolescence markers

Including on non-publishing

  $ hg push --new-branch draft
  pushing to $TESTTMP/draft (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files (+1 heads)
  1 new obsolescence markers

Testing topic behavior
======================

Local peer tests
----------------

  $ hg up -r 'desc(CA)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic babar
  marked working directory as topic: babar
  $ echo aaa > ddd
  $ hg add ddd
  $ hg commit -m 'CD'
  active topic 'babar' grew its first changeset
  $ hg log -G # keep track of phase because I saw some strange bug during developement
  @  4 default babar draft CD
  |
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

Pushing a new topic to a non publishing server should not be seen as a new head

  $ hg push draft
  pushing to $TESTTMP/draft (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  $ hg log -G
  @  4 default babar draft CD
  |
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

Pushing a new topic to a publishing server should be seen as a new head

  $ hg push
  pushing to $TESTTMP/main (glob)
  searching for changes
  abort: push creates new remote head 67f579af159d!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg log -G
  @  4 default babar draft CD
  |
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

wireprotocol tests
------------------

  $ hg up -r 'desc(CA)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic celeste
  marked working directory as topic: celeste
  $ echo aaa > eee
  $ hg add eee
  $ hg commit -m 'CE'
  active topic 'celeste' grew its first changeset
  $ hg log -G # keep track of phase because I saw some strange bug during developement
  @  5 default celeste draft CE
  |
  | o  4 default babar draft CD
  |/
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

Pushing a new topic to a non publishing server without topic -> new head

  $ cat << EOF >> ../draft/.hg/hgrc
  > [extensions]
  > topic=!
  > EOF
  $ hg push ssh://user@dummy/draft
  pushing to ssh://user@dummy/draft
  searching for changes
  abort: push creates new remote head 84eaf32db6c3!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg log -G
  @  5 default celeste draft CE
  |
  | o  4 default babar draft CD
  |/
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

Pushing a new topic to a non publishing server should not be seen as a new head

  $ printf "topic=" >> ../draft/.hg/hgrc
  $ hg config extensions.topic >> ../draft/.hg/hgrc
  $ hg push ssh://user@dummy/draft
  pushing to ssh://user@dummy/draft
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  $ hg log -G
  @  5 default celeste draft CE
  |
  | o  4 default babar draft CD
  |/
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

Pushing a new topic to a publishing server should be seen as a new head

  $ hg push ssh://user@dummy/main
  pushing to ssh://user@dummy/main
  searching for changes
  abort: push creates new remote head 67f579af159d!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg log -G
  @  5 default celeste draft CE
  |
  | o  4 default babar draft CD
  |/
  | o  3 mountain  public CC
  |/
  | o  1 default  public CB
  |/
  o  0 default  public CA
  

Check that we reject multiple head on the same topic
----------------------------------------------------

  $ hg up 'desc(CB)'
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg topic babar
  marked working directory as topic: babar
  $ echo aaa > fff
  $ hg add fff
  $ hg commit -m 'CF'
  $ hg log -G
  @  6 default babar draft CF
  |
  | o  5 default celeste draft CE
  | |
  | | o  4 default babar draft CD
  | |/
  | | o  3 mountain  public CC
  | |/
  o |  1 default  public CB
  |/
  o  0 default  public CA
  

  $ hg push draft
  pushing to $TESTTMP/draft (glob)
  searching for changes
  abort: push creates new remote head f0bc62a661be on branch 'default:babar'!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]

Multiple head on a branch merged in a topic changesets
------------------------------------------------------------------------


  $ hg up 'desc(CA)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo aaa > ggg
  $ hg add ggg
  $ hg commit -m 'CG'
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg up 'desc(CF)'
  switching to topic babar
  2 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg merge 'desc(CG)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -m 'CM'
  $ hg log -G
  @    8 default babar draft CM
  |\
  | o  7 default  draft CG
  | |
  o |  6 default babar draft CF
  | |
  | | o  5 default celeste draft CE
  | |/
  | | o  4 default babar draft CD
  | |/
  | | o  3 mountain  public CC
  | |/
  o |  1 default  public CB
  |/
  o  0 default  public CA
  

Reject when pushing to draft

  $ hg push draft -r .
  pushing to $TESTTMP/draft (glob)
  searching for changes
  abort: push creates new remote head 4937c4cad39e!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]


Reject when pushing to publishing

  $ hg push -r .
  pushing to $TESTTMP/main (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 2 changes to 2 files

  $ cd ..

Test phase move
==================================

setup, two repo knowns about two small topic branch

  $ hg init repoA
  $ hg clone repoA repoB
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat << EOF >> repoA/.hg/hgrc
  > [phases]
  > publish=False
  > EOF
  $ cat << EOF >> repoB/.hg/hgrc
  > [phases]
  > publish=False
  > EOF
  $ cd repoA
  $ echo aaa > base
  $ hg add base
  $ hg commit -m 'CBASE'
  $ echo aaa > aaa
  $ hg add aaa
  $ hg topic topicA
  marked working directory as topic: topicA
  $ hg commit -m 'CA'
  active topic 'topicA' grew its first changeset
  $ hg up 'desc(CBASE)'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo aaa > bbb
  $ hg add bbb
  $ hg topic topicB
  marked working directory as topic: topicB
  $ hg commit -m 'CB'
  active topic 'topicB' grew its first changeset
  $ cd ..
  $ hg push -R repoA repoB
  pushing to repoB
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files (+1 heads)
  $ hg log -G -R repoA
  @  2 default topicB draft CB
  |
  | o  1 default topicA draft CA
  |/
  o  0 default  draft CBASE
  

We turn different topic to public on each side,

  $ hg -R repoA phase --public topicA
  $ hg -R repoB phase --public topicB

Pushing should complain because it create to heads on default

  $ hg push -R repoA repoB
  pushing to repoB
  searching for changes
  no changes found
  abort: push create a new head on branch "default"
  [255]
