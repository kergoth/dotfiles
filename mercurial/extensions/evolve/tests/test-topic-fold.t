test of the fold command
------------------------

  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > split=-d "0 0"
  > amend=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [diff]
  > git = 1
  > unified = 0
  > [ui]
  > interactive = true
  > [extensions]
  > EOF
  $ echo "topic=$(echo $(dirname $TESTDIR))/hgext3rd/topic/" >> $HGRCPATH
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1" $2 $3
  > }
  $ logtopic() {
  >    hg log -G -T "{rev}:{node}\ntopics: {topics}" 
  > }

Check that fold keep the topic if all revisions have the topic
--------------------------------------------------------------

  $ hg init testfold
  $ cd testfold
  $ mkcommit ROOT
  $ hg topic myfeature
  marked working directory as topic: myfeature
  $ mkcommit feature1
  active topic 'myfeature' grew its first changeset
  $ mkcommit feature2
  $ logtopic
  @  2:d76a6166b18c835be9a487c5e21c7d260f0a1676
  |  topics: myfeature
  o  1:39e7a938055e87615edf675c24a10997ff05bb06
  |  topics: myfeature
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:
  $ hg fold --exact -r "(tip~1)::" -m "folded"
  2 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg stack
  ### topic: myfeature
  ### target: default (branch)
  t1@ folded (current)
  t0^ add ROOT (base)
  $ logtopic
  @  3:4fd43e5bdc443dc8489edffac19bd8f93ccf1a5c
  |  topics: myfeature
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:
  $ hg summary
  parent: 3:4fd43e5bdc44 tip
   folded
  branch: default
  commit: (clean)
  update: (current)
  phases: 2 draft
  topic:  myfeature

Check that fold dismis the topic if not all revisions have the topic
--------------------------------------------------------------------

(I'm not sure this behavior make senses, but now it is tested)

  $ hg topic --clear
  $ mkcommit feature3
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')
  $ hg topic myotherfeature
  marked working directory as topic: myotherfeature
  $ mkcommit feature4
  active topic 'myotherfeature' grew its first changeset
  $ logtopic
  @  5:5ded4d6d578c37f339b0716de2e46e12ece7cbde
  |  topics: myotherfeature
  o  4:bdf6950b9b5b7c6b377c8132667c73ec86d5734f
  |  topics:
  o  3:4fd43e5bdc443dc8489edffac19bd8f93ccf1a5c
  |  topics: myfeature
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:
  $ hg fold --exact -r "(tip~1)::" -m "folded 2"
  active topic 'myotherfeature' is now empty
  2 changesets folded
  clearing empty topic "myotherfeature"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ logtopic
  @  6:03da8f7238e9a4d708d6b8af402c91c68f271477
  |  topics:
  o  3:4fd43e5bdc443dc8489edffac19bd8f93ccf1a5c
  |  topics: myfeature
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:
  $ hg summary
  parent: 6:03da8f7238e9 tip
   folded 2
  branch: default
  commit: (clean)
  update: (current)
  phases: 3 draft
