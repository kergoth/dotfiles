.. Copyright 2011 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
..                Logilab SA        <contact@logilab.fr>

------------------------------------------------
Collaboration Using Evolve: A user story
------------------------------------------------


After having written some code for ticket #42, Alice starts a patch
(this will be kind of like a 'work-in-progress' checkpoint
initially)::

    $ hg ci -m '[entities] remove magic'

Instant patch! Note how the default phase of this changeset is (still)
in "draft" state.

This is easily checkable::

    $ hg phase tip
    827: draft

See? Until the day it becomes a "public" changeset, this can be
altered to no end. How? It happens with an explicit::

    $ hg phase --public

In practice, pushing to a "publishing" repository can also turn draft
changesets into public ones. Older Mercurial releases are automatically
"publishing" since they do not have the notion of non-public changesets
(or mutable history).

During the transition from older Mercurial servers to new ones, this will
happen often, so be careful.

Now let's come back to our patch. Next hour sees good progress and Alice
wants to complete the patch with the recent stuff (all that's shown by
an "hg diff") to share with a co-worker, Bob::

    $ hg amend -m '[entities] fix frobulator (closes #42)'

Note that we also fix the commit message. (For recovering MQ users: this
is just like "hg qrefresh -m").

Before leaving, let's push to the central shared repository. That will
give Bob the signal that something is ripe for review / further amendments::

    $ hg push # was done with a modern mercurial, draft phase is preserved

The next day, Bob, who arrives very early, can immediately work out
some glitches in the patch.

He then starts two others, for ticket #43 and #44 and finally commits them.
Then, as original worker arrives, he pushes his stuff.

Alice, now equipped with enough properly sugared coffee to survive the
next two hours::

    $ hg pull

Then::

    $ hg up "tip ~ 2"

brings her to yesterday's patch. Indeed the patch serial number has
increased (827 still exists but has been obsoleted).

She understands that her original patch has been altered. But how did it
evolve?

The enhanced hgview shows the two patches. By default only the most
recent version of a patch is shown.

Now, when Alice installed the mutable-history extensions, she got an alias
that allows her to see the diff between two amendments, defined like this::

    odiff=diff --rev 'limit(obsparents(.),1)' --rev .

She can see exactly how Bob amended her work.

* odiff


Amend ... Stabilize
--------------------

Almost perfect! Alice just needs to fix a half dozen grammar oddities in
the new docstrings and it will be publishable.

Then, another round of:

    $ hg amend

and a quick look at hgview ... shows something strange (at first).

Ticket #42 yesterday's version is still showing up, with two descendant lineages:

* the next version, containing grammar fixes,

* the two stacked changesets for tickets #43 .. 44 committed by Bob.

Indeed, since this changeset still has non-obsolete descendant
changesets it cannot be hidden. This branch (old version of #42 and
the two descendants by C.W.) is said to be _unstable_.

Why would one want such a state? Why not auto-stabilize each time "hg
amend" is typed out?

Alice for one, wouldn't want to merge each time she amends something that
might conflict with the descendant changesets. Remember she is
currently updating the very middle of an history!

Being now done with grammar and typo fixes, Alice decides it is time to
stabilize again the tree. She does::

    $ hg evolve

two times, one for each unstable descendant. The last time, hgview
shows her a straight line again. Wow! that feels a bit like a
well-planned surgical operation. At the end, the patient tree has
been properly trimmed and any conflict properly handled.

Of course nothing fancy really happened: each "stablilize" can be
understood in terms of a rebase of the next unstable descendant to the
newest version of its parent (including the possible manual conflict
resolution intermission ...).

Except that rebase is a destructive (it removes information from the
repository), unrecoverable operation, and the "evolve + obsolete"
combo, using changeset copy and obsolescence marker, provides evolution
semantics by only adding new information to the repository (but more
on that later).

She pushes again.

