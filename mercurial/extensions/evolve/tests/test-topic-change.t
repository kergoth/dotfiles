Tests for changing and clearing topics
======================================

  $ . "$TESTDIR/testlib/topic_setup.sh"
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > # disable the new graph style until we drop 3.7 support
  > graphstyle.missing = |
  > evolution=createmarkers, allowunstable
  > [phases]
  > publish=false
  > [alias]
  > glog = log -G -T "{rev}:{node|short} \{{topic}}\n{desc}  ({bookmarks})\n\n"
  > EOF

About the glog output: {} contains the topic name and () will contain the bookmark

Setting up a repo
----------------

  $ hg init topics
  $ cd topics
  $ for ch in a b c d e f g h; do touch $ch; echo "foo" >> $ch; hg ci -Aqm "Added "$ch; done

  $ hg glog
  @  7:ec2426147f0e {}
  |  Added h  ()
  |
  o  6:87d6d6676308 {}
  |  Added g  ()
  |
  o  5:825660c69f0c {}
  |  Added f  ()
  |
  o  4:aa98ab95a928 {}
  |  Added e  ()
  |
  o  3:62615734edd5 {}
  |  Added d  ()
  |
  o  2:28ad74487de9 {}
  |  Added c  ()
  |
  o  1:29becc82797a {}
  |  Added b  ()
  |
  o  0:18d04c59bb5d {}
     Added a  ()
  

Clearing topic from revision without topic

  $ hg topic -r . --clear
  changed topic on 0 changes

Clearing current topic when no active topic is not error

  $ hg topic
  $ hg topic --clear

Setting topics to all the revisions

  $ hg topic -r 0:: foo
  switching to topic foo
  changed topic on 8 changes
  $ hg glog
  @  15:05095f607171 {foo}
  |  Added h  ()
  |
  o  14:97505b53ab0d {foo}
  |  Added g  ()
  |
  o  13:75a8360fe626 {foo}
  |  Added f  ()
  |
  o  12:abcedffeae90 {foo}
  |  Added e  ()
  |
  o  11:1315a3808ed0 {foo}
  |  Added d  ()
  |
  o  10:1fa891977a22 {foo}
  |  Added c  ()
  |
  o  9:a53ba98dd6b8 {foo}
  |  Added b  ()
  |
  o  8:86a186070af2 {foo}
     Added a  ()
  

Clearing the active topic using --clear

  $ hg topic
   * foo (8 changesets)
  $ hg topic --clear
  $ hg topic
     foo (8 changesets)
Changing topics on some revisions (also testing issue 5441)

  $ hg topic -r abcedffeae90:: bar
  switching to topic bar
  changed topic on 4 changes
  $ hg glog
  @  19:d7d36e193ea7 {bar}
  |  Added h  ()
  |
  o  18:e7b418d79a05 {bar}
  |  Added g  ()
  |
  o  17:82e0b14f4d9e {bar}
  |  Added f  ()
  |
  o  16:edc4a6b9ea60 {bar}
  |  Added e  ()
  |
  o  11:1315a3808ed0 {foo}
  |  Added d  ()
  |
  o  10:1fa891977a22 {foo}
  |  Added c  ()
  |
  o  9:a53ba98dd6b8 {foo}
  |  Added b  ()
  |
  o  8:86a186070af2 {foo}
     Added a  ()
  

Changing topics without passing topic name and clear

  $ hg topic -r .
  abort: changing topic requires a topic name or --clear
  [255]

Changing topic using --current flag

  $ hg topic foobar
  $ hg topic -r . --current
  active topic 'foobar' grew its first changeset
  changed topic on 1 changes
  $ hg glog -r .
  @  20:c2d6b7df5dcf {foobar}
  |  Added h  ()
  |

Changing topic in between the stack

  $ hg topic -r 9::10 --current
  5 new orphan changesets
  changed topic on 2 changes
  $ hg glog
  o  22:1b88140feefe {foobar}
  |  Added c  ()
  |
  o  21:c39cabfcbbf7 {foobar}
  |  Added b  ()
  |
  | @  20:c2d6b7df5dcf {foobar}
  | |  Added h  ()
  | |
  | *  18:e7b418d79a05 {bar}
  | |  Added g  ()
  | |
  | *  17:82e0b14f4d9e {bar}
  | |  Added f  ()
  | |
  | *  16:edc4a6b9ea60 {bar}
  | |  Added e  ()
  | |
  | *  11:1315a3808ed0 {foo}
  | |  Added d  ()
  | |
  | x  10:1fa891977a22 {foo}
  | |  Added c  ()
  | |
  | x  9:a53ba98dd6b8 {foo}
  |/   Added b  ()
  |
  o  8:86a186070af2 {foo}
     Added a  ()
  
  $ hg rebase -s 11 -d 22
  rebasing 11:1315a3808ed0 "Added d" (foo)
  switching to topic foo
  rebasing 16:edc4a6b9ea60 "Added e" (bar)
  switching to topic bar
  rebasing 17:82e0b14f4d9e "Added f" (bar)
  rebasing 18:e7b418d79a05 "Added g" (bar)
  rebasing 20:c2d6b7df5dcf "Added h" (foobar)
  switching to topic foobar

  $ hg glog
  @  27:a1a9465da59b {foobar}
  |  Added h  ()
  |
  o  26:7c76c271395f {bar}
  |  Added g  ()
  |
  o  25:7f26084dfaf1 {bar}
  |  Added f  ()
  |
  o  24:b1f05e9ba0b5 {bar}
  |  Added e  ()
  |
  o  23:f9869da2286e {foo}
  |  Added d  ()
  |
  o  22:1b88140feefe {foobar}
  |  Added c  ()
  |
  o  21:c39cabfcbbf7 {foobar}
  |  Added b  ()
  |
  o  8:86a186070af2 {foo}
     Added a  ()
  
