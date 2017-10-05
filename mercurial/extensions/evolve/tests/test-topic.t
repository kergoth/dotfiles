  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ hg init pinky --traceback
  $ cd pinky
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > # disable the new graph style until we drop 3.7 support
  > graphstyle.missing = |
  > EOF

  $ hg help topics
  hg topics [TOPIC]
  
  View current topic, set current topic, change topic for a set of revisions, or
  see all topics.
  
      Clear topic on existing topiced revisions:
  
        hg topics --rev <related revset> --clear
  
      Change topic on some revisions:
  
        hg topics <newtopicname> --rev <related revset>
  
      Clear current topic:
  
        hg topics --clear
  
      Set current topic:
  
        hg topics <topicname>
  
      List of topics:
  
        hg topics
  
      List of topics sorted according to their last touched time displaying last
      touched time and the user who last touched the topic:
  
        hg topics --age
  
      The active topic (if any) will be prepended with a "*".
  
      The '--current' flag helps to take active topic into account. For example,
      if you want to set the topic on all the draft changesets to the active
      topic, you can do: 'hg topics -r "draft()" --current'
  
      The --verbose version of this command display various information on the
      state of each topic.
  
  options ([+] can be repeated):
  
      --clear       clear active topic if any
   -r --rev REV [+] revset of existing revisions
   -l --list        show the stack of changeset in the topic
      --age         show when you last touched the topics
      --current     display the current topic only
  
  (some details hidden, use --verbose to show complete help)
  $ hg topics

Test topics interaction with evolution:

  $ hg topics --config experimental.evolution=
  $ hg topics --config experimental.evolution= --rev . bob
  abort: must have obsolete enabled to change topics
  [255]

Create some changes:

  $ for x in alpha beta gamma delta ; do
  >   echo file $x >> $x
  >   hg addremove
  >   hg ci -m "Add file $x"
  > done
  adding alpha
  adding beta
  adding gamma
  adding delta

Still no topics
  $ hg topics
  $ hg topics --current
  no active topic
  [1]
  $ hg topics --current somerandomtopic
  abort: cannot use --current when setting a topic
  [255]
  $ hg topics --current --clear
  abort: cannot use --current and --clear
  [255]
  $ hg topics --clear somerandomtopic
  abort: cannot use --clear when setting a topic
  [255]

Trying some invalid topicnames

  $ hg topic '.'
  abort: the name '.' is reserved
  [255]
  $ hg topic null
  abort: the name 'null' is reserved
  [255]
  $ hg topic tip
  abort: the name 'tip' is reserved
  [255]
  $ hg topic 12345
  abort: cannot use an integer as a name
  [255]
  $ hg topic '   '
  abort: topic name cannot consist entirely of whitespaces
  [255]

Test commit flag and help text

  $ echo stuff >> alpha
  $ HGEDITOR=cat hg ci -t topicflag
  
  
  HG: Enter commit message.  Lines beginning with 'HG:' are removed.
  HG: Leave message empty to abort commit.
  HG: --
  HG: user: test
  HG: topic 'topicflag'
  HG: branch 'default'
  HG: changed alpha
  abort: empty commit message
  [255]
  $ hg revert alpha
  $ hg topic
   * topicflag

Make a topic

  $ hg topic narf
  $ hg topics
   * narf
  $ hg topics -v
   * narf (on branch: default, 0 changesets)
  $ hg stack
  ### topic: narf
  ### target: default (branch)
  (stack is empty)
  t0^ Add file delta (base)

Add commits to topic

  $ echo topic work >> alpha
  $ hg ci -m 'start on narf'
  active topic 'narf' grew its first changeset
  $ hg co .^
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic fran
  marked working directory as topic: fran
  $ hg topics
   * fran
     narf
  $ hg topics --current
  fran
  $ echo >> fran work >> beta
  $ hg ci -m 'start on fran'
  active topic 'fran' grew its first changeset
  $ hg co narf
  switching to topic narf
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic
     fran
   * narf
  $ hg log -r . -T '{topics}\n'
  narf
  $ echo 'narf!!!' >> alpha
  $ hg ci -m 'narf!'
  $ hg log -G
  @  changeset:   6:7c34953036d6
  |  tag:         tip
  |  topic:       narf
  |  parent:      4:fb147b0b417c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     narf!
  |
  | o  changeset:   5:0469d521db49
  | |  topic:       fran
  | |  parent:      3:a53952faf762
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     start on fran
  | |
  o |  changeset:   4:fb147b0b417c
  |/   topic:       narf
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     start on narf
  |
  o  changeset:   3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file delta
  |
  o  changeset:   2:15d1eb11d2fa
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file gamma
  |
  o  changeset:   1:c692ea2c9224
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file beta
  |
  o  changeset:   0:c2b7d2f7d14b
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Add file alpha
  

