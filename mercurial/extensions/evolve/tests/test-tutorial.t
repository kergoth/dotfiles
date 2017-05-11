
Initial setup
-------------

This Mercurial configuration example is used for testing.
.. Various setup

  $ cat >> $HGRCPATH << EOF
  > [ui]
  > # This is change the default output of log for clear tutorial
  > logtemplate ="{node|short} ({phase}): {desc}\n"
  > [diff]
  > # use "git" diff format, clearer and smarter format
  > git = 1
  > [alias]
  > # "-d '0 0'" means that the new commit will be at January 1st 1970.
  > # This is used for stable hash during test
  > # (this tutorial is automatically tested.)
  > amend = amend -d '0 0'
  > EOF

  $ hg init local
  $ cat >> local/.hg/hgrc << EOF
  > [paths]
  > remote = ../remote
  > other = ../other
  > [ui]
  > user = Babar the King
  > EOF

  $ hg init remote
  $ cat >> remote/.hg/hgrc << EOF
  > [paths]
  > local = ../local
  > [ui]
  > user = Celestine the Queen
  > EOF

  $ hg init other
  $ cat >> other/.hg/hgrc << EOF
  > [ui]
  > user = Princess Flore
  > EOF


This tutorial uses the following configuration for Mercurial:

A compact log template with phase data:

  $ hg showconfig ui | grep log
  ui.logtemplate="{node|short} ({phase}): {desc}\n"

Improved git format diff:

  $ hg showconfig diff
  diff.git=1

And of course, we enable the experimental extensions for mutable history:

  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > evolve = $TESTDIR/../hgext3rd/evolve/
  > # enabling rebase is also needed for now
  > rebase =
  > EOF

-----------------------
Single Developer Usage
-----------------------

This tutorial shows how to use evolution to rewrite history locally.


Fixing mistake with `hg amend`
--------------------------------

We are versioning a shopping list

  $ cd local
  $ cat  >> shopping << EOF
  > Spam
  > Whizzo butter
  > Albatross
  > Rat (rather a lot)
  > Jugged fish
  > Blancmange
  > Salmon mousse
  > EOF
  $ hg commit -A -m "Monthy Python Shopping list"
  adding shopping

Its first version is shared with the outside.

  $ hg push remote
  pushing to $TESTTMP/remote (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files

Later I add additional item to my list

  $ cat >> shopping << EOF
  > Egg
  > Suggar
  > Vinegar
  > Oil
  > EOF
  $ hg commit -m "adding condiment"
  $ cat >> shopping << EOF
  > Bananos
  > Pear
  > Apple
  > EOF
  $ hg commit -m "adding fruit"

This history is very linear

  $ hg log -G
  @  d85de4546133 (draft): adding fruit
  |
  o  4d5dc8187023 (draft): adding condiment
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

But a typo was made in Babanas!

  $ hg export tip
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID d85de4546133030c82d257bbcdd9b1b416d0c31c
  # Parent  4d5dc81870237d492284826e21840b2ca00e26d1
  adding fruit
  
  diff --git a/shopping b/shopping
  --- a/shopping
  +++ b/shopping
  @@ -9,3 +9,6 @@
   Suggar
   Vinegar
   Oil
  +Bananos
  +Pear
  +Apple

The faulty changeset is in the "draft" phase because it has not been exchanged with
the outside. The first one has been exchanged and is "public" (immutable).

  $ hg log -G
  @  d85de4546133 (draft): adding fruit
  |
  o  4d5dc8187023 (draft): adding condiment
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

hopefully. I can use `hg commit --amend` to rewrite my faulty changeset!

  $ sed -i'' -e s/Bananos/Banana/ shopping
  $ hg diff
  diff --git a/shopping b/shopping
  --- a/shopping
  +++ b/shopping
  @@ -9,6 +9,6 @@
   Suggar
   Vinegar
   Oil
  -Bananos
  +Banana
   Pear
   Apple
  $ hg commit --amend

A new changeset with the right diff replace the wrong one.

  $ hg log -G
  @  9d0363b81950 (draft): adding fruit
  |
  o  4d5dc8187023 (draft): adding condiment
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  
  $ hg export tip
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 9d0363b81950646bc6ad1ec5de8b8197ea586541
  # Parent  4d5dc81870237d492284826e21840b2ca00e26d1
  adding fruit
  
  diff --git a/shopping b/shopping
  --- a/shopping
  +++ b/shopping
  @@ -9,3 +9,6 @@
   Suggar
   Vinegar
   Oil
  +Banana
  +Pear
  +Apple

Getting rid of branchy history
----------------------------------

While I was working on my list. someone made a change remotely.

  $ cd ../remote
  $ hg up -q
  $ sed -i'' -e 's/Spam/Spam Spam Spam/' shopping
  $ hg ci -m 'SPAM'
  $ cd ../local

I'll get this remote changeset when pulling

  $ hg pull remote
  pulling from $TESTTMP/remote (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)

I now have a new heads. Note that this remote head is immutable

  $ hg log -G
  o  9ca060c80d74 (public): SPAM
  |
  | @  9d0363b81950 (draft): adding fruit
  | |
  | o  4d5dc8187023 (draft): adding condiment
  |/
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

instead of merging my head with the new one. I'm going to rebase my work

  $ hg diff
  $ hg rebase --dest 9ca060c80d74 --source 4d5dc8187023
  rebasing 1:4d5dc8187023 "adding condiment"
  merging shopping
  rebasing 4:9d0363b81950 "adding fruit"
  merging shopping


My local work is now rebased on the remote one.

  $ hg log -G
  @  41aff6a42b75 (draft): adding fruit
  |
  o  dfd3a2d7691e (draft): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

Removing changesets
------------------------

I add new item to my list

  $ cat >> shopping << EOF
  > car
  > bus
  > plane
  > boat
  > EOF
  $ hg ci -m 'transport'
  $ hg log -G
  @  1125e39fbf21 (draft): transport
  |
  o  41aff6a42b75 (draft): adding fruit
  |
  o  dfd3a2d7691e (draft): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

I have a new commit but I realize that don't want it. (transport shop list does
not fit well in my standard shopping list)

  $ hg prune . # "." is for working directory parent
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory now at 41aff6a42b75
  1 changesets pruned

