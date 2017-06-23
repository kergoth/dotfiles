.. Copyright © 2014 Greg Ward <greg@gerg.ca>

==================================
Changeset Evolution with Mercurial
==================================

.. toctree::
   :maxdepth: 2

   user-guide
   sharing
   concepts
   from-mq

`evolve`_ is an experimental Mercurial extension for safe mutable history.

.. _`evolve`: https://www.mercurial-scm.org/wiki/EvolveExtension

With core Mercurial, changesets are permanent and immutable. You can
commit new changesets to modify your source code, but you cannot
modify or remove old changesets—they are carved in stone for all
eternity.

For years, Mercurial has included various extensions that allow
history modification: ``rebase``, ``mq``, ``histedit``, and so forth.
These are useful and popular extensions, and in fact history
modification is one of the big reasons DVCSes (distributed version
control systems) like Mercurial took off.

But there's a catch: until now, Mercurial's various mechanisms for
modifying history have been *unsafe*, in that changesets were
destroyed (“stripped”) rather than simply made invisible.

``evolve`` makes things better in a couple of ways:

  * It changes the behaviour of most existing history modification
    extensions (``rebase``, ``histedit``, etc.) so they use a safer
    mechanism (*changeset obsolescence*, covered below) rather than
    the older, less safe *strip* operation.

  * It provides a new way of modifying history that is roughly
    equivalent to ``mq`` (but much nicer and safer).

It helps to understand that ``evolve`` builds on infrastructure
already in core Mercurial:

  * *Phases* (starting in Mercurial 2.1) allow you to distinguish
    mutable and immutable changesets. We'll cover phases early in the
    user guide, since understanding phases is essential to
    understanding ``evolve``.

  * *Changeset obsolescence* (starting in Mercurial 2.3) is how
    Mercurial knows how history has been modified, specifically when
    one changeset replaces another. In the obsolescence model, a
    changeset is neither removed nor modified, but is instead marked
    *obsolete* and typically replaced by a *successor*. Obsolete
    changesets usually become *hidden* as well. Obsolescence is an
    invisible feature until you start using ``evolve``, so we'll cover
    it in the user guide too.

Some of the things you can do with ``evolve`` are:

  * Fix a mistake immediately: “Oops! I just committed a changeset
    with a syntax error—I'll fix that and amend the changeset so no
    one sees my mistake.” (While this is possible using existing
    features of core Mercurial, ``evolve`` makes it safer.)

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

``evolve`` is experimental!
---------------------------

The long-term plan for ``evolve`` is to add it to core Mercurial.
However, it is not yet stable enough for that. In particular:

  * The UI is unstable: ``evolve``'s command names and command options
    are not completely nailed down yet. They are subject to occasional
    backwards-incompatible changes. If you write scripts that use
    evolve commands, a future release could break your scripts.

  * There are still some corner cases that aren't handled yet. If you
    think you have found such a case, please check if it's already
    described in the Mercurial bug tracker (https://bz.mercurial-scm.org/).
    Bugs in ``evolve`` are files under component "evolution": use
    `this query`_ to view open bugs in ``evolve``.

.. _`this query`: https://bz.mercurial-scm.org/buglist.cgi?component=evolution&bug_status=UNCONFIRMED&bug_status=CONFIRMED&bug_status=NEED_EXAMPLE

Installation and setup
----------------------

To use ``evolve``, you must:

  #. Clone the ``evolve`` repository::

       cd ~/src
       hg clone https://www.mercurial-scm.org/repo/evolve

  #. Configure the extension, either locally ::

       hg config --local

     or for all your repositories ::

       hg config --edit

     Then add ::

       evolve=~/src/evolve-main/hgext3rd/evolve/

     in the ``[extensions]`` section (adding the section if necessary). Use
     the directory that you actually cloned to, of course.


Next steps:
-----------

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