Exchanging of topics:
  $ cd ..
  $ hg init brain
  $ hg -R pinky push -r 4 brain
  pushing to brain
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 5 changesets with 5 changes to 4 files

Export

  $ hg -R pinky export
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID 7c34953036d6a36eae468c550d0592b89ee8bffc
  # Parent  fb147b0b417c25ca15547cd945acf51cf8dcaf02
  # EXP-Topic narf
  narf!
  
  diff -r fb147b0b417c -r 7c34953036d6 alpha
  --- a/alpha	Thu Jan 01 00:00:00 1970 +0000
  +++ b/alpha	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,2 +1,3 @@
   file alpha
   topic work
  +narf!!!

Import

  $ hg -R pinky export > narf.diff
  $ hg -R pinky --config extensions.strip= strip .
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  saved backup bundle to $TESTTMP/pinky/.hg/strip-backup/7c34953036d6-1ff3bae2-backup.hg (glob)
  $ hg -R pinky import narf.diff
  applying narf.diff
  $ hg -R pinky log -r .
  changeset:   6:7c34953036d6
  tag:         tip
  topic:       narf
  parent:      4:fb147b0b417c
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     narf!
  
Now that we've pushed to brain, the work done on narf is no longer a
draft, so we won't see that topic name anymore:

  $ hg log -R pinky -G
  @  changeset:   6:7c34953036d6
  |  tag:         tip
  |  topic:       narf
  |  parent:      4:fb147b0b417c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     narf!
  |
  | o  changeset:   5:0469d521db49
  | |  topic:       fran
  | |  parent:      3:a53952faf762
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     start on fran
  | |
  o |  changeset:   4:fb147b0b417c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     start on narf
  |
  o  changeset:   3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file delta
  |
  o  changeset:   2:15d1eb11d2fa
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file gamma
  |
  o  changeset:   1:c692ea2c9224
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file beta
  |
  o  changeset:   0:c2b7d2f7d14b
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Add file alpha
  
  $ cd brain
  $ hg co tip
  4 files updated, 0 files merged, 0 files removed, 0 files unresolved

Because the change is public, we won't inherit the topic from narf.

  $ hg topic
  $ echo what >> alpha
  $ hg topic query
  marked working directory as topic: query
  $ hg ci -m 'what is narf, pinky?'
  active topic 'query' grew its first changeset
  $ hg log -Gl2
  @  changeset:   5:c01515cfc331
  |  tag:         tip
  |  topic:       query
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     what is narf, pinky?
  |
  o  changeset:   4:fb147b0b417c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on narf
  |

  $ hg push -f ../pinky -r query
  pushing to ../pinky
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)

  $ hg -R ../pinky log -Gl 4
  o  changeset:   7:c01515cfc331
  |  tag:         tip
  |  topic:       query
  |  parent:      4:fb147b0b417c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     what is narf, pinky?
  |
  | @  changeset:   6:7c34953036d6
  |/   topic:       narf
  |    parent:      4:fb147b0b417c
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     narf!
  |
  | o  changeset:   5:0469d521db49
  | |  topic:       fran
  | |  parent:      3:a53952faf762
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     start on fran
  | |
  o |  changeset:   4:fb147b0b417c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     start on narf
  |

  $ hg topics
   * query
  $ cd ../pinky
  $ hg co query
  switching to topic query
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo answer >> alpha
  $ hg ci -m 'Narf is like `zort` or `poit`!'
  $ hg merge narf
  merging alpha
  warning: conflicts while merging alpha! (edit, then use 'hg resolve --mark')
  0 files updated, 0 files merged, 0 files removed, 1 files unresolved
  use 'hg resolve' to retry unresolved file merges or 'hg update -C .' to abandon
  [1]
  $ hg revert -r narf alpha
  $ hg resolve -m alpha
  (no more unresolved files)
  $ hg topic narf
  $ hg ci -m 'Finish narf'
  $ hg topics
     fran
   * narf
     query
  $ hg debugnamecomplete # branch:topic here is a buggy side effect
  default
  default:fran
  default:narf
  default:query
  fran
  narf
  query
  tip
  $ hg phase --public narf
  active topic 'narf' is now empty

