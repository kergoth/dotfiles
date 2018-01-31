==============
Topic Tutorial
==============

This Mercurial configuration example is used for testing.

.. Various setup

  $ . "$TESTDIR/testlib/topic_setup.sh"
  $ cat >> $HGRCPATH << EOF
  > [experimental]
  > evolution=all
  > [extensions]
  > evolve=
  > EOF

  $ hg init server

  $ cd server

  $ cat >> .hg/hgrc << EOF
  > [ui]
  > user= Shopping Master
  > EOF

  $ cat >> shopping << EOF
  > Spam
  > Whizzo butter
  > Albatross
  > Rat (rather a lot)
  > Jugged fish
  > Blancmange
  > Salmon mousse
  > EOF

  $ hg commit -A -m "Shopping list"
  adding shopping

  $ cd ..
  $ hg clone server client
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd client
  $ cat >> .hg/hgrc << EOF
  > [ui]
  > user= Tutorial User
  > EOF
#if docgraph-ext
  $ . "$TESTDIR/testlib/docgraph_setup.sh" #rest-ignore
#endif

Topic branches are lightweight branches which disappear when changes are
finalized (moved to the public phase). They can help users to organize and share
their unfinished work.

In this tutorial, we explain how to use topics for local development. In the
first part, there is a central *publishing* server. Anything pushed to the
central server will become public and immutable. This means no unfinished work
should escape the local repository.


Topic Basics
============

Let's say we use Mercurial to manage our shopping list:

  $ hg log --graph
  @  changeset:   0:38da43f0a2ea
     tag:         tip
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  
#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      }
#endif

We are about to make some additions to this list and would like to do them
within a topic. Creating a new topic is done using the ``topic`` command:

  $ hg topics food
  marked working directory as topic: food

Much like a named branch, our topic is active but it does not contain any
changeset yet:

  $ hg topics
   * food (0 changesets)

  $ hg summary
  parent: 0:38da43f0a2ea tip
   Shopping list
  branch: default
  commit: (clean)
  update: (current)
  topic:  food

  $ hg log --graph
  @  changeset:   0:38da43f0a2ea
     tag:         tip
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  

#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      }
#endif

Our next commit will be part of the active topic:

  $ cat >> shopping << EOF
  > Egg
  > Suggar
  > Vinegar
  > Oil
  > EOF

  $ hg commit -m "adding condiments"
  active topic 'food' grew its first changeset

  $ hg log --graph --rev 'topic("food")'
  @  changeset:   1:13900241408b
  |  tag:         tip
  ~  topic:       food
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     adding condiments
  

#if docgraph-ext
  $ hg docgraph -r "topic("food")" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	1	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=1,
      		pin=true,
      		pos="1,1!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      }
#endif

And future commits will be part of that topic too:

  $ cat >> shopping << EOF
  > Bananas
  > Pear
  > Apple
  > EOF

  $ hg commit -m "adding fruits"

  $ hg log --graph --rev 'topic("food")'
  @  changeset:   2:287de11b401f
  |  tag:         tip
  |  topic:       food
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding fruits
  |
  o  changeset:   1:13900241408b
  |  topic:       food
  ~  user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     adding condiments
  

#if docgraph-ext
  $ hg docgraph -r "topic("food")" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	1	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=1,
      		pin=true,
      		pos="1,1!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=2,
      		pin=true,
      		pos="1,2!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	1 -> 2	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

We can get a compact view of the content of our topic using the ``stack``
command:

  $ hg stack
  ### topic: food
  ### target: default (branch)
  t2@ adding fruits (current)
  t1: adding condiments
  t0^ Shopping list (base)

The topic deactivates when we update away from it:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topics
     food (2 changesets)

Note that ``default`` (name of the branch) now refers to the tipmost
changeset of default without a topic:

  $ hg log --graph
  o  changeset:   2:287de11b401f
  |  tag:         tip
  |  topic:       food
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding fruits
  |
  o  changeset:   1:13900241408b
  |  topic:       food
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding condiments
  |
  @  changeset:   0:38da43f0a2ea
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  

#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	1	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=1,
      		pin=true,
      		pos="1,1!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	0 -> 1	 [arrowhead=none,
      		penwidth=2.0];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=2,
      		pin=true,
      		pos="1,2!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	1 -> 2	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif
