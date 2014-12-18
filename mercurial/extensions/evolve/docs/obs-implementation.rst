.. Copyright 2011 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
..                Logilab SA        <contact@logilab.fr>

-----------------------------------------------------
Implementation of Obsolete Marker
-----------------------------------------------------
.. warning:: This document is still in heavy work in progress

Main questions about Obsolete Marker Implementation
-----------------------------------------------------




How shall we exchange Marker over the Wire ?
`````````````````````````````````````````````````````````

We can have a lot of markers. We do not want to exchange data for the one we
already know. Listkey() is not very appropriate there as you get everything.

Moreover, we might want to only hear about Marker that impact changeset we are
pulling.

pushkey is not batchable yet (could be fixed)

A dedicated discovery and exchange protocol seems mandatory here.


Various technical details
-----------------------------------------------------

Some stuff that worse to note. some may deserve their own section later.

storing old changeset
``````````````````````

The new general delta format allows a very efficient storage of two very similar
changesets. Storing obsolete children using general delta takes no more place
than storing the obsolete diff. Reverted file will even we reused. The whole
operation will take much less space the strip backup.


Abstraction from history rewriting UI
```````````````````````````````````````````

How Mercurial handles obsolete marker is independent from what decides
to create them and what actual operation solves the error case. Any of
the existing history rewriting UI (rebase, mq, histedit) can lay
obsolete markers and resolve situation created by others. To go
further, a hook system of obsolete marker creation would allow each
mechanism to collaborate with other though a standard and central
mechanism.


Obsolete marker storage
```````````````````````````

The Obsolete marker will most likely be stored outside standard
history. They are multiple reasons for this:

First, obsolete markers are really perpendicular to standard history
there is no strong reason to include it here other than convenience.

Second, storing obsolete marker inside standard history means:

* A changeset must be created every time an obsolete relation is added. Very
  inconvenient for delete operation.

* Obsolete marker must be forged at the creation of the new changeset. This
  is very inconvenient for split operation. And in general it becomes
  complicated to fix history afterward in particular when working with older
  clients.

Storing obsolete marker outside history have several pros:

* It eases Exchange of obsolete markers without unnecessary obsolete
  changeset contents.

* It allows tuning the actual storage and protocol exchange while maintaining
  compatibility with older clients through the wire (as we do the repository
  format).

* It eases the exchange of obsolete related information during
  discovery to exchange obsolete changeset relevant to conflict
  resolution. Exchanging such information deserves a dedicated
  protocol.

Persistent
```````````````````````

*Extinct* changeset and obsolete marker will most likely be garbage collected as
some point. However, archive server may decide to keep them forever in order to
keep a fully auditable history in its finest conception.


Current status
-----------------------------------------------------

Obsolete marker are partialy in core.

2.3:

- storage over obsolete marker
- exchange suing pushkey
- extinct changeset are properly hidden
- extinct changeset are excluded from exchange
