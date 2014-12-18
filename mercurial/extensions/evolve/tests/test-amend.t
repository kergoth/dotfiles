  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext/evolve.py" >> $HGRCPATH

  $ glog() {
  >   hg glog --template '{rev}@{branch}({phase}) {desc|firstline}\n' "$@"
  > }

  $ hg init repo --traceback
  $ cd repo
  $ echo a > a
  $ hg ci -Am adda
  adding a

Test that amend captures branches

  $ hg branch foo
  marked working directory as branch foo
  (branches are permanent and global, did you want a bookmark?)
  $ hg amend -d '0 0'
  $ hg debugobsolete
  07f4944404050f47db2e5c5071e0e84e7a27bba9 6a022cbb61d5ba0f03f98ff2d36319dfea1034ae 0 (*) {'user': 'test'} (glob)
  b2e32ffb533cbe1d5759638c0cd4e8abc43b2738 0 {07f4944404050f47db2e5c5071e0e84e7a27bba9} (*) {'user': 'test'} (glob)
  $ hg branch
  foo
  $ hg branches
  foo                            2:6a022cbb61d5
  $ glog
  @  2@foo(draft) adda
  
Test no-op

  $ hg amend -d '0 0'
  nothing changed
  [1]
  $ glog
  @  2@foo(draft) adda
  

Test forcing the message to the same value, no intermediate revision.

  $ hg amend -d '0 0' -m 'adda'
  nothing changed
  [1]
  $ glog
  @  2@foo(draft) adda
  

Test collapsing into an existing revision, no intermediate revision.

  $ echo a >> a
  $ hg ci -m changea
  $ echo a > a
  $ hg status
  M a
  $ hg pstatus
  $ hg diff
  diff -r f7a50201fe3a a
  --- a/a	Thu Jan 01 00:00:00 1970 +0000
  +++ b/a	* +0000 (glob)
  @@ -1,2 +1,1 @@
   a
  -a
  $ hg pdiff
  $ hg ci -m reseta
  $ hg debugobsolete
  07f4944404050f47db2e5c5071e0e84e7a27bba9 6a022cbb61d5ba0f03f98ff2d36319dfea1034ae 0 (*) {'user': 'test'} (glob)
  b2e32ffb533cbe1d5759638c0cd4e8abc43b2738 0 {07f4944404050f47db2e5c5071e0e84e7a27bba9} (*) {'user': 'test'} (glob)
  $ hg phase 2
  2: draft
  $ glog
  @  4@foo(draft) reseta
  |
  o  3@foo(draft) changea
  |
  o  2@foo(draft) adda
  
Specify precise commit date with -d
  $ hg amend -d '2001-02-03 04:05:06 +0700'
  $ hg parents --template '{rev}  {date|date}\n'
  5  Sat Feb 03 04:05:06 2001 +0700

Specify "now" as commit date with -D
  $ before=`date +%s`
  $ hg amend -D
  $ commit=`hg parents --template '{date|hgdate} rev{rev}\n'`
  $ after=`date +%s`
  $ (echo $before ; echo $commit; echo $after) | sort -k1 -n -s
  \d+ (re)
  \d+ 0 rev6 (re)
  \d+ (re)

Specify current user as committer with -U
  $ HGUSER=newbie hg amend -U
  $ hg parents --template '{rev}  {author}\n'
  7  newbie

Check that --logfile works
  $ echo "logfile message" > logfile.txt
  $ hg amend -l logfile.txt
  $ hg log -r . -T "{desc}\n"
  logfile message

# Make sure we don't get reparented to -1 with no username (issue4211)
  $ HGUSER=
  $ hg amend -e --config ui.username= -m "empty user"
  abort: no username supplied
  (use "hg config --edit" to set your username)
  [255]
  $ hg sum
  parent: 8:* tip (glob)
   logfile message
  branch: foo
  commit: 1 unknown (clean)
  update: (current)