And updating back to the topic reactivates it:

  $ hg update food
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topics
   * food (2 changesets)

Updating to any changeset that is part of a topic activates the topic
regardless of how the revision was specified:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg update --rev 'desc("condiments")'
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topics
   * food (2 changesets)

.. Server side activity:

  $ cd ../server/
  $ cat > shopping << EOF
  > T-Shirt
  > Trousers
  > Spam
  > Whizzo butter
  > Albatross
  > Rat (rather a lot)
  > Jugged fish
  > Blancmange
  > Salmon mousse
  > EOF

  $ hg commit -A -m "Adding clothes"

  $ cd ../client

The topic will also affect the rebase and the merge destinations. Let's pull
the latest update from the main server:

  $ hg pull
  pulling from $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  new changesets 6104862e8b84
  (run 'hg heads' to see heads)

  $ hg log -G
  o  changeset:   3:6104862e8b84
  |  tag:         tip
  |  parent:      0:38da43f0a2ea
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding clothes
  |
  | o  changeset:   2:287de11b401f
  | |  topic:       food
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     adding fruits
  | |
  | @  changeset:   1:13900241408b
  |/   topic:       food
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     adding condiments
  |
  o  changeset:   0:38da43f0a2ea
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  
#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	1	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=1,
      		pin=true,
      		pos="1,1!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	0 -> 1	 [arrowhead=none,
      		penwidth=2.0];
      	3	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=3,
      		pin=true,
      		pos="1,3!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 3	 [arrowhead=none,
      		penwidth=2.0];
      	2	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=2,
      		pin=true,
      		pos="1,2!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	1 -> 2	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

The topic head will not be considered when merging from the new head of the
branch:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg merge
  abort: branch 'default' has one head - please merge with an explicit rev
  (run 'hg heads' to see all heads)
  [255]

But the topic will see that branch head as a valid destination:

  $ hg update food
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg rebase
  rebasing 1:13900241408b "adding condiments" (food)
  merging shopping
  switching to topic food
  rebasing 2:287de11b401f "adding fruits" (food)
  merging shopping

  $ hg log --graph
  @  changeset:   5:2d50db8b5b4c
  |  tag:         tip
  |  topic:       food
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding fruits
  |
  o  changeset:   4:4011b46eeb33
  |  topic:       food
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding condiments
  |
  o  changeset:   3:6104862e8b84
  |  parent:      0:38da43f0a2ea
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding clothes
  |
  o  changeset:   0:38da43f0a2ea
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  
#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=3,
      		pin=true,
      		pos="1,3!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 3	 [arrowhead=none,
      		penwidth=2.0];
      	4	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=4,
      		pin=true,
      		pos="1,4!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	3 -> 4	 [arrowhead=none,
      		penwidth=2.0];
      	5	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=5,
      		pin=true,
      		pos="1,5!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	4 -> 5	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

There exists a template keyword named "topic" which can be used

  $ hg log -GT "{rev}:{node|short} {topic}\n {desc}"
  @  5:2d50db8b5b4c food
  |   adding fruits
  o  4:4011b46eeb33 food
  |   adding condiments
  o  3:6104862e8b84
  |   Adding clothes
  o  0:38da43f0a2ea
      Shopping list

The topic information will disappear when we publish the changesets:

  $ hg topics
   * food (2 changesets)

  $ hg push
  pushing to $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files
  2 new obsolescence markers
  active topic 'food' is now empty

  $ hg topics
   * food (0 changesets)

The topic still exists, and any new commit will be in the topic. But
note that it is now devoid of any commit.

  $ hg topics --list
  ### topic: food
  ### target: default (branch)
  (stack is empty)
  t0^ adding fruits (base current)

  $ hg log --graph
  @  changeset:   5:2d50db8b5b4c
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding fruits
  |
  o  changeset:   4:4011b46eeb33
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding condiments
  |
  o  changeset:   3:6104862e8b84
  |  parent:      0:38da43f0a2ea
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding clothes
  |
  o  changeset:   0:38da43f0a2ea
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  
#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=3,
      		pin=true,
      		pos="1,3!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 3	 [arrowhead=none,
      		penwidth=2.0];
      	4	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=4,
      		pin=true,
      		pos="1,4!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3 -> 4	 [arrowhead=none,
      		penwidth=2.0];
      	5	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=5,
      		pin=true,
      		pos="1,5!",
      		shape=circle,
      		style=filled,
      		width=1];
      	4 -> 5	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

