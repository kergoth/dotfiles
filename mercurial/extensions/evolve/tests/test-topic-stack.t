  $ . "$TESTDIR/testlib/topic_setup.sh"

Initial setup


  $ cat << EOF >> $HGRCPATH
  > [ui]
  > logtemplate = {rev} {branch} \{{get(namespaces, "topics")}} {phase} {desc|firstline}\n
  > [experimental]
  > evolution=all
  > EOF

  $ hg init main
  $ cd main
  $ hg topic other
  marked working directory as topic: other
  $ echo aaa > aaa
  $ hg add aaa
  $ hg commit -m c_a
  active topic 'other' grew its first changeset
  $ echo aaa > bbb
  $ hg add bbb
  $ hg commit -m c_b
  $ hg topic foo
  $ echo aaa > ccc
  $ hg add ccc
  $ hg commit -m c_c
  active topic 'foo' grew its first changeset
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
  ### target: default (branch)
  t2@ c_b (current)
  t1: c_a
  $ hg phase --public 'topic("other")'
  active topic 'other' is now empty

After changing the phase of all the changesets in "other" to public, the topic should still be active, but is empty. We should be better at informating the user about it and displaying good data in this case.

  $ hg topic
     foo   (4 changesets)
   * other (0 changesets)
  $ hg stack
  ### topic: other
  ### target: default (branch)
  (stack is empty)
  t0^ c_b (base current)

  $ hg up foo
  switching to topic foo
  4 files updated, 0 files merged, 0 files removed, 0 files unresolved

Simple test
-----------

'hg stack' list all changeset in the topic

  $ hg topic
   * foo (4 changesets)
  $ hg stack
  ### topic: foo
  ### target: default (branch)
  t4@ c_f (current)
  t3: c_e
  t2: c_d
  t1: c_c
  t0^ c_b (base)
  $ hg stack -v
  ### topic: foo
  ### target: default (branch)
  t4(6559e6d93aea)@ c_f (current)
  t3(0f9ac936c87d): c_e
  t2(e629654d7050): c_d
  t1(8522f9e3fee9): c_c
  t0(ea705abc4f51)^ c_b (base)
  $ hg stack -Tjson | python -m json.tool
  [
      {
          "isentry": true,
          "topic.stack.desc": "c_f",
          "topic.stack.index": 4,
          "topic.stack.state": [
              "current"
          ],
          "topic.stack.state.symbol": "@"
      },
      {
          "isentry": true,
          "topic.stack.desc": "c_e",
          "topic.stack.index": 3,
          "topic.stack.state": [
              "clean"
          ],
          "topic.stack.state.symbol": ":"
      },
      {
          "isentry": true,
          "topic.stack.desc": "c_d",
          "topic.stack.index": 2,
          "topic.stack.state": [
              "clean"
          ],
          "topic.stack.state.symbol": ":"
      },
      {
          "isentry": true,
          "topic.stack.desc": "c_c",
          "topic.stack.index": 1,
          "topic.stack.state": [
              "clean"
          ],
          "topic.stack.state.symbol": ":"
      },
      {
          "isentry": false,
          "topic.stack.desc": "c_b",
          "topic.stack.index": 0,
          "topic.stack.state": [
              "base"
          ],
          "topic.stack.state.symbol": "^"
      }
  ]
  $ hg stack -v -Tjson | python -m json.tool
  [
      {
          "isentry": true,
          "topic.stack.desc": "c_f",
          "topic.stack.index": 4,
          "topic.stack.shortnode": "6559e6d93aea",
          "topic.stack.state": [
              "current"
          ],
          "topic.stack.state.symbol": "@"
      },
      {
          "isentry": true,
          "topic.stack.desc": "c_e",
          "topic.stack.index": 3,
          "topic.stack.shortnode": "0f9ac936c87d",
          "topic.stack.state": [
              "clean"
          ],
          "topic.stack.state.symbol": ":"
      },
      {
          "isentry": true,
          "topic.stack.desc": "c_d",
          "topic.stack.index": 2,
          "topic.stack.shortnode": "e629654d7050",
          "topic.stack.state": [
              "clean"
          ],
          "topic.stack.state.symbol": ":"
      },
      {
          "isentry": true,
          "topic.stack.desc": "c_c",
          "topic.stack.index": 1,
          "topic.stack.shortnode": "8522f9e3fee9",
          "topic.stack.state": [
              "clean"
          ],
          "topic.stack.state.symbol": ":"
      },
      {
          "isentry": false,
          "topic.stack.desc": "c_b",
          "topic.stack.index": 0,
          "topic.stack.shortnode": "ea705abc4f51",
          "topic.stack.state": [
              "base"
          ],
          "topic.stack.state.symbol": "^"
      }
  ]

