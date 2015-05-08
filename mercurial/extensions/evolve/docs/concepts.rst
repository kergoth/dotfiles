.. Copyright 2014 Greg Ward <greg@gerg.ca>

----------------
Evolve: Concepts
----------------

Getting the most out of software requires an accurate understanding of
the concepts underlying it. For example, you cannot use Mercurial to
its full potential without understanding the DAG (directed acyclic
graph) of changesets and the meaning of parent/child relationships
between nodes in that graph. Mercurial with changeset evolution adds
some additional concepts to the graph of changesets. Understanding
those concepts will make you an informed and empowered user of
``evolve``.

.. note:: This document contains math! If you have a pathological fear
          of set theory and the associated notation, you might be
          better off just reading the `user guide`_. But if you
          appreciate the theoretical rigour underlying core Mercurial,
          you will be happy to know that it continues right into
          changeset evolution.

.. note:: This document is incomplete! (The formatting of the math
          isn't quite right yet, and the diagrams are missing for
          malformatted.)

This document follows standard set theory notation::

  x ∈ A: x is a member of A

  A ∪ B: union of A and B: { x | x ∈ A or x ∈ B }

  A ∖ B: set difference: { x | x ∈ A and x ∉ B }

  A ⊇ B: superset: if x ∈ B, then x ∈ A

.. _`user guide`: user-guide.html

Phases
------

First, every changeset in a Mercurial repository (since 2.3) has a
*phase*. Phases are independent of ``evolve`` and they affect
Mercurial usage with or without changeset evolution. However, they
were implemented in order to support evolution, and are a critical
foundation of ``evolve``.

Phases are strictly ordered:

  secret > draft > public

Changesets generally only move from a higher phase to a lower phase.
Typically, changesets start life in *draft* phase, and move to
*public* phase when they are pushed to a public repository. (You can
set the default phase of new commits in Mercurial configuration.)

The purpose of phases is to prevent modifying published history.
``evolve`` will therefore only let you rewrite changesets in one of
the two *mutable* phases (secret or draft).

Run ``hg help phases`` for more information on phases.

Obsolete changesets
-------------------

*Obsolescence* is they key concept at the heart of changeset
evolution. Everything else in this document depends on understanding
obsolescence. So: what does it mean for a changeset to be obsolete?

In implementation terms, there is an *obsolescence marker* associated
with changesets: every changeset is either obsolete or not.

The simplest way that a changeset becomes obsolete is by *pruning* it.
The ``hg prune`` command simply marks the specified changesets
obsolete, as long as they are mutable.

