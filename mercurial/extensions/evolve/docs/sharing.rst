.. Copyright © 2014 Greg Ward <greg@gerg.ca>

------------------------------
Evolve: Shared Mutable History
------------------------------

.. contents::

Once you have mastered the art of mutable history in a single
repository (see the `user guide`_), you can move up to the next level:
*shared* mutable history. ``evolve`` lets you push and pull draft
changesets between repositories along with their obsolescence markers.
This opens up a number of interesting possibilities.

.. _`user guide`: user-guide.html

The simplest scenario is a single developer working across two
computers. Say you're working on code that must be tested on a remote
test server, probably in a rack somewhere, only accessible by SSH, and
running an “enterprise-grade” (out-of-date) OS. But you probably
prefer to write code locally: everything is setup the way you like it,
and you can use your preferred editor, IDE, merge/diff tools, etc.

Traditionally, your options are limited: either

  * (ab)use your source control system by committing half-working code
    in order to get it onto the remote test server, or
  * go behind source control's back by using ``rsync`` (or similar) to
    transfer your code back-and-forth until it is ready to commit

The former is less bad with distributed version control systems like
Mercurial, but it's still far from ideal. (One important version
control “best practice” is that every commit should make things just a
little bit better, i.e. you should never commit code that is worse
than what came before.) The latter, avoiding version control entirely,
means that you're walking a tightrope without a safety net. One
accidental ``rsync`` in the wrong direction could destroy hours of
work.

Using Mercurial with ``evolve`` to share mutable history solves these
problems. As with single-repository ``evolve``, you can commit
whenever the code is demonstrably better, even if all the tests aren't
passing yet—just ``hg amend`` when they are. And you can transfer
those half-baked changesets between repositories to try things out on
your test server before anything is carved in stone.

A less common scenario is multiple developers sharing mutable history,
typically for code review. We'll cover this scenario later. But first,
single-user sharing.

Sharing with a single developer
-------------------------------

Publishing and non-publishing repositories
==========================================

The key to shared mutable history is to keep your changesets in
*draft* phase as you pass them around. Recall that by default, ``hg
push`` promotes changesets from *draft* to *public*, and public
changesets are immutable. You can change this behaviour by
reconfiguring the *target* repository so that it is non-publishing.
(Short version: set ``phases.publish`` to ``false``. Long version
follows.)

Setting up
==========

We'll work through an example with three local repositories, although
in the real world they'd most likely be on three different computers.
First, the ``public`` repository is where tested, polished changesets
live, and it is where you synchronize with the rest of your team. ::

  $ hg init public

We'll need two clones where work gets done, ``test-repo`` and
``dev-repo``::

  $ hg clone public test-repo
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone test-repo dev-repo
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

``dev-repo`` is your local machine, with GUI merge tools and IDEs and
everything configured just the way you like it. ``test-repo`` is the
test server in a rack somewhere behind SSH. So for the most part,
we'll develop in ``dev-repo``, push to ``test-repo``, test and polish
there, and push to ``public``.

The key to shared mutable history is to make the target repository, in
this case ``test-repo``, non-publishing. And, of course, we have to
enable ``evolve`` in both ``test-repo`` and ``dev-repo``.

First, edit the configuration for ``test-repo``::

  $ hg -R test-repo config --edit --local

and add ::

  [phases]
  publish = false

  [extensions]
  evolve = /path/to/evolve-main/hgext3rd/evolve/

Then edit the configuration for ``dev-repo``::

  $ hg -R dev-repo config --edit --local

and add ::

  [extensions]
  evolve = /path/to/evolve-main/hgext3rd/evolve/

Keep in mind that in real life, these repositories would probably be
on separate computers, so you'd have to login to each one to configure
each repository.

To start things off, let's make one public, immutable changeset::

  $ cd test-repo
  $ echo 'my new project' > file1
  $ hg add file1
  $ hg commit -m 'create new project'
  $ hg push
  [...]
  added 1 changesets with 1 changes to 1 files

and pull that into the development repository::

  $ cd ../dev-repo
  $ hg pull -u
  [...]
  added 1 changesets with 1 changes to 1 files
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

Example 1: Amend a shared changeset
===================================

