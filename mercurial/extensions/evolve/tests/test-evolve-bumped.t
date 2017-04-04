  $ hg init public
  $ cd public
  $ echo a > a
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }
  $ hg commit -A -m init
  adding a
  $ cd ..

  $ evolvepath=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/
  $ hg clone -U public private
  $ cd private
  $ cat >> .hg/hgrc <<EOF
  > [extensions]
  > evolve = $evolvepath
  > [ui]
  > logtemplate = {rev}:{node|short}@{branch}({phase}) {desc|firstline}\n
  > [phases]
  > publish = false
  > EOF
  $ cd ..

  $ cp -a private alice
  $ cp -a private bob

  $ cd alice
  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo a >> a
  $ hg commit -u alice -m 'modify a'
  $ hg push ../private
  pushing to ../private
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg log -r 'draft()'
  1:4d1169d82e47@default(draft) modify a

  $ cd ../bob
  $ hg pull ../private
  pulling from ../private
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  (run 'hg update' to get a working copy)
  $ hg log -r 'draft()'
  1:4d1169d82e47@default(draft) modify a
  $ hg push ../public
  pushing to ../public
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  $ hg log -r 'draft()'

  $ cd ../alice
  $ hg amend -m 'tweak a'
  $ hg pull ../public
  pulling from ../public
  searching for changes
  no changes found
  1 new bumped changesets

  $ hg evolve -a -A --bumped
  recreate:[2] tweak a
  atop:[1] modify a
  computing new diff
  committed as 4d1169d82e47
  working directory is now at 4d1169d82e47

Bumped Merge changeset:
-----------------------

We currently cannot automatically solve bumped changeset that is the
product of a merge, we add a test for it.

  $ mkcommit _a
  $ hg up .^
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit _b
  created new head
  $ mkcommit _c
  $ hg log -G
  @  5:eeaf70969381@default(draft) add _c
  |
  o  4:6612fc0ddeb6@default(draft) add _b
  |
  | o  3:154ad198ff4a@default(draft) add _a
  |/
  o  1:4d1169d82e47@default(public) modify a
  |
  o  0:d3873e73d99e@default(public) init
  
  $ hg merge 3
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -m "merge"
  $ hg commit --amend -m "New message"
  $ hg phase --public 551127da2a8a --hidden
  1 new bumped changesets
  $ hg log -G
  @    7:b28e84916d8c@default(draft) New message
  |\
  +---o  6:551127da2a8a@default(public) merge
  | |/
  | o  5:eeaf70969381@default(public) add _c
  | |
  | o  4:6612fc0ddeb6@default(public) add _b
  | |
  o |  3:154ad198ff4a@default(public) add _a
  |/
  o  1:4d1169d82e47@default(public) modify a
  |
  o  0:d3873e73d99e@default(public) init
  
  $ hg evolve --all --bumped
  skipping b28e84916d8c : we do not handle merge yet