More commonly, a changeset *A* becomes obsolete by *amending* it.
Amendment creates a new changeset *A'* that replaces *A*, which is now
obsolete. *A'* is the successor of *A*, and *A* the predecessor of *A'*:

  [diagram: A and A' with pred/succ edge]

The predecessor/successor relationship forms an additional
*obsolescence graph* overlaid on top of the traditional DAG formed by
changesets and their parent/child relationships. In fact, the
obsolescence graph is second-order version control. Where the
traditional parent/child DAG tracks changes to your source code, the
obsolescence graph tracks changes to your changesets. It tracks the
evolution of your changesets.

(If you prefer a calculus metaphor to set theory, it might help to
think of the traditional parent/child DAG as the first derivative of
your source code, and the obsolescence DAG as the second derivative.)

Troubled changesets (unstable, bumped, divergent)
-------------------------------------------------

Evolving history can introduce problems that need to be solved. For
example, if you prune a changeset *P* but not its descendants, those
descendants are now on thin ice. To push a changeset to another
repository *R*, all of its ancestors must be present in *R* or pushed
at the same time. But Mercurial does not push obsolete changesets like
*P*, so it cannot push the descendants of *P*. Any non-obsolete
changeset that is a descendant of an obsolete changeset is said to be
*unstable*.

  [diagram: obsolete cset with non-obsolete descendant]

Another sort of trouble occurs when two developers, Alice and Bob,
collaborate via a shared non-publishing repository. (This is how
developers can safely `share mutable history`_.) Say Alice and Bob
both start the day with changeset *C* in *draft* phase. If Alice
pushes *C* to their public repository, then it is now published and
therefore immutable. But Bob is working from a desert island and
cannot pull this change in *C*'s phase. For Bob, *C* is still in draft
phase and therefore mutable. So Bob amends *C*, which marks it
obsolete and replaces it with *C'*. When he is back online and pulls
from the public repository, Mercurial learns that *C* is public, which
means it cannot be obsolete. We say that *C'* is *bumped*, since it is
the successor of a public changeset.

.. _`share mutable history`: sharing.html

(Incidentally, the terminology here comes from airline overbooking: if
two people have bought tickets for the same seat on a plane and they
both show up at the airport, only one of them gets on the plane. The
passenger who is left behind in the airport terminal has been
"bumped".)

The third sort of trouble is when Alice and Bob both amend the same
changeset *C* to have different successors. When this happens, the
successors are both called *divergent* (unless one of them is in
public phase; only mutable changesets are divergent).

The collective term for unstable, bumped, and divergent changeset is
*troubled*::

  troubled = unstable ∪ bumped ∪ divergent

It is possible for a changeset to be in any of the troubled categories
at the same time: it might be unstable and divergent, or bumped and
divergent, or whatever.

  [diagram: Venn diagram of troubled changesets, showing overlap]

The presence of troubled changesets indicates the need to run ``hg
evolve``.

Hidden (and visible) changesets
-------------------------------

Some obsolete changesets are *hidden*: deliberately suppressed by
Mercurial and usually not visible through the UI. (As of Mercurial
2.9, there are still some commands that inadvertently reveal hidden
changesets; these are bugs and will be fixed in due course.)

All hidden changesets are obsolete, and all obsolete changesets are
part of your repository. Mathematically speaking::

  repo ⊇ obsolete ⊇ hidden

Or, putting it visually:

  [diagram: Venn diagram showing nested strict subsets]

However, the presence of obsolete but not hidden changesets should be
temporary. The desired end state for any history mutation operation is
that all obsolete changesets are hidden, i.e.:

  repo ⊇ obsolete, obsolete = hidden

Visually:

  [diagram: Venn diagram showing obsolete = hidden, subset of repo]


Why is this changeset visible?
------------------------------

Any changeset which is not hidden is *visible*. That is, ::

  visible = repo ∖ hidden

(Recall that ∖ means set difference: *visible* is the set of
changesets that are in *repo* but not in *hidden*.)

After amending or pruning a changeset, you might expect it to be
hidden. It doesn't always work out that way. The precise rules are::

  hideable = obsolete
  blockers = bookmarks ∪ parents(workingcopy) ∪ localtags
  hidden = hideable ∖ ancestors((repo ∖ hideable) ∪ blockers)

This will probably be clearer with a worked example. First, here's a
repository with some obsolete changesets, some troubled changesets,
one bookmark, a working copy, and some hidden changesets::

        x-x
       /
  -o-o-o-o
     \
      x-x-o

Here's the computation required to determine which changesets are
hidden::

  repo = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }

  hideable = obsolete = { 2, 4, 5, 8 }

  blockers = { 6 } ∪ { 4 } ∪ {}

  blockers = { 4, 6 }

  hidden = hideable ∖ ancestors((repo ∖ { 2, 4, 5, 8 }) ∪ { 4, 6 })

  hidden = hideable ∖ ancestors({ 0, 1, 3, 6, 7 } ∪ { 4, 6 })

  hidden = hideable ∖ ancestors({ 0, 1, 3, 4, 6, 7 })

  hidden = { 2, 4, 5, 8 } ∖ { 0, 1, 2, 3, 4, 5, 6, 7 }

  hidden = { 8 }
