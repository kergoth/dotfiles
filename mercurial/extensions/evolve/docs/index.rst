.. Copyright © 2014 Greg Ward <greg@gerg.ca>

==================================
Changeset Evolution with Mercurial
==================================

`evolve`_ is a Mercurial extension for faster and safer mutable history. It
implements the `changeset evolution`_ concept for `Mercurial`_.

* It offers a safe and simple way to refine changesets locally and propagate
  those changes to other repositories.

* It can automatically detect and handle the complex issues that can arise from
  exchanging draft changesets.

* It even makes it possible for multiple developers to safely rewrite the same
  parts of history in a distributed way.

* It fully respects the Phases concept so users will only be able to rewrite
  parts of the history that are safe to change. Phases have been part of
  Mercurial since early 2012.

.. _`evolve`: https://www.mercurial-scm.org/wiki/EvolveExtension
.. _`Mercurial`: https://www.mercurial-scm.org/

Installation and setup
----------------------

We recommend you subscribe to the `evolve-testers`_ mailing list to stay up
to date with the latest news and announcement.

.. _`evolve-testers`: https://www.mercurial-scm.org/mailman/listinfo/evolve-testers

Using pip::

    pip install --user hg-evolve

Then add in your `hgrc` config::

   [extensions]
   evolve=

You can easily edit the `hgrc` of a repository using `hg config --local`.
Alternatively, you can edit your user configuration with `hg config --edit`.

Table of Contents
-----------------

.. toctree::
   :maxdepth: 2

   index
   user-guide
   sharing
   concepts
   from-mq
   commands
   known-doc-issues

.. _`changeset evolution`:

What is Changeset Evolution?
----------------------------

With core Mercurial, changesets are permanent and immutable. You can
commit new changesets to modify your source code, but you cannot
modify or remove old changesets.

For years, Mercurial has included various commands that allow
history modification: ``rebase``, ``histedit``, ``commit --amend`` and so forth.
However, there's a catch: until now, Mercurial's various mechanisms for
modifying history have been *unsafe*, in that changesets were
destroyed (“stripped”) rather than simply hidden and still easy to recover.

``evolve`` makes things better by changing the behaviour of most existing
history modification commands so they use a safer mechanism (*changeset
obsolescence*, covered below) rather than the older, less safe *strip*
operation.

``evolve`` is built on infrastructure in core Mercurial:

  * *Phases* (starting in Mercurial 2.1) allow you to distinguish
    mutable and immutable changesets.

  * *Changeset obsolescence* (starting in Mercurial 2.3) is how
    Mercurial knows how history has been modified, specifically when
    one changeset replaces another. In the obsolescence model, a
    changeset is neither removed nor modified, but is instead marked
    *obsolete* and typically replaced by a *successor*. Obsolete
    changesets usually become *hidden* as well. Obsolescence is a
    disabled feature in Mercurial until you start using ``evolve``.

Some of the things you can do with ``evolve`` are:

  * Fix a mistake immediately: “Oops! I just committed a changeset
    with a syntax error—I'll fix that and amend the changeset so no
    one sees my mistake.” (While this is possible using default
    features of core Mercurial, changeset evolution makes it safer.)

  * Fix a mistake a little bit later: “Oops! I broke the tests three
    commits back, but only noticed it now—I'll just update back to the
    bad changeset, fix my mistake, amend the changeset, and evolve
    history to update the affected changesets.”

  * Remove unwanted changes: “I hacked in some debug output two
    commits back; everything is working now, so I'll just prune that
    unwanted changeset and evolve history before pushing.”

  * Share mutable history with yourself: say you do most of your
    programming work locally, but need to test on a big remote server
    somewhere before you know everything is good. You can use
    ``evolve`` to share mutable history between two computers, pushing
    finely polished changesets to a public repository only after
    testing on the test server.

  * Share mutable history for code review: you don't want to publish
    unreviewed changesets, but you can't block every commit waiting
    for code review. The solution is to share mutable history with
    your reviewer, amending each changeset until it passes review.

  * Explore and audit the rewrite history of a changeset. Since Mercurial is
    tracking the edits you make to a changeset, you can look at the history of
    these edits. This is similar to Mercurial tracking the history of file
    edits, but at the changeset level.

Why the `evolve` extension?
---------------------------

Mercurial core already has some support for `changeset evolution`_ so why have a
dedicated extension?

The long-term plan for ``evolve`` is to add it to core Mercurial. However,
having the extension helps us experiment with various user experience
approaches and technical prototypes. Having a dedicated extension helps current
users deploy the latest changes quickly and provides developers with low latency
feedback.

Whenever we are happy with a experimental direction in the extension, the
relevant code can go upstream into Core Mercurial.

Development status
------------------

While well underway, the full implementation of the `changeset evolution`_
concept is still a work in progress. Core Mercurial already supports many of the
associated features, but for now they are still disabled by default. The current
implementation has been usable for multiple years already, and some parts of it
are used in production by multiple projects and companies (including the
Mercurial project itself, Facebook, Google, etc…).

However, there are still some areas were the current implementation has gaps.
This means some use cases or performance issues are not handled as well as they
currently are without evolution. Mercurial has been around for a long time and
is strongly committed to backward compatibility. Therefore turning evolution on
by default today could regress the experience of some of our current users. The
features will only be enabled by default at the point where users who do not use
or care about the new features added by evolution won't be negatively impacted
by the new default.

You can find the `evolution roadmap in the wiki`_.

.. # .. _`this query`: https://bz.mercurial-scm.org/buglist.cgi?component=evolution&bug_status=UNCONFIRMED&bug_status=CONFIRMED&bug_status=NEED_EXAMPLE

Resources
---------

  * For a practical guide to using ``evolve`` in a single repository,
    see the `user guide`_.
  * For more advanced tricks, see `sharing mutable history`_.
  * To learn about the concepts underlying ``evolve``, see `concepts`_
    (incomplete).
  * If you're coming from MQ, see the `MQ migration guide`_ (incomplete).

.. _`user guide`: user-guide.html
.. _`sharing mutable history`: sharing.html
.. _`concepts`: concepts.html
.. _`MQ migration guide`: from-mq.html
.. _`evolution roadmap in the wiki`: https://www.mercurial-scm.org/wiki/CEDRoadMap
