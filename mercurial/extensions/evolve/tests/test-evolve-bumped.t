  $ hg init public
  $ cd public
  $ echo a > a
  $ hg commit -A -m init
  adding a
  $ cd ..

  $ evolvepath=$(echo $(dirname $TESTDIR))/hgext/evolve.py
  $ hg clone -U public private
  $ cd private
  $ cat >> .hg/hgrc <<EOF
  > [extensions]
  > evolve = $evolvepath
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
  changeset:   1:4d1169d82e47
  tag:         tip
  user:        alice
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     modify a
  

  $ cd ../bob
  $ hg pull ../private
  pulling from ../private
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  pull obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg log -r 'draft()'
  changeset:   1:4d1169d82e47
  tag:         tip
  user:        alice
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     modify a
  
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
  pull obsolescence markers
  1 new bumped changesets

  $ hg evolve -a
  recreate:[2] tweak a
  atop:[1] modify a
  computing new diff
  committed as 4d1169d82e47
  working directory is now at 4d1169d82e47
