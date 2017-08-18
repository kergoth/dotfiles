  $ . $TESTDIR/testlib/common.sh

setup

  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > fold=-d "0 0"
  > [extensions]
  > evolve=
  > [ui]
  > logtemplate = '{rev} - {node|short} {desc|firstline} [{author}] ({phase})\n'
  > EOF

  $ hg init fold-tests
  $ cd fold-tests/
  $ hg debugbuilddag .+3:branchpoint+4*branchpoint+2
  $ hg up 'desc("r7")'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  o  10 - a8407f9a3dc1 r10 [debugbuilddag] (draft)
  |
  o  9 - 529dfc5bb875 r9 [debugbuilddag] (draft)
  |
  o  8 - abf57d94268b r8 [debugbuilddag] (draft)
  |
  | @  7 - 4de32a90b66c r7 [debugbuilddag] (draft)
  | |
  | o  6 - f69452c5b1af r6 [debugbuilddag] (draft)
  | |
  | o  5 - c8d03c1b5e94 r5 [debugbuilddag] (draft)
  | |
  | o  4 - bebd167eb94d r4 [debugbuilddag] (draft)
  |/
  o  3 - 2dc09a01254d r3 [debugbuilddag] (draft)
  |
  o  2 - 01241442b3c2 r2 [debugbuilddag] (draft)
  |
  o  1 - 66f7d451a68b r1 [debugbuilddag] (draft)
  |
  o  0 - 1ea73414a91b r0 [debugbuilddag] (draft)
  

Test various error case

  $ hg fold --exact null::
  abort: cannot fold the null revision
  (no changeset checked out)
  [255]
  $ hg fold
  abort: no revisions specified
  [255]
  $ hg fold --from
  abort: no revisions specified
  [255]
  $ hg fold .
  abort: must specify either --from or --exact
  [255]
  $ hg fold --from . --exact
  abort: cannot use both --from and --exact
  [255]
  $ hg fold --from .
  single revision specified, nothing to fold
  [1]
  $ hg fold '0::(7+10)' --exact
  abort: cannot fold non-linear revisions (multiple heads given)
  [255]
  $ hg fold -r 4 -r 6 --exact
  abort: cannot fold non-linear revisions (multiple roots given)
  [255]
  $ hg fold --from 10 1
  abort: cannot fold non-linear revisions
  (given revisions are unrelated to parent of working directory)
  [255]
  $ hg fold --exact -r "4 and not 4"
  abort: specified revisions evaluate to an empty set
  (use different revision arguments)
  [255]
  $ hg phase --public 0
  $ hg fold --from -r 0
  abort: cannot fold public changesets: 1ea73414a91b
  (see 'hg help phases' for details)
  [255]

Test actual folding

  $ hg fold --from -r 'desc("r5")'
  3 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

(test inherited from test-evolve.t)

  $ hg fold --from 6 # want to run hg fold 6
  abort: hidden revision '6'!
  (use --hidden to access hidden revisions; successor: 198b5c405d01)
  [255]

  $ hg log -G
  @  11 - 198b5c405d01 r5 [debugbuilddag] (draft)
  |
  | o  10 - a8407f9a3dc1 r10 [debugbuilddag] (draft)
  | |
  | o  9 - 529dfc5bb875 r9 [debugbuilddag] (draft)
  | |
  | o  8 - abf57d94268b r8 [debugbuilddag] (draft)
  | |
  o |  4 - bebd167eb94d r4 [debugbuilddag] (draft)
  |/
  o  3 - 2dc09a01254d r3 [debugbuilddag] (draft)
  |
  o  2 - 01241442b3c2 r2 [debugbuilddag] (draft)
  |
  o  1 - 66f7d451a68b r1 [debugbuilddag] (draft)
  |
  o  0 - 1ea73414a91b r0 [debugbuilddag] (public)
  

test fold --exact

  $ hg fold --exact 'desc("r8") + desc("r10")'
  abort: cannot fold non-linear revisions (multiple roots given)
  [255]
  $ hg fold --exact 'desc("r8")::desc("r10")'
  3 changesets folded
  $ hg log -G
  o  12 - b568edbee6e0 r8 [debugbuilddag] (draft)
  |
  | @  11 - 198b5c405d01 r5 [debugbuilddag] (draft)
  | |
  | o  4 - bebd167eb94d r4 [debugbuilddag] (draft)
  |/
  o  3 - 2dc09a01254d r3 [debugbuilddag] (draft)
  |
  o  2 - 01241442b3c2 r2 [debugbuilddag] (draft)
  |
  o  1 - 66f7d451a68b r1 [debugbuilddag] (draft)
  |
  o  0 - 1ea73414a91b r0 [debugbuilddag] (public)
  

Test allow unstable

  $ echo a > a
  $ hg add a
  $ hg commit '-m r11'
  $ hg up '.^'
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg log -G
  o  13 - 14d0e0da8e91 r11 [test] (draft)
  |
  | o  12 - b568edbee6e0 r8 [debugbuilddag] (draft)
  | |
  @ |  11 - 198b5c405d01 r5 [debugbuilddag] (draft)
  | |
  o |  4 - bebd167eb94d r4 [debugbuilddag] (draft)
  |/
  o  3 - 2dc09a01254d r3 [debugbuilddag] (draft)
  |
  o  2 - 01241442b3c2 r2 [debugbuilddag] (draft)
  |
  o  1 - 66f7d451a68b r1 [debugbuilddag] (draft)
  |
  o  0 - 1ea73414a91b r0 [debugbuilddag] (public)
  

  $ cat << EOF >> .hg/hgrc
  > [experimental]
  > evolution = createmarkers, allnewcommands
  > EOF
  $ hg fold --from 'desc("r4")'
  abort: fold will orphan 1 descendants
  (see 'hg help evolution.instability')
  [255]
  $ hg fold --from 'desc("r3")::desc("r11")'
  abort: fold will orphan 1 descendants
  (see 'hg help evolution.instability')
  [255]

test --user variant

  $ cat << EOF >> .hg/hgrc
  > [experimental]
  > evolution = createmarkers, allnewcommands
  > EOF
  $ cat << EOF >> .hg/hgrc
  > [experimental]
  > evolution = all
  > EOF

  $ hg fold --exact 'desc("r5") + desc("r11")' --user 'Victor Rataxes <victor@rhino.savannah>'
  2 changesets folded
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  @  14 - 29b470a33594 r5 [Victor Rataxes <victor@rhino.savannah>] (draft)
  |
  | o  12 - b568edbee6e0 r8 [debugbuilddag] (draft)
  | |
  o |  4 - bebd167eb94d r4 [debugbuilddag] (draft)
  |/
  o  3 - 2dc09a01254d r3 [debugbuilddag] (draft)
  |
  o  2 - 01241442b3c2 r2 [debugbuilddag] (draft)
  |
  o  1 - 66f7d451a68b r1 [debugbuilddag] (draft)
  |
  o  0 - 1ea73414a91b r0 [debugbuilddag] (public)
  

  $ hg fold --from 'desc("r4")' -U
  2 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  @  15 - 91880abed0f2 r4 [test] (draft)
  |
  | o  12 - b568edbee6e0 r8 [debugbuilddag] (draft)
  |/
  o  3 - 2dc09a01254d r3 [debugbuilddag] (draft)
  |
  o  2 - 01241442b3c2 r2 [debugbuilddag] (draft)
  |
  o  1 - 66f7d451a68b r1 [debugbuilddag] (draft)
  |
  o  0 - 1ea73414a91b r0 [debugbuilddag] (public)
  
  $ cd ..

