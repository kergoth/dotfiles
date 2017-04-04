
Check we can find the topic extensions

  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > [phases]
  > publish = False
  > [ui]
  > logtemplate = {rev} - \{{get(namespaces, "topics")}} {node|short} {desc} ({phase})\n
  > [diff]
  > git = 1
  > unified = 0
  > [extensions]
  > rebase = 
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ echo "topic=$(echo $(dirname $TESTDIR))/hgext3rd/topic/" >> $HGRCPATH

  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

Create a simple setup

  $ hg init repoa
  $ cd repoa
  $ mkcommit aaa
  $ mkcommit bbb
  $ hg topic foo
  $ mkcommit ccc
  $ mkcommit ddd
  $ mkcommit eee
  $ mkcommit fff
  $ hg topic bar
  $ mkcommit ggg
  $ mkcommit hhh
  $ mkcommit iii
  $ mkcommit jjj

  $ hg log -G
  @  9 - {bar} 1d964213b023 add jjj (draft)
  |
  o  8 - {bar} fcab990f3261 add iii (draft)
  |
  o  7 - {bar} b0c2554835ac add hhh (draft)
  |
  o  6 - {bar} c748293f1c1a add ggg (draft)
  |
  o  5 - {foo} 6a6b7365c751 add fff (draft)
  |
  o  4 - {foo} 3969ab847d9c add eee (draft)
  |
  o  3 - {foo} 4e3a154f38c7 add ddd (draft)
  |
  o  2 - {foo} cced9bac76e3 add ccc (draft)
  |
  o  1 - {} a4dbed0837ea add bbb (draft)
  |
  o  0 - {} 199cc73e9a0b add aaa (draft)
  

Test that evolve --all evolve the current topic
-----------------------------------------------

make a mess

  $ hg up foo
  switching to topic foo
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ hg topic -l 
  ### topic: foo (?)
  ### branch: default (?)
  t4@ add fff (current)
  t3: add eee
  t2: add ddd
  t1: add ccc
    ^ add bbb
  $ hg up 'desc(ddd)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo ddd >> ddd
  $ hg amend
  6 new unstable changesets
  $ hg up 'desc(fff)'
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo fff >> fff
  $ hg amend

  $ hg log -G
  @  13 - {foo} e104f49bab28 add fff (draft)
  |
  | o  11 - {foo} d9cacd156ffc add ddd (draft)
  | |
  | | o  9 - {bar} 1d964213b023 add jjj (draft)
  | | |
  | | o  8 - {bar} fcab990f3261 add iii (draft)
  | | |
  | | o  7 - {bar} b0c2554835ac add hhh (draft)
  | | |
  | | o  6 - {bar} c748293f1c1a add ggg (draft)
  | | |
  +---x  5 - {foo} 6a6b7365c751 add fff (draft)
  | |
  o |  4 - {foo} 3969ab847d9c add eee (draft)
  | |
  x |  3 - {foo} 4e3a154f38c7 add ddd (draft)
  |/
  o  2 - {foo} cced9bac76e3 add ccc (draft)
  |
  o  1 - {} a4dbed0837ea add bbb (draft)
  |
  o  0 - {} 199cc73e9a0b add aaa (draft)
  

Run evolve --all

  $ hg evolve --all
  move:[4] add eee
  atop:[11] add ddd
  move:[13] add fff
  atop:[14] add eee
  working directory is now at 070c5573d8f9
  $ hg log -G
  @  15 - {foo} 070c5573d8f9 add fff (draft)
  |
  o  14 - {foo} 42b49017ff90 add eee (draft)
  |
  o  11 - {foo} d9cacd156ffc add ddd (draft)
  |
  | o  9 - {bar} 1d964213b023 add jjj (draft)
  | |
  | o  8 - {bar} fcab990f3261 add iii (draft)
  | |
  | o  7 - {bar} b0c2554835ac add hhh (draft)
  | |
  | o  6 - {bar} c748293f1c1a add ggg (draft)
  | |
  | x  5 - {foo} 6a6b7365c751 add fff (draft)
  | |
  | x  4 - {foo} 3969ab847d9c add eee (draft)
  | |
  | x  3 - {foo} 4e3a154f38c7 add ddd (draft)
  |/
  o  2 - {foo} cced9bac76e3 add ccc (draft)
  |
  o  1 - {} a4dbed0837ea add bbb (draft)
  |
  o  0 - {} 199cc73e9a0b add aaa (draft)
  

Test that evolve does not loose topic information
-------------------------------------------------

  $ hg evolve --rev 'topic(bar)'
  move:[6] add ggg
  atop:[15] add fff
  move:[7] add hhh
  atop:[16] add ggg
  move:[8] add iii
  atop:[17] add hhh
  move:[9] add jjj
  atop:[18] add iii
  working directory is now at 9bf430c106b7
  $ hg log -G
  @  19 - {bar} 9bf430c106b7 add jjj (draft)
  |
  o  18 - {bar} d2dc89c57700 add iii (draft)
  |
  o  17 - {bar} 20bc4d02aa62 add hhh (draft)
  |
  o  16 - {bar} 16d6f664b17c add ggg (draft)
  |
  o  15 - {foo} 070c5573d8f9 add fff (draft)
  |
  o  14 - {foo} 42b49017ff90 add eee (draft)
  |
  o  11 - {foo} d9cacd156ffc add ddd (draft)
  |
  o  2 - {foo} cced9bac76e3 add ccc (draft)
  |
  o  1 - {} a4dbed0837ea add bbb (draft)
  |
  o  0 - {} 199cc73e9a0b add aaa (draft)
  

Tests next and prev behavior
============================

Basic move are restricted to the current topic

  $ hg up foo
  switching to topic foo
  0 files updated, 0 files merged, 4 files removed, 0 files unresolved
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [14] add eee
  $ hg next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [15] add fff
  $ hg next
  no children on topic "foo"
  do you want --no-topic
  [1]
  $ hg next --no-topic
  switching to topic bar
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [16] add ggg
  $ hg prev
  no parent in topic "bar"
  (do you want --no-topic)
  $ hg prev --no-topic
  switching to topic foo
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [15] add fff
