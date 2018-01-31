==================================================
Test for `hg debugconvertbookmark` added by topics
==================================================

  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ cat << EOF >> $HGRCPATH
  > drawdag=$RUNTESTDIR/drawdag.py
  > [ui]
  > logtemplate = [{rev}:{node|short}] {desc|firstline}\n\
  > {if(bookmarks, "  bookmark: {join(bookmarks,"\n  bookmark:")}\n")}\
  > {if(topics, "  topic: {topics}\n")}
  > EOF

Setting up the things
---------------------

  $ hg init repo
  $ cd repo
  $ echo "Hello" > root
  $ hg commit -Aqm "root"
  $ hg phase --public .
  $ echo "Hello" > a
  $ hg commit -Aqm "First commit"
  $ echo "Hello" > b
  $ hg commit -Aqm "Second commit"
  $ hg bookmark "hellos"
  $ hg up 0 -q
  $ echo "Fix 1" > l
  $ hg commit -Aqm "Fixing first"
  $ echo "Fix 2" > m
  $ hg commit -Aqm "Fixing second"
  $ hg bookmark "secondfix"

  $ hg log -G
  @  [4:ec0e17135a94] Fixing second
  |    bookmark: secondfix
  o  [3:e05947b88d69] Fixing first
  |
  | o  [2:f53d1144f925] Second commit
  | |    bookmark: hellos
  | o  [1:df1fd5e18154] First commit
  |/
  o  [0:249055fcca50] root
  

Generic tests
=============

Help for the command
--------------------

  $ hg help debugconvertbookmark
  hg debugcb [-b BOOKMARK] [--all]
  
  aliases: debugconvertbookmark
  
  Converts a bookmark to a topic with the same name.
  
  options:
  
   -b --bookmark VALUE bookmark to convert to topic
      --all            convert all bookmarks to topics
  
  (some details hidden, use --verbose to show complete help)

Running without any argument
----------------------------

  $ hg debugconvertbookmark
  abort: you must specify either '--all' or '-b'
  [255]

Changing a particular bookmark to topic
=======================================

  $ hg debugconvertbookmark -b hellos
  changed topic to "hellos" on 2 revisions
  $ hg log -G
  o  [6:98ae7930f6ed] Second commit
  |    topic: hellos
  o  [5:ff69f6ee4618] First commit
  |    topic: hellos
  | @  [4:ec0e17135a94] Fixing second
  | |    bookmark: secondfix
  | o  [3:e05947b88d69] Fixing first
  |/
  o  [0:249055fcca50] root
  

Changing all bookmarks to topic
===============================

Simple test
-----------

  $ hg debugconvertbookmark --all
  switching to topic secondfix
  changed topic to "secondfix" on 2 revisions
  $ hg log -G
  @  [8:5f0f9cc1979a] Fixing second
  |    topic: secondfix
  o  [7:f8ecbf3b10be] Fixing first
  |    topic: secondfix
  | o  [6:98ae7930f6ed] Second commit
  | |    topic: hellos
  | o  [5:ff69f6ee4618] First commit
  |/     topic: hellos
  o  [0:249055fcca50] root
  

Trying with multiple bookmarks on a single changeset
----------------------------------------------------

  $ echo "multiple bookmarks" >> m
  $ hg commit -Aqm "Trying multiple bookmarks"
  $ hg bookmark book1
  $ hg bookmark book2
  $ hg log -G
  @  [9:4ad3e7d421d4] Trying multiple bookmarks
  |    bookmark: book1
  |    bookmark:book2
  |    topic: secondfix
  o  [8:5f0f9cc1979a] Fixing second
  |    topic: secondfix
  o  [7:f8ecbf3b10be] Fixing first
  |    topic: secondfix
  | o  [6:98ae7930f6ed] Second commit
  | |    topic: hellos
  | o  [5:ff69f6ee4618] First commit
  |/     topic: hellos
  o  [0:249055fcca50] root
  
  $ hg debugconvertbookmark --all
  skipping '9' as it has multiple bookmarks on it
  $ hg log -G
  @  [9:4ad3e7d421d4] Trying multiple bookmarks
  |    bookmark: book1
  |    bookmark:book2
  |    topic: secondfix
  o  [8:5f0f9cc1979a] Fixing second
  |    topic: secondfix
  o  [7:f8ecbf3b10be] Fixing first
  |    topic: secondfix
  | o  [6:98ae7930f6ed] Second commit
  | |    topic: hellos
  | o  [5:ff69f6ee4618] First commit
  |/     topic: hellos
  o  [0:249055fcca50] root
  

