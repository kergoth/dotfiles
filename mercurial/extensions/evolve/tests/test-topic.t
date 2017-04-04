  $ . "$TESTDIR/testlib/topic_setup.sh"

  $ hg init pinky
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
  
  View current topic, set current topic, or see all topics.
  
      The --verbose version of this command display various information on the
      state of each topic.
  
  options:
  
      --clear        clear active topic if any
      --change VALUE revset of existing revisions to change topic
   -l --list         show the stack of changeset in the topic
  
  (some details hidden, use --verbose to show complete help)
  $ hg topics

Test topics interaction with evolution:

  $ hg topics --config experimental.evolution=
  $ hg topics --config experimental.evolution= --change . bob
  abort: must have obsolete enabled to use --change
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
  $ echo topic work >> alpha
  $ hg ci -m 'start on narf'
  $ hg co .^
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg topic fran
  $ hg topics
   * fran
     narf
  $ echo >> fran work >> beta
  $ hg ci -m 'start on fran'
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
  $ hg ci -m 'what is narf, pinky?'
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
  $ hg topic --change 9
  abort: changing topic requires a topic name or --clear
  [255]

Can't change topic of a public change
  $ hg topic --change 1:: --clear
  abort: can't change topic of a public change
  [255]

Can clear topics
  $ hg topic --change 9 --clear
  changed topic on 1 changes
  please run hg evolve --rev "not topic()" now
  $ hg log -Gr 'draft() and not obsolete()'
  o  changeset:   11:783930e1d79e
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
  $ hg topic --change 11 wat
  changed topic on 1 changes
  please run hg evolve --rev "topic(wat)" now
  $ hg log -Gr 'draft() and not obsolete()'
  o  changeset:   13:d91cd8fd490e
  |  tag:         tip
  |  topic:       wat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |
  | @  changeset:   12:d9e32f4c4806
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  trouble:     unstable
  | |  summary:     fran?
  | |

Normally you'd do this with evolve, but we'll use rebase to avoid
bonus deps in the testsuite.

  $ hg rebase -d tip -s .
  rebasing 12:d9e32f4c4806 "fran?"

  $ hg log -Gr 'draft()'
  @  changeset:   14:cf24ad8bbef5
  |  tag:         tip
  |  topic:       wat
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   13:d91cd8fd490e
  |  topic:       wat
  |  parent:      3:a53952faf762
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     start on fran
  |

Amend a topic

  $ hg topic watwat
  $ hg ci --amend
  $ hg log -Gr 'draft()'
  @  changeset:   16:893ffcf66c1f
  |  tag:         tip
  |  topic:       watwat
  |  parent:      13:d91cd8fd490e
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     fran?
  |
  o  changeset:   13:d91cd8fd490e
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
  changeset:   18:a13639e22b65
  tag:         tip
  parent:      13:d91cd8fd490e
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     fran?
  
Readding the same topic with topic --change should work:
  $ hg topic --change . watwat
  changed topic on 1 changes