If we update to the *default* head, we will leave the topic behind,
and since it is commit-less, it will vanish.

  $ hg update default
  clearing empty topic "food"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

From there, the topic has been completely forgotten.

  $ hg topics


Keep working within topics
==========================

Making sure all your new local commit are made within a topic will help you
organize your work. It is possible to ensure this through the Mercurial
configuration.

For this tutorial, we'll add the config at the repository level:

  $ cat << EOF >> .hg/hgrc
  > [experimental]
  > topic-mode = enforce
  > EOF

You can also use `hg config --edit` to update your mercurial configuration.


Once enforcement is turned on. New local commit will be denied if no topic is active.

  $ echo sickle >> shopping
  $ hg commit -m 'Adding sickle'
  abort: no active topic
  (see 'hg help -e topic.topic-mode' for details)
  [255]

Ok, let's clean this up and delve into multiple topics.

  $ hg revert .
  reverting shopping


Working with Multiple Topics
============================

In the above example, topics do not bring many benefits since you only have one
line of development. Topics start to be more useful when you have to work on
multiple features at the same time.

We might go shopping in a hardware store in the same go, so let's add some
tools to the shopping list within a new topic:

  $ hg topics tools
  marked working directory as topic: tools
  $ echo hammer >> shopping
  $ hg commit -m 'Adding hammer'
  active topic 'tools' grew its first changeset

  $ echo saw >> shopping
  $ hg commit -m 'Adding saw'

  $ echo drill >> shopping
  $ hg commit -m 'Adding drill'

But we are not sure we will actually go to the hardware store, so in the
meantime, we want to extend the list with drinks. We go back to the official
default branch and start a new topic:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topics drinks
  marked working directory as topic: drinks
  $ echo 'apple juice' >> shopping
  $ hg commit -m 'Adding apple juice'
  active topic 'drinks' grew its first changeset

  $ echo 'orange juice' >> shopping
  $ hg commit -m 'Adding orange juice'

We now have two topics:

  $ hg topics
   * drinks (2 changesets)
     tools  (3 changesets)

The information displayed by ``hg stack`` adapts to the active topic:

  $ hg stack
  ### topic: drinks
  ### target: default (branch)
  t2@ Adding orange juice (current)
  t1: Adding apple juice
  t0^ adding fruits (base)

  $ hg update tools
  switching to topic tools
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### target: default (branch)
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ adding fruits (base)

They are seen as independent branches by Mercurial. No rebase or merge
between them will be attempted by default:

  $ hg rebase
  nothing to rebase
  [1]

We simulate independant contributions to the repo with this
activity:

  $ cd ../server
  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ mv shopping foo
  $ echo 'Coat' > shopping
  $ cat foo >> shopping
  $ hg commit -m 'add a coat'
  $ echo 'Coat' > shopping
  $ echo 'Shoes' >> shopping
  $ cat foo >> shopping
  $ rm foo
  $ hg commit -m 'add a pair of shoes'
  $ cd ../client

Let's discover what other people did contribute:

  $ hg pull
  pulling from $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files (+1 heads)
  new changesets f2d6cacc6115:fbff9bc37a43
  (run 'hg heads' to see heads)

