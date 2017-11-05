  $ . "$TESTDIR/testlib/topic_setup.sh"

Testing the config knob to forbid untopiced commit
======================================================

  $ hg init $TESTTMP/untopic-commit
  $ cd $TESTTMP/untopic-commit
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > topic-mode = enforce
  > EOF
  $ touch a b c d
  $ hg add a
  $ hg ci -m "Added a"
  abort: no active topic
  (see 'hg help -e topic.topic-mode' for details)
  [255]

(same test, checking we abort before the editor)

  $ EDITOR=cat hg ci -m "Added a" --edit
  abort: no active topic
  (see 'hg help -e topic.topic-mode' for details)
  [255]
  $ hg ci -m "added a" --config experimental.topic-mode=ignore
  $ hg log
  changeset:   0:a154386e50d1
  tag:         tip
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     added a
  

Testing the config knob to warn about untopiced commit
==========================================================

  $ hg init $TESTTMP/untopic-warn-commit
  $ cd $TESTTMP/untopic-warn-commit
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > topic-mode = warning
  > EOF
  $ touch a b c d
  $ hg add a

(same test, checking we abort before the editor)

  $ HGEDITOR=cat hg ci -m "Added a" --edit
  warning: new draft commit without topic
  (see 'hg help -e topic.topic-mode' for details)
  Added a
  
  
  HG: Enter commit message.  Lines beginning with 'HG:' are removed.
  HG: Leave message empty to abort commit.
  HG: --
  HG: user: test
  HG: branch 'default'
  HG: added a

  $ HGEDITOR=cat hg ci --amend -m "Added a" --edit
  Added a
  
  
  HG: Enter commit message.  Lines beginning with 'HG:' are removed.
  HG: Leave message empty to abort commit.
  HG: --
  HG: user: test
  HG: branch 'default'
  HG: added a
  $ hg ci --amend -m "added a'" --config experimental.topic-mode=ignore
  $ hg log
  changeset:   2:2e862d8b5eff
  tag:         tip
  parent:      -1:000000000000
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     added a'
  

Testing the config knob to warn about untopiced merge commit
================================================================

  $ hg init $TESTTMP/test-untopic-merge-commit
  $ cd $TESTTMP/test-untopic-merge-commit
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > topic-mode = enforce
  > EOF
  $ touch ROOT
  $ hg commit -A -m "ROOT" --config experimental.topic-mode=ignore
  adding ROOT
  $ touch a
  $ hg add a
  $ hg topic mytopic
  marked working directory as topic: mytopic
  $ hg ci -m "Added a"
  active topic 'mytopic' grew its first changeset

  $ hg up -r "desc('ROOT')"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ touch default
  $ hg add default
  $ hg commit -m "default" --config experimental.topic-mode=ignore

  $ hg merge mytopic
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -m "merge mytopic"
  warning: new draft commit without topic
  (see 'hg help -e topic.topic-mode' for details)

  $ hg log -G
  @    changeset:   3:676a445d1c09
  |\   tag:         tip
  | |  parent:      2:a4da109ee59f
  | |  parent:      1:e5b6c632bd8e
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     merge mytopic
  | |
  | o  changeset:   2:a4da109ee59f
  | |  parent:      0:ec1d2790416d
  | |  user:        test
  | |  date:        Thu Jan 01 00:00:00 1970 +0000
  | |  summary:     default
  | |
  o |  changeset:   1:e5b6c632bd8e
  |/   topic:       mytopic
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Added a
  |
  o  changeset:   0:ec1d2790416d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  

Testing the config knob to about on untopiced merge commit
================================================================

  $ hg init $TESTTMP/test-untopic-merge-commit-abort
  $ cd $TESTTMP/test-untopic-merge-commit-abort
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > topic-mode = enforce-all
  > EOF
  $ touch ROOT
  $ hg commit -A -m "ROOT" --config experimental.topic-mode=ignore
  adding ROOT
  $ touch a
  $ hg add a
  $ hg topic mytopic
  marked working directory as topic: mytopic
  $ hg ci -m "Added a"
  active topic 'mytopic' grew its first changeset

  $ hg up -r "desc('ROOT')"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ touch default
  $ hg add default
  $ hg commit -m "default" --config experimental.topic-mode=ignore

  $ hg merge mytopic
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg commit -m "merge mytopic"
  abort: no active topic
  (see 'hg help -e topic.topic-mode' for details)
  [255]

  $ hg log -G
  @  changeset:   2:a4da109ee59f
  |  tag:         tip
  |  parent:      0:ec1d2790416d
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     default
  |
  | @  changeset:   1:e5b6c632bd8e
  |/   topic:       mytopic
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Added a
  |
  o  changeset:   0:ec1d2790416d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
Testing the config knob to use a random topic for untopic commit
====================================================================

  $ hg init $TESTTMP/test-untopic-random
  $ cd $TESTTMP/test-untopic-random
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > topic-mode = random
  > EOF

  $ touch ROOT
  $ hg commit -A -m "ROOT" --config experimental.topic-mode=ignore
  adding ROOT

  $ touch A
  $ hg add A
  $ hg commit -m "Add A" --config devel.randomseed=42
  active topic 'panoramic-antelope' grew its first changeset

  $ hg up -r "desc(ROOT)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ touch B
  $ hg add B
  $ hg commit -m "Add B" --config devel.randomseed=128
  active topic 'various-dove' grew its first changeset

Test a merge too

  $ hg phase --public -r .
  active topic 'various-dove' is now empty
  $ hg up default
  clearing empty topic "various-dove"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  @  changeset:   2:2d2acb6efad5
  |  tag:         tip
  |  parent:      0:ec1d2790416d
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add B
  |
  | o  changeset:   1:d4b548f35972
  |/   topic:       panoramic-antelope
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Add A
  |
  o  changeset:   0:ec1d2790416d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg merge panoramic-antelope
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m 'merge'
Testing the config knob to use a random topic for untopic commit (even for merge)
=================================================================================

  $ hg init $TESTTMP/test-untopic-random-all
  $ cd $TESTTMP/test-untopic-random-all
  $ cat <<EOF >> .hg/hgrc
  > [phases]
  > publish=false
  > EOF
  $ cat <<EOF >> $HGRCPATH
  > [experimental]
  > topic-mode = random-all
  > EOF

  $ touch ROOT
  $ hg commit -A -m "ROOT" --config experimental.topic-mode=ignore
  adding ROOT

  $ touch A
  $ hg add A
  $ hg commit -m "Add A" --config devel.randomseed=42
  active topic 'panoramic-antelope' grew its first changeset

  $ hg up -r "desc(ROOT)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved

  $ touch B
  $ hg add B
  $ hg commit -m "Add B" --config devel.randomseed=128
  active topic 'various-dove' grew its first changeset

Test a merge too

  $ hg phase --public -r .
  active topic 'various-dove' is now empty
  $ hg up default
  clearing empty topic "various-dove"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  @  changeset:   2:2d2acb6efad5
  |  tag:         tip
  |  parent:      0:ec1d2790416d
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     Add B
  |
  | o  changeset:   1:d4b548f35972
  |/   topic:       panoramic-antelope
  |    user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     Add A
  |
  o  changeset:   0:ec1d2790416d
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     ROOT
  
  $ hg merge panoramic-antelope
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m 'merge'  --config devel.randomseed=1337
  active topic 'omniscient-locust' grew its first changeset
