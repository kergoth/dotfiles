.. Copyright © 2014 Greg Ward <greg@gerg.ca>

------------------------------
Evolve: Shared Mutable History
------------------------------

Once you have mastered the art of mutable history in a single
repository, you might want to move up to the next level: *shared*
mutable history. ``evolve`` lets you push and pull draft changesets
between repositories along with their obsolescence markers. This opens
up a number of interesting possibilities.

The most common scenario is a single developer working across two
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

Using Mercurial with ``evolve`` to share mutable history solves all of
these problems. As with single-repository ``evolve``, you can commit
whenever the code is demonstrably better, even if all the tests aren't
passing yet—just ``hg amend`` when they are. And you can transfer
those half-baked changesets between repositories to try things out on
your test server before anything is carved in stone.

A less common scenario is multiple developers sharing mutable history.
(This is in fact how Mercurial itself is developed.) We'll cover this
scenario later. But first, single-user sharing.

Publishing and non-publishing repositories
------------------------------------------

The key to shared mutable history is to keep your changesets in
*draft* phase as you pass them around. Recall that by default, ``hg
push`` promotes changesets from *draft* to *public*, and public
changesets are immutable. You can change this behaviour by
reconfiguring the *target* repository so that it is non-publishing.
(Short version: set ``phases.publish`` to ``false``. Long version
follows.)

Setting things up
-----------------

We'll work an example with three local repositories, although in the
real world they'd most likely be on three different computers. First,
the public repository is where tested, polished changesets live, and
it is where you push/pull changesets to/from the rest of your team. ::

  $ hg init public

We'll need two clones where work gets done::

  $ hg clone -q public test-repo
  $ hg clone -q test-repo dev-repo

``dev-repo`` is your local machine, with GUI merge tools and IDEs and
everything configured just the way you like it. ``test-repo`` is the
test server in a rack somewhere behind SSH. So for the most part,
we'll develop in ``dev-repo``, push to ``test-repo``, test and polish
there, and push to ``public``.

The key to making this whole thing work is to make ``test-repo``
non-publishing::

  $ cat >> test-repo/.hg/hgrc <<EOF
  [phases]
  publish = false
  EOF

We also have to configure ``evolve`` in both ``test-repo`` and
``dev-repo``, so that we can amend and evolve in both of them. ::

  $ cat >> test-repo/.hg/hgrc <<EOF
  [extensions]
  evolve = /path/to/mutable-history/hgext/evolve.py
  EOF
  $ cat >> dev-repo/.hg/hgrc <<EOF
  [extensions]
  evolve = /path/to/mutable-history/hgext/evolve.py
  EOF

Keep in mind that in real life, these repositories would probably be
on separate computers, so you'd have to login to each one to configure
each repository.

To start things off, let's make one public, immutable changeset::

  $ cd test-repo
  $ echo 'my new project' > file1
  $ hg add file1
  $ hg commit -m 'create new project'
  $ hg push -q

and pull that into the development repository::

  $ cd ../dev-repo
  $ hg pull -u

Amending a shared changeset
---------------------------

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

  [figure SG02: rev 0:0dc9 public, rev 1:f649, 2:2a03 obsolete, rev 3:60ff draft -- but dev-repo same as in SG01]

Let's resynchronize::

  $ cd ../dev-repo
  $ hg pull -u

As seen in figure 3, this transfers the new changeset *and* the
obsolescence marker for revision 1. However, it does *not* transfer
the temporary amend commit, because it is obsolete. Push and pull
transfer obsolesence markers between repositories, but they do not
normally transfer obsolete changesets.

  [figure SG03: dev-repo grows new rev 2:60ff, marks 1:f649 obsolete]

Because of this deliberately incomplete synchronization, revision
numbers in ``test-repo`` and ``dev-repo`` are no longer consistent. We
*must* use changeset IDs.

Amend again, locally
--------------------

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
  $ hg update -q

This time, all the tests pass, so no further amendment is required.
This bug fix is finished, so we push it to the public repository::

  $ hg push
  [...]
  added 1 changesets with 1 changes to 1 files

Note that only one changeset—the final version, after two
amendments—was actually pushed. Again, Mercurial normally doesn't
transfer obsolete changesets on push and pull. (Specifically, it
doesn't transfer *hidden* changesets: roughly speaking, obsolete
changesets with no non-obsolete descendants. If you're curious, see
the `concept guide`_ for the precise definition of hidden.)

.. _`concept guide`: concepts.html

So the picture in ``public`` is much simpler than in either
``dev-repo`` or ``test-repo``. None of our missteps or amendments are
visible publicly, just the final, beautifully polished changeset:

  [figure SG05: public repo with rev 0:0dc9, 1:de61, both public]

There is one important step left to do. Because we pushed from
``test-repo`` to ``public``, the pushed changeset is in *public* phase
in those two repositories. But ``dev-repo`` knows nothing of this:
that changeset is still *draft* there. If we're not careful, we might
mutate history in ``dev-repo``, obsoleting a changeset that is already
public. Let's avoid that situation for now by pulling from
``test-repo`` down to ``dev-repo``::

  $ cd ../dev-repo
  $ hg pull -u