There are new changes! We can simply use ``hg rebase`` to update our
changeset on top of the latest:

  $ hg log -G
  o  changeset:   12:fbff9bc37a43
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add a pair of shoes
  |
  o  changeset:   11:f2d6cacc6115
  |  parent:      5:2d50db8b5b4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add a coat
  |
  | o  changeset:   10:70dfa201ed73
  | |  topic:       drinks
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding orange juice
  | |
  | o  changeset:   9:8dfa45bd5e0c
  |/   topic:       drinks
  |    parent:      5:2d50db8b5b4c
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Adding apple juice
  |
  | @  changeset:   8:34255b455dac
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding drill
  | |
  | o  changeset:   7:cffff85af537
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding saw
  | |
  | o  changeset:   6:183984ef46d1
  |/   topic:       tools
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Adding hammer
  |
  o  changeset:   5:2d50db8b5b4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding fruits
  |
  o  changeset:   4:4011b46eeb33
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding condiments
  |
  o  changeset:   3:6104862e8b84
  |  parent:      0:38da43f0a2ea
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding clothes
  |
  o  changeset:   0:38da43f0a2ea
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  
#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=3,
      		pin=true,
      		pos="1,3!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 3	 [arrowhead=none,
      		penwidth=2.0];
      	4	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=4,
      		pin=true,
      		pos="1,4!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3 -> 4	 [arrowhead=none,
      		penwidth=2.0];
      	5	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=5,
      		pin=true,
      		pos="1,5!",
      		shape=circle,
      		style=filled,
      		width=1];
      	4 -> 5	 [arrowhead=none,
      		penwidth=2.0];
      	6	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=6,
      		pin=true,
      		pos="1,6!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	5 -> 6	 [arrowhead=none,
      		penwidth=2.0];
      	9	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=9,
      		pin=true,
      		pos="1,9!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	5 -> 9	 [arrowhead=none,
      		penwidth=2.0];
      	11	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=11,
      		pin=true,
      		pos="1,11!",
      		shape=circle,
      		style=filled,
      		width=1];
      	5 -> 11	 [arrowhead=none,
      		penwidth=2.0];
      	7	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=7,
      		pin=true,
      		pos="1,7!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	6 -> 7	 [arrowhead=none,
      		penwidth=2.0];
      	8	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=8,
      		pin=true,
      		pos="1,8!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	7 -> 8	 [arrowhead=none,
      		penwidth=2.0];
      	10	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=10,
      		pin=true,
      		pos="1,10!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	9 -> 10	 [arrowhead=none,
      		penwidth=2.0];
      	12	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=12,
      		pin=true,
      		pos="1,12!",
      		shape=circle,
      		style=filled,
      		width=1];
      	11 -> 12	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

  $ hg rebase
  rebasing 6:183984ef46d1 "Adding hammer" (tools)
  merging shopping
  switching to topic tools
  rebasing 7:cffff85af537 "Adding saw" (tools)
  merging shopping
  rebasing 8:34255b455dac "Adding drill" (tools)
  merging shopping

But what about the other topic? You can use 'hg topics --verbose' to see
information about all the topics:

  $ hg topics --verbose
     drinks (on branch: default, 2 changesets, 2 behind)
   * tools  (on branch: default, 3 changesets)

The "2 behind" is telling you that there are 2 new changesets over the base of the topic.

Pushing that topic would create a new head, and therefore will be prevented:

  $ hg push --rev drinks
  pushing to $TESTTMP/server (glob)
  searching for changes
  abort: push creates new remote head 70dfa201ed73!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]


Even after a rebase, pushing all active topics at the same time would publish
them to the default branch, and then mercurial would complain about the
multiple *public* heads it would create on that branch:

  $ hg rebase -b drinks
  rebasing 9:8dfa45bd5e0c "Adding apple juice" (drinks)
  merging shopping
  switching to topic drinks
  rebasing 10:70dfa201ed73 "Adding orange juice" (drinks)
  merging shopping
  switching to topic tools

  $ hg push
  pushing to $TESTTMP/server (glob)
  searching for changes
  abort: push creates new remote head 4cd7c1591a67!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]

Publishing only one of them is allowed (as long as it does not create a new
branch head as we just saw in the previous case):

  $ hg push -r drinks
  pushing to $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files
  2 new obsolescence markers

The published topic has now disappeared, and the other is now marked as
"behind":

  $ hg topics --verbose
   * tools (on branch: default, 3 changesets, 2 behind)

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ add a pair of shoes (base)

Working Within Your Stack
===========================

Navigating within your stack
----------------------------

As we saw before `stack` displays changesets on your current topic in a clean way:

  $ hg topics --verbose
   * tools (on branch: default, 3 changesets, 2 behind)

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ add a pair of shoes (base)

You can navigate in your current stack with `previous` and `next`.

