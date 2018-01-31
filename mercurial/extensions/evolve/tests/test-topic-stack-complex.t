Testing `hg stack` on complex cases when we have multiple successors because of
divergence, split etc.
  $ . "$TESTDIR/testlib/topic_setup.sh"

Setup

  $ cat << EOF >> $HGRCPATH
  > [experimental]
  > evolution = all
  > [ui]
  > interactive = True
  > [extensions]
  > show =
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

  $ hg init test
  $ cd test
  $ echo foo > foo
  $ hg add foo
  $ hg ci -m "Added foo"
  $ hg phase -r . --public
  $ hg topic foo
  marked working directory as topic: foo
  $ echo a > a
  $ echo b > b
  $ hg ci -Aqm "Added a and b"
  $ echo c > c
  $ echo d > d
  $ hg ci -Aqm "Added c and d"
  $ echo e > e
  $ echo f > f
  $ hg ci -Aqm "Added e and f"
  $ hg show work
  @  f1d3 (foo) Added e and f
  o  8e82 (foo) Added c and d
  o  002b (foo) Added a and b
  o  f360 Added foo

Testing in case of split within the topic

  $ hg stack
  ### topic: foo
  ### target: default (branch)
  t3@ Added e and f (current)
  t2: Added c and d
  t1: Added a and b
  t0^ Added foo (base)
  $ hg prev
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  [2] Added c and d

  $ echo 0 > num
  $ cat > editor.sh << '__EOF__'
  > NUM=$(cat num)
  > NUM=`expr "$NUM" + 1`
  > echo "$NUM" > num
  > echo "split$NUM" > "$1"
  > __EOF__
  $ export HGEDITOR="\"sh\" \"editor.sh\""

  $ hg split << EOF
  > y
  > y
  > n
  > y
  > EOF
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  adding c
  adding d
  diff --git a/c b/c
  new file mode 100644
  examine changes to 'c'? [Ynesfdaq?] y
  
  @@ -0,0 +1,1 @@
  +c
  record change 1/2 to 'c'? [Ynesfdaq?] y
  
  diff --git a/d b/d
  new file mode 100644
  examine changes to 'd'? [Ynesfdaq?] n
  
  Done splitting? [yN] y
  1 new orphan changesets

  $ hg stack
  ### topic: foo
  ### target: default (branch)
  t4$ Added e and f (unstable)
  t3@ split2 (current)
  t2: split1
  t1: Added a and b
  t0^ Added foo (base)

  $ hg show work
  @  5cce (foo) split2
  o  f26c (foo) split1
  | *  f1d3 (foo) Added e and f
  | x  8e82 (foo) Added c and d
  |/
  o  002b (foo) Added a and b
  o  f360 Added foo

  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [4] split1
  $ echo foo > c
  $ hg diff
  diff -r f26c1b9addde c
  --- a/c	Thu Jan 01 00:00:00 1970 +0000
  +++ b/c	Thu Jan 01 00:00:00 1970 +0000
  @@ -1,1 +1,1 @@
  -c
  +foo

  $ hg amend
  1 new orphan changesets
  $ hg show work
  @  7d94 (foo) split1
  | *  5cce (foo) split2
  | x  f26c (foo) split1
  |/
  | *  f1d3 (foo) Added e and f
  | x  8e82 (foo) Added c and d
  |/
  o  002b (foo) Added a and b
  o  f360 Added foo

  $ hg stack
  ### topic: foo (2 heads)
  ### target: default (branch), 2 behind
  t4$ Added e and f (unstable)
  t3$ split2 (unstable)
  t2@ split1 (current)
  t1: Added a and b
  t0^ Added foo (base)
