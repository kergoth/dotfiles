.. Copyright 2011 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
..                Logilab SA        <contact@logilab.fr>

---------------------------------------------------------------------
Qsync: Mercurial to MQ exporter
---------------------------------------------------------------------


People may have tools or co-workers that expect to receive mutable history using
a versioned MQ repository.

For this purpose you can use the ``qsync`` extension.


To enable the evolve extension use::

    $ hg clone http://hg-dev.octopoid.net/hgwebdir.cgi/mutable-history/
    $ mutable-history/iqsync-enable.sh >> ~/.hgrc
    $ hg help qsync