`previous` will bring you back to the parent of the topic head.

  $ hg previous
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [14] Adding saw

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3: Adding drill
  t2@ Adding saw (current)
  t1: Adding hammer
  t0^ add a pair of shoes (base)

`next` will move you forward to the topic head.

  $ hg next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [15] Adding drill

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ add a pair of shoes (base)

You can also directly jump to a changeset within your stack with the revset `t#`.

  $ hg update t1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3: Adding drill
  t2: Adding saw
  t1@ Adding hammer (current)
  t0^ add a pair of shoes (base)

Editing your work mid-stack
---------------------------

It's easy to edit your work inside your stack:

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3: Adding drill
  t2: Adding saw
  t1@ Adding hammer (current)
  t0^ add a pair of shoes (base)

  $ hg amend -m "Adding hammer to the shopping list"
  2 new orphan changesets

Understanding the current situation with hg log is not so easy, because
it shows too many things:

  $ hg log -G -r "t0::"
  @  changeset:   18:b7509bd417f8
  |  tag:         tip
  |  topic:       tools
  |  parent:      12:fbff9bc37a43
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding hammer to the shopping list
  |
  | o  changeset:   17:4cd7c1591a67
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding orange juice
  | |
  | o  changeset:   16:20759cb47ff8
  |/   parent:      12:fbff9bc37a43
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Adding apple juice
  |
  | *  changeset:   15:bb1e6254f532
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     Adding drill
  | |
  | *  changeset:   14:d4f97f32f8a1
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  instability: orphan
  | |  summary:     Adding saw
  | |
  | x  changeset:   13:a8ab3599d53d
  |/   topic:       tools
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    reworded using amend as 18:b7509bd417f8
  |    summary:     Adding hammer
  |
  o  changeset:   12:fbff9bc37a43
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add a pair of shoes
  

#if docgraph-ext
  $ hg docgraph -r "t0::" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	12	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=12,
      		pin=true,
      		pos="1,12!",
      		shape=circle,
      		style=filled,
      		width=1];
      	13	 [fillcolor="#DFDFFF",
      		fixedsize=true,
      		group=default_alt,
      		height=1,
      		label=13,
      		pin=true,
      		pos="2,13!",
      		shape=pentagon,
      		style="dotted, filled",
      		width=1];
      	12 -> 13	 [arrowhead=none,
      		penwidth=2.0];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=18,
      		pin=true,
      		pos="1,18!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	12 -> 18	 [arrowhead=none,
      		penwidth=2.0];
      	16	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=16,
      		pin=true,
      		pos="1,16!",
      		shape=circle,
      		style=filled,
      		width=1];
      	12 -> 16	 [arrowhead=none,
      		penwidth=2.0];
      	13 -> 18	 [arrowtail=none,
      		dir=back,
      		minlen=0,
      		penwidth=2.0,
      		style=dashed];
      	14	 [fillcolor="#FF4F4F",
      		fixedsize=true,
      		group=default_alt,
      		height=1,
      		label=14,
      		pin=true,
      		pos="2,14!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	13 -> 14	 [arrowhead=none,
      		penwidth=2.0];
      	15	 [fillcolor="#FF4F4F",
      		fixedsize=true,
      		group=default_alt,
      		height=1,
      		label=15,
      		pin=true,
      		pos="2,15!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	14 -> 15	 [arrowhead=none,
      		penwidth=2.0];
      	17	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=17,
      		pin=true,
      		pos="1,17!",
      		shape=circle,
      		style=filled,
      		width=1];
      	16 -> 17	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

Fortunately stack shows you a better visualization:

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3$ Adding drill (unstable)
  t2$ Adding saw (unstable)
  t1@ Adding hammer to the shopping list (current)
  t0^ add a pair of shoes (base)

It's easy to stabilize the situation, `next` has an `--evolve` option.  It will
do the necessary relocation of `t2` and `t3` over the new `t1` without having
to do that rebase by hand.:

  $ hg next --evolve
  move:[14] Adding saw
  atop:[18] Adding hammer to the shopping list
  working directory now at d5c51ee5762a

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3$ Adding drill (unstable)
  t2@ Adding saw (current)
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

One more to go:

  $ hg next --evolve
  move:[15] Adding drill
  atop:[19] Adding saw
  working directory now at bae3758e46bf

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

