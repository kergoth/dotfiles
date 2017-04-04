  $ . "$TESTDIR/testlib/topic_setup.sh"

Initial setup


  $ cat << EOF >> $HGRCPATH
  > [ui]
  > logtemplate = {rev} {branch} \{{get(namespaces, "topics")}} {phase} {desc|firstline}\n
  > [experimental]
  > evolution=createmarkers,exchange,allowunstable
  > EOF

  $ hg init main
  $ cd main
  $ hg topic other
  $ echo aaa > aaa
  $ hg add aaa
  $ hg commit -m c_a
  $ echo aaa > bbb
  $ hg add bbb
  $ hg commit -m c_b
  $ hg topic foo
  $ echo aaa > ccc
  $ hg add ccc
  $ hg commit -m c_c
  $ echo aaa > ddd
  $ hg add ddd
  $ hg commit -m c_d
  $ echo aaa > eee
  $ hg add eee
  $ hg commit -m c_e
  $ echo aaa > fff
  $ hg add fff
  $ hg commit -m c_f
  $ hg log -G
  @  5 default {foo} draft c_f
  |
  o  4 default {foo} draft c_e
  |
  o  3 default {foo} draft c_d
  |
  o  2 default {foo} draft c_c
  |
  o  1 default {other} draft c_b
  |
  o  0 default {other} draft c_a
  

Check that topic without any parent does not crash --list
---------------------------------------------------------

  $ hg up other
  switching to topic other
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ hg topic --list
  ### topic: other
  ### branch: default
  t2@ c_b (current)
  t1: c_a
  $ hg phase --public 'topic("other")'
  $ hg up foo
  switching to topic foo
  4 files updated, 0 files merged, 0 files removed, 0 files unresolved

Simple test
-----------

'hg stack' list all changeset in the topic

  $ hg topic
   * foo
  $ hg stack
  ### topic: foo
  ### branch: default
  t4@ c_f (current)
  t3: c_e
  t2: c_d
  t1: c_c
    ^ c_b

error case, nothing to list

  $ hg topic --clear
  $ hg stack
  abort: no active topic to list
  [255]

Test "t#" reference
-------------------


  $ hg up t2
  abort: cannot resolve "t2": no active topic
  [255]
  $ hg topic foo
  $ hg up t42
  abort: cannot resolve "t42": topic "foo" has only 4 changesets
  [255]
  $ hg up t2
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg summary
  parent: 3:e629654d7050 
   c_d
  branch: default
  commit: (clean)
  update: (current)
  phases: 4 draft
  topic:  foo

Case with some of the topic unstable
------------------------------------

  $ echo bbb > ddd
  $ hg commit --amend
  $ hg log -G
  @  7 default {foo} draft c_d
  |
  | o  5 default {foo} draft c_f
  | |
  | o  4 default {foo} draft c_e
  | |
  | x  3 default {foo} draft c_d
  |/
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  
  $ hg topic --list
  ### topic: foo
  ### branch: default
  t4$ c_f (unstable)
  t3$ c_e (unstable)
  t2@ c_d (current)
  t1: c_c
    ^ c_b

Also test the revset:

  $ hg log -r 'stack()'
  2 default {foo} draft c_c
  7 default {foo} draft c_d
  4 default {foo} draft c_e
  5 default {foo} draft c_f

Case with multiple heads on the topic
-------------------------------------

Make things linear again

  $ hg rebase -s 'desc(c_e)' -d 'desc(c_d) - obsolete()'
  rebasing 4:0f9ac936c87d "c_e"
  rebasing 5:6559e6d93aea "c_f"
  $ hg log -G
  o  9 default {foo} draft c_f
  |
  o  8 default {foo} draft c_e
  |
  @  7 default {foo} draft c_d
  |
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  


Create the second branch

  $ hg up 'desc(c_d)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo aaa > ggg
  $ hg add ggg
  $ hg commit -m c_g
  $ echo aaa > hhh
  $ hg add hhh
  $ hg commit -m c_h
  $ hg log -G
  @  11 default {foo} draft c_h
  |
  o  10 default {foo} draft c_g
  |
  | o  9 default {foo} draft c_f
  | |
  | o  8 default {foo} draft c_e
  |/
  o  7 default {foo} draft c_d
  |
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  

Test output

  $ hg top -l
  ### topic: foo (2 heads)
  ### branch: default
  t6: c_f
  t5: c_e
  t2^ c_d (base)
  t4@ c_h (current)
  t3: c_g
  t2: c_d
  t1: c_c
    ^ c_b

Case with multiple heads on the topic with unstability involved
---------------------------------------------------------------

We amend the message to make sure the display base pick the right changeset

  $ hg up 'desc(c_d)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo ccc > ddd
  $ hg commit --amend -m 'c_D' 
  $ hg rebase -d . -s 'desc(c_g)'
  rebasing 10:81264ae8a36a "c_g"
  rebasing 11:fde5f5941642 "c_h"
  $ hg log -G
  o  15 default {foo} draft c_h
  |
  o  14 default {foo} draft c_g
  |
  @  13 default {foo} draft c_D
  |
  | o  9 default {foo} draft c_f
  | |
  | o  8 default {foo} draft c_e
  | |
  | x  7 default {foo} draft c_d
  |/
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  

  $ hg topic --list
  ### topic: foo (2 heads)
  ### branch: default
  t6$ c_f (unstable)
  t5$ c_e (unstable)
  t2^ c_D (base)
  t4: c_h
  t3: c_g
  t2@ c_D (current)
  t1: c_c
    ^ c_b
