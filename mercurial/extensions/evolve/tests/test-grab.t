Test for the grab command

  $ cat >> $HGRCPATH <<EOF
  > [alias]
  > glog = log -G -T "{rev}:{node|short} {desc}\n"
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ hg init repo
  $ cd repo
  $ hg help grab
  hg grab [-r] rev
  
  grabs a commit, move it on the top of working directory parent and
      updates to it.
  
  options:
  
   -r --rev VALUE revision to grab
   -c --continue  continue interrupted grab
   -a --abort     abort interrupted grab
  
  (some details hidden, use --verbose to show complete help)

  $ mkcommit a
  $ mkcommit b
  $ mkcommit c

  $ hg glog
  @  2:4538525df7e2 add c
  |
  o  1:7c3bad9141dc add b
  |
  o  0:1f0dee641bb7 add a
  

Grabbing an ancestor

  $ hg grab -r 7c3bad9141dc
  abort: cannot grab an ancestor revision
  [255]

Grabbing the working directory parent

  $ hg grab -r .
  abort: cannot grab an ancestor revision
  [255]

Specifying multiple revisions to grab

  $ hg grab 1f0dee641bb7 -r 7c3bad9141dc
  abort: specify just one revision
  [255]

Specifying no revisions to grab

  $ hg grab
  abort: empty revision set
  [255]

Continuing without interrupted grab

  $ hg grab --continue
  abort: no interrupted grab state exists
  [255]

Aborting without interrupted grab

  $ hg grab --abort
  abort: no interrupted grab state exists
  [255]

Specifying both continue and revs

  $ hg up 1f0dee641bb7
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg grab -r 4538525df7e2 --continue
  abort: cannot specify both --continue and revision
  [255]

Making new branch heads

  $ mkcommit x
  created new head
  $ mkcommit y

  $ hg glog
  @  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  | o  2:4538525df7e2 add c
  | |
  | o  1:7c3bad9141dc add b
  |/
  o  0:1f0dee641bb7 add a
  
Grabbing a revision

  $ hg grab 7c3bad9141dc
  grabbing 1:7c3bad9141dc "add b"
  1 new orphan changesets
  $ hg glog
  @  5:7c15c05db6fa add b
  |
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  | *  2:4538525df7e2 add c
  | |
  | x  1:7c3bad9141dc add b
  |/
  o  0:1f0dee641bb7 add a
  

When grab does not create any changes

  $ hg graft -r 4538525df7e2
  grafting 2:4538525df7e2 "add c"

  $ hg glog
  @  6:c4636a81ebeb add c
  |
  o  5:7c15c05db6fa add b
  |
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  | *  2:4538525df7e2 add c
  | |
  | x  1:7c3bad9141dc add b
  |/
  o  0:1f0dee641bb7 add a
  
  $ hg grab -r 4538525df7e2
  grabbing 2:4538525df7e2 "add c"
  note: grab of 2:4538525df7e2 created no changes to commit

  $ hg glog
  @  6:c4636a81ebeb add c
  |
  o  5:7c15c05db6fa add b
  |
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  o  0:1f0dee641bb7 add a
  
interrupted grab

  $ hg up d46dc301d92f
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo foo > c
  $ hg ci -Aqm "foo to c"
  $ hg grab -r c4636a81ebeb
  grabbing 6:c4636a81ebeb "add c"
  merging c
  warning: conflicts while merging c! (edit, then use 'hg resolve --mark')
  unresolved merge conflicts (see hg help resolve)
  [1]

  $ echo foobar > c
  $ hg resolve --all --mark
  (no more unresolved files)
  continue: hg grab --continue
  $ hg grab --continue
  $ hg glog
  @  8:44e155eb95c7 add c
  |
  o  7:2ccc03d1d096 foo to c
  |
  | o  5:7c15c05db6fa add b
  |/
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  o  0:1f0dee641bb7 add a
  

When interrupted grab results in no changes to commit

  $ hg up d46dc301d92f
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo bar > c
  $ hg add c
  $ hg ci -m "foo to c"
  created new head

  $ hg up 44e155eb95c7
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg grab 4e04628911f6
  grabbing 9:4e04628911f6 "foo to c"
  merging c
  warning: conflicts while merging c! (edit, then use 'hg resolve --mark')
  unresolved merge conflicts (see hg help resolve)
  [1]
  $ echo foobar > c
  $ hg resolve -m
  (no more unresolved files)
  continue: hg grab --continue

  $ hg grab --continue
  note: grab of 9:4e04628911f6 created no changes to commit

Testing the abort functionality of hg grab

  $ echo foo > b
  $ hg ci -Aqm "foo to b"
  $ hg glog -r .^::
  @  10:c437988de89f foo to b
  |
  o  8:44e155eb95c7 add c
  |
  ~

  $ hg grab -r 7c15c05db6fa
  grabbing 5:7c15c05db6fa "add b"
  merging b
  warning: conflicts while merging b! (edit, then use 'hg resolve --mark')
  unresolved merge conflicts (see hg help resolve)
  [1]

  $ hg grab --abort
  aborting grab, updating to c437988de89f

  $ hg glog
  @  10:c437988de89f foo to b
  |
  o  8:44e155eb95c7 add c
  |
  o  7:2ccc03d1d096 foo to c
  |
  | o  5:7c15c05db6fa add b
  |/
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  o  0:1f0dee641bb7 add a
  

Trying to grab a public changeset

  $ hg phase -r 7c15c05db6fa -p

  $ hg grab -r 7c15c05db6fa
  abort: cannot grab public changesets: 7c15c05db6fa
  (see 'hg help phases' for details)
  [255]

  $ hg glog
  @  10:c437988de89f foo to b
  |
  o  8:44e155eb95c7 add c
  |
  o  7:2ccc03d1d096 foo to c
  |
  | o  5:7c15c05db6fa add b
  |/
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  o  0:1f0dee641bb7 add a
  
Checking phase preservation while grabbing secret changeset

In case of merge conflicts

  $ hg phase -r 7c15c05db6fa -s -f

  $ hg grab -r 7c15c05db6fa
  grabbing 5:7c15c05db6fa "add b"
  merging b
  warning: conflicts while merging b! (edit, then use 'hg resolve --mark')
  unresolved merge conflicts (see hg help resolve)
  [1]

  $ echo bar > b
  $ hg resolve -m
  (no more unresolved files)
  continue: hg grab --continue

  $ hg grab --continue
  $ hg phase -r .
  11: secret

No merge conflicts

  $ hg up d46dc301d92f
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ echo foo > l
  $ hg add l
  $ hg ci -qm "added l" --secret

  $ hg phase -r .
  12: secret

  $ hg glog
  @  12:508d572e7053 added l
  |
  | o  11:10427de9e26e add b
  | |
  | o  10:c437988de89f foo to b
  | |
  | o  8:44e155eb95c7 add c
  | |
  | o  7:2ccc03d1d096 foo to c
  |/
  o  4:d46dc301d92f add y
  |
  o  3:8e224524cd09 add x
  |
  o  0:1f0dee641bb7 add a
  
  $ hg up 10427de9e26e
  3 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ hg grab -r 508d572e7053
  grabbing 12:508d572e7053 "added l"

  $ hg phase -r .
  13: secret