Let's take a look at `hg log` once again:

  $ hg log -G -r "t0::"
  @  changeset:   20:bae3758e46bf
  |  tag:         tip
  |  topic:       tools
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding drill
  |
  o  changeset:   19:d5c51ee5762a
  |  topic:       tools
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding saw
  |
  o  changeset:   18:b7509bd417f8
  |  topic:       tools
  |  parent:      12:fbff9bc37a43
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding hammer to the shopping list
  |
  | o  changeset:   17:4cd7c1591a67
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding orange juice
  | |
  | o  changeset:   16:20759cb47ff8
  |/   parent:      12:fbff9bc37a43
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Adding apple juice
  |
  o  changeset:   12:fbff9bc37a43
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add a pair of shoes
  

#if docgraph-ext
  $ hg docgraph -r "t0::" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	12	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=12,
      		pin=true,
      		pos="1,12!",
      		shape=circle,
      		style=filled,
      		width=1];
      	16	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=16,
      		pin=true,
      		pos="1,16!",
      		shape=circle,
      		style=filled,
      		width=1];
      	12 -> 16	 [arrowhead=none,
      		penwidth=2.0];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=18,
      		pin=true,
      		pos="1,18!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	12 -> 18	 [arrowhead=none,
      		penwidth=2.0];
      	17	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=17,
      		pin=true,
      		pos="1,17!",
      		shape=circle,
      		style=filled,
      		width=1];
      	16 -> 17	 [arrowhead=none,
      		penwidth=2.0];
      	19	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=19,
      		pin=true,
      		pos="1,19!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	18 -> 19	 [arrowhead=none,
      		penwidth=2.0];
      	20	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=20,
      		pin=true,
      		pos="1,20!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	19 -> 20	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif
Multi-headed stack
------------------

Stack is also very helpful when you have a multi-headed stack:

  $ hg up t1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ echo "nails" > new_shopping
  $ cat shopping >> new_shopping
  $ mv new_shopping shopping

  $ hg commit -m 'Adding nails'

  $ hg stack
  ### topic: tools (2 heads)
  ### target: default (branch), 2 behind
  t4: Adding drill
  t3: Adding saw
  t1^ Adding hammer to the shopping list (base)
  t2@ Adding nails (current)
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

Solving this situation is easy with a topic: use merge or rebase.
Merge within a multi-headed stack will use the other topic head as
destination if the topic has two heads. But rebasing will yield a
completely linear history so it's what we will do.

  $ hg log -G
  @  changeset:   21:f936c6da9d61
  |  tag:         tip
  |  topic:       tools
  |  parent:      18:b7509bd417f8
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding nails
  |
  | o  changeset:   20:bae3758e46bf
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding drill
  | |
  | o  changeset:   19:d5c51ee5762a
  |/   topic:       tools
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Adding saw
  |
  o  changeset:   18:b7509bd417f8
  |  topic:       tools
  |  parent:      12:fbff9bc37a43
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding hammer to the shopping list
  |
  | o  changeset:   17:4cd7c1591a67
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Adding orange juice
  | |
  | o  changeset:   16:20759cb47ff8
  |/   parent:      12:fbff9bc37a43
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Adding apple juice
  |
  o  changeset:   12:fbff9bc37a43
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add a pair of shoes
  |
  o  changeset:   11:f2d6cacc6115
  |  parent:      5:2d50db8b5b4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add a coat
  |
  o  changeset:   5:2d50db8b5b4c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding fruits
  |
  o  changeset:   4:4011b46eeb33
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     adding condiments
  |
  o  changeset:   3:6104862e8b84
  |  parent:      0:38da43f0a2ea
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Adding clothes
  |
  o  changeset:   0:38da43f0a2ea
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  