The silly changeset is gone.

  $ hg log -G
  @  41aff6a42b75 (draft): adding fruit
  |
  o  dfd3a2d7691e (draft): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

Reordering changesets
------------------------


We create two changesets.


  $ cat >> shopping << EOF
  > Shampoo
  > Toothbrush
  > ... More bathroom stuff to come
  > Towel
  > Soap
  > EOF
  $ hg ci -m 'bathroom stuff' -q # XXX remove the -q

  $ sed -i'' -e 's/Spam/Spam Spam Spam/g' shopping
  $ hg ci -m 'SPAM SPAM'
  $ hg log -G
  @  fac207dec9f5 (draft): SPAM SPAM
  |
  o  10b8aeaa8cc8 (draft): bathroom stuff
  |
  o  41aff6a42b75 (draft): adding fruit
  |
  o  dfd3a2d7691e (draft): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

.. note:: We can't amend changeset 7e82d3f3c2cb or 9ca060c80d74 as they are immutable.

 I now want to push to remote all my changes except the bathroom one, which I'm
 not totally happy with yet. To be able to push "SPAM SPAM" I need a version of
 "SPAM SPAM" which is not a child of "bathroom stuff"

You can use the 'grab' alias for that.

.. note: grab is an alias for `hg rebase --dest . --rev <target>; hg up <there>`

  $ hg up 'p1(10b8aeaa8cc8)' # going on "bathroom stuff" parent
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg grab fac207dec9f5 # moving "SPAM SPAM" to the working directory parent
  rebasing 10:fac207dec9f5 "SPAM SPAM" (tip)
  merging shopping
  ? files updated, 0 files merged, 0 files removed, 0 files unresolved (glob)
  $ hg log -G
  @  a224f2a4fb9f (draft): SPAM SPAM
  |
  | o  10b8aeaa8cc8 (draft): bathroom stuff
  |/
  o  41aff6a42b75 (draft): adding fruit
  |
  o  dfd3a2d7691e (draft): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

We have a new SPAM SPAM version without the bathroom stuff

  $ grep Spam shopping  # enough spam
  Spam Spam Spam Spam Spam Spam Spam Spam Spam
  $ grep Toothbrush shopping # no Toothbrush
  [1]
  $ hg export .
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID a224f2a4fb9f9f828f608959912229d7b38b26de
  # Parent  41aff6a42b7578ec7ec3cb2041633f1ca43cca96
  SPAM SPAM
  
  diff --git a/shopping b/shopping
  --- a/shopping
  +++ b/shopping
  @@ -1,4 +1,4 @@
  -Spam Spam Spam
  +Spam Spam Spam Spam Spam Spam Spam Spam Spam
   Whizzo butter
   Albatross
   Rat (rather a lot)

To make sure I do not push unready changeset by mistake I set the "bathroom
stuff" changeset in the secret phase.

  $ hg phase --force --secret 10b8aeaa8cc8