POSSIBLE BUG: narf topic stays alive even though we just made all
narf commits public:

  $ hg topics
     fran
   * narf
  $ hg log -Gl 6
  @    changeset:   9:ae074045b7a7
  |\   tag:         tip
  | |  parent:      8:54c943c1c167
  | |  parent:      6:7c34953036d6
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Finish narf
  | |
  | o  changeset:   8:54c943c1c167
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Narf is like `zort` or `poit`!
  | |
  | o  changeset:   7:c01515cfc331
  | |  parent:      4:fb147b0b417c
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     what is narf, pinky?
  | |
  o |  changeset:   6:7c34953036d6
  |/   parent:      4:fb147b0b417c
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     narf!
  |
  | o  changeset:   5:0469d521db49
  | |  topic:       fran
  | |  parent:      3:a53952faf762
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     start on fran
  | |
  o |  changeset:   4:fb147b0b417c
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     start on narf
  |

  $ cd ../brain
  $ hg topics
   * query
  $ hg pull ../pinky -r narf
  pulling from ../pinky
  abort: unknown revision 'narf'!
  [255]
  $ hg pull ../pinky -r default
  pulling from ../pinky
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 1 files
  active topic 'query' is now empty
  (run 'hg update' to get a working copy)
  $ hg topics
   * query

We can pull in the draft-phase change and we get the new topic

  $ hg pull ../pinky
  pulling from ../pinky
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files (+1 heads)
  (run 'hg heads' to see heads)
  $ hg topics
     fran
   * query
  $ hg log -Gr 'draft()'
  o  changeset:   9:0469d521db49
  |  tag:         tip
  |  topic:       fran
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

query is not an open topic, so when we clear the current topic it'll
disappear:

  $ hg topics --clear
  clearing empty topic "query"
  $ hg topics
     fran

--clear when we don't have an active topic isn't an error:

  $ hg topics --clear

Topic revset
  $ hg log -r 'topic()' -G
  o  changeset:   9:0469d521db49
  |  tag:         tip
  |  topic:       fran
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |
  $ hg log -r 'not topic()' -G
  o    changeset:   8:ae074045b7a7
  |\   parent:      7:54c943c1c167
  | |  parent:      6:7c34953036d6
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Finish narf
  | |
  | o  changeset:   7:54c943c1c167
  | |  parent:      5:c01515cfc331
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     Narf is like `zort` or `poit`!
  | |
  o |  changeset:   6:7c34953036d6
  | |  parent:      4:fb147b0b417c
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     narf!
  | |
  | @  changeset:   5:c01515cfc331
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     what is narf, pinky?
  |
  o  changeset:   4:fb147b0b417c
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on narf
  |
  o  changeset:   3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file delta
  |
  o  changeset:   2:15d1eb11d2fa
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file gamma
  |
  o  changeset:   1:c692ea2c9224
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add file beta
  |
  o  changeset:   0:c2b7d2f7d14b
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     Add file alpha
  
No matches because narf is already closed:
  $ hg log -r 'topic(narf)' -G
This regexp should match the topic `fran`:
  $ hg log -r 'topic("re:.ra.")' -G
  o  changeset:   9:0469d521db49
  |  tag:         tip
  |  topic:       fran
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |
Exact match on fran:
  $ hg log -r 'topic(fran)' -G
  o  changeset:   9:0469d521db49
  |  tag:         tip
  |  topic:       fran
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Match current topic:
  $ hg topic
     fran
  $ hg log -r 'topic(.)'
