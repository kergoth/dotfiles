
  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [experimental]
  > obsmarkers-exchange-debug=true
  > bundle2-exp=true
  > [ui]
  > ssh=python "$RUNTESTDIR/dummyssh"
  > [phases]
  > publish = False
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

setup repo

  $ hg init server

  $ hg clone ssh://user@dummy/server client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cp -r client other

Smoke testing
===============.t

  $ cd client
  $ mkcommit 0
  $ mkcommit a
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  $ hg pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found
  $ hg pull -R ../other
  pulling from ssh://user@dummy/server
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  new changesets 8685c6d34325:4957bfdac07e
  (run 'hg update' to get a working copy)
  $ hg push -R ../other
  pushing to ssh://user@dummy/server
  searching for changes
  no changes found
  [1]

Push
=============

  $ echo 'A' > a
  $ hg amend
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  remote: obsmarker-exchange: 92 bytes received
  remote: 1 new obsolescence markers
  remote: obsoleted 1 changesets
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  no changes found
  [1]

Pull
=============

  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to [12] files \(\+1 heads\) (re)
  obsmarker-exchange: 92 bytes received
  1 new obsolescence markers
  obsoleted 1 changesets
  new changesets 9d1c114e7797
  (run 'hg heads' to see heads)
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found

Test some markers discovery
===========================

  $ echo c > C
  $ hg add C
  $ hg commit -m C
  $ echo c >> C
  $ hg amend
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: obsmarker-exchange: 92 bytes received
  remote: 1 new obsolescence markers
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  obsmarker-exchange: 92 bytes received
  1 new obsolescence markers
  new changesets a5687ec59dd4
  (run 'hg update' to get a working copy)

some common hidden

  $ hg touch .
  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 0 changes to 1 files (+1 heads)
  remote: obsmarker-exchange: 167 bytes received
  remote: 1 new obsolescence markers
  remote: obsoleted 1 changesets
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 1 files (+1 heads)
  obsmarker-exchange: 167 bytes received
  1 new obsolescence markers
  obsoleted 1 changesets
  new changesets * (glob)
  (run 'hg heads' to see heads)

test discovery avoid exchanging known markers

  $ hg push
  pushing to ssh://user@dummy/server
  searching for changes
  no changes found
  [1]
  $ hg -R ../other pull
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found

test discovery can be disabled

  $ hg push --config experimental.evolution.obsdiscovery=no
  pushing to ssh://user@dummy/server
  searching for changes
  (skipping discovery of obsolescence markers, will exchange everything)
  (controled by 'experimental.evolution.obsdiscovery' configuration)
  no changes found
  remote: obsmarker-exchange: 258 bytes received
  [1]
  $ hg -R ../other pull --config experimental.evolution.obsdiscovery=no
  pulling from ssh://user@dummy/server
  searching for changes
  no changes found
  (skipping discovery of obsolescence markers, will exchange everything)
  (controled by 'experimental.evolution.obsdiscovery' configuration)
  obsmarker-exchange: 258 bytes received

  $ cd ..

And disable it server side too:

  $ hg serve -R server -n test -p $HGPORT -d --pid-file=hg.pid -A access.log -E errors.log  --config experimental.evolution.obsdiscovery=no
  $ cat hg.pid >> $DAEMON_PIDS

  $ curl -s http://localhost:$HGPORT/?cmd=capabilities
  _evoext_getbundle_obscommon batch branchmap bundle2=HG20%0Achangegroup%3D01%2C02%0Adigests%3Dmd5%2Csha1%2Csha512%0Aerror%3Dabort%2Cunsupportedcontent%2Cpushraced%2Cpushkey%0Ahgtagsfnodes%0Alistkeys%0Aobsmarkers%3DV0%2CV1%0Aphases%3Dheads%0Apushkey%0Aremote-changegroup%3Dhttp%2Chttps changegroupsubset compression=zstd,zlib getbundle httpheader=1024 httpmediatype=0.1rx,0.1tx,0.2tx known lookup pushkey streamreqs=generaldelta,revlogv1 unbundle=HG10GZ,HG10BZ,HG10UN unbundlehash (no-eol)

Check we cannot use pushkey for marker exchange anymore

  $ hg debugpushkey http://localhost:$HGPORT/ obsolete
  abort: HTTP Error 410: won't exchange obsmarkers through pushkey
  [255]
  $ hg debugpushkey ssh://user@dummy/server obsolete
  remote: abort: won't exchange obsmarkers through pushkey
  remote: (upgrade your client or server to use the bundle2 protocol)
  abort: unexpected response: empty string
  [255]

(do some extra pulling to be sure)

  $ hg -R client pull http://localhost:$HGPORT/
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found
  obsmarker-exchange: 258 bytes received

  $ hg -R client pull http://localhost:$HGPORT/ --config experimental.evolution=createmarkers
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found

  $ hg -R client pull http://localhost:$HGPORT/ --config experimental.evolution=createmarkers --config extensions.evolve='!'
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found

But we do let it goes fine on repository with exchange disabled:

  $ $RUNTESTDIR/killdaemons.py $DAEMON_PIDS
  $ hg serve -R server -n test -p $HGPORT -d --pid-file=hg.pid -A access.log -E errors.log  --config experimental.evolution='!'
  $ hg debugpushkey http://localhost:$HGPORT/ obsolete

(do some extra pulling to be sure)

  $ hg -R client pull http://localhost:$HGPORT/
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found

  $ hg -R client pull http://localhost:$HGPORT/ --config experimental.evolution=createmarkers
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found

  $ hg -R client pull http://localhost:$HGPORT/ --config experimental.evolution=createmarkers --config extensions.evolve='!'
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found

  $ $RUNTESTDIR/killdaemons.py $DAEMON_PIDS