Two bookmarks on two different topological branches
---------------------------------------------------

  $ cd ..
  $ rm -rf repo
  $ hg init setup1
  $ cd setup1
  $ echo "Hello" > root
  $ hg commit -Aqm "root"
  $ hg phase --public .
  $ echo "Hello" > A
  $ hg commit -Aqm "A"
  $ echo "Hello" > B
  $ hg commit -Aqm "B"
  $ echo "Hello" > C
  $ hg commit -Aqm "C"
  $ echo "Hello" > D
  $ hg commit -Aqm "D"
  $ hg up 'desc(B)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo "Hello" > E
  $ hg commit -Aqm "E"
  $ echo "Hello" > F
  $ hg commit -Aqm "F"
  $ hg bookmark -r 'desc(D)' bar
  $ hg bookmark -r 'desc(F)' foo

  $ hg log -G
  @  [6:32f4660df717] F
  |    bookmark: foo
  o  [5:d4608d9df75e] E
  |
  | o  [4:4963af405f62] D
  | |    bookmark: bar
  | o  [3:ac05e0d05d00] C
  |/
  o  [2:10f317d09e78] B
  |
  o  [1:e34122c9a2bf] A
  |
  o  [0:249055fcca50] root
  
  $ hg debugconvertbookmark --all
  changed topic to "bar" on 2 revisions
  switching to topic foo
  changed topic to "foo" on 2 revisions
  $ hg log -G
  @  [10:f0b5f2a5f31a] F
  |    topic: foo
  o  [9:7affa1350ff0] E
  |    topic: foo
  | o  [8:a1bb64d88f0e] D
  | |    topic: bar
  | o  [7:71827f564e9e] C
  |/     topic: bar
  o  [2:10f317d09e78] B
  |
  o  [1:e34122c9a2bf] A
  |
  o  [0:249055fcca50] root
  

Two bookmarks on top of each other
----------------------------------

  $ cd ..
  $ rm -rf setup1
  $ hg init setup2
  $ cd setup2
  $ echo "Hello" > root
  $ hg commit -Aqm "root"
  $ hg phase --public .
  $ echo "Hello" > A
  $ hg commit -Aqm "A"
  $ hg phase --public .
  $ echo "Hello" > B
  $ hg commit -Aqm "B"
  $ echo "Hello" > C
  $ hg commit -Aqm "C"
  $ hg bookmark -r . bar
  $ echo "Hello" > D
  $ hg commit -Aqm "D"
  $ echo "Hello" > E
  $ hg commit -Aqm "E"
  $ hg bookmark -r . foo

  $ hg log -G
  @  [5:c633aa1ad270] E
  |    bookmark: foo
  o  [4:4963af405f62] D
  |
  o  [3:ac05e0d05d00] C
  |    bookmark: bar
  o  [2:10f317d09e78] B
  |
  o  [1:e34122c9a2bf] A
  |
  o  [0:249055fcca50] root
  

XXX: this should  avoid create orphan changesets.

  $ hg debugconvertbookmark --all
  changed topic to "bar" on 2 revisions
  switching to topic foo
  changed topic to "foo" on 2 revisions
  2 new orphan changesets

  $ hg log -G
  @  [9:b14d13efcfa7] E
  |    topic: foo
  *  [8:c89ca6e70978] D
  |    topic: foo
  | o  [7:a3ea0dfe6a10] C
  | |    topic: bar
  | o  [6:db1bc6aab480] B
  | |    topic: bar
  x |  [3:ac05e0d05d00] C
  | |
  x |  [2:10f317d09e78] B
  |/
  o  [1:e34122c9a2bf] A
  |
  o  [0:249055fcca50] root
  

Check that phase are properly take in account
---------------------------------------------

(we reuse above test, taking advantage of a small bug regarding stacked bookmarks. we can fuse the two tests once that bug is fixed)

  $ cd ..
  $ hg init setup-phases
  $ cd setup-phases
  $ echo "Hello" > root
  $ hg commit -Aqm "root"
  $ hg phase --public .
  $ echo "Hello" > A
  $ hg commit -Aqm "A"
  $ echo "Hello" > B
  $ hg commit -Aqm "B"
  $ echo "Hello" > C
  $ hg commit -Aqm "C"
  $ hg bookmark -r . bar
  $ hg log -G
  @  [3:ac05e0d05d00] C
  |    bookmark: bar
  o  [2:10f317d09e78] B
  |
  o  [1:e34122c9a2bf] A
  |
  o  [0:249055fcca50] root
  

  $ hg debugconvertbookmark --all
  switching to topic bar
  changed topic to "bar" on 3 revisions
  $ hg log -G
  @  [6:863c43a7951c] C
  |    topic: bar
  o  [5:ac7f12ac947f] B
  |    topic: bar
  o  [4:fc82c8c14b4c] A
  |    topic: bar
  o  [0:249055fcca50] root
  
