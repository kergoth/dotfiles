
  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [experimental]
  > bundle2-exp=False # < Mercurial-4.0
  > [devel]
  > legacy.exchange=bundle1
  > [extensions]
  > EOF

  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

setup repo

  $ hg init server
  $ echo "[extensions]" >> ./server/.hg/hgrc
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/simple4server.py" >> ./server/.hg/hgrc
  $ hg serve -R server -n test -p $HGPORT -d --pid-file=hg.pid -A access.log -E errors.log
  $ cat hg.pid >> $DAEMON_PIDS

  $ hg clone http://localhost:$HGPORT/ client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat ./errors.log
  $ echo "[extensions]" >> ./client/.hg/hgrc
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> ./client/.hg/hgrc
  $ cp -r client other

Smoke testing
===============

  $ cd client
  $ mkcommit 0
  $ mkcommit a
  $ hg push
  pushing to http://localhost:$HGPORT/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 2 changesets with 2 changes to 2 files
  $ hg pull
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found
  $ cat ../errors.log
  $ hg pull -R ../other
  pulling from http://localhost:$HGPORT/
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  pull obsolescence markers
  (run 'hg update' to get a working copy)
  $ cat ../errors.log
  $ hg push -R ../other
  pushing to http://localhost:$HGPORT/
  searching for changes
  no changes found
  [1]
  $ cat ../errors.log

Capacity testing
===================

  $ wget -q -O - http://localhost:$HGPORT/?cmd=hello
  capabilities: * _evoext_pushobsmarkers_0 _evoext_pullobsmarkers_0 _evoext_obshash_0 _evoext_obshash_1 _evoext_getbundle_obscommon (glob)
  $ wget -q -O - http://localhost:$HGPORT/?cmd=capabilities
  * _evoext_pushobsmarkers_0 _evoext_pullobsmarkers_0 _evoext_obshash_0 _evoext_obshash_1 _evoext_getbundle_obscommon (no-eol) (glob)

  $ wget -q -O - "http://localhost:$HGPORT/?cmd=listkeys&namespace=namespaces" | sort
  bookmarks	
  namespaces	
  obsolete	
  phases	

Push
=============

  $ echo 'A' > a
  $ hg amend
  $ hg push
  pushing to http://localhost:$HGPORT/
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files (+1 heads)
  pushing 2 obsolescence markers (* bytes) (glob)
  $ cat ../errors.log
  $ hg push
  pushing to http://localhost:$HGPORT/
  searching for changes
  no changes found
  [1]
  $ cat ../errors.log

Pull
=============

  $ hg -R ../other pull
  pulling from http://localhost:$HGPORT/
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to [12] files \(\+1 heads\) (re)
  pull obsolescence markers
  2 obsolescence markers added
  (run 'hg heads' to see heads)
  $ cat ../errors.log
  $ hg -R ../other pull
  pulling from http://localhost:$HGPORT/
  searching for changes
  no changes found
  $ cat ../errors.log

  $ cd ..

Test disabling obsolete advertisement
===========================================
(used by bitbucket to select which repo use evolve)

  $ wget -q -O - "http://localhost:$HGPORT/?cmd=listkeys&namespace=namespaces" | sort
  bookmarks	
  namespaces	
  obsolete	
  phases	
  $ wget -q -O - http://localhost:$HGPORT/?cmd=hello
  capabilities: * _evoext_pushobsmarkers_0 _evoext_pullobsmarkers_0 _evoext_obshash_0 _evoext_obshash_1 _evoext_getbundle_obscommon (glob)
  $ wget -q -O - http://localhost:$HGPORT/?cmd=capabilities
  * _evoext_pushobsmarkers_0 _evoext_pullobsmarkers_0 _evoext_obshash_0 _evoext_obshash_1 _evoext_getbundle_obscommon (no-eol) (glob)

  $ echo '[__temporary__]' >> server/.hg/hgrc
  $ echo 'advertiseobsolete=False' >> server/.hg/hgrc
  $ $RUNTESTDIR/killdaemons.py $DAEMON_PIDS
  $ hg serve -R server -n test -p $HGPORT -d --pid-file=hg.pid -A access.log -E errors.log
  $ cat hg.pid >> $DAEMON_PIDS

  $ wget -q -O - "http://localhost:$HGPORT/?cmd=listkeys&namespace=namespaces" | sort
  bookmarks	
  namespaces	
  phases	
  $ wget -q -O - http://localhost:$HGPORT/?cmd=hello | grep _evoext_pushobsmarkers_0
  [1]
  $ wget -q -O - http://localhost:$HGPORT/?cmd=capabilities | grep _evoext_pushobsmarkers_0
  [1]

  $ echo 'advertiseobsolete=True' >> server/.hg/hgrc
  $ $RUNTESTDIR/killdaemons.py $DAEMON_PIDS
  $ hg serve -R server -n test -p $HGPORT -d --pid-file=hg.pid -A access.log -E errors.log
  $ cat hg.pid >> $DAEMON_PIDS

  $ wget -q -O - "http://localhost:$HGPORT/?cmd=listkeys&namespace=namespaces" | sort
  bookmarks	
  namespaces	
  obsolete	
  phases	
  $ wget -q -O - http://localhost:$HGPORT/?cmd=hello
  capabilities: * _evoext_pushobsmarkers_0 _evoext_pullobsmarkers_0 _evoext_obshash_0 _evoext_obshash_1 _evoext_getbundle_obscommon (glob)
  $ wget -q -O - http://localhost:$HGPORT/?cmd=capabilities
  * _evoext_pushobsmarkers_0 _evoext_pullobsmarkers_0 _evoext_obshash_0 _evoext_obshash_1 _evoext_getbundle_obscommon (no-eol) (glob)