Getting into trouble
--------------------

Mercurial with ``evolve`` is a powerful tool, and using powerful tools
can have consequences. (You can cut yourself badly with a sharp knife,
but every competent chef keeps several around. Ever try to chop onions
with a spoon?)

In the user guide, we saw examples of *unstable* changesets, which are
the most common type of troubled changeset. (Recall that a
non-obsolete changeset with obsolete ancestors is unstable.)

Two other types of trouble can crop up: *bumped* and *divergent*
changesets. Both are more likely with shared mutable history,
especially mutable history shared by multiple developers.

To demonstrate, let's start with the ``public`` repository as we left
it in the last example, with two immutable changesets (figure 5
above). Two developers, Alice and Bob, start working from this point::

  $ hg clone -q public alice
  $ hg clone -q public bob

We need to configure Alice's and Bob's working repositories similar to
``test-repo``, i.e. make them non-publishing and enable ``evolve``::

  $ cat >> alice/.hg/hgrc <<EOF
  [phases]
  publish = false
  [extensions]
  evolve = /path/to/mutable-history/hgext/evolve.py
  EOF
  $ cp alice/.hg/hgrc bob/.hg/hgrc

Bumped changesets: only one gets on the plane
---------------------------------------------

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
  $ hg commit -q -A -m 'fix bug 15'

Now Bob has a bad idea: he decides to pull whatever Alice is working
on and tweak her bug fix to his taste::

  $ cd ../bob
  $ hg pull -q -u ../alice
  $ echo 'Fix.' > file2
  $ hg amend -q -A -m 'fix bug 15 (amended)'

(Note the lack of communication between Alice and Bob. Failing to
communicate with your colleagues is a good way to get into trouble.
Nevertheless, ``evolve`` can usually sort things out, as we will see.)

  [figure SG06: Bob's repo with one amendment]

After some testing, Alice realizes her bug fix is just fine as it is:
no need for further polishing and amending, this changeset is ready to
publish. ::

  $ cd ../alice
  $ hg push  -q

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

Divergent changesets
--------------------

In addition to *unstable* and *bumped*, there is a third kind of
troubled changeset: *divergent*. When an obsolete changeset has two
successors, those successors are divergent.

To illustrate, let's start Alice and Bob at the same
point—specifically, the point where Alice's repository currently
stands. Bob's repository is a bit of a mess, so we'll throw it away
and start him off with a copy of Alice's repository::

  $ cd ..
  $ rm -rf bob
  $ cp -rp alice bob

Now we'll have Bob commit a bug fix that could still be improved::

  $ cd bob
  $ echo 'pretty good fix' >> file1
  $ hg commit -u bob -m 'fix bug 24 (v1)'

This time, Alice meddles with her colleague's work (still a bad
idea)::

  $ cd ../alice
  $ hg pull -q -u ../bob
  $ echo 'better (alice)' >> file1
  $ hg amend -u alice -m 'fix bug 24 (v2 by alice)'

Here's where things change from the "bumped" scenario above: this
time, the original author (Bob) decides to amend his changeset too. ::

  $ cd ../bob
  $ echo 'better (bob)' >> file1
  $ hg amend -u bob -m 'fix bug 24 (v2 by bob)'

At this point, the divergence exists, but only in theory: Bob's
original changeset, 3:fe81, is obsolete and has two successors. But
those successors are in different repositories, so the trouble is not
visible to anyone yet. It will be as soon as one of our players pulls
from the other's repository. Let's make Bob the victim again::

  $ hg pull -q -u ../alice
  not updating: not a linear update
  (merge or update --check to force update)
  2 new divergent changesets

The “not a linear update” is our first hint that something is wrong,
but of course “2 new divergent changesets” is the real problem. Figure
9 shows both problems.

  [figure SG09: bob's repo with 2 heads for the 2 divergent changesets, 5:fc16 and 6:694f; wc is at 5:fc16, hence update refused; both are successors of obsolete 3:fe81, hence divergence]

Now we need to get out of trouble. Unfortunately, a `bug`_ in
``evolve`` means that the usual answer (run ``hg evolve --all``) does
not work. Bob has to figure out the solution on his own: in this case,
merge. To avoid distractions, we'll set ``HGMERGE`` to make Mercurial
resolve any conflicts in favour of Bob. ::

  $ HGMERGE=internal:local hg merge
  $ hg commit -m merge

.. _`bug`: https://bitbucket.org/marmoute/mutable-history/issue/48/

This is approximately what ``hg evolve`` would do in this
circumstance, if not for that bug. One annoying difference is that
Mercurial thinks the two divergent changesets are still divergent,
which you can see with a simple revset query::

  $ hg log -q -r 'divergent()'
  5:fc16901f4d7a
  6:694fd0f6b503

(That annoyance should go away when the bug is fixed.)

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
