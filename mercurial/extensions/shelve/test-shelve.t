  $ HGRCPATH=$HGTMP/.hgrc
  $ export HGRCPATH
  $ echo "[ui]" >> $HGRCPATH
  $ echo "interactive=true" >> $HGRCPATH
  $ echo "[extensions]" >> $HGRCPATH
  $ echo "hgshelve=" >> $HGRCPATH

Create repo for testing

  $ hg init a
  $ cd a
  $ for i in 1 2 3 4; do
  >    echo $i >> file1.txt
  > done
  $ cp file1.txt file2.txt
  $ hg add file1.txt file2.txt
  $ hg commit -d '1 0' -m 'first file' file1.txt
  $ hg commit -d '2 0' -m 'second file' file2.txt
  $ hg bundle --base -2 tip.bundle
  1 changesets found
  $ hg add tip.bundle
  $ hg commit -d '3 0' -m 'binary file' tip.bundle
  $ rm file1.txt
  $ for i in a 1 2 3 4 b; do
  >     echo $i >> file1.txt
  > done
  $ cp file1.txt file2.txt
  $ hg bundle --base -2 tip.bundle
  1 changesets found
  $ hg commit -d '4 0' -m 'more changes'

Create changes for shelving

  $ hg revert --rev 2 --all
  reverting file1.txt
  reverting file2.txt
  reverting tip.bundle
  $ hg diff --nodates
  diff -r a71f3ef38ad4 file1.txt
  --- a/file1.txt
  +++ b/file1.txt
  @@ -1,6 +1,4 @@
  -a
   1
   2
   3
   4
  -b
  diff -r a71f3ef38ad4 file2.txt
  --- a/file2.txt
  +++ b/file2.txt
  @@ -1,6 +1,4 @@
  -a
   1
   2
   3
   4
  -b
  diff -r a71f3ef38ad4 tip.bundle
  Binary file tip.bundle has changed

Do selective shelve
  $ hg shelve<<EOF
  > y
  > n
  > y
  > y
  > y
  > n
  > y
  > EOF
  diff --git a/file1.txt b/file1.txt
  2 hunks, 2 lines changed
  examine changes to 'file1.txt'? [Ynsfdaq?] 
  @@ -1,5 +1,4 @@
  -a
   1
   2
   3
   4
  shelve change 1/4 to 'file1.txt'? [Ynsfdaq?] 
  @@ -2,5 +1,4 @@
   1
   2
   3
   4
  -b
  shelve change 2/4 to 'file1.txt'? [Ynsfdaq?] 
  diff --git a/file2.txt b/file2.txt
  2 hunks, 2 lines changed
  examine changes to 'file2.txt'? [Ynsfdaq?] 
  @@ -1,5 +1,4 @@
  -a
   1
   2
   3
   4
  shelve change 3/4 to 'file2.txt'? [Ynsfdaq?] 
  @@ -2,5 +1,4 @@
   1
   2
   3
   4
  -b
  shelve change 4/4 to 'file2.txt'? [Ynsfdaq?] 
  diff --git a/tip.bundle b/tip.bundle
  this modifies a binary file (all or nothing)
  examine changes to 'tip.bundle'? [Ynsfdaq?] 

  $ echo
  
Check remaining diffs

  $ hg status
  M file1.txt
  M file2.txt
  $ hg diff --nodates
  diff -r a71f3ef38ad4 file1.txt
  --- a/file1.txt
  +++ b/file1.txt
  @@ -1,4 +1,3 @@
  -a
   1
   2
   3
  diff -r a71f3ef38ad4 file2.txt
  --- a/file2.txt
  +++ b/file2.txt
  @@ -3,4 +3,3 @@
   2
   3
   4
  -b

Append to existing shelf

  $ hg shelve --append --all

Inpect shelved data

  $ hg shelve --list
  default
  $ hg unshelve --inspect
  diff --git a/file1.txt b/file1.txt
  --- a/file1.txt
  +++ b/file1.txt
  @@ -1,4 +1,3 @@
  -a
   1
   2
   3
  diff --git a/file2.txt b/file2.txt
  --- a/file2.txt
  +++ b/file2.txt
  @@ -3,4 +3,3 @@
   2
   3
   4
  -b
  diff --git a/file1.txt b/file1.txt
  --- a/file1.txt
  +++ b/file1.txt
  @@ -1,5 +1,4 @@
   1
   2
   3
   4
  -b
  diff --git a/tip.bundle b/tip.bundle
  index 7360ca0c61fa832e44b5e5c936b87701de8bda12..225d2fbb02d47c2162cda09e9e3332f88ec4069a
  GIT binary patch
  literal 396
  zc$@)@0dxLHM=>x$T4*^jL0KkKStX{nX#fBX|NrgVUcpx-fA>nDw?IGjzt|Zn3<N+R
  z|BwcW6wm;i1fZ}0`xXsS6B7VTCYof)fCw2eF$|3|VLbw1nl!>=N$Aw|KPWX!r1qxN
  z^$Fr58kz=%Mg+nGH3ox5h7d3&k5fjP82~jVplFx@3<;)9G{#6607em$6DC2lXdu%9
  zWWtIPid_|~ry%P%q~tW$!Qw;eFEkK<6vCK+fG?6(b&ooFr>96-LNf@JgmnR>9F0i>
  ze{=>YwaT|6O3VY*<7P<REtEl|{eVVw$`}c<quJ8ZJB1CNd*EPLA;Y87RE9EZxpoTg
  zP`oJpG$rVyq{E>DEZNDG$>}T!HpVbAF4V<{0^jlDd5^jXR;#7pJv}%>Mf#_26KF$$
  z01Qg)6*km`Z;!B^0@j~Kfn)~2GXWMpfFcFFL^RD?et!VbV9$*?K&7}2Bv2(pTRHo>
  qar#atNvM%#;0jJt&??Xnqyaz5Pzsh+06idB-Y(>daG@YeO>ELh`lWmT
  
  diff --git a/file2.txt b/file2.txt
  --- a/file2.txt
  +++ b/file2.txt
  @@ -1,5 +1,4 @@
  -a
   1
   2
   3
   4

Unshelve and verify

  $ hg unshelve
  unshelve completed
  $ hg diff --rev 2 --git


Check shelf names

  $ hg shelve --name file1 --all file1.txt
  $ hg shelve --name file2 --all file2.txt
  $ hg status
  M tip.bundle
  $ hg shelve --list
  file1
  file2
  $ hg unshelve --list
  file1
  file2
  $ hg unshelve --name file1
  unshelve completed
  $ hg unshelve --name file2
  unshelve completed
  $ hg status
  M file1.txt
  M file2.txt
  M tip.bundle
  $ hg unshelve
  nothing to unshelve

Check shelving newly added files

  $ hg up -C tip >/dev/null
  $ cp file1.txt file3.txt
  $ hg add file3.txt
  $ hg status
  A file3.txt
  $ hg shelve --all file3.txt
  $ hg status
  $ hg unshelve
  unshelve completed
  $ hg status
  A file3.txt
  $ diff file1.txt file3.txt

Check shelving removed files

  $ hg commit -d '4 0' -m 'third file' file3.txt
  $ hg rm file3.txt
  $ hg status
  R file3.txt
  $ hg shelve --all file3.txt
  $ hg status
  $ hg unshelve
  unshelve completed
  $ hg status
  R file3.txt
  $ diff file1.txt file3.txt
  diff: file3.txt: No such file or directory
  [2]