Amending a topic
----------------

When the changeset has a topic and we have different active topic

  $ hg topic wat
  $ hg ci --amend
  active topic 'wat' grew its first changeset
  $ hg glog -r .
  @  28:61470c956807 {wat}
  |  Added h  ()
  |

Clear the current topic and amending

  $ hg topic --clear
  $ hg ci --amend
  $ hg glog -r .
  @  29:b584fa49f42e {}
  |  Added h  ()
  |

When the changeset does not has a topic but we have an active topic

  $ hg topic watwat
  marked working directory as topic: watwat
  $ hg ci --amend
  active topic 'watwat' grew its first changeset
  $ hg glog -r .
  @  30:a24c31c35013 {watwat}
  |  Added h  ()
  |

Testing changing topics on public changeset
-------------------------------------------

  $ hg phase -r 8 -p

Clearing the topic

  $ hg topic -r 8 --clear
  abort: can't change topic of a public change
  [255]

Changing the topic

  $ hg topic -r 8 foobarboo
  abort: can't change topic of a public change
  [255]

Testing the bookmark movement
-----------------------------

  $ hg bookmark book
  $ hg glog
  @  30:a24c31c35013 {watwat}
  |  Added h  (book)
  |
  o  26:7c76c271395f {bar}
  |  Added g  ()
  |
  o  25:7f26084dfaf1 {bar}
  |  Added f  ()
  |
  o  24:b1f05e9ba0b5 {bar}
  |  Added e  ()
  |
  o  23:f9869da2286e {foo}
  |  Added d  ()
  |
  o  22:1b88140feefe {foobar}
  |  Added c  ()
  |
  o  21:c39cabfcbbf7 {foobar}
  |  Added b  ()
  |
  o  8:86a186070af2 {}
     Added a  ()
  
On clearing the topic

  $ hg topic -r . --clear
  clearing empty topic "watwat"
  active topic 'watwat' is now empty
  changed topic on 1 changes

  $ hg glog
  @  31:c48d6d71b2d9 {}
  |  Added h  (book)
  |
  o  26:7c76c271395f {bar}
  |  Added g  ()
  |
  o  25:7f26084dfaf1 {bar}
  |  Added f  ()
  |
  o  24:b1f05e9ba0b5 {bar}
  |  Added e  ()
  |
  o  23:f9869da2286e {foo}
  |  Added d  ()
  |
  o  22:1b88140feefe {foobar}
  |  Added c  ()
  |
  o  21:c39cabfcbbf7 {foobar}
  |  Added b  ()
  |
  o  8:86a186070af2 {}
     Added a  ()
  

On changing the topic

  $ hg bookmark bookboo
  $ hg topic -r . movebook
  switching to topic movebook
  changed topic on 1 changes
  $ hg glog
  @  32:1b83d11095b9 {movebook}
  |  Added h  (book bookboo)
  |
  o  26:7c76c271395f {bar}
  |  Added g  ()
  |
  o  25:7f26084dfaf1 {bar}
  |  Added f  ()
  |
  o  24:b1f05e9ba0b5 {bar}
  |  Added e  ()
  |
  o  23:f9869da2286e {foo}
  |  Added d  ()
  |
  o  22:1b88140feefe {foobar}
  |  Added c  ()
  |
  o  21:c39cabfcbbf7 {foobar}
  |  Added b  ()
  |
  o  8:86a186070af2 {}
     Added a  ()
  
Changing topic on secret changesets
-----------------------------------

  $ hg up 26
  switching to topic bar
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  (leaving bookmark bookboo)

  $ hg phase -r . -s -f
  $ hg phase -r .
  26: secret

  $ hg topic -r . watwat
  switching to topic watwat
  1 new orphan changesets
  changed topic on 1 changes

  $ hg glog
  @  33:894983f69e69 {watwat}
  |  Added g  ()
  |
  | *  32:1b83d11095b9 {movebook}
  | |  Added h  (book bookboo)
  | |
  | x  26:7c76c271395f {bar}
  |/   Added g  ()
  |
  o  25:7f26084dfaf1 {bar}
  |  Added f  ()
  |
  o  24:b1f05e9ba0b5 {bar}
  |  Added e  ()
  |
  o  23:f9869da2286e {foo}
  |  Added d  ()
  |
  o  22:1b88140feefe {foobar}
  |  Added c  ()
  |
  o  21:c39cabfcbbf7 {foobar}
  |  Added b  ()
  |
  o  8:86a186070af2 {}
     Added a  ()
  
  $ hg phase -r .
  33: secret