(no output is expected)
  $ hg co fran
  switching to topic fran
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -r 'topic(.)'
  changeset:   9:0469d521db49
  tag:         tip
  topic:       fran
  parent:      3:a53952faf762
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     start on fran
  

Deactivate the topic.
  $ hg topics
   * fran
  $ hg topics --clear
  $ echo fran? >> beta
  $ hg ci -m 'fran?'
  created new head
  $ hg log -Gr 'draft()'
  @  changeset:   10:4073470c35e1
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   9:0469d521db49
  |  topic:       fran
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |
  $ hg topics
     fran
Changing topic fails if we don't give a topic
  $ hg topic --rev 9
  abort: changing topic requires a topic name or --clear
  [255]

Can't change topic of a public change
  $ hg topic --rev 1:: --clear
  abort: can't change topic of a public change
  [255]

Can clear topics
  $ hg topic --rev 9 --clear
  changed topic on 1 changes
  $ hg log -Gr 'draft() and not obsolete()'
  o  changeset:   11:0beca5ab56c3
  |  tag:         tip
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |
  | @  changeset:   10:4073470c35e1
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  trouble:     unstable
  | |  summary:     fran?
  | |

Normally you'd do this with evolve, but we'll use rebase to avoid
bonus deps in the testsuite.

  $ hg rebase -d tip -s .
  rebasing 10:4073470c35e1 "fran?"

Can add a topic to an existing change
  $ hg topic
  $ hg sum
  parent: 12:18b70b8de1f0 tip
   fran?
  branch: default
  commit: (clean)
  update: 5 new changesets, 2 branch heads (merge)
  phases: 2 draft
  $ hg topic --rev 11 wat
  changed topic on 1 changes
  $ hg log -r .
  changeset:   12:18b70b8de1f0
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  trouble:     unstable
  summary:     fran?
  
  $ hg sum
  parent: 12:18b70b8de1f0  (unstable)
   fran?
  branch: default
  commit: (clean)
  update: 5 new changesets, 2 branch heads (merge)
  phases: 3 draft
  unstable: 1 changesets
  $ hg topic
     wat
  $ hg log -Gr 'draft() and not obsolete()'
  o  changeset:   13:686a642006db
  |  tag:         tip
  |  topic:       wat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |
  | @  changeset:   12:18b70b8de1f0
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  trouble:     unstable
  | |  summary:     fran?
  | |

Normally you'd do this with evolve, but we'll use rebase to avoid
bonus deps in the testsuite.

  $ hg topic
     wat
  $ hg rebase -d tip -s .
  rebasing 12:18b70b8de1f0 "fran?"
  switching to topic wat
  $ hg topic
     wat

  $ hg log -Gr 'draft()'
  @  changeset:   14:45358f7a5892
  |  tag:         tip
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   13:686a642006db
  |  topic:       wat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Amend a topic

  $ hg topic watwat
  marked working directory as topic: watwat
  $ hg ci --amend
  active topic 'watwat' grew its first changeset
  $ hg log -Gr 'draft()'
  @  changeset:   16:6c40a4c21bbe
  |  tag:         tip
  |  topic:       watwat
  |  parent:      13:686a642006db
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   13:686a642006db
  |  topic:       wat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Clear and amend:

  $ hg topic --clear
  $ hg ci --amend
  $ hg log -r .
  changeset:   18:0f9cd5070654
  tag:         tip
  parent:      13:686a642006db
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     fran?
  
Reading the same topic with topic --rev should work:
  $ hg topic --rev . watwat
  switching to topic watwat
  changed topic on 1 changes

