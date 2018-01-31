Tests the resolution of divergence

  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [diff]
  > git = 1
  > unified = 0
  > [ui]
  > logtemplate = {rev}:{node|short}@{branch}({phase}) {desc|firstline} [{troubles}]\n
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ mkcommits() {
  >   for i in $@; do mkcommit $i ; done
  > }

Basic test of divergence: two divergent changesets with the same parents
With --all --any we dedupe the divergent and solve the divergence once

  $ hg init test1
  $ cd test1
  $ mkcommits _a _b
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bdivergent1
  created new head
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bdivergent2
  created new head
  $ hg prune -s "desc(bdivergent1)" "desc(_b)"
  1 changesets pruned
  $ hg prune -s "desc(bdivergent2)" "desc(_b)" --hidden
  1 changesets pruned
  2 new content-divergent changesets
  $ hg log -G
  @  3:e708fd28d5cf@default(draft) add bdivergent2 [content-divergent]
  |
  | *  2:c2f698071cba@default(draft) add bdivergent1 [content-divergent]
  |/
  o  0:135f39f4bd78@default(draft) add _a []
  
  $ hg evolve --all --any --content-divergent
  merge:[2] add bdivergent1
  with: [3] add bdivergent2
  base: [1] add _b
  updating to "local" conflict
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory is now at c26f1d3baed2
  $ hg log -G
  @  4:c26f1d3baed2@default(draft) add bdivergent1 []
  |
  o  0:135f39f4bd78@default(draft) add _a []
  
Test divergence resolution when it yields to an empty commit (issue4950)
cdivergent2 contains the same content than cdivergent1 and they are divergent
versions of the revision _c

  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit _c
  created new head
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit cdivergent1
  created new head
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo "cdivergent1" > cdivergent1
  $ hg add cdivergent1
  $ hg ci -m "cdivergent2"
  created new head
  $ hg prune -s "desc(cdivergent1)" "desc(_c)"
  1 changesets pruned
  $ hg prune -s "desc(cdivergent2)" "desc(_c)" --hidden
  1 changesets pruned
  2 new content-divergent changesets
  $ hg log -G
  @  7:0a768ef678d9@default(draft) cdivergent2 [content-divergent]
  |
  | *  6:26c7705fee96@default(draft) add cdivergent1 [content-divergent]
  |/
  | o  4:c26f1d3baed2@default(draft) add bdivergent1 []
  |/
  o  0:135f39f4bd78@default(draft) add _a []
  
  $ hg evolve --all --any --content-divergent
  merge:[6] add cdivergent1
  with: [7] cdivergent2
  base: [5] add _c
  updating to "local" conflict
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  nothing changed
  working directory is now at 26c7705fee96

Test None docstring issue of evolve divergent, which caused hg crush

  $ hg init test2
  $ cd test2
  $ mkcommits _a _b
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bdivergent1
  created new head
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit bdivergent2
  created new head
  $ hg prune -s "desc(bdivergent1)" "desc(_b)"
  1 changesets pruned
  $ hg prune -s "desc(bdivergent2)" "desc(_b)" --hidden
  1 changesets pruned
  2 new content-divergent changesets
  $ hg log -G
  @  3:e708fd28d5cf@default(draft) add bdivergent2 [content-divergent]
  |
  | *  2:c2f698071cba@default(draft) add bdivergent1 [content-divergent]
  |/
  o  0:135f39f4bd78@default(draft) add _a []
  
  $ cat >$TESTTMP/test_extension.py  << EOF
  > from mercurial import merge
  > origupdate = merge.update
  > def newupdate(*args, **kwargs):
  >   return origupdate(*args, **kwargs)
  > merge.update = newupdate
  > EOF
  $ cat >> $HGRCPATH << EOF
  > [extensions]
  > testextension=$TESTTMP/test_extension.py
  > EOF
  $ hg evolve --all
  nothing to evolve on current working copy parent
  (do you want to use --content-divergent)
  [2]
  $ hg evolve --content-divergent
  merge:[3] add bdivergent2
  with: [2] add bdivergent1
  base: [1] add _b
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory is now at aa26817f6fbe


  $ cd ..