check that topics and stack are available even if ui.strict=true

  $ hg topics
   * foo (4 changesets)
  $ hg stack
  ### topic: foo
  ### target: default (branch)
  t4@ c_f (current)
  t3: c_e
  t2: c_d
  t1: c_c
  t0^ c_b (base)
  $ hg topics --config ui.strict=true
   * foo (4 changesets)
  $ hg stack --config ui.strict=true
  ### topic: foo
  ### target: default (branch)
  t4@ c_f (current)
  t3: c_e
  t2: c_d
  t1: c_c
  t0^ c_b (base)

error case, nothing to list

  $ hg topic --clear
  $ hg stack
  ### target: default (branch)
  (stack is empty)
  b0^ c_f (base current)

Test "t#" reference
-------------------


  $ hg up t2
  abort: cannot resolve "t2": no active topic
  [255]
  $ hg topic foo
  marked working directory as topic: foo
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
  2 new orphan changesets
  $ hg log -G
  @  6 default {foo} draft c_d
  |
  | *  5 default {foo} draft c_f
  | |
  | *  4 default {foo} draft c_e
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
  ### target: default (branch)
  t4$ c_f (unstable)
  t3$ c_e (unstable)
  t2@ c_d (current)
  t1: c_c
  t0^ c_b (base)
  $ hg up t3
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic --list
  ### topic: foo
  ### target: default (branch)
  t4$ c_f (unstable)
  t3$ c_e (current unstable)
  t2: c_d
  t1: c_c
  t0^ c_b (base)
  $ hg topic --list --color=debug
  [topic.stack.summary.topic|### topic: [topic.active|foo]]
  [topic.stack.summary.branches|### target: default (branch)]
  [topic.stack.index topic.stack.index.unstable|t4][topic.stack.state topic.stack.state.unstable|$] [topic.stack.desc topic.stack.desc.unstable|c_f][topic.stack.state topic.stack.state.unstable| (unstable)]
  [topic.stack.index topic.stack.index.current topic.stack.index.unstable|t3][topic.stack.state topic.stack.state.current topic.stack.state.unstable|$] [topic.stack.desc topic.stack.desc.current topic.stack.desc.unstable|c_e][topic.stack.state topic.stack.state.current topic.stack.state.unstable| (current unstable)]
  [topic.stack.index topic.stack.index.clean|t2][topic.stack.state topic.stack.state.clean|:] [topic.stack.desc topic.stack.desc.clean|c_d]
  [topic.stack.index topic.stack.index.clean|t1][topic.stack.state topic.stack.state.clean|:] [topic.stack.desc topic.stack.desc.clean|c_c]
  [topic.stack.index topic.stack.index.base|t0][topic.stack.state topic.stack.state.base|^] [topic.stack.desc topic.stack.desc.base|c_b][topic.stack.state topic.stack.state.base| (base)]
  $ hg up t2
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved

Also test the revset:

  $ hg log -r 'stack()'
  2 default {foo} draft c_c
  6 default {foo} draft c_d
  4 default {foo} draft c_e
  5 default {foo} draft c_f

  $ hg log -r 'stack(foo)'
  hg: parse error: stack() takes no argument, it works on current topic
  [255]

  $ hg log -r 'stack(foobar)'
  hg: parse error: stack() takes no argument, it works on current topic
  [255]

Case with multiple heads on the topic
-------------------------------------

Make things linear again

  $ hg rebase -s 'desc(c_e)' -d 'desc(c_d) - obsolete()'
  rebasing 4:0f9ac936c87d "c_e" (foo)
  rebasing 5:6559e6d93aea "c_f" (foo)
  $ hg log -G
  o  8 default {foo} draft c_f
  |
  o  7 default {foo} draft c_e
  |
  @  6 default {foo} draft c_d
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
  @  10 default {foo} draft c_h
  |
  o  9 default {foo} draft c_g
  |
  | o  8 default {foo} draft c_f
  | |
  | o  7 default {foo} draft c_e
  |/
  o  6 default {foo} draft c_d
  |
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  

Test output

  $ hg top -l
  ### topic: foo (2 heads)
  ### target: default (branch)
  t6@ c_h (current)
  t5: c_g
  t2^ c_d (base)
  t4: c_f
  t3: c_e
  t2: c_d
  t1: c_c
  t0^ c_b (base)

Case with multiple heads on the topic with unstability involved
---------------------------------------------------------------

We amend the message to make sure the display base pick the right changeset

  $ hg up 'desc(c_d)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo ccc > ddd
  $ hg commit --amend -m 'c_D' 
  4 new orphan changesets
  $ hg rebase -d . -s 'desc(c_g)'
  rebasing 9:81264ae8a36a "c_g" (foo)
  rebasing 10:fde5f5941642 "c_h" (foo)
  $ hg log -G
  o  13 default {foo} draft c_h
  |
  o  12 default {foo} draft c_g
  |
  @  11 default {foo} draft c_D
  |
  | *  8 default {foo} draft c_f
  | |
  | *  7 default {foo} draft c_e
  | |
  | x  6 default {foo} draft c_d
  |/
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  

  $ hg topic --list
  ### topic: foo (2 heads)
  ### target: default (branch)
  t6: c_h
  t5: c_g
  t2^ c_D (base current)
  t4$ c_f (unstable)
  t3$ c_e (unstable)
  t2@ c_D (current)
  t1: c_c
  t0^ c_b (base)

Trying to list non existing topic
  $ hg stack thisdoesnotexist
  abort: cannot resolve "thisdoesnotexist": no such topic found
  [255]
  $ hg topic --list thisdoesnotexist
  abort: cannot resolve "thisdoesnotexist": no such topic found
  [255]

Complex cases where commits with same topic are not consecutive but are linear
==============================================================================

  $ hg log --graph
  o  13 default {foo} draft c_h
  |
  o  12 default {foo} draft c_g
  |
  @  11 default {foo} draft c_D
  |
  | *  8 default {foo} draft c_f
  | |
  | *  7 default {foo} draft c_e
  | |
  | x  6 default {foo} draft c_d
  |/
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  
Converting into a linear chain
  $ hg rebase -s 'desc("c_e") - obsolete()' -d 'desc("c_h") - obsolete()'
  rebasing 7:215bc359096a "c_e" (foo)
  rebasing 8:ec9267b3f33f "c_f" (foo)

  $ hg log -G
  o  15 default {foo} draft c_f
  |
  o  14 default {foo} draft c_e
  |
  o  13 default {foo} draft c_h
  |
  o  12 default {foo} draft c_g
  |
  @  11 default {foo} draft c_D
  |
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  
Changing topics on some commits in between
  $ hg topic foobar -r 'desc(c_e) + desc(c_D)'
  switching to topic foobar
  4 new orphan changesets
  changed topic on 2 changes
  $ hg log -G
  @  17 default {foobar} draft c_D
  |
  | *  16 default {foobar} draft c_e
  | |
  | | *  15 default {foo} draft c_f
  | | |
  | | x  14 default {foo} draft c_e
  | |/
  | *  13 default {foo} draft c_h
  | |
  | *  12 default {foo} draft c_g
  | |
  | x  11 default {foo} draft c_D
  |/
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  
  $ hg rebase -s 'desc("c_f") - obsolete()' -d 'desc("c_e") - obsolete()'
  rebasing 15:77082e55de88 "c_f" (foo)
  switching to topic foo
  1 new orphan changesets
  switching to topic foobar
  $ hg rebase -s 'desc("c_g") - obsolete()' -d 'desc("c_D") - obsolete()'
  rebasing 12:0c3e8aed985d "c_g" (foo)
  switching to topic foo
  rebasing 13:b9e4f3709bc5 "c_h" (foo)
  rebasing 16:4bc813530301 "c_e" (foobar)
  switching to topic foobar
  rebasing 18:4406ea4be852 "c_f" (tip foo)
  switching to topic foo
  switching to topic foobar
  $ hg up
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log --graph
  o  22 default {foo} draft c_f
  |
  @  21 default {foobar} draft c_e
  |
  o  20 default {foo} draft c_h
  |
  o  19 default {foo} draft c_g
  |
  o  17 default {foobar} draft c_D
  |
  o  2 default {foo} draft c_c
  |
  o  1 default {} public c_b
  |
  o  0 default {} public c_a
  
XXX: The following should show single heads
XXX: The behind count is weird, because the topic are interleaved.

  $ hg stack
  ### topic: foobar
  ### target: default (branch), 3 behind
  t2@ c_e (current)
    ^ c_h
  t1: c_D
  t0^ c_c (base)

  $ hg stack foo
  ### topic: foo
  ### target: default (branch), ambiguous rebase destination - topic 'foo' has 3 heads
  t4: c_f
    ^ c_e
  t3: c_h
  t2: c_g
    ^ c_D
  t1: c_c
  t0^ c_b (base)

case involving a merge
----------------------

  $ cd ..
  $ hg init stack-gap-merge
  $ cd stack-gap-merge

  $ echo aaa > aaa
  $ hg commit -Am 'c_A'
  adding aaa
  $ hg topic red
  marked working directory as topic: red
  $ echo bbb > bbb
  $ hg commit -Am 'c_B'
  adding bbb
  active topic 'red' grew its first changeset
  $ echo ccc > ccc
  $ hg commit -Am 'c_C'
  adding ccc
  $ hg topic blue
  $ echo ddd > ddd
  $ hg commit -Am 'c_D'
  adding ddd
  active topic 'blue' grew its first changeset
  $ hg up 'desc("c_B")'
  switching to topic red
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo eee > eee
  $ hg commit -Am 'c_E'
  adding eee
  $ echo fff > fff
  $ hg commit -Am 'c_F'
  adding fff
  $ hg topic blue
  $ echo ggg > ggg
  $ hg commit -Am 'c_G'
  adding ggg
  $ hg up 'desc("c_D")'
  2 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg topic red
  $ hg merge 'desc("c_G")'
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -Am 'c_H'
  $ hg topic blue
  $ echo iii > iii
  $ hg ci -Am 'c_I'
  adding iii

  $ hg log -G
  @  8 default {blue} draft c_I
  |
  o    7 default {red} draft c_H
  |\
  | o  6 default {blue} draft c_G
  | |
  | o  5 default {red} draft c_F
  | |
  | o  4 default {red} draft c_E
  | |
  o |  3 default {blue} draft c_D
  | |
  o |  2 default {red} draft c_C
  |/
  o  1 default {red} draft c_B
  |
  o  0 default {} draft c_A
  

  $ hg stack red
  ### topic: red
  ### target: default (branch), 6 behind
  t5: c_H
    ^ c_G
    ^ c_D
  t4: c_C
  t1^ c_B (base)
  t3: c_F
  t2: c_E
  t1: c_B
  t0^ c_A (base)
  $ hg stack blue
  ### topic: blue
  ### target: default (branch), ambiguous rebase destination - topic 'blue' has 3 heads
  t3@ c_I (current)
    ^ c_H
  t2: c_D
    ^ c_C
  t1: c_G
  t0^ c_F (base)

Even with some obsolete and orphan changesets

(the ordering of each branch of "blue" change because their hash change. we
should stabilize this eventuelly)

  $ hg up 'desc("c_B")'
  switching to topic red
  0 files updated, 0 files merged, 6 files removed, 0 files unresolved
  $ hg commit --amend --user test2
  7 new orphan changesets
  $ hg up 'desc("c_C")'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg commit --amend --user test2
  $ hg up 'desc("c_D")'
  switching to topic blue
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg commit --amend --user test2

  $ hg log -G --rev 'sort(all(), "topo")'
  @  11 default {blue} draft c_D
  |
  | *  8 default {blue} draft c_I
  | |
  | *    7 default {red} draft c_H
  | |\
  | | *  6 default {blue} draft c_G
  | | |
  | | *  5 default {red} draft c_F
  | | |
  | | *  4 default {red} draft c_E
  | | |
  | x |  3 default {blue} draft c_D
  |/ /
  x /  2 default {red} draft c_C
  |/
  | *  10 default {red} draft c_C
  |/
  x  1 default {red} draft c_B
  |
  | o  9 default {red} draft c_B
  |/
  o  0 default {} draft c_A
  

  $ hg stack red
  ### topic: red
  ### target: default (branch), ambiguous rebase destination - topic 'red' has 3 heads
  t5$ c_H (unstable)
    ^ c_G
    ^ c_D
  t4$ c_C (unstable)
  t1^ c_B (base)
  t3$ c_F (unstable)
  t2$ c_E (unstable)
  t1: c_B
  t0^ c_A (base)
  $ hg stack blue
  ### topic: blue
  ### target: default (branch), ambiguous rebase destination - topic 'blue' has 3 heads
  t3$ c_I (unstable)
    ^ c_H
  t2$ c_G (unstable)
    ^ c_F
  t1$ c_D (current unstable)
  t0^ c_C (base unstable)

more obsolescence

  $ hg up 'max(desc("c_H"))'
  switching to topic red
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg commit --amend --user test3
  $ hg up 'max(desc("c_G"))'
  switching to topic blue
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg commit --amend --user test3
  $ hg up 'max(desc("c_B"))'
  switching to topic red
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg commit --amend --user test3
  $ hg up 'max(desc("c_C"))'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg commit --amend --user test3
  $ hg up 'max(desc("c_D"))'
  switching to topic blue
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg commit --amend --user test3

  $ hg log -G --rev 'sort(all(), "topo")'
  @  16 default {blue} draft c_D
  |
  | *  13 default {blue} draft c_G
  | |
  | | *    12 default {red} draft c_H
  | | |\
  | | | | *  8 default {blue} draft c_I
  | | | | |
  | | +---x  7 default {red} draft c_H
  | | | |/
  | +---x  6 default {blue} draft c_G
  | | |
  | * |  5 default {red} draft c_F
  | | |
  | * |  4 default {red} draft c_E
  | | |
  +---x  3 default {blue} draft c_D
  | |
  x |  2 default {red} draft c_C
  |/
  | *  15 default {red} draft c_C
  |/
  x  1 default {red} draft c_B
  |
  | o  14 default {red} draft c_B
  |/
  o  0 default {} draft c_A
  

  $ hg stack red
  ### topic: red
  ### target: default (branch), ambiguous rebase destination - topic 'red' has 3 heads
  t5$ c_H (unstable)
    ^ c_G
    ^ c_D
  t4$ c_F (unstable)
  t3$ c_E (unstable)
  t1^ c_B (base)
  t2$ c_C (unstable)
  t1: c_B
  t0^ c_A (base)
  $ hg stack blue
  ### topic: blue
  ### target: default (branch), ambiguous rebase destination - topic 'blue' has 3 heads
  t3$ c_I (unstable)
    ^ c_H
  t2$ c_G (unstable)
    ^ c_F
  t1$ c_D (current unstable)
  t0^ c_C (base unstable)

Test stack behavior with a split
--------------------------------

get things linear again

  $ hg rebase -r t1 -d default
  rebasing 16:1d84ec948370 "c_D" (tip blue)
  switching to topic blue
  $ hg rebase -r t2 -d t1
  rebasing 13:3ab2eedae500 "c_G" (blue)
  $ hg rebase -r t3 -d t2
  rebasing 8:3bfe800e0486 "c_I" (blue)
  $ hg stack
  ### topic: blue
  ### target: default (branch)
  t3: c_I
  t2: c_G
  t1@ c_D (current)
  t0^ c_A (base)

making a split
(first get something to split)

  $ hg up t2
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg status --change .
  A ggg
  $ echo zzz > Z
  $ hg add Z
  $ hg commit --amend
  1 new orphan changesets
  $ hg status --change .
  A Z
  A ggg
  $ hg stack
  ### topic: blue
  ### target: default (branch)
  t3$ c_I (unstable)
  t2@ c_G (current)
  t1: c_D
  t0^ c_A (base)
  $ hg --config extensions.evolve=  --config ui.interactive=yes split << EOF
  > y
  > y
  > n
  > y
  > EOF
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  adding Z
  adding ggg
  diff --git a/Z b/Z
  new file mode 100644
  examine changes to 'Z'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +zzz
  record change 1/2 to 'Z'? [Ynesfdaq?] y
  
  diff --git a/ggg b/ggg
  new file mode 100644
  examine changes to 'ggg'? [Ynesfdaq?] n
  
  Done splitting? [yN] y

  $ hg --config extensions.evolve= obslog --all
  o  dde94df880e9 (21) c_G
  |
  | @  e7ea874afbd5 (22) c_G
  |/
  x  b24bab30ac12 (20) c_G
  |    rewritten(parent, content) as dde94df880e9, e7ea874afbd5 using split by test (Thu Jan 01 00:00:00 1970 +0000)
  |
  x  907f7d3c2333 (18) c_G
  |    rewritten(content) as b24bab30ac12 using amend by test (Thu Jan 01 00:00:00 1970 +0000)
  |
  x  3ab2eedae500 (13) c_G
  |    rewritten(parent) as 907f7d3c2333 using rebase by test (Thu Jan 01 00:00:00 1970 +0000)
  |
  x  c7d60a180d05 (6) c_G
       rewritten(user) as 3ab2eedae500 using amend by test (Thu Jan 01 00:00:00 1970 +0000)
  
  $ hg export .
  # HG changeset patch
  # User test3
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID e7ea874afbd5c17aeee366d39a828dbcb01682ce
  # Parent  dde94df880e97f4a1ee8c5408254b429b3d90204
  # EXP-Topic blue
  c_G
  
  diff -r dde94df880e9 -r e7ea874afbd5 ggg
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/ggg	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +ggg
  $ hg export .^
  # HG changeset patch
  # User test3
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID dde94df880e97f4a1ee8c5408254b429b3d90204
  # Parent  f3328cd199dc389b850ca952f65a15a8e6dbc79b
  # EXP-Topic blue
  c_G
  
  diff -r f3328cd199dc -r dde94df880e9 Z
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/Z	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +zzz

Check that stack ouput still make sense

  $ hg stack
  ### topic: blue
  ### target: default (branch)
  t4$ c_I (unstable)
  t3@ c_G (current)
  t2: c_G
  t1: c_D
  t0^ c_A (base)