Testing issue5441
  $ hg co 19
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -Gr 'draft()'
  @  changeset:   19:980a0f608481
  |  tag:         tip
  |  topic:       watwat
  |  parent:      13:686a642006db
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   13:686a642006db
  |  topic:       wat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Using the current flag

  $ hg topic changewat
  $ hg topics --rev '13::19' --current
  active topic 'changewat' grew its 2 first changesets
  changed topic on 2 changes

  $ hg log -Gr 'draft()'
  @  changeset:   21:56c83be6105f
  |  tag:         tip
  |  topic:       changewat
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   20:ceba5be9d56f
  |  topic:       changewat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Case with branching:

  $ hg up changewat
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up t1
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo gamma >> gamma
  $ hg ci -m gamma

  $ hg log -Gr 'draft()'
  @  changeset:   22:0d3d805542b4
  |  tag:         tip
  |  topic:       changewat
  |  parent:      20:ceba5be9d56f
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     gamma
  |
  | o  changeset:   21:56c83be6105f
  |/   topic:       changewat
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     fran?
  |
  o  changeset:   20:ceba5be9d56f
  |  topic:       changewat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

  $ hg topics --rev 't1::' changewut
  switching to topic changewut
  active topic 'changewat' is now empty
  changed topic on 3 changes

  $ hg log -Gr 'draft()'
  @  changeset:   25:729ed5717393
  |  tag:         tip
  |  topic:       changewut
  |  parent:      23:62e49f09f883
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     gamma
  |
  | o  changeset:   24:369c6e2e5474
  |/   topic:       changewut
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     fran?
  |
  o  changeset:   23:62e49f09f883
  |  topic:       changewut
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Testing for updating to t0
==========================

  $ hg stack
  ### topic: changewut (2 heads)
  ### target: default (branch), 5 behind
  t3: fran?
  t1^ start on fran (base)
  t2@ gamma (current)
  t1: start on fran
  t0^ Add file delta (base)

  $ hg up t0
  preserving the current topic 'changewut'
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg topic
   * changewut
  $ hg stack
  ### topic: changewut (2 heads)
  ### target: default (branch), 5 behind
  t3: fran?
  t1^ start on fran (base)
  t2: gamma
  t1: start on fran
  t0^ Add file delta (base)

  $ hg topics --age
   * changewut (1970-01-01 by test)

  $ cd ..

Testing the new config knob to forbid untopiced commit
======================================================

  $ hg init ponky
  $ cd ponky
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > enforce-topic = yes
  > EOF
  $ touch a b c d
  $ hg add a
  $ hg ci -m "Added a"
  abort: no active topic
  (set a current topic or use '--config experimental.enforce-topic=no' to commit without a topic)
  [255]

(same test, checking we abort before the editor)

  $ EDITOR=cat hg ci -m "Added a" --edit
  abort: no active topic
  (set a current topic or use '--config experimental.enforce-topic=no' to commit without a topic)
  [255]
  $ hg ci -m "added a" --config experimental.enforce-topic=no
  $ hg log
  changeset:   0:a154386e50d1
  tag:         tip
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     added a
  
Testing the --age flag for `hg topics`
======================================

  $ hg topic topic1970 --rev 0
  switching to topic topic1970
  changed topic on 1 changes

  $ hg add b
  $ hg topic topic1990
  $ hg ci -m "Added b" --config devel.default-date="631152000 0" --user "foo"
  active topic 'topic1990' grew its first changeset
  $ hg add c
  $ hg topic topic2010
  $ hg ci -m "Added c" --config devel.default-date="1262304000 0" --user "bar"
  active topic 'topic2010' grew its first changeset

  $ hg log -G
  @  changeset:   3:76b16af75125
  |  tag:         tip
  |  topic:       topic2010
  |  user:        bar
  |  date:        Fri Jan 01 00:00:00 2010 +0000
  |  summary:     Added c
  |
  o  changeset:   2:bba5bde53608
  |  topic:       topic1990
  |  user:        foo
  |  date:        Mon Jan 01 00:00:00 1990 +0000
  |  summary:     Added b
  |
  o  changeset:   1:e5a30a141954
     topic:       topic1970
     parent:      -1:000000000000
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     added a
  
  $ hg topics
     topic1970
     topic1990
   * topic2010

  $ hg topics --age
   * topic2010 (2010-01-01 by bar)
     topic1990 (1990-01-01 by foo)
     topic1970 (1970-01-01 by test)

  $ hg up topic1970
  switching to topic topic1970
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved

  $ hg topics --age
     topic2010 (2010-01-01 by bar)
     topic1990 (1990-01-01 by foo)
   * topic1970 (1970-01-01 by test)

  $ hg topics --age random
  abort: cannot use --age while setting a topic
  [255]
  $ cd ..
