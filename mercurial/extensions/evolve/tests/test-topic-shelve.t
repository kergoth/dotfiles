testing topic with shelve extension
------------------------------------

  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ hg init repo
  $ cd repo
  $ cat <<EOF >>.hg/hgrc
  > [extensions]
  > shelve=
  > EOF

  $ touch a
  $ echo "Hello" >> a
  $ hg topic "testing-shelve"
  $ hg topic
   * testing-shelve
  $ hg ci -m "First commit" -A
  adding a
  $ hg topic
   * testing-shelve
  $ echo " World" >> a
  $ hg stack
  ### topic: testing-shelve
  ### branch: default
  t1@ First commit (current)

shelve test
-----------

  $ hg shelve
  shelved as default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic
   * testing-shelve
  $ hg stack
  ### topic: testing-shelve
  ### branch: default
  t1@ First commit (current)

unshelve test
-------------
  $ hg unshelve
  unshelving change 'default'
  $ hg topic
   * testing-shelve
  $ hg stack
  ### topic: testing-shelve
  ### branch: default
  t1@ First commit (current)
