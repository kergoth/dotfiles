.. Copyright 2011 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
..                Logilab SA        <contact@logilab.fr>

-----------------------------------------------------------
Why Do We Need a New Concept
-----------------------------------------------------------

Current DVCSes are great tools for forging a series of flawless
changesets on your own. But they perform poorly when it comes to
**sharing** some work in progress and **collaborating** on such work
in progress.

When people forge a new version of a changeset they actually create a
new changeset and get rid of the original changeset. Difficulties to
collaborate mostly came from the way old content is *removed* from
a repository.

Mercurial Approach: Strip
-----------------------------------------------------

With the current version of mercurial, every changeset that exists in
your repository is *visible* and *meaningful*. To delete old
(rewritten) changesets, mercurial removes them from the repository
storage with an operation called *strip*. After the *stripping*, the
repository looks as if the changeset never existed.

This approach is simple and effective except for one big
drawback: you can remove changesets from **your repository only**. If
a stripped changeset exists in another repository it touches, it will
show up again. This is because a shared changeset becomes
part of a shared global history. Stripping a changeset from all
repositories is at best impractical and in most case impossible.

As consequence, **you can not rewrite something once you exchange it with
others**. The old version will still exist along side the new one [#]_.

Moreover stripping changesets creates backup bundles. This allows
restoration of the deleted changesets, but the process is painful.

Finally, as the repository format is not optimized for deletion. stripping a
changeset may be slow in some situations.

To sum up, the strip approach is very simple but does not handle
interaction with the outer world, which is very unfortunate for a
*Distributed* VCS.

.. [#] various work around exists but they require their own workflows
   which are distinct from the very elegant basic workflow of
   Mercurial.

Git Approach: Overwrite Reference
-----------------------------------------------------

The Git approach to repository structure is a bit more complex: there
can be any amount of unrelated changesets in a repository, and **only
changesets referenced by a git branch** are *visible* and
*meaningful*.


.. figure:: ./figures/git.*


This simplifies the process of getting rid of old changesets. You can
just leave them in place and move the reference on the new one. You
can then propagate this change by moving the git-branch on remote host
with the newer version of the marker overwriting the older one.

This approach goes a bit further but still has a major drawback:

Because you **overwrite** the git-branch, you have no conflict
resolution. The last to act wins. This makes collaboration on multiple
changesets difficult because you can't merge concurrent updates on a
changeset.

Every overwrite is a forced operation where the operator says, "yes I
want this to replace that". In highly distributed environments, a user
may end up with conflicting references and no proper way to choose.

Because of this way to visualize a repository, git-branches are a core
part of git, which makes the user interface more complicated and
constrains moving through history.

Finally, even if all older changesets still exist in the repository,
accesing them is still painful.


-----------------------------------------------------
The Obsolete Marker Concept
-----------------------------------------------------


As none of the concepts was powerful enough to fulfill the need of
safely rewriting history, including easy sharing and collaboration on
mutable history, we needed another one.

Basic concept
-----------------------------------------------------


Every history rewriting operation stores the information that old rewritten
changeset is replaced by newer version in a given set of changesets.

All basic history rewriting operation can create an appropriate obsolete marker.


.. figure:: ./figures/example-1-update.*

    *Updating* a changeset

    Create one obsolete marker: ``([A'] obsolete A)``



.. figure:: ./figures/example-2-split.*

    *Splitting* a changeset in multiple one

    Create one obsolete marker ``([B1, B2] obsolete B)]``


.. figure:: ./figures/simple-3-merge.*

    *Merging* multiple changeset in a single one

    Create two obsolete markers ``([C] obsolete A), ([C] obsolete B)``

.. figure:: ./figures/simple-4-reorder.*

    *Moving* changeset around

    Reordering those two changesets need two obsolete markers:
    ``([A'] obsolete A), ([B'] obsolete B)``



.. figure:: ./figures/simple-5-delete.*

    *Removing* a changeset:

    One obselete marker ``([] obsolete B)``


To conclude, a single obsolete marker express a relation from **0..n** new
changesets to **1** old changeset.

Basic Usage
-----------------------------------------------------

Obsolete markers create a perpendicular history: **a versioned
changeset graph**. This means that offers the same features we have
for versioned files but applied to changeset:

First: we can display a **coherent view** of the history graph in which only a
single version of your changesets is displayed by the UI.

Second, because obsolete changeset content is still **available**. You can 
you can

    * **browse** the content of your obsolete commits,

    * **compare** newer and older versions of a changeset,

    * **restore** content of previously obsolete changesets.

Finally, the obsolete marker can be **exchanged between
repositories**. You are able to share the result on your history
rewriting operations with other prople and **collaborate on the
mutable part of the history**.

Conflicting history rewriting operation can be detected and
**resolved** as easily as conflicting changes on a file.


Detecting and solving tricky situations
-----------------------------------------------------

History rewriting can lead to complex situations. The obsolete marker
introduces a simple representation for this complex reality. But
people using complex workflows will one day or another have to face
the intrinsic complexity of some real-world situation.

This section describes possible situations, defines precise sets of
changesets involved in such situations and explains how the error
cases can be resolved automatically using the available information.


Obsolete changesets
````````````````````

Old changesets left behind by obsolete operation are called **obsolete**.

With the current version of mercurial, this *obsolete* part is stripped from the
repository before the end of every rewriting operation.

.. figure:: ./figures/error-obsolete.*

    Rebasing `B` and `C` on `A` (as `B'`, `C'`)

    This rebase operation added two obsolete markers from new
    changesets to old changesets. These two old changesets are now
    part of the *obsolete* part of the history.

In most cases, the obsolete set will be fully hidden to both the UI and
discovery, hence users do not have to care about them unless they want to
audit history rewriting operations.

Unstable changesets
```````````````````

While exploring the possibilities of the obsolete marker a bit
further, you may end up with *obsolete* changesets which have
*non-obsolete* children. There is two common ways to achieve this:

* Pull a changeset based of an old version of a changeset [#]_.

* Use a partial rewriting operation. For example amend on a changeset with
  children.

*Non-obsolete* changeset based on *obsolete* one are called **unstable**

.. figure:: ./figures/error-unstable.*

    Amend `A` into `A'` leaving `B` behind.

    In this situation we cannot consider `B` as *obsolete*. But we
    have all the necessary data to detect `B` as an *unstable* branch
    of the history because its parent `A` is *obsolete*. In addition,
    we have enough data to automatically resolve this instability: we
    know that the new version of `B` parent (`A`) is `A'`. We can
    deduce that we should rebase `B` on `A'` to get a stable history
    again.

Proper warnings should be issued when part of the history becomes
unstable. The UI will be able to use the obsolete marker to
automatically suggest a resolution to the user of even carry them out
for them.


XXX details on automatic resolution for

* movement

* handling deletion

* handling split on multiple head


.. [#] For this to happen one needs to explicitly enable exchange of draft
       changesets. See phase help for details.

The two parts of the obsolete set
``````````````````````````````````````

The previous section shows that there could be two kinds of *obsolete*
changesets:

* an *obsolete* changeset with no or *obsolete* only descendants is called **extinct**.

* an *obsolete* changeset with *unstable* descendants is called **suspended**.


.. figure:: ./figures/error-extinct.*

    Amend `A` and `C` leaving `B` behind.

    In this example we have two *obsolete* changesets: `C` with no *unstable*
    children is *extinct*. `A` with *unstable* descendant (`B`) is *suspended*.
    `B` is *unstable* as before.


Because nothing outside the obsolete set default on *extinct*
changesets, they can be safely hidden in the UI and even garbage
collected. *Suspended* changesets have to stay visible and available
until their unstable descendant are rewritten into stable version.


Conflicting rewrites
````````````````````

If people start to concurrently edit the same part of the history they will
likely meet conflicting situations when a changeset has been rewritten in two
different ways.


.. figure:: ./figures/error-conflicting.*

    Conflicting rewrite of `A` into `A'` and `A''`

This kind of conflict is easy to detect with an obsolete marker
because an obsolete changeset can have more than one new version. It
may be seen as the multiple heads case. Mercurial warns you about this
on pull. It is resolved the same way by a merge of A' and A'' that
will keep the same parent than `A'` and `A''` with two obsolete
markers pointing to both `A` and `A'`

.. figure:: ./figures/explain-troubles-concurrent-10-solution.*

Allowing multiple new changesets to obsolete a single one allows to
distinguish a split changeset from a history rewriting conflict.

Reliable history
``````````````````````

Obsolete markers help to smooth rewriting operation process. However
they do not change the fact that **you should only rewrite the mutable
part of the history**. The phase concept enforces this rule by
explicitly defining a public immutable set of changesets. Rewriting
operations refuse to work on public changesets, but there are still
some corner cases where previously rewritten changesets are made
public.

Special rules apply for obsolete markers pointing to public changesets:

* Public changesets are excluded from the obsolete set (public
  changesets are never hidden or candidate to garbage collection)

* *newer* version of a public changeset are called **bumped** and
  highlighted as an error case.

.. figure:: ./figures/explain-troubles-concurrent-10-sumup.*

Solving such an error is easy. Because we know what changeset a
*bumped* tries to rewrite, we can easily compute a smaller
changeset containing only the change from the old *public* to the new
*bumped*.

.. figure:: ./figures/explain-troubles-concurrent-15-solution.*


Conclusion
----------------

The obsolete marker is a powerful concept that allows mercurial to safely handle
history rewriting operations. It is a new type of relation between Mercurial
changesets which tracks the result of history rewriting operations.

This concept is simple to define and provides a very solid base for:


- Very fast history rewriting operations,

- auditable and reversible history rewriting process,

- clean final history,

- sharing and collaborating on the mutable part of the history,

- gracefully handling history rewriting conflicts,

- various history rewriting UI's collaborating with an underlying common API.

.. list-table:: Comparison on solution [#]_
   :header-rows: 1

   * - Solution
     - Remove changeset locally
     - Works on any point of your history
     - Propagation
     - Collaboration
     - Speed
     - Access to older version

   * - Strip
     - `+`
     - `+`
     - \
     - \ 
     - \ 
     - `- -`

   * - Reference
     - `+`
     - \ 
     - `+`
     - \ 
     - `+`
     - `-`

   * - Obsolete
     - `+`
     - `+`
     - `++`
     - `++`
     - `+`
     - `+`



.. [#] To preserve good tradition in comparison table, an overwhelming advantage
       goes to the defended solution.
