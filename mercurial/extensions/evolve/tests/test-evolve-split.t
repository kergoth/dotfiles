Check that evolve shows error while handling split commits
--------------------------------------
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
  > logtemplate = {rev}:{node|short}@{branch}({phase}) {desc|firstline}\n
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ hg init split
  $ cd split
  $ mkcommit aa

Create a split commit
  $ printf "oo" > oo;
  $ printf "pp" > pp;
  $ hg add oo pp
  $ hg commit -m "oo+pp"
  $ mkcommit uu
  $ hg up 0
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ printf "oo" > oo;
  $ hg add oo
  $ hg commit -m "_oo"
  created new head
  $ printf "pp" > pp;
  $ hg add pp
  $ hg commit -m "_pp"
  $ hg prune --succ "desc(_oo) + desc(_pp)" -r "desc('oo+pp')" --split
  1 changesets pruned
  1 new unstable changesets
  $ hg log -G
  @  4:d0dcf24cddd3@default(draft) _pp
  |
  o  3:a7fdfda64c08@default(draft) _oo
  |
  | o  2:f52200b086ca@default(draft) add uu
  | |
  | x  1:d55647aaa0c6@default(draft) oo+pp
  |/
  o  0:58663bb03074@default(draft) add aa
  
  $ hg evolve --rev "0::"
  move:[2] add uu
  atop:[4] _pp
  working directory is now at 6f5bbe2e3df3
