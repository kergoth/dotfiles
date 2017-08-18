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

Topic branches are lightweight branches which disappear when changes are
finalized (move to the public phase). They can help users to organize and share
their unfinished work.

Topic Basics
============

Let's say we use Mercurial to manage our shopping list:

  $ hg log --graph
  @  changeset:   0:38da43f0a2ea
     tag:         tip
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  

We are about to make some additions to this list and would like to do them 
within a topic. Creating a new topic is done using the ``topic`` command:

  $ hg topic food

Much like a named branch, our topic is active but it does not contain any
changesets yet:

  $ hg topic
   * food

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
  

Our next commit will be part of the active topic:

  $ cat >> shopping << EOF
  > Egg
  > Suggar
  > Vinegar
  > Oil
  > EOF

  $ hg commit -m "adding condiments"

  $ hg log --graph --rev 'topic("food")'
  @  changeset:   1:13900241408b
  |  tag:         tip
  ~  topic:       food
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     adding condiments
  

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
  

We can get a compact view of the content of our topic using the ``stack``
command:

  $ hg stack
  ### topic: food
  ### branch: default
  t2@ adding fruits (current)
  t1: adding condiments
  t0^ Shopping list (base)

The topic deactivates when we update away from it:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topic
     food

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
  
And updating back to the topic reactivates it:

  $ hg update food
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topic
   * food

Updating to any changeset that is part of a topic activates the topic
regardless of how the revision was specified:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg update --rev 'desc("condiments")'
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topic
   * food

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
  rebasing 1:13900241408b "adding condiments"
  merging shopping
  switching to topic food
  rebasing 2:287de11b401f "adding fruits"
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
  

The topic information will disappear when we publish the changesets:

  $ hg topic
   * food

  $ hg push
  pushing to $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files
  2 new obsolescence markers

  $ hg topic
   * food

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
  
  $ hg update default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

Working with Multiple Topics
============================

In the above example, topics do not bring much benefit since you only have one
line of development. Topics start to be more useful when you have to work on
multiple features at the same time.

We might go shopping in a hardware store in the same go, so let's add some
tools to the shopping list within a new topic:

  $ hg topic tools
  $ echo hammer >> shopping
  $ hg commit -m 'Adding hammer'

  $ echo saw >> shopping
  $ hg commit -m 'Adding saw'

  $ echo drill >> shopping
  $ hg commit -m 'Adding drill'

But we are not sure we will actually go to the hardware store, so in the
meantime, we want to extend the list with drinks. We go back to the official
default branch and start a new topic:

  $ hg update default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topic drinks
  $ echo 'apple juice' >> shopping
  $ hg commit -m 'Adding apple juice'

  $ echo 'orange juice' >> shopping
  $ hg commit -m 'Adding orange juice'

We now have two topics:

  $ hg topic
   * drinks
     tools

The information displayed by ``hg stack`` adapts to the active topic:

  $ hg stack
  ### topic: drinks
  ### branch: default
  t2@ Adding orange juice (current)
  t1: Adding apple juice
  t0^ adding fruits (base)

  $ hg update tools
  switching to topic tools
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### branch: default
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ adding fruits (base)

They are seen as independent branches by Mercurial. No rebase or merge
between them will be attempted by default:

  $ hg rebase
  nothing to rebase
  [1]

Server activity:

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

Let's see what other people did in the meantime:

  $ hg pull
  pulling from $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files (+1 heads)
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
  
  $ hg rebase
  rebasing 6:183984ef46d1 "Adding hammer"
  merging shopping
  switching to topic tools
  rebasing 7:cffff85af537 "Adding saw"
  merging shopping
  rebasing 8:34255b455dac "Adding drill"
  merging shopping

But what about the other topic? You can use 'hg topic --verbose' to see
information about all the topics:

  $ hg topic --verbose
     drinks (on branch: default, 2 changesets, 2 behind)
   * tools  (on branch: default, 3 changesets)

The "2 behind" is telling you that there are 2 new changesets on the named
branch of the topic. You need to merge or rebase to incorporate them.

Pushing that topic would create a new head, and therefore will be prevented:

  $ hg push --rev drinks
  pushing to $TESTTMP/server (glob)
  searching for changes
  abort: push creates new remote head 70dfa201ed73!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]