we can now push our change:

  $ hg push remote
  pushing to $TESTTMP/remote (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 1 files
  6 new obsolescence markers

for simplicity sake we get the bathroom change in line again

  $ hg grab 10b8aeaa8cc8
  rebasing 9:10b8aeaa8cc8 "bathroom stuff"
  merging shopping
  ? files updated, 0 files merged, 0 files removed, 0 files unresolved (glob)
  $ hg phase --draft .
  $ hg log -G
  @  75954b8cd933 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  



Splitting change
------------------

This part is not written yet, but you can use either the `histedit` extension
of the `uncommit` command to splitting a change.

  $ hg help uncommit
  hg uncommit [OPTION]... [NAME]
  
  move changes from parent revision to working directory
  
      Changes to selected files in the checked out revision appear again as
      uncommitted changed in the working directory. A new revision without the
      selected changes is created, becomes the checked out revision, and
      obsoletes the previous one.
  
      The --include option specifies patterns to uncommit. The --exclude option
      specifies patterns to keep in the commit.
  
      The --rev argument let you change the commit file to a content of another
      revision. It still does not change the content of your file in the working
      directory.
  
      Return 0 if changed files are uncommitted.
  
  options ([+] can be repeated):
  
   -a --all                 uncommit all changes when no arguments given
   -r --rev VALUE           revert commit content to REV instead
   -I --include PATTERN [+] include names matching the given patterns
   -X --exclude PATTERN [+] exclude names matching the given patterns
  
  (some details hidden, use --verbose to show complete help)


The edit command of histedit can be used to split changeset:


Collapsing change
------------------

The tutorial part is not written yet but can use `hg fold`:

  $ hg help fold
  hg fold [OPTION]... [-r] REV
  
  aliases: squash
  
  fold multiple revisions into a single one
  
      With --from, folds all the revisions linearly between the given revisions
      and the parent of the working directory.
  
      With --exact, folds only the specified revisions while ignoring the parent
      of the working directory. In this case, the given revisions must form a
      linear unbroken chain.
  
  options ([+] can be repeated):
  
   -r --rev VALUE [+] revision to fold
      --exact         only fold specified revisions
      --from          fold revisions linearly to working copy parent
   -m --message TEXT  use text as commit message
   -l --logfile FILE  read commit message from file
   -d --date DATE     record the specified date as commit date
   -u --user USER     record the specified user as committer
  
  (some details hidden, use --verbose to show complete help)


-----------------------
Collaboration
-----------------------


sharing mutable changesets
----------------------------

To share mutable changesets with others, just check that the repo you interact
with is "not publishing". Otherwise you will get the previously observe
behavior where exchanged changeset are automatically published.

  $ cd ../remote
  $ hg -R ../local/ showconfig phases
  [1]

the localrepo does not have any specific configuration for `phases.publish`. It
is ``true`` by default.

  $ hg pull local
  pulling from $TESTTMP/local (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  1 new obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg log -G
  o  75954b8cd933 (public): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  @  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  



We do not want to publish the "bathroom changeset". Let's rollback the last transaction.

.. Warning: Rollback is actually a dangerous kind of internal command that is deprecated and should not be exposed to user. Please forget you read about it until someone fix this tutorial.

  $ hg rollback
  repository tip rolled back to revision 4 (undo pull)
  $ hg log -G
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  @  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

Let's make the local repo "non publishing"

  $ echo '[phases]' >> ../local/.hg/hgrc
  $ echo 'publish=false' >> ../local/.hg/hgrc
  $ echo '[phases]' >> .hg/hgrc
  $ echo 'publish=false' >> .hg/hgrc
  $ hg showconfig phases
  phases.publish=false
  $ hg -R ../local/ showconfig phases
  phases.publish=false


I can now exchange mutable changeset between "remote" and "local" repository.

  $ hg pull local
  pulling from $TESTTMP/local (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  1 new obsolescence markers
  (run 'hg update' to get a working copy)
  $ hg log -G
  o  75954b8cd933 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  @  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

Rebasing unstable change after pull
----------------------------------------------

Remotely someone add a new changeset on top of the mutable "bathroom" on.

  $ hg up 75954b8cd933 -q
  $ cat >> shopping << EOF
  > Giraffe
  > Rhino
  > Lion
  > Bear
  > EOF
  $ hg ci -m 'animals'

But at the same time, locally, this same "bathroom changeset" was updated.

  $ cd ../local
  $ hg up 75954b8cd933 -q
  $ sed -i'' -e 's/... More bathroom stuff to come/Bath Robe/' shopping
  $ hg commit --amend
  $ hg log -G
  @  a44c85f957d3 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  


When we pull from remote again we get an unstable state!

  $ hg pull remote
  pulling from $TESTTMP/remote (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  1 new unstable changesets


The new changeset "animal" is based on an old changeset of "bathroom". You can
see both version showing up in the log.

  $ hg log -G
  o  bf1b0d202029 (draft): animals
  |
  | @  a44c85f957d3 (draft): bathroom stuff
  | |
  x |  75954b8cd933 (draft): bathroom stuff
  |/
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

The older version 75954b8cd933 never ceased to exist in the local repo. It was
just hidden and excluded from pull and push.

.. note:: In hgview there is a nice dotted relation highlighting a44c85f957d3 as a new version of 75954b8cd933. this is not yet ported to ``hg log -G``.

There is now an **unstable** changeset in this history. Mercurial will refuse to
share it with the outside:

  $ hg push other
  pushing to $TESTTMP/other (glob)
  searching for changes
  abort: push includes unstable changeset: bf1b0d202029!
  (use 'hg evolve' to get a stable history or --force to ignore warnings)
  [255]
 



To resolve this unstable state, you need to rebase bf1b0d202029 onto
a44c85f957d3. The `hg evolve` command will do this for you.

It has a --dry-run option to only suggest the next move.

  $ hg evolve --dry-run
  move:[15] animals
  atop:[14] bathroom stuff
  hg rebase -r bf1b0d202029 -d a44c85f957d3

Let's do it

  $ hg evolve
  move:[15] animals
  atop:[14] bathroom stuff
  merging shopping
  working directory is now at ee942144f952

The old version of bathroom is hidden again.

  $ hg log -G
  @  ee942144f952 (draft): animals
  |
  o  a44c85f957d3 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  


We can push this evolution to remote

  $ hg push remote
  pushing to $TESTTMP/remote (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files (+1 heads)
  3 new obsolescence markers

remote get a warning that current working directory is based on an obsolete changeset

  $ cd ../remote
  $ hg pull local # we up again to trigger the warning. it was displayed during the push
  pulling from $TESTTMP/local (glob)
  searching for changes
  no changes found
  working directory parent is obsolete! (bf1b0d202029)
  (use 'hg evolve' to update to its successor: ee942144f952)

now let's see where we are, and update to the successor

  $ hg parents
  bf1b0d202029 (draft): animals
  working directory parent is obsolete! (bf1b0d202029)
  (use 'hg evolve' to update to its successor: ee942144f952)
  $ hg evolve
  update:[8] animals
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory is now at ee942144f952

Relocating unstable change after prune
----------------------------------------------

The remote guy keep working

  $ sed -i'' -e 's/Spam/Spam Spam Spam Spam/g' shopping
  $ hg commit -m "SPAM SPAM SPAM"

I'm pulling its work locally.

  $ cd ../local
  $ hg pull remote
  pulling from $TESTTMP/remote (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  (run 'hg update' to get a working copy)
  $ hg log -G
  o  99f039c5ec9e (draft): SPAM SPAM SPAM
  |
  @  ee942144f952 (draft): animals
  |
  o  a44c85f957d3 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

In the mean time I noticed you can't buy animals in a super market and I prune the animal changeset:

  $ hg prune ee942144f952
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  working directory now at a44c85f957d3
  1 changesets pruned
  1 new unstable changesets


The animals changeset is still displayed because the "SPAM SPAM SPAM" changeset
is neither dead or obsolete.  My repository is in an unstable state again.

  $ hg log -G
  o  99f039c5ec9e (draft): SPAM SPAM SPAM
  |
  x  ee942144f952 (draft): animals
  |
  @  a44c85f957d3 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  

  $ hg log -r 'unstable()'
  99f039c5ec9e (draft): SPAM SPAM SPAM

  $ hg evolve
  move:[17] SPAM SPAM SPAM
  atop:[14] bathroom stuff
  merging shopping
  working directory is now at 40aa40daeefb

  $ hg log -G
  @  40aa40daeefb (draft): SPAM SPAM SPAM
  |
  o  a44c85f957d3 (draft): bathroom stuff
  |
  o  a224f2a4fb9f (public): SPAM SPAM
  |
  o  41aff6a42b75 (public): adding fruit
  |
  o  dfd3a2d7691e (public): adding condiment
  |
  o  9ca060c80d74 (public): SPAM
  |
  o  7e82d3f3c2cb (public): Monthy Python Shopping list
  


Handling Divergent amend
----------------------------------------------

We can detect that multiple diverging amendments have been made.
The `evolve` command can solve this situation. But all corner case are not
handled now.

This section needs to be written.
