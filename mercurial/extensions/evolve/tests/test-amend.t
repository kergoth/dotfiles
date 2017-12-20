  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ glog() {
  >   hg log -G --template '{rev}@{branch}({phase}) {desc|firstline}\n' "$@"
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
  $ hg amend -d '0 0' -n "this a note on the obsmarker and supported for hg>=4.4"
  $ hg debugobsolete
  07f4944404050f47db2e5c5071e0e84e7a27bba9 6a022cbb61d5ba0f03f98ff2d36319dfea1034ae 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg obslog
  @  6a022cbb61d5 (1) adda
  |
  x  07f494440405 (0) adda
       rewritten(branch) as 6a022cbb61d5 by test (Thu Jan 01 00:00:00 1970 +0000)
         note: this a note on the obsmarker and supported for hg>=4.4
  
  $ hg branch
  foo
  $ hg branches
  foo                            1:6a022cbb61d5
  $ glog
  @  1@foo(draft) adda
  
Test no-op

  $ hg amend -d '0 0'
  nothing changed
  [1]
  $ glog
  @  1@foo(draft) adda
  

Test forcing the message to the same value, no intermediate revision.

  $ hg amend -d '0 0' -m 'adda'
  nothing changed
  [1]
  $ glog
  @  1@foo(draft) adda
  

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
  07f4944404050f47db2e5c5071e0e84e7a27bba9 6a022cbb61d5ba0f03f98ff2d36319dfea1034ae 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg phase 2
  2: draft
  $ glog
  @  3@foo(draft) reseta
  |
  o  2@foo(draft) changea
  |
  o  1@foo(draft) adda
  
Specify precise commit date with -d
  $ hg amend -d '2001-02-03 04:05:06 +0700'
  $ hg parents --template '{rev}  {date|date}\n'
  4  Sat Feb 03 04:05:06 2001 +0700

Specify "now" as commit date with -D
  $ before=`date +%s`
  $ hg amend -D
  $ commit=`hg parents --template '{date|hgdate} rev{rev}\n'`
  $ after=`date +%s`
  $ (echo $before ; echo $commit; echo $after) | sort -k1 -n -s
  \d+ (re)
  \d+ 0 rev5 (re)
  \d+ (re)

Specify current user as committer with -U
  $ HGUSER=newbie hg amend -U
  $ hg parents --template '{rev}  {author}\n'
  6  newbie

Check that --logfile works
  $ echo "logfile message" > logfile.txt
  $ hg amend -l logfile.txt
  $ hg log -r . -T "{desc}\n"
  logfile message

# Make sure we don't get reparented to -1 with no username (issue4211)
  $ HGUSER=
  $ hg amend -e --config ui.username= -m "empty user"
  abort: no username supplied
  (use 'hg config --edit' to set your username)
  [255]
  $ hg sum
  parent: 7:* tip (glob)
   logfile message
  branch: foo
  commit: 1 unknown (clean)
  update: (current)
  phases: 3 draft

Check the help
  $ hg amend -h
  hg amend [OPTION]... [FILE]...
  
  aliases: refresh
  
  combine a changeset with updates and replace it with a new one
  
      Commits a new changeset incorporating both the changes to the given files
      and all the changes from the current parent changeset into the repository.
  
      See 'hg commit' for details about committing changes.
  
      If you don't specify -m, the parent's message will be reused.
  
      If --extract is specified, the behavior of 'hg amend' is reversed: Changes
      to selected files in the checked out revision appear again as uncommitted
      changed in the working directory.
  
      Returns 0 on success, 1 if nothing changed.
  
  options ([+] can be repeated):
  
   -A --addremove           mark new/missing files as added/removed before
                            committing
   -a --all                 match all files
   -e --edit                invoke editor on commit messages
      --extract             extract changes from the commit to the working copy
      --close-branch        mark a branch as closed, hiding it from the branch
                            list
   -s --secret              use the secret phase for committing
   -n --note VALUE          store a note on amend
   -I --include PATTERN [+] include names matching the given patterns
   -X --exclude PATTERN [+] exclude names matching the given patterns
   -m --message TEXT        use text as commit message
   -l --logfile FILE        read commit message from file
   -d --date DATE           record the specified date as commit date
   -u --user USER           record the specified user as committer
   -D --current-date        record the current date as commit date
   -U --current-user        record the current user as committer
   -i --interactive         use interactive mode
  
  (some details hidden, use --verbose to show complete help)
