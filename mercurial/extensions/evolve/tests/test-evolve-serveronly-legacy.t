
  $ . ${TESTDIR}/testlib/pythonpath.sh

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


  $ hg init server

Try the multiple ways to setup the extension

  $ hg -R server log --config 'extensions.evolve.serveronly='
  $ hg -R server log --config "extensions.evolve.serveronly=${SRCDIR}/hgext3rd/evolve/serveronly.py"
  $ PYTHONPATH=$HGTEST_ORIG_PYTHONPATH hg -R server log --config "extensions.evolve.serveronly=${SRCDIR}/hgext3rd/evolve/serveronly.py"

setup repo

  $ echo "[extensions]" >> ./server/.hg/hgrc
  $ echo "evolve.serveronly=" >> ./server/.hg/hgrc
  $ hg serve -R server -n test -p $HGPORT -d --pid-file=hg.pid -A access.log -E errors.log --traceback
  $ cat hg.pid >> $DAEMON_PIDS

  $ hg clone http://localhost:$HGPORT/ client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat ./errors.log
  $ echo "[extensions]" >> ./client/.hg/hgrc
  $ echo "evolve=" >> ./client/.hg/hgrc
  $ cp -r client other

Smoke testing
===============

  $ cd client
  $ mkcommit 0
  $ mkcommit a
  $ hg push
  pushing to http://localhost:$HGPORT/
  searching for changes
  abort: remote error:
  incompatible Mercurial client; bundle2 required
  (see https://www.mercurial-scm.org/wiki/IncompatibleClient)
  [255]
  $ cat ../errors.log
