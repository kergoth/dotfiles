Test script based on sharing.rst: ensure that all scenarios in that
document work as advertised.

Setting things up

  $ cat >> $HGRCPATH <<EOF
  > [alias]
  > shortlog = log --template '{rev}:{node|short}  {phase}  {desc|firstline}\n'
  > [extensions]
  > rebase =
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ hg init public
  $ hg clone public test-repo
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone test-repo dev-repo
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat >> test-repo/.hg/hgrc <<EOF
  > [phases]
  > publish = false
  > EOF

To start things off, let's make one public, immutable changeset::

  $ cd test-repo
  $ echo 'my new project' > file1
  $ hg add file1
  $ hg commit -m'create new project'
  $ hg push
  pushing to $TESTTMP/public (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

and pull that into the development repository::

  $ cd ../dev-repo
  $ hg pull -u
  pulling from $TESTTMP/test-repo (glob)
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

Let's commit a preliminary change and push it to ``test-repo`` for
testing. ::

  $ echo 'fix fix fix' > file1
  $ hg commit -m'prelim change'
  $ hg push -q ../test-repo

Figure SG01 (roughly)
  $ hg shortlog -G
  @  1:f6490818a721  draft  prelim change
  |
  o  0:0dc9c9f6ab91  public  create new project
  
Now let's switch to test-repo to test our change and amend::
  $ cd ../test-repo
  $ hg update -q
  $ echo 'Fix fix fix.' > file1
  $ hg amend -m'fix bug 37'

Figure SG02
  $ hg shortlog --hidden -G
  @  3:60ffde5765c5  draft  fix bug 37
  |
  | x  2:2a039763c0f4  draft  temporary amend commit for f6490818a721
  | |
  | x  1:f6490818a721  draft  prelim change
  |/
  o  0:0dc9c9f6ab91  public  create new project
  
Pull into dev-repo: obsolescence markers are transferred, but not
the new obsolete changeset.
  $ cd ../dev-repo
  $ hg pull -u
  pulling from $TESTTMP/test-repo (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  1 other heads for branch "default"

Figure SG03
  $ hg shortlog --hidden -G
  @  2:60ffde5765c5  draft  fix bug 37
  |
  | x  1:f6490818a721  draft  prelim change
  |/
  o  0:0dc9c9f6ab91  public  create new project
  
Amend again in dev-repo
  $ echo 'Fix, fix, and fix.' > file1
  $ hg amend
  $ hg push -q

Figure SG04 (dev-repo)
  $ hg shortlog --hidden -G
  @  4:de6151c48e1c  draft  fix bug 37
  |
  | x  3:ad19d3570adb  draft  temporary amend commit for 60ffde5765c5
  | |
  | x  2:60ffde5765c5  draft  fix bug 37
  |/
  | x  1:f6490818a721  draft  prelim change
  |/
  o  0:0dc9c9f6ab91  public  create new project
  
Figure SG04 (test-repo)
  $ cd ../test-repo
  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  1 other heads for branch "default"
  $ hg shortlog --hidden -G
  @  4:de6151c48e1c  draft  fix bug 37
  |
  | x  3:60ffde5765c5  draft  fix bug 37
  |/
  | x  2:2a039763c0f4  draft  temporary amend commit for f6490818a721
  | |
  | x  1:f6490818a721  draft  prelim change
  |/
  o  0:0dc9c9f6ab91  public  create new project
  
This bug fix is finished. We can push it to the public repository.
  $ hg push
  pushing to $TESTTMP/public (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  4 new obsolescence markers

Now that the fix is public, we cannot amend it any more.
  $ hg amend -m 'fix bug 37'
  abort: cannot amend public changesets
  [255]

Figure SG05
  $ hg -R ../public shortlog -G
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  
Oops, still have draft changesets in dev-repo: push the phase change there.
  $ hg -R ../dev-repo shortlog -r 'draft()'
  4:de6151c48e1c  draft  fix bug 37
  $ hg push ../dev-repo
  pushing to ../dev-repo
  searching for changes
  no changes found
  [1]
  $ hg -R ../dev-repo shortlog -r 'draft()'

Sharing with multiple developers: code review

  $ cd ..
  $ hg clone public review
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone review alice
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone review bob
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat >> review/.hg/hgrc <<EOF
  > [phases]
  > publish = false
  > EOF

Alice commits a draft bug fix, pushes to review repo.
  $ cd alice
  $ hg bookmark bug15
  $ echo 'fix' > file2
  $ hg commit -A -u alice -m 'fix bug 15 (v1)'
  adding file2
  $ hg push -B bug15
  pushing to $TESTTMP/review (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  exporting bookmark bug15
  $ hg -R ../review bookmarks
     bug15                     2:f91e97234c2b

Alice receives code review, amends her fix, and goes out to lunch to
await second review.
  $ echo 'Fix.' > file2
  $ hg amend -m 'fix bug 15 (v2)'
  $ hg push
  pushing to $TESTTMP/review (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers
  updating bookmark bug15
  $ hg -R ../review bookmarks
     bug15                     3:cbdfbd5a5db2

Figure SG06: review repository after Alice pushes her amended changeset.
  $ hg --hidden -R ../review shortlog -G -r 1::
  o  3:cbdfbd5a5db2  draft  fix bug 15 (v2)
  |
  | x  2:f91e97234c2b  draft  fix bug 15 (v1)
  |/
  @  1:de6151c48e1c  public  fix bug 37
  |
  ~

Bob commits a draft changeset, pushes to review repo.
  $ cd ../bob
  $ echo 'stuff' > file1
  $ hg bookmark featureX
  $ hg commit -u bob -m 'implement feature X (v1)'
  $ hg push -B featureX
  pushing to $TESTTMP/review (glob)
  searching for changes
  remote has heads on branch 'default' that are not known locally: cbdfbd5a5db2
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  exporting bookmark featureX
  $ hg -R ../review bookmarks
     bug15                     3:cbdfbd5a5db2
     featureX                  4:193657d1e852

Bob receives first review, amends and pushes.
  $ echo 'do stuff' > file1
  $ hg amend -m 'implement feature X (v2)'
  $ hg push
  pushing to $TESTTMP/review (glob)
  searching for changes
  remote has heads on branch 'default' that are not known locally: cbdfbd5a5db2
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers
  updating bookmark featureX

Bob receives second review, amends, and pushes to public:
this time, he's sure he got it right!
  $ echo 'Do stuff.' > file1
  $ hg amend -m 'implement feature X (v3)'
  $ hg push ../public
  pushing to ../public
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  4 new obsolescence markers
  $ hg -R ../public bookmarks
  no bookmarks set
  $ hg push ../review
  pushing to ../review
  searching for changes
  remote has heads on branch 'default' that are not known locally: cbdfbd5a5db2
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers
  updating bookmark featureX
  $ hg -R ../review bookmarks
     bug15                     3:cbdfbd5a5db2
     featureX                  6:540ba8f317e6

Figure SG07: review and public repos after Bob implements feature X.
  $ hg --hidden -R ../review shortlog -G -r 1::
  o  6:540ba8f317e6  public  implement feature X (v3)
  |
  | x  5:0eb74a7b6698  draft  implement feature X (v2)
  |/
  | x  4:193657d1e852  draft  implement feature X (v1)
  |/
  | o  3:cbdfbd5a5db2  draft  fix bug 15 (v2)
  |/
  | x  2:f91e97234c2b  draft  fix bug 15 (v1)
  |/
  @  1:de6151c48e1c  public  fix bug 37
  |
  ~
  $ hg --hidden -R ../public shortlog -G -r 1::
  o  2:540ba8f317e6  public  implement feature X (v3)
  |
  o  1:de6151c48e1c  public  fix bug 37
  |
  ~

How do things look in the review repo?
  $ cd ../review
  $ hg --hidden shortlog -G -r 1::
  o  6:540ba8f317e6  public  implement feature X (v3)
  |
  | x  5:0eb74a7b6698  draft  implement feature X (v2)
  |/
  | x  4:193657d1e852  draft  implement feature X (v1)
  |/
  | o  3:cbdfbd5a5db2  draft  fix bug 15 (v2)
  |/
  | x  2:f91e97234c2b  draft  fix bug 15 (v1)
  |/
  @  1:de6151c48e1c  public  fix bug 37
  |
  ~

Meantime, Alice is back from lunch. While she was away, Bob approved
her change, so now she can publish it.
  $ cd ../alice
  $ hg --hidden shortlog -G -r 1::
  @  4:cbdfbd5a5db2  draft  fix bug 15 (v2)
  |
  | x  3:55dd95168a35  draft  temporary amend commit for f91e97234c2b
  | |
  | x  2:f91e97234c2b  draft  fix bug 15 (v1)
  |/
  o  1:de6151c48e1c  public  fix bug 37
  |
  ~
  $ hg outgoing -q ../public
  4:cbdfbd5a5db2
  $ hg push ../public
  pushing to ../public
  searching for changes
  remote has heads on branch 'default' that are not known locally: 540ba8f317e6
  abort: push creates new remote head cbdfbd5a5db2 with bookmark 'bug15'!
  (pull and merge or see 'hg help push' for details about pushing new heads)
  [255]
  $ hg pull ../public
  pulling from ../public
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  4 new obsolescence markers
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg log -G -q -r 'head()'
  o  5:540ba8f317e6
  |
  ~
  @  4:cbdfbd5a5db2
  |
  ~
  $ hg --hidden shortlog -G -r 1::
  o  5:540ba8f317e6  public  implement feature X (v3)
  |
  | @  4:cbdfbd5a5db2  draft  fix bug 15 (v2)
  |/
  | x  3:55dd95168a35  draft  temporary amend commit for f91e97234c2b
  | |
  | x  2:f91e97234c2b  draft  fix bug 15 (v1)
  |/
  o  1:de6151c48e1c  public  fix bug 37
  |
  ~

Alice rebases her draft changeset on top of Bob's public changeset and
publishes the result.
  $ hg rebase -d 5
  rebasing 4:cbdfbd5a5db2 "fix bug 15 (v2)" (bug15)
  $ hg push ../public
  pushing to ../public
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  3 new obsolescence markers
  $ hg push ../review
  pushing to ../review
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 1 files
  1 new obsolescence markers
  updating bookmark bug15

Figure SG08: review and public changesets after Alice pushes.
  $ hg --hidden -R ../review shortlog -G -r 1::
  o  7:a06ec1bf97bd  public  fix bug 15 (v2)
  |
  o  6:540ba8f317e6  public  implement feature X (v3)
  |
  | x  5:0eb74a7b6698  draft  implement feature X (v2)
  |/
  | x  4:193657d1e852  draft  implement feature X (v1)
  |/
  | x  3:cbdfbd5a5db2  draft  fix bug 15 (v2)
  |/
  | x  2:f91e97234c2b  draft  fix bug 15 (v1)
  |/
  @  1:de6151c48e1c  public  fix bug 37
  |
  ~
  $ hg --hidden -R ../public shortlog -G -r 1::
  o  3:a06ec1bf97bd  public  fix bug 15 (v2)
  |
  o  2:540ba8f317e6  public  implement feature X (v3)
  |
  o  1:de6151c48e1c  public  fix bug 37
  |
  ~
  $ cd ..

Setup for "cowboy mode" shared mutable history (to illustrate divergent
and bumped changesets).
  $ rm -rf review alice bob
  $ hg clone public alice
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone public bob
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat >> alice/.hg/hgrc <<EOF
  > [phases]
  > publish = false
  > EOF
  $ cp alice/.hg/hgrc bob/.hg/hgrc

Now we'll have Bob commit a bug fix that could still be improved::

  $ cd bob
  $ echo 'pretty good fix' >> file1
  $ hg commit -u bob -m 'fix bug 24 (v1)'
  $ hg shortlog -r .
  4:2fe6c4bd32d0  draft  fix bug 24 (v1)

Since Alice and Bob are now in cowboy mode, Alice pulls Bob's draft
changeset and amends it herself. ::

  $ cd ../alice
  $ hg pull -u ../bob
  pulling from ../bob
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo 'better fix (alice)' >> file1
  $ hg amend -u alice -m 'fix bug 24 (v2 by alice)'

Bob implements a better fix of his own::

  $ cd ../bob
  $ echo 'better fix (bob)' >> file1
  $ hg amend -u bob -m 'fix bug 24 (v2 by bob)'
  $ hg --hidden shortlog -G -r 3::
  @  6:a360947f6faf  draft  fix bug 24 (v2 by bob)
  |
  | x  5:3466c7f5a149  draft  temporary amend commit for 2fe6c4bd32d0
  | |
  | x  4:2fe6c4bd32d0  draft  fix bug 24 (v1)
  |/
  o  3:a06ec1bf97bd  public  fix bug 15 (v2)
  |
  ~

Bob discovers the divergence.
  $ hg pull ../alice
  pulling from ../alice
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  2 new obsolescence markers
  (run 'hg heads' to see heads, 'hg merge' to merge)
  2 new divergent changesets

Figure SG09: multiple heads! divergence! oh my!
  $ hg --hidden shortlog -G -r 3::
  o  7:e3f99ce9d9cd  draft  fix bug 24 (v2 by alice)
  |
  | @  6:a360947f6faf  draft  fix bug 24 (v2 by bob)
  |/
  | x  5:3466c7f5a149  draft  temporary amend commit for 2fe6c4bd32d0
  | |
  | x  4:2fe6c4bd32d0  draft  fix bug 24 (v1)
  |/
  o  3:a06ec1bf97bd  public  fix bug 15 (v2)
  |
  ~
  $ hg --hidden shortlog -r 'successors(2fe6)'
  6:a360947f6faf  draft  fix bug 24 (v2 by bob)
  7:e3f99ce9d9cd  draft  fix bug 24 (v2 by alice)

Use evolve to fix the divergence.
  $ HGMERGE=internal:other hg evolve --divergent
  merge:[6] fix bug 24 (v2 by bob)
  with: [7] fix bug 24 (v2 by alice)
  base: [4] fix bug 24 (v1)
  0 files updated, 1 files merged, 0 files removed, 0 files unresolved
  working directory is now at 5ad6037c046c
  $ hg log -q -r 'divergent()'

Figure SG10: Bob's repository after fixing divergence.
  $ hg --hidden shortlog -G -r 3::
  @  9:5ad6037c046c  draft  fix bug 24 (v2 by bob)
  |
  | x  8:bcfc9a755ac3  draft  temporary amend commit for a360947f6faf
  | |
  +---x  7:e3f99ce9d9cd  draft  fix bug 24 (v2 by alice)
  | |
  | x  6:a360947f6faf  draft  fix bug 24 (v2 by bob)
  |/
  | x  5:3466c7f5a149  draft  temporary amend commit for 2fe6c4bd32d0
  | |
  | x  4:2fe6c4bd32d0  draft  fix bug 24 (v1)
  |/
  o  3:a06ec1bf97bd  public  fix bug 15 (v2)
  |
  ~
  $ hg --hidden shortlog -r 'precursors(9)'
  6:a360947f6faf  draft  fix bug 24 (v2 by bob)
  7:e3f99ce9d9cd  draft  fix bug 24 (v2 by alice)
  $ cat file1
  Do stuff.
  pretty good fix
  better fix (alice)
