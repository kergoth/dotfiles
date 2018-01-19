test of the rebase command
--------------------------

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
  > rebase=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ echo "topic=$(echo $(dirname $TESTDIR))/hgext3rd/topic/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1" $2 $3
  > }
  $ logtopic() {
  >    hg log -G -T "{rev}:{node}\ntopics: {topic}" 
  > }

Check that rebase keep the topic in the simple case (1 changeset, no merge conflict)
------------------------------------------------------------------------------------

  $ hg init testrebase
  $ cd testrebase
  $ mkcommit ROOT

Work on myfeature
  $ hg topic myfeature
  marked working directory as topic: myfeature
  $ mkcommit feature1
  active topic 'myfeature' grew its first changeset
  $ hg stack
  ### topic: myfeature
  ### target: default (branch)
  t1@ add feature1 (current)
  t0^ add ROOT (base)
  $ logtopic
  @  1:39e7a938055e87615edf675c24a10997ff05bb06
  |  topics: myfeature
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:

Create another commit on default
  $ hg update --rev default
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit default
  $ logtopic
  @  2:be7622a7a0f43ba713e152f56441275f8e8711ef
  |  topics:
  | o  1:39e7a938055e87615edf675c24a10997ff05bb06
  |/   topics: myfeature
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:

Rebase the commit
  $ hg update --rev 1
  switching to topic myfeature
  1 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg rebase
  rebasing 1:39e7a938055e "add feature1" (myfeature)
  switching to topic myfeature
  $ hg stack
  ### topic: myfeature
  ### target: default (branch)
  t1@ add feature1 (current)
  t0^ add default (base)
  $ logtopic
  @  3:fc6593661cf3256ba165cbccd6019ead17cc3726
  |  topics: myfeature
  o  2:be7622a7a0f43ba713e152f56441275f8e8711ef
  |  topics:
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:
  $ hg up 3
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg stack
  ### topic: myfeature
  ### target: default (branch)
  t1@ add feature1 (current)
  t0^ add default (base)

Check that rebase keep the topic in case of merge conflict
----------------------------------------------------------

Create a common base
  $ hg topic --clear
  $ echo "A" > file
  $ hg commit -A -m "default2" file
  created new head
  (consider using topic for lightweight branches. See 'hg help topic')

Update the common file in a topic
  $ hg topic myotherfeature
  marked working directory as topic: myotherfeature
  $ echo "B" >> file
  $ hg commit -m "myotherfeature1"
  active topic 'myotherfeature' grew its first changeset

Update the common file in default
  $ hg update --rev default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo "A2" > file
  $ hg commit -m "default3"

Rebase the topic
  $ hg update --rev 5
  switching to topic myotherfeature
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg rebase
  rebasing 5:81f854012ec5 "myotherfeature1" (myotherfeature)
  merging file
  warning: conflicts while merging file! (edit, then use 'hg resolve --mark')
  switching to topic myotherfeature
  unresolved conflicts (see hg resolve, then hg rebase --continue)
  [1]

Resolve the conflict
  $ echo A2 > file
  $ echo B >> file
  $ hg resolve -m
  (no more unresolved files)
  continue: hg rebase --continue
  $ hg rebase --continue
  rebasing 5:81f854012ec5 "myotherfeature1" (myotherfeature)

Check the the commit has the right topic

  $ logtopic
  @  7:6ccb9ec4913b64f3ad719ff1ba66495a70bf35a4
  |  topics: myotherfeature
  o  6:0b124ef641a7a6f4715d962650d3b367e8c800be
  |  topics:
  o  4:0cd2e1a45ac4e3f9603a05ccfa6d1c70cd759bc5
  |  topics:
  o  3:fc6593661cf3256ba165cbccd6019ead17cc3726
  |  topics: myfeature
  o  2:be7622a7a0f43ba713e152f56441275f8e8711ef
  |  topics:
  o  0:3e7df3b3b17c6deb4a1c70e790782fdf17af96a7
     topics:
  $ hg stack
  ### topic: myotherfeature
  ### target: default (branch)
  t1@ myotherfeature1 (current)
  t0^ default3 (base)
  $ hg update --rev 7
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg stack
  ### topic: myotherfeature
  ### target: default (branch)
  t1@ myotherfeature1 (current)
  t0^ default3 (base)
