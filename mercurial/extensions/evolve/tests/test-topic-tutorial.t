==============
Topic Tutorial
==============

.. This test file is also supposed to be able to compile as a rest file.


.. Some Setup::

  $ . "$TESTDIR/testlib/topic_setup.sh"
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
finalized (move to the public phase). They can help users to organise and share
their unfinished work.

Topic Basics
============

Let's says we use Mercurial to manage our shopping list::

  $ hg log --graph
  @  changeset:   0:38da43f0a2ea
     tag:         tip
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Shopping list
  

We are about to do some edition to this list and would like to do them within
a topic. Creating a new topic is done using the ``topic`` command::

  $ hg topic food

As for named branch, our topic is active but it does not contains any changesets yet::

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
  

Our next commit will be part of the active topic::

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
  

And future commit will be part of that topic too::

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
  

We can get a compact view of the content of our topic using the ``stack`` command::

  $ hg stack
  ### topic: food
  ### branch: default
  t2@ adding fruits (current)
  t1: adding condiments
    ^ Shopping list

The topic desactivate when we update away from it::

  $ hg up default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic
     food

Note that ``default`` (name of the branch) now refers to the tipmost changeset of default without a topic::

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
  

And updating back to the topic reactivate it::

  $ hg up food
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic
   * food

The name used for updating does not affect the activation of the topic, updating to a revision part of a topic will activate it in all cases::

  $ hg up default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up --rev 'desc("condiments")'
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic
   * food

.. server side activity::

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

Topic will also affect rebase and merge destination. Let's pull the latest update from the main server::

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
  

The topic head will not be considered when merge from the new head of the branch::

  $ hg up default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg merge
  abort: branch 'default' has one head - please merge with an explicit rev
  (run 'hg heads' to see all heads)
  [255]

But the topic will see that branch head as a valid destination::

  $ hg up food
  switching to topic food
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg rebase
  rebasing 1:13900241408b "adding condiments"
  merging shopping
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
  

The topic information will fade out when we publish the changesets::

  $ hg topic
     food
  $ hg push
  pushing to $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files
  2 new obsolescence markers
  $ hg topic
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
  
  $ hg up default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

Working with Multiple Topics
============================

In the above example, topic are not bring much benefit since you only have one
line of developement. Topic start to be more useful when you have to work on
multiple features are the same time.

We might go shopping in a hardware store in the same go, so let's add some
tools to the shopping list withing a new topic::

  $ hg topic tools
  $ echo hammer >> shopping
  $ hg ci -m 'Adding hammer'
  $ echo saw >> shopping
  $ hg ci -m 'Adding saw'
  $ echo drill >> shopping
  $ hg ci -m 'Adding drill'

But are not sure to actually go in the hardward store, so in the meantime, we
want to extend the list with drinks. We go back to the official default branch
and start a new topic::

  $ hg up default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic drinks
  $ echo 'apple juice' >> shopping
  $ hg ci -m 'Adding apple juice'
  $ echo 'orange juice' >> shopping
  $ hg ci -m 'Adding orange juice'

We now have two topics::

  $ hg topic
   * drinks
     tools

The information ``hg stack`` command adapt to the active topic::

  $ hg stack
  ### topic: drinks
  ### branch: default
  t2@ Adding orange juice (current)
  t1: Adding apple juice
    ^ adding fruits
  $ hg up tools
  switching to topic tools
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg stack
  ### topic: tools
  ### branch: default
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
    ^ adding fruits

They are seen as independant branch by Mercurial. No rebase or merge betwen them will be attempted by default::

  $ hg rebase
  nothing to rebase
  [1]

.. server activity::

  $ cd ../server
  $ hg up
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ mv shopping foo
  $ echo 'Coat' > shopping
  $ cat foo >> shopping
  $ hg ci -m 'add a coat'
  $ echo 'Coat' > shopping
  $ echo 'Shoes' >> shopping
  $ cat foo >> shopping
  $ hg rm foo
  not removing foo: file is untracked
  [1]
  $ hg ci -m 'add a pair of shoes'
  $ cd ../client

Lets see what other people did in the mean time::

  $ hg pull
  pulling from $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files (+1 heads)
  (run 'hg heads' to see heads)

There is new changes! We can simply use ``hg rebase`` to update our changeset on top of the latest::

  $ hg rebase
  rebasing 6:183984ef46d1 "Adding hammer"
  merging shopping
  rebasing 7:cffff85af537 "Adding saw"
  merging shopping
  rebasing 8:34255b455dac "Adding drill"
  merging shopping

But what about the other topic? You can use 'hg topic --verbose' to see information about them::

  $ hg topic --verbose
     drinks (on branch: default, 2 changesets, 2 behind)
     tools  (on branch: default, 3 changesets)

The "2 behind" is telling you that there is 2 new changesets on the named branch of the topic. You need to merge or rebase to incorporate them.

Pushing that topic would create a new heads will be prevented::

  $ hg push --rev drinks
  pushing to $TESTTMP/server (glob)
  searching for changes
  abort: push creates new remote head 70dfa201ed73!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]


Even after a rebase Pushing all active topics at the same time will complains about the multiple heads it would create on that branch::

  $ hg rebase -b drinks
  rebasing 9:8dfa45bd5e0c "Adding apple juice"
  merging shopping
  rebasing 10:70dfa201ed73 "Adding orange juice"
  merging shopping
  switching to topic tools
  $ hg push
  pushing to $TESTTMP/server (glob)
  searching for changes
  abort: push creates new remote head 4cd7c1591a67!
  (merge or see 'hg help push' for details about pushing new heads)
  [255]

Publishing only one of them is allowed (as long as it does not create a new branch head has we just saw in the previous case)::

  $ hg push -r drinks
  pushing to $TESTTMP/server (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files
  2 new obsolescence markers

The publishing topic has now vanished, and the one still draft is now marked as "behind"::

  $ hg topic --verbose
   * tools (on branch: default, 3 changesets, 2 behind)
  $ hg stack
  ### topic: tools
  ### branch: default, 2 behind
  t3@ Adding drill (current)
  t2: Adding saw
  t1: Adding hammer
    ^ add a pair of shoes

