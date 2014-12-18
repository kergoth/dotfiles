Test script based on sharing.rst: ensure that all scenarios in that
document work as advertised.

Setting things up

  $ cat >> $HGRCPATH <<EOF
  > [alias]
  > shortlog = log --template '{rev}:{node|short}  {phase}  {desc|firstline}\n'
  > [extensions]
  > rebase =
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> $HGRCPATH
  $ hg init public
  $ hg clone -q public test-repo
  $ hg clone -q test-repo dev-repo
  $ cat >> test-repo/.hg/hgrc <<EOF
  > [phases]
  > publish = false
  > EOF

To start things off, let's make one public, immutable changeset::

  $ cd test-repo
  $ echo 'my new project' > file1
  $ hg add file1
  $ hg commit -m'create new project'
  $ hg push -q

and pull that into the development repository::

  $ cd ../dev-repo
  $ hg pull -q -u

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
  $ hg pull -q -u

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
  $ hg update -q
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
  pushing 4 obsolescence markers (* bytes) (glob)
  4 obsolescence markers added

Figure SG05
  $ hg -R ../public shortlog -G
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  
Oops, still have draft changesets in dev-repo.
  $ cd ../dev-repo
  $ hg shortlog -r 'draft()'
  4:de6151c48e1c  draft  fix bug 37
  $ hg pull -q -u
  $ hg shortlog -r 'draft()'

Sharing by Alice and Bob to demonstrate bumped and divergent changesets.
First, setup repos for them.

  $ cd ..
  $ hg clone -q public alice
  $ hg clone -q public bob
  $ cat >> alice/.hg/hgrc <<EOF
  > [phases]
  > publish = false
  > EOF
  $ cp alice/.hg/hgrc bob/.hg/hgrc

Alice commits a bug fix.
  $ cd alice
  $ echo 'fix' > file2
  $ hg commit -q -A -u alice -m 'fix bug 15'

Bob pulls and amends Alice's fix.
  $ cd ../bob
  $ hg pull -q -u ../alice
  $ echo 'Fix.' > file2
  $ hg amend -q -A -u bob -m 'fix bug 15 (amended)'

Figure SG06: Bob's repository after amending Alice's fix.
(Nothing new here; we could have seen this in the user guide.
  $ hg --hidden shortlog -G
  @  4:fe884dfac355  draft  fix bug 15 (amended)
  |
  | x  3:0376cac226f8  draft  temporary amend commit for e011baf925da
  | |
  | x  2:e011baf925da  draft  fix bug 15
  |/
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  

But in the meantime, Alice decides the fix is just fine and publishes it.
  $ cd ../alice
  $ hg push -q

Which means that Bob now has an formerly obsolete changeset that is
also public (2:6e83). As soon as he pulls its phase change, he's got
trouble: the successors of that formerly obsolete changeset are
bumped.

  $ cd ../bob
  $ hg --hidden shortlog -r 'obsolete()'
  2:e011baf925da  draft  fix bug 15
  3:0376cac226f8  draft  temporary amend commit for e011baf925da
  $ hg pull -q -u
  1 new bumped changesets
  $ hg --hidden shortlog -r 'obsolete()'
  3:0376cac226f8  draft  temporary amend commit for e011baf925da
  $ hg shortlog -r 'bumped()'
  4:fe884dfac355  draft  fix bug 15 (amended)

Figure SG07: Bob's repo with one bumped changeset (rev 4:c02d)
  $ hg --hidden shortlog -G
  @  4:fe884dfac355  draft  fix bug 15 (amended)
  |
  | x  3:0376cac226f8  draft  temporary amend commit for e011baf925da
  | |
  | o  2:e011baf925da  public  fix bug 15
  |/
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  

Bob gets out of trouble by evolving the repository.
  $ hg evolve --all
  recreate:[4] fix bug 15 (amended)
  atop:[2] fix bug 15
  computing new diff
  committed as 227d860d9ad0
  working directory is now at 227d860d9ad0

Figure SG08
  $ hg --hidden shortlog -G
  @  5:227d860d9ad0  draft  bumped update to e011baf925da:
  |
  | x  4:fe884dfac355  draft  fix bug 15 (amended)
  | |
  +---x  3:0376cac226f8  draft  temporary amend commit for e011baf925da
  | |
  o |  2:e011baf925da  public  fix bug 15
  |/
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  

Throw away Bob's messy repo and start over.
  $ cd ..
  $ rm -rf bob
  $ cp -rp alice bob

Bob commits a pretty good fix that both he and Alice will amend,
leading to divergence.
  $ cd bob
  $ echo 'pretty good fix' >> file1
  $ hg commit -u bob -m 'fix bug 24 (v1)'

Alice pulls Bob's fix and improves it.
  $ cd ../alice
  $ hg pull -q -u ../bob
  $ echo 'better (alice)' >> file1
  $ hg amend -u alice -m 'fix bug 24 (v2 by alice)'

Likewise, Bob amends his own fix. Now we have an obsolete changeset
with two successors, although the successors are in different repos.
  $ cd ../bob
  $ echo 'better (bob)' >> file1
  $ hg amend -u bob -m 'fix bug 24 (v2 by bob)'

Bob pulls from Alice's repo and discovers the trouble: divergent changesets!
  $ hg pull -q -u ../alice
  not updating: not a linear update
  (merge or update --check to force update)
  2 new divergent changesets
  $ hg shortlog -r 'divergent()'
  5:fc16901f4d7a  draft  fix bug 24 (v2 by bob)
  6:694fd0f6b503  draft  fix bug 24 (v2 by alice)

Figure SG09
  $ hg --hidden shortlog -G
  o  6:694fd0f6b503  draft  fix bug 24 (v2 by alice)
  |
  | @  5:fc16901f4d7a  draft  fix bug 24 (v2 by bob)
  |/
  | x  4:162612d3335b  draft  temporary amend commit for fe81d904ed08
  | |
  | x  3:fe81d904ed08  draft  fix bug 24 (v1)
  |/
  o  2:e011baf925da  public  fix bug 15
  |
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  
Merge the trouble away.
  $ hg merge --tool internal:local
  0 files updated, 1 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -m merge
  $ hg shortlog -G
  @    7:b1d30ba26e44  draft  merge
  |\
  | o  6:694fd0f6b503  draft  fix bug 24 (v2 by alice)
  | |
  o |  5:fc16901f4d7a  draft  fix bug 24 (v2 by bob)
  |/
  o  2:e011baf925da  public  fix bug 15
  |
  o  1:de6151c48e1c  public  fix bug 37
  |
  o  0:0dc9c9f6ab91  public  create new project
  
  $ hg log -q -r 'divergent()'
  5:fc16901f4d7a
  6:694fd0f6b503

# XXX hg evolve does not solve this trouble! bug in evolve?
#Evolve the trouble away.
#  $ hg evolve --all --tool=internal:local
#  merge:[5] fix bug 24 (v2 by bob)
#  with: [6] fix bug 24 (v2 by alice)
#  base: [3] fix bug 24 (v1)
#  0 files updated, 1 files merged, 0 files removed, 0 files unresolved
#  $ hg status
#  $ hg shortlog -G
#  o  6:694fd0f6b503  draft  fix bug 24 (v2 by alice)
#  |
#  | @  5:fc16901f4d7a  draft  fix bug 24 (v2 by bob)
#  |/
#  o  2:e011baf925da  public  fix bug 15
#  |
#  o  1:de6151c48e1c  public  fix bug 37
#  |
#  o  0:0dc9c9f6ab91  public  create new project
#  
#  $ hg --hidden shortlog -G
