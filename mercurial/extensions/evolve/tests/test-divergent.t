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
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> $HGRCPATH
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
  2 new divergent changesets
  $ hg log -G
  @  3:e708fd28d5cf@default(draft) add bdivergent2 [divergent]
  |
  | o  2:c2f698071cba@default(draft) add bdivergent1 [divergent]
  |/
  o  0:135f39f4bd78@default(draft) add _a []
  
  $ hg evolve --all --any --divergent
  merge:[2] add bdivergent1
  with: [3] add bdivergent2
  base: [1] add _b
  updating to "local" conflict
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory is now at c26f1d3baed2
  $ hg log -G
  @  5:c26f1d3baed2@default(draft) add bdivergent1 []
  |
  o  0:135f39f4bd78@default(draft) add _a []
  
  $ cd ..  
