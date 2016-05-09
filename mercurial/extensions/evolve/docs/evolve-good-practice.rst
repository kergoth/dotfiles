.. Copyright 2011 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
..                Logilab SA        <contact@logilab.fr>

-----------------------------------------
Good practice for (early) users of evolve
-----------------------------------------

Avoid unstability
-----------------

The less unstability you have the less you need to resolve.

Evolve is not yet able to detect and solve every situation. And your mind is
not ready neither.

Branch as much as possible
--------------------------

This is not MQ; you are not constrained to linear history.

Making a branch per independent branch will help you avoid unstability
and conflict.

Rewrite your changes only
-------------------------

There is no descent conflict detection and handling right now.
Rewriting other people's changesets guarantees that you will get
conflicts. Communicate with your fellow developers before trying to
touch other people's work (which is a good practice in any case).

Using multiple branches will help you to achieve this goal.

Prefer pushing unstability to touching other people changesets
--------------------------------------------------------------


If you have children changesets from other people that you don't really care
about, prefer not altering them to risking a conflict by stabilizing them.


Do not get too confident
------------------------

This is an experimental extension and a complex concept. This is beautiful,
powerful and robust on paper, but the tool and your mind may not be prepared for
all situations yet.
