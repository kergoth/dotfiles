.. Copyright 2011 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
..                Logilab SA        <contact@logilab.fr>

-----------------------------------
From MQ To Evolve, The Refugee Book
-----------------------------------

Cheat sheet
-----------

==============================  ============================================
mq command                       new equivalent
==============================  ============================================
qseries                         ``log``
qnew                            ``commit``
qrefresh                        ``amend``
qrefresh --exclude              ``uncommit``
qpop                            ``update`` or ``gdown``
qpush                           ``update`` or ``gup`` sometimes ``evolve``
qrm                             ``prune``
qfold                           ``fold``
qdiff                           ``odiff``
qrecord                         ``record``

qfinish                         --
qimport                         --
==============================  ============================================


Replacement details
-------------------

hg qseries
``````````

All your work in progress is now in real changesets all the time.

You can use the standard log command to display them. You can use the
phase revset to display unfinished work only, and use templates to have
the same kind of compact that the output of qseries has.

This will result in something like::

  [alias]
  wip = log -r 'not public()' --template='{rev}:{node|short} {desc|firstline}\n'

hg qnew
```````

With evolve you handle standard changesets without an additional overlay.

Standard changeset are created using hg commit as usual::

  $ hg commit

If you want to keep the "WIP is not pushed" behavior, you want to
set your changeset in the secret phase using the phase command.

Note that you only need it for the first commit you want to be secret. Later
commits will inherit their parent's phase.

If you always want your new commit to be in the secret phase, your should
consider updating your configuration:

  [phases]
  new-commit=secret

hg qref
```````

A new command from evolution will allow you to rewrite the changeset you are
currently on. Just call:

  $ hg amend

This command takes the same options as commit, plus the switch '-e' (--edit)
to edit the commit message in an editor.


.. -c is very confusig
..
.. The amend command also has a -c switch which allows you to make an
.. explicit amending commit before rewriting a changeset.::
..
..   $ hg record -m 'feature A'
..   # oups, I forgot some stuff
..   $ hg record babar.py
..   $ hg amend -c .^ # .^ refer to "working directory parent, here 'feature A'

.. note: refresh is an alias for amend

hg qref --exclude
`````````````````

To remove changes from your current commit use::

  $ hg uncommit not-ready.txt


hg qpop
```````

The following command emulates the behavior of hg qpop:

  $ hg gdown

If you need to go back to an arbitrary commit you can use:

  $ hg update

.. note:: gdown and update allow movement with working directory
          changes applied, and gracefully merge them.

hg qpush
````````

When you rewrite changesets, descendants of rewritten changesets are marked as
"unstable". You need to rewrite them on top of the new version of their
ancestor.

The evolution extension adds a command to rewrite "unstable"
changesets:::

  $ hg evolve

You can also decide to do it manually using::

  $ hg graft -O <old-version>

or::

  $ hg rebase -r <revset for old version> -d .

note: using graft allows you to pick the changeset you want next as the --move
option of qpush do.


hg qrm
``````

evolution introduce a new command to mark a changeset as "not wanted anymore".::

  $ hg prune <revset>

hg qfold
````````


::

  $ hg fold first::last

hg qdiff
````````

``pdiff`` is an alias for `hg diff -r .^` It works like qdiff, but outside MQ.



hg qfinish and hg qimport
`````````````````````````

These are not necessary anymore. If you want to control the
mutability of changesets, see the phase feature.



hg qcommit
``````````

If you really need to send patches through versioned mq patches, you should
look at the qsync extension.