Everything you learned in the `user guide`_ applies to work done in
``dev-repo``. You can commit, amend, uncommit, evolve, and so forth
just as before.

.. _`user guide`: user-guide.html

Things get different when you push changesets to ``test-repo``. Or
rather, things stay the same, which *is* different: because we
configured ``test-repo`` to be non-publishing, draft changesets stay
draft when we push them to ``test-repo``. Importantly, they're also
draft (mutable) in ``test-repo``.

Let's commit a preliminary change and push it to ``test-repo`` for
testing. ::

  $ echo 'fix fix fix' > file1
  $ hg commit -m 'prelim change'
  $ hg push ../test-repo

At this point, ``dev-repo`` and ``test-repo`` have the same changesets
in the same phases:

  [figure SG01: rev 0:0dc9 public, rev 1:f649 draft, same on both repos]

(You may notice a change in notation from the user guide: now
changesets are labelled with their revision number and the first four
digits of the 40-digit hexadecimal changeset ID. Mercurial revision
numbers are never stable when working across repositories, especially
when obsolescence is involved. We'll see why shortly.)

Now let's switch to ``test-repo`` to test our change::

  $ cd ../test-repo
  $ hg update

Don't forget to ``hg update``! Pushing only adds changesets to a
remote repository; it does not update the working directory (unless
you have a hook that updates for you).

Now let's imagine the tests failed because we didn't use proper
punctuation and capitalization (oops). Let's amend our preliminary fix
(and fix the lame commit message while we're at it)::

  $ echo 'Fix fix fix.' > file1
  $ hg amend -m 'fix bug 37'

Now we're in a funny intermediate state (figure 2): revision 1:f649 is
obsolete in ``test-repo``, having been replaced by revision 3:60ff
(revision 2:2a03 is another one of those temporary amend commits that
we saw in the user guide)—but ``dev-repo`` knows nothing of these
recent developments.

  [figure SG02: test-repo has rev 0:0dc9 public, rev 1:f649, 2:2a03 obsolete, rev 3:60ff draft; dev-repo same as in SG01]

Let's resynchronize::

  $ cd ../dev-repo
  $ hg pull -u
  [...]
  added 1 changesets with 1 changes to 1 files (+1 heads)
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

As seen in figure 3, this transfers the new changeset *and* the
obsolescence marker for revision 1. However, it does *not* transfer
the temporary amend commit, because it is hidden. Push and pull
transfer obsolesence markers between repositories, but they do not
transfer hidden changesets.

  [figure SG03: dev-repo grows new rev 2:60ff, marks 1:f649 obsolete]

Because of this deliberately incomplete synchronization, revision
numbers in ``test-repo`` and ``dev-repo`` are no longer consistent. We
*must* use changeset IDs.

Example 2: Amend again, locally
===============================

This process can repeat. Perhaps you figure out a more elegant fix to
the bug, and want to mutate history so nobody ever knows you had a
less-than-perfect idea. We'll implement it locally in ``dev-repo`` and
push to ``test-repo``::

  $ echo 'Fix, fix, and fix.' > file1
  $ hg amend
  $ hg push

This time around, the temporary amend commit is in ``dev-repo``, and
it is not transferred to ``test-repo``—the same as before, just in the
opposite direction. Figure 4 shows the two repositories after amending
in ``dev-repo`` and pushing to ``test-repo``.

  [figure SG04: each repo has one temporary amend commit, but they're different in each one]

Let's hop over to ``test-repo`` to test the more elegant fix::

  $ cd ../test-repo
  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

This time, all the tests pass, so no further amending is required.
This bug fix is finished, so we push it to the public repository::

  $ hg push
  [...]
  added 1 changesets with 1 changes to 1 files

Note that only one changeset—the final version, after two
amendments—was actually pushed. Again, Mercurial doesn't transfer
hidden changesets on push and pull.

.. _`concept guide`: concepts.html

So the picture in ``public`` is much simpler than in either
``dev-repo`` or ``test-repo``. Neither our missteps nor our amendments
are publicly visible, just the final, beautifully polished changeset:

  [figure SG05: public repo with rev 0:0dc9, 1:de61, both public]

There is one important step left to do. Because we pushed from
``test-repo`` to ``public``, the pushed changeset is in *public* phase
in those two repositories. But ``dev-repo`` has been out-of-the-loop;
changeset de61 is still *draft* there. If we're not careful, we might
mutate history in ``dev-repo``, obsoleting a changeset that is already
public. Let's avoid that situation for now by pushing up to
``dev-repo``::

  $ hg push ../dev-repo
  pushing to ../dev-repo
  searching for changes
  no changes found

Even though no *changesets* were pushed, Mercurial still pushed
obsolescence markers and phase changes to ``dev-repo``.

A final note: since this fix is now *public*, it is immutable. It's no
longer possible to amend it::

  $ hg amend -m 'fix bug 37'
  abort: cannot amend public changesets

This is, after all, the whole point of Mercurial's phases: to prevent
rewriting history that has already been published.

Sharing with multiple developers: code review
---------------------------------------------

Now that you know how to share your own mutable history across
multiple computers, you might be wondering if it makes sense to share
mutable history with others. It does, but you have to be careful, stay
alert, and *communicate* with your peers.

Code review is a good use case for sharing mutable history across
multiple developers: Alice commits a draft changeset, submits it for
review, and amends her changeset until her reviewer is satisfied.
Meanwhile, Bob is also committing draft changesets for review,
amending until his reviewer is satisfied. Once a particular changeset
passes review, the respective author (Alice or Bob) pushes it to the
public (publishing) repository.

Incidentally, the reviewers here can be anyone: maybe Bob and Alice
review each other's work; maybe the same third party reviews both; or
maybe they pick different experts to review their work on different
parts of a large codebase. Similarly, it doesn't matter if reviews are
conducted in person, by email, or by carrier pigeon. Code review is
outside of the scope of Mercurial, so all we're looking at here
is the mechanics of committing, amending, pushing, and pulling.

Setting up
==========

To demonstrate, let's start with the ``public`` repository as we left
it in the last example, with two immutable changesets (figure 5
above). We'll clone a ``review`` repository from it, and then Alice
and Bob will both clone from ``review``. ::

  $ hg clone public review
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone review alice
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone review bob
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

We need to configure Alice's and Bob's working repositories to enable
``evolve``. First, edit Alice's configuration with ::

  $ hg -R alice config --edit --local

and add ::

  [extensions]
  evolve = /path/to/evolve-main/hgext3rd/evolve/

Then edit Bob's repository configuration::

  $ hg -R bob config --edit --local

and add the same text.

Example 3: Alice commits and amends a draft fix
===============================================

We'll follow Alice working on a bug fix. We're going to use bookmarks to
make it easier to understand multiple branch heads in the ``review``
repository, so Alice starts off by creating a bookmark and committing
her first attempt at a fix::

  $ hg bookmark bug15
  $ echo 'fix' > file2
  $ hg commit -A -u alice -m 'fix bug 15 (v1)'
  adding file2

Note the unorthodox "(v1)" in the commit message. We're just using
that to make this tutorial easier to follow; it's not something we'd
recommend in real life.

Of course Alice wouldn't commit unless her fix worked to her
satisfaction, so it must be time to solicit a code review. She does
this by pushing to the ``review`` repository::

  $ hg push -B bug15
  [...]
  added 1 changesets with 1 changes to 1 files
  exporting bookmark bug15

(The use of ``-B`` is important to ensure that we only push the
bookmarked head, and that the bookmark itself is pushed. See this
`guide to bookmarks`_, especially the `Sharing Bookmarks`_ section, if
you're not familiar with bookmarks.)

.. _`guide to bookmarks`: http://mercurial.aragost.com/kick-start/en/bookmarks/
.. _`Sharing Bookmarks`: http://mercurial.aragost.com/kick-start/en/bookmarks/#sharing-bookmarks

Some time passes, and Alice receives her code review. As a result,
Alice revises her fix and submits it for a second review::

  $ echo 'Fix.' > file2
  $ hg amend -m 'fix bug 15 (v2)'
  $ hg push
  [...]
  added 1 changesets with 1 changes to 1 files (+1 heads)
  updating bookmark bug15

Figure 6 shows the state of the ``review`` repository at this point.

  [figure SG06: rev 2:fn1e is Alice's obsolete v1, rev 3:cbdf is her v2; both children of rev 1:de61]

After a busy morning of bug fixing, Alice stops for lunch. Let's see
what Bob has been up to.

Example 4: Bob implements and publishes a new feature
=====================================================

Meanwhile, Bob has been working on a new feature. Like Alice, he'll
use a bookmark to track his work, and he'll push that bookmark to the
``review`` repository, so that reviewers know which changesets to
review. ::

  $ cd ../bob
  $ echo 'stuff' > file1
  $ hg bookmark featureX
  $ hg commit -u bob -m 'implement feature X (v1)'          # rev 4:1636
  $ hg push -B featureX
  [...]
  added 1 changesets with 1 changes to 1 files (+1 heads)
  exporting bookmark featureX

When Bob receives his code review, he improves his implementation a
bit, amends, and submits the resulting changeset for review::

  $ echo 'do stuff' > file1
  $ hg amend -m 'implement feature X (v2)'                  # rev 5:0eb7
  $ hg push
  [...]
  added 1 changesets with 1 changes to 1 files (+1 heads)
  updating bookmark featureX

Unfortunately, that still doesn't pass muster. Bob's reviewer insists
on proper capitalization and punctuation. ::

  $ echo 'Do stuff.' > file1
  $ hg amend -m 'implement feature X (v3)'                  # rev 6:540b

On the bright side, the second review said, "Go ahead and publish once
you fix that." So Bob immediately publishes his third attempt::

  $ hg push ../public
  [...]
  added 1 changesets with 1 changes to 1 files

It's not enough just to update ``public``, though! Other people also
use the ``review`` repository, and right now it doesn't have Bob's
latest amendment ("v3", revision 6:540b), nor does it know that the
precursor of that changeset ("v2", revision 5:0eb7) is obsolete. Thus,
Bob pushes to ``review`` as well::

  $ hg push ../review
  [...]
  added 1 changesets with 1 changes to 1 files (+1 heads)
  updating bookmark featureX

Figure 7 shows the result of Bob's work in both ``review`` and
``public``.

  [figure SG07: review includes Alice's draft work on bug 15, as well as Bob's v1, v2, and v3 changes for feature X: v1 and v2 obsolete, v3 public. public contains only the final, public implementation of feature X]

Incidentally, it's important that Bob push to ``public`` *before*
``review``. If he pushed to ``review`` first, then revision 6:540b
would still be in *draft* phase in ``review``, but it would be
*public* in both Bob's local repository and the ``public`` repository.
That could lead to confusion at some point, which is easily avoided by
pushing first to ``public``.

Example 5: Alice integrates and publishes
=========================================

Finally, Alice gets back from lunch and sees that the carrier pigeon
with her second review has arrived (or maybe it's in her email inbox).
Alice's reviewer approved her amended changeset, so she pushes it to
``public``::

  $ hg push ../public
  [...]
  remote has heads on branch 'default' that are not known locally: 540ba8f317e6
  abort: push creates new remote head cbdfbd5a5db2!
  (pull and merge or see "hg help push" for details about pushing new heads)

Oops! Bob has won the race to push first to ``public``. So Alice needs
to integrate with Bob: let's pull his changeset(s) and see what the
branch heads are. ::

  $ hg pull ../public
  [...]
  added 1 changesets with 1 changes to 1 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg log -G -q -r 'head()' --template '{rev}:{node|short}  ({author})\n'
  o  5:540ba8f317e6  (bob)
  |
  | @  4:cbdfbd5a5db2  (alice)
  |/

We'll assume Alice and Bob are perfectly comfortable with rebasing
changesets. (After all, they're already using mutable history in the
form of ``amend``.) So Alice rebases her changeset on top of Bob's and
publishes the result::

  $ hg rebase -d 5
  $ hg push ../public
  [...]
  added 1 changesets with 1 changes to 1 files
  $ hg push ../review
  [...]
  added 1 changesets with 0 changes to 0 files
  updating bookmark bug15

The result, in both ``review`` and ``public`` repositories, is shown
in figure 8.

  [figure SG08: review shows v1 and v2 of Alice's fix, then v1, v2, v3 of Bob's feature, finally Alice's fix rebased onto Bob's. public just shows the final public version of each changeset]

Getting into trouble with shared mutable history
------------------------------------------------

Mercurial with ``evolve`` is a powerful tool, and using powerful tools
can have consequences. (You can cut yourself badly with a sharp knife,
but every competent chef keeps several around. Ever try to chop onions
with a spoon?)

In the user guide, we saw examples of *unstable* changesets, which are
the most common type of troubled changeset. (Recall that a
non-obsolete changeset with obsolete ancestors is unstable.)

Two other types of trouble can happen: *divergent* and *bumped*
changesets. Both are more likely with shared mutable history,
especially mutable history shared by multiple developers.

Setting up
==========

For these examples, we're going to use a slightly different workflow:
as before, Alice and Bob share a ``public`` repository. But this time
there is no ``review`` repository. Instead, Alice and Bob put on their
cowboy hats, throw good practice to the wind, and pull directly from
each other's working repositories.

So we throw away everything except ``public`` and reclone::

  $ rm -rf review alice bob
  $ hg clone public alice
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg clone public bob
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

Once again we have to configure their repositories: enable ``evolve``
and (since Alice and Bob will be pulling directly from each other)
make their repositories non-publishing. Edit Alice's configuration::

  $ hg -R alice config --edit --local

and add ::

  [extensions]
  rebase =
  evolve = /path/to/evolve-main/hgext3rd/evolve/

  [phases]
  publish = false

Then edit Bob's repository configuration::

  $ hg -R bob config --edit --local

and add the same text.

Example 6: Divergent changesets
===============================

When an obsolete changeset has two successors, those successors are
*divergent*. One way to get into such a situation is by failing to
communicate with your teammates. Let's see how that might happen.

First, we'll have Bob commit a bug fix that could still be improved::

  $ cd bob
  $ echo 'pretty good fix' >> file1
  $ hg commit -u bob -m 'fix bug 24 (v1)'                   # rev 4:2fe6

Since Alice and Bob are now in cowboy mode, Alice pulls Bob's draft
changeset and amends it herself. ::

  $ cd ../alice
  $ hg pull -u ../bob
  [...]
  added 1 changesets with 1 changes to 1 files
  $ echo 'better fix (alice)' >> file1
  $ hg amend -u alice -m 'fix bug 24 (v2 by alice)'

But Bob has no idea that Alice just did this. (See how important good
communication is?) So he implements a better fix of his own::

  $ cd ../bob
  $ echo 'better fix (bob)' >> file1
  $ hg amend -u bob -m 'fix bug 24 (v2 by bob)'             # rev 6:a360

At this point, the divergence exists, but only in theory: Bob's
original changeset, 4:2fe6, is obsolete and has two successors. But
those successors are in different repositories, so the trouble is not
visible to anyone yet. It will be as soon as Bob pulls from Alice's
repository (or vice-versa). ::

  $ hg pull ../alice
  [...]
  added 1 changesets with 1 changes to 2 files (+1 heads)
  (run 'hg heads' to see heads, 'hg merge' to merge)
  2 new divergent changesets

Figure 9 shows the situation in Bob's repository.

  [figure SG09: Bob's repo with 2 heads for the 2 divergent changesets, 6:a360 and 7:e3f9; wc is at 6:a360; both are successors of obsolete 4:2fe6, hence divergence]

Now we need to get out of trouble. As usual, the answer is to evolve
history. ::

  $ HGMERGE=internal:other hg evolve
  merge:[6] fix bug 24 (v2 by bob)
  with: [7] fix bug 24 (v2 by alice)
  base: [4] fix bug 24 (v1)
  0 files updated, 1 files merged, 0 files removed, 0 files unresolved

Figure 10 shows how Bob's repository looks now.

  [figure SG10: only one visible head, 9:5ad6, successor to hidden 6:a360 and 7:e3f9]

We carefully dodged a merge conflict by specifying a merge tool
(``internal:other``) that will take Alice's changes over Bob's. (You
might wonder why Bob wouldn't prefer his own changes by using
``internal:local``. He's avoiding a `bug`_ in ``evolve`` that occurs
when evolving divergent changesets using ``internal:local``.)

.. _`bug`: https://bitbucket.org/marmoute/mutable-history/issue/48/

** STOP HERE: WORK IN PROGRESS **

Bumped changesets: only one gets on the plane
=============================================

If two people show up at the airport with tickets for the same seat on
the same plane, only one of them gets on the plane. The would-be
traveller left behind in the airport terminal is said to have been
*bumped*.

Similarly, if Alice and Bob are collaborating on some mutable
changesets, it's possible to get into a situation where an otherwise
worthwhile changeset cannot be pushed to the public repository; it is
bumped by an alternative changeset that happened to get there first.
Let's demonstrate one way this could happen.

It starts with Alice committing a bug fix. Right now, we don't yet
know if this bug fix is good enough to push to the public repository,
but it's good enough for Alice to commit. ::

  $ cd alice
  $ echo 'fix' > file2
  $ hg commit -A -m 'fix bug 15'
  adding file2

Now Bob has a bad idea: he decides to pull whatever Alice is working
on and tweak her bug fix to his taste::

  $ cd ../bob
  $ hg pull -u ../alice
  [...]
  added 1 changesets with 1 changes to 1 files
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo 'Fix.' > file2
  $ hg amend -A -m 'fix bug 15 (amended)'

(Note the lack of communication between Alice and Bob. Failing to
communicate with your colleagues is a good way to get into trouble.
Nevertheless, ``evolve`` can usually sort things out, as we will see.)

  [figure SG06: Bob's repo with one amendment]

After some testing, Alice realizes her bug fix is just fine as it is:
no need for further polishing and amending, this changeset is ready to
publish. ::

  $ cd ../alice
  $ hg push
  [...]
  added 1 changesets with 1 changes to 1 files

This introduces a contradiction: in Bob's repository, changeset 2:e011
(his copy of Alice's fix) is obsolete, since Bob amended it. But in
Alice's repository (and ``public``), that changeset is public: it is
immutable, carved in stone for all eternity. No changeset can be both
obsolete and public, so Bob is in for a surprise the next time he
pulls from ``public``::

  $ cd ../bob
  $ hg pull -q -u
  1 new bumped changesets

Figure 7 shows what just happened to Bob's repository: changeset
2:e011 is now public, so it can't be obsolete. When that changeset was
obsolete, it made perfect sense for it to have a successor, namely
Bob's amendment of Alice's fix (changeset 4:fe88). But it's illogical
for a public changeset to have a successor, so 4:fe88 is in trouble:
it has been *bumped*.

  [figure SG07: 2:e011 now public not obsolete, 4:fe88 now bumped]

As usual when there's trouble in your repository, the solution is to
evolve it::

  $ hg evolve --all

Figure 8 illustrate's Bob's repository after evolving away the bumped
changeset. Ignoring the obsolete changesets, Bob now has a nice,
clean, simple history. His amendment of Alice's bug fix lives on, as
changeset 5:227d—albeit with a software-generated commit message. (Bob
should probably amend that changeset to improve the commit message.)
But the important thing is that his repository no longer has any
troubled changesets, thanks to ``evolve``.

  [figure SG08: 5:227d is new, formerly bumped changeset 4:fe88 now hidden]

Conclusion
----------

Mutable history is a powerful tool. Like a sharp knife, an experienced
user can do wonderful things with it, much more wonderful than with a
dull knife (never mind a rusty spoon). At the same time, an
inattentive or careless user can do harm to himself or others.
Mercurial with ``evolve`` goes to great lengths to limit the harm you
can do by trying to handle all possible types of “troubled”
changesets. But having a first-aid kit nearby does not excuse you from
being careful with sharp knives.

Mutable history shared across multiple repositories by a single
developer is a natural extension of this model. Once you are used to
using a single sharp knife on its own, it's pretty straightforward to
chop onions and mushrooms using the same knife, or to alternate
between two chopping boards with different knives.

Mutable history shared by multiple developers is a scary place to go.
Imagine a professional kitchen full of expert chefs tossing their
favourite knives back and forth, with the occasional axe or chainsaw
thrown in to spice things up. If you're confident that you *and your
colleagues* can do it without losing a limb, go for it. But be sure to
practice a lot first before you rely on it!
