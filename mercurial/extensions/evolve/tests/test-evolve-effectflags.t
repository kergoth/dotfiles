Test the 'effect-flags' feature

Global setup
============

  $ . $TESTDIR/testlib/common.sh
  $ cat >> $HGRCPATH <<EOF
  > [ui]
  > interactive = true
  > [phases]
  > publish=False
  > [extensions]
  > evolve =
  > rebase =
  > [experimental]
  > evolution.effect-flags = 1
  > EOF

  $ hg init $TESTTMP/effect-flags
  $ cd $TESTTMP/effect-flags
  $ mkcommit ROOT

amend touching the description only
-----------------------------------

  $ mkcommit A0
  $ hg amend -m "A1"

check result

  $ hg debugobsolete --rev .
  471f378eab4c5e25f6c77f785b27c936efb22874 fdf9bde5129a28d4548fadd3f62b265cdd3b7a2e 0 (*) {'ef1': '1', 'user': 'test'} (glob)
  $ hg obslog .
  @  fdf9bde5129a (2) A1
  |
  x  471f378eab4c (1) A0
       rewritten(description) by test (*) as fdf9bde5129a (glob)
  

amend touching the user only
----------------------------

  $ mkcommit B0
  $ hg amend -u "bob <bob@bob.com>"

check result

  $ hg debugobsolete --rev .
  ef4a313b1e0ade55718395d80e6b88c5ccd875eb 5485c92d34330dac9d7a63dc07e1e3373835b964 0 (*) {'ef1': '16', 'user': 'test'} (glob)
  $ hg obslog .
  @  5485c92d3433 (4) B0
  |
  x  ef4a313b1e0a (3) B0
       rewritten(user) by test (*) as 5485c92d3433 (glob)
  

amend touching the date only
----------------------------

  $ mkcommit B1
  $ hg amend -d "42 0"

check result

  $ hg debugobsolete --rev .
  2ef0680ff45038ac28c9f1ff3644341f54487280 4dd84345082e9e5291c2e6b3f335bbf8bf389378 0 (*) {'ef1': '32', 'user': 'test'} (glob)
  $ hg obslog .
  @  4dd84345082e (6) B1
  |
  x  2ef0680ff450 (5) B1
       rewritten(date) by test (*) as 4dd84345082e (glob)
  

amend touching the branch only
----------------------------

  $ mkcommit B2
  $ hg branch my-branch
  marked working directory as branch my-branch
  (branches are permanent and global, did you want a bookmark?)
  $ hg amend

check result

  $ hg debugobsolete --rev .
  4d1430a201c1ffbd8465dec75edd4a691a2d97ec 0 {bd3db8264ceebf1966319f5df3be7aac6acd1a8e} (*) {'ef1': '0', 'user': 'test'} (glob)
  bd3db8264ceebf1966319f5df3be7aac6acd1a8e 14a01456e0574f0e0a0b15b2345486a6364a8d79 0 (*) {'ef1': '64', 'user': 'test'} (glob)
  $ hg obslog .
  @  14a01456e057 (9) B2
  |
  x  bd3db8264cee (7) B2
       rewritten(branch) by test (*) as 14a01456e057 (glob)
  

  $ hg up default
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved

rebase (parents change)
-----------------------

  $ mkcommit C0
  $ mkcommit D0
  $ hg rebase -r . -d 'desc(B0)'
  rebasing 11:c85eff83a034 "D0" (tip)

check result

  $ hg debugobsolete --rev .
  c85eff83a0340efd9da52b806a94c350222f3371 da86aa2f19a30d6686b15cae15c7b6c908ec9699 0 (*) {'ef1': '4', 'user': 'test'} (glob)
  $ hg obslog .
  @  da86aa2f19a3 (12) D0
  |
  x  c85eff83a034 (11) D0
       rewritten(parent) by test (*) as da86aa2f19a3 (glob)
  

amend touching the diff
-----------------------

  $ mkcommit E0
  $ echo 42 >> E0
  $ hg amend

check result

  $ hg debugobsolete --rev .
  d6f4d8b8d3c8cde990f13915bced7f92ce1cc54f 0 {ebfe0333e0d96f68a917afd97c0a0af87f1c3b5f} (*) {'ef1': '0', 'user': 'test'} (glob)
  ebfe0333e0d96f68a917afd97c0a0af87f1c3b5f 75781fdbdbf58a987516b00c980bccda1e9ae588 0 (*) {'ef1': '8', 'user': 'test'} (glob)
  $ hg obslog .
  @  75781fdbdbf5 (15) E0
  |
  x  ebfe0333e0d9 (13) E0
       rewritten(content) by test (*) as 75781fdbdbf5 (glob)
  

amend with multiple effect (desc and meta)
-------------------------------------------

  $ mkcommit F0
  $ hg branch my-other-branch
  marked working directory as branch my-other-branch
  $ hg amend -m F1 -u "bob <bob@bob.com>" -d "42 0"

check result

  $ hg debugobsolete --rev .
  3b12912003b4e7aa6df6cded86255006c3c29d27 0 {fad47e5bd78e6aa4db1b5a0a1751bc12563655ff} (*) {'ef1': '0', 'user': 'test'} (glob)
  fad47e5bd78e6aa4db1b5a0a1751bc12563655ff a94e0fd5f1c81d969381a76eb0d37ce499a44fae 0 (*) {'ef1': '113', 'user': 'test'} (glob)
  $ hg obslog .
  @  a94e0fd5f1c8 (18) F1
  |
  x  fad47e5bd78e (16) F0
       rewritten(description, user, date, branch) by test (*) as a94e0fd5f1c8 (glob)
  
rebase not touching the diff
----------------------------

  $ cat << EOF > H0
  > 0
  > 1
  > 2
  > 3
  > 4
  > 5
  > 6
  > 7
  > 8
  > 9
  > 10
  > EOF
  $ hg add H0
  $ hg commit -m 'H0'
  $ echo "H1" >> H0
  $ hg commit -m "H1"
  $ hg up -r "desc(H0)"
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat << EOF > H0
  > H2
  > 0
  > 1
  > 2
  > 3
  > 4
  > 5
  > 6
  > 7
  > 8
  > 9
  > 10
  > EOF
  $ hg commit -m "H2"
  created new head
  $ hg rebase -s "desc(H1)" -d "desc(H2)" -t :merge3
  rebasing 20:b57fed8d8322 "H1"
  merging H0
  $ hg obslog tip
  o  e509e2eb3df5 (22) H1
  |
  x  b57fed8d8322 (20) H1
       rewritten(parent) by test (*) as e509e2eb3df5 (glob)
  
amend closing the branch should be detected as meta change
----------------------------------------------------------

  $ hg branch closedbranch
  marked working directory as branch closedbranch
  $ mkcommit G0
  $ mkcommit I0
  $ hg commit --amend --close-branch

check result

  $ hg obslog .
  @  12c6238b5e37 (26) I0
  |
  x  2f599e54c1c6 (24) I0
       rewritten(meta) by test (*) as 12c6238b5e37 (glob)
  