#if docgraph-ext
  $ hg docgraph -r "all()" --sphinx-directive --rankdir LR #rest-ignore
  .. graphviz::
  
      strict digraph "Mercurial graph" {
      	graph [rankdir=LR,
      		splines=polyline
      	];
      	node [label="\N"];
      	0	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=0,
      		pin=true,
      		pos="1,0!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=3,
      		pin=true,
      		pos="1,3!",
      		shape=circle,
      		style=filled,
      		width=1];
      	0 -> 3	 [arrowhead=none,
      		penwidth=2.0];
      	4	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=4,
      		pin=true,
      		pos="1,4!",
      		shape=circle,
      		style=filled,
      		width=1];
      	3 -> 4	 [arrowhead=none,
      		penwidth=2.0];
      	5	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=5,
      		pin=true,
      		pos="1,5!",
      		shape=circle,
      		style=filled,
      		width=1];
      	4 -> 5	 [arrowhead=none,
      		penwidth=2.0];
      	11	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=11,
      		pin=true,
      		pos="1,11!",
      		shape=circle,
      		style=filled,
      		width=1];
      	5 -> 11	 [arrowhead=none,
      		penwidth=2.0];
      	12	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=12,
      		pin=true,
      		pos="1,12!",
      		shape=circle,
      		style=filled,
      		width=1];
      	11 -> 12	 [arrowhead=none,
      		penwidth=2.0];
      	16	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=16,
      		pin=true,
      		pos="1,16!",
      		shape=circle,
      		style=filled,
      		width=1];
      	12 -> 16	 [arrowhead=none,
      		penwidth=2.0];
      	18	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=18,
      		pin=true,
      		pos="1,18!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	12 -> 18	 [arrowhead=none,
      		penwidth=2.0];
      	17	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=17,
      		pin=true,
      		pos="1,17!",
      		shape=circle,
      		style=filled,
      		width=1];
      	16 -> 17	 [arrowhead=none,
      		penwidth=2.0];
      	19	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=19,
      		pin=true,
      		pos="1,19!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	18 -> 19	 [arrowhead=none,
      		penwidth=2.0];
      	21	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=21,
      		pin=true,
      		pos="1,21!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	18 -> 21	 [arrowhead=none,
      		penwidth=2.0];
      	20	 [fillcolor="#7F7FFF",
      		fixedsize=true,
      		group=default,
      		height=1,
      		label=20,
      		pin=true,
      		pos="1,20!",
      		shape=pentagon,
      		style=filled,
      		width=1];
      	19 -> 20	 [arrowhead=none,
      		penwidth=2.0];
      }
#endif

  $ hg up t4
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg rebase
  rebasing 19:d5c51ee5762a "Adding saw" (tools)
  merging shopping
  rebasing 20:bae3758e46bf "Adding drill" (tools)
  merging shopping

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t4@ Adding drill (current)
  t3: Adding saw
  t2: Adding nails
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

Collaborating through a non-publishing server
=============================================

.. setup:

.. Let's create a non-publishing server:

  $ cd ..

  $ hg clone server non-publishing-server
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ cd non-publishing-server
  $ cat >> .hg/hgrc << EOF
  > [phases]
  > publish = false
  > EOF

.. And another client:

  $ cd ..

  $ hg clone server other-client
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ cd client

We can now share these draft changesets:

  $ hg push ../non-publishing-server -r tools
  pushing to ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 1 files (+1 heads)
  8 new obsolescence markers

Pushing the new topic branch to a non-publishing server did not require
--force. As long as new heads are on their own topic, Mercurial will not
complain about them.

From another client, we will get them with their topic:

  $ cd ../other-client

  $ hg pull ../non-publishing-server
  pulling from ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 1 files (+1 heads)
  8 new obsolescence markers
  new changesets b7509bd417f8:2d084ac00115
  (run 'hg heads' to see heads)

  $ hg topics --verbose
     tools (on branch: default, 4 changesets, 2 behind)

  $ hg up tools
  switching to topic tools
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t4@ Adding drill (current)
  t3: Adding saw
  t2: Adding nails
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

We can also add new changesets and share them:

  $ echo screws >> shopping

  $ hg commit -A -m "Adding screws"

  $ hg push ../non-publishing-server
  pushing to ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

And retrieve them from the first client:

  $ cd ../client

  $ hg pull ../non-publishing-server
  pulling from ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  new changesets 0d409663a1fd
  (run 'hg update' to get a working copy)

  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### target: default (branch), 2 behind
  t5@ Adding screws (current)
  t4: Adding drill
  t3: Adding saw
  t2: Adding nails
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)