Even after a rebase, pushing all active topics at the same time will complain
about the multiple heads it would create on that branch:

  $ hg rebase -b drinks
  rebasing 9:8dfa45bd5e0c "Adding apple juice"
  merging shopping
  switching to topic drinks
  rebasing 10:70dfa201ed73 "Adding orange juice"
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

  $ hg topic --verbose
   * tools (on branch: default, 3 changesets, 2 behind)

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ add a pair of shoes (base)

Working Within Your Stack
===========================

Navigating within your stack
----------------------------

As we saw before `stack` display changesets on your current topic in a clean way:

  $ hg topics --verbose
   * tools (on branch: default, 3 changesets, 2 behind)

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ add a pair of shoes (base)

You can navigate in your current stack with `previous` and `next`.

`previous` will takes you to the parent of your working directory parent on the same topic.

  $ hg previous
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [14] Adding saw

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3: Adding drill
  t2@ Adding saw (current)
  t1: Adding hammer
  t0^ add a pair of shoes (base)

`next` will moves take you to the children of your working directory parent on the same topic.

  $ hg next
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  [15] Adding drill

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
  t0^ add a pair of shoes (base)

You can also directly access changesets within your stack with the revset `t#`.

  $ hg update t1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3: Adding drill
  t2: Adding saw
  t1@ Adding hammer (current)
  t0^ add a pair of shoes (base)

Editing your work mid-stack
---------------------------

It's easy to edit your work inside your stack:

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3: Adding drill
  t2: Adding saw
  t1@ Adding hammer (current)
  t0^ add a pair of shoes (base)

  $ hg amend -m "Adding hammer to the shopping list"
  2 new unstable changesets

Understanding the current situation with hg log is not so easy:

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
  | o  changeset:   15:bb1e6254f532
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  trouble:     unstable
  | |  summary:     Adding drill
  | |
  | o  changeset:   14:d4f97f32f8a1
  | |  topic:       tools
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  trouble:     unstable
  | |  summary:     Adding saw
  | |
  | x  changeset:   13:a8ab3599d53d
  |/   topic:       tools
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    obsolete:    rewritten as b7509bd417f8
  |    summary:     Adding hammer
  |
  o  changeset:   12:fbff9bc37a43
  |  user:        test
  ~  date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add a pair of shoes
  
Fortunately stack show you a better visualization:

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3$ Adding drill (unstable)
  t2$ Adding saw (unstable)
  t1@ Adding hammer to the shopping list (current)
  t0^ add a pair of shoes (base)

It's easy to stabilize the situation, `next` has an `--evolve` option:

  $ hg next --evolve
  move:[14] Adding saw
  atop:[18] Adding hammer to the shopping list
  working directory now at d5c51ee5762a

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
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
  ### branch: default, 2 behind
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
  ### branch: default, 2 behind
  t4: Adding drill
  t3: Adding saw
  t1^ Adding hammer to the shopping list (base)
  t2@ Adding nails (current)
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

Solving this situation is easy with a topic, use merge or rebase.
Merge within a multi-headed stack will use the other topic head as
redestination if the topic has multiple heads.

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
  

  $ hg up t4
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg rebase
  rebasing 19:d5c51ee5762a "Adding saw"
  merging shopping
  rebasing 20:bae3758e46bf "Adding drill"
  merging shopping

  $ hg commit -m "Merge tools"
  nothing changed
  [1]

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t4@ Adding drill (current)
  t3: Adding saw
  t2: Adding nails
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)

Collaborating through non-publishing server
===========================================

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

We can now share theses drafts changesets:

  $ hg push ../non-publishing-server -r tools
  pushing to ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 1 files (+1 heads)
  8 new obsolescence markers

Pushing the new topic branch to a non publishing server did not required
--force. As long as new heads are on their own topic, Mercurial will not
complains about them.

From another client, we will gets them with their topic:

  $ cd ../other-client

  $ hg pull ../non-publishing-server
  pulling from ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 4 changes to 1 files (+1 heads)
  8 new obsolescence markers
  (run 'hg heads' to see heads)

  $ hg topics --verbose
     tools (on branch: default, 4 changesets, 2 behind)

  $ hg up tools
  switching to topic tools
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
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

And retrieve them on the first client:

  $ cd ../client

  $ hg pull ../non-publishing-server
  pulling from ../non-publishing-server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  (run 'hg update' to get a working copy)

  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t5@ Adding screws (current)
  t4: Adding drill
  t3: Adding saw
  t2: Adding nails
  t1: Adding hammer to the shopping list
  t0^ add a pair of shoes (base)
