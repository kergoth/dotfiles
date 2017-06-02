  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ template='{rev}:{node|short}@{branch}({separate("/", obsolete, phase)}) {desc|firstline}\n'
  $ glog() {
  >   hg glog --template "$template" "$@"
  > }

Test outgoing, common A is suspended, B unstable and C secret, remote
has A and B, neither A or C should be in outgoing.

  $ hg init source
  $ cd source
  $ echo a > a
  $ hg ci -qAm A a
  $ echo b > b
  $ hg ci -qAm B b
  $ hg up 0
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo c > c
  $ hg ci -qAm C c
  $ hg phase --secret --force .
  $ hg prune 0 1
  2 changesets pruned
  1 new unstable changesets
  $ glog --hidden
  @  2:244232c2222a@default(secret) C
  |
  | x  1:6c81ed0049f8@default(obsolete/draft) B
  |/
  x  0:1994f17a630e@default(obsolete/draft) A
  
  $ hg init ../clone
  $ cat >  ../clone/.hg/hgrc <<EOF
  > [phases]
  > publish = false
  > EOF
  $ hg outgoing ../clone --template "$template"
  comparing with ../clone
  searching for changes
  0:1994f17a630e@default(obsolete/draft) A
  $ cd ..

Test options to prevent implicite publishing of changesets
----------------------------------------------------------


  $ hg clone source strict-publish-client --pull
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  2 new obsolescence markers
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd strict-publish-client
  $ echo c > c
  $ hg ci -qAm C c

abort behavior

  $ cat >> .hg/hgrc <<eof
  > [experimental]
  > auto-publish = abort
  > eof
  $ hg push -r .
  pushing to $TESTTMP/source
  abort: push would publish 1 changesets
  (behavior controlled by 'experimental.auto-publish' config)
  [255]
  $ hg push
  pushing to $TESTTMP/source
  abort: push would publish 1 changesets
  (behavior controlled by 'experimental.auto-publish' config)
  [255]

warning behavior

  $ echo 'auto-publish = warn' >> .hg/hgrc
  $ hg push
  pushing to $TESTTMP/source
  1 changesets about to be published
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 0 changesets with 0 changes to 1 files
