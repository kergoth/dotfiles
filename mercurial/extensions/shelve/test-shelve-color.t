  $ echo "[extensions]" >> $HGRCPATH
  $ echo "color=" >> $HGRCPATH

Create repo for testing

  $ hg init repo
  $ cd repo
  $ cat > a <<EOF
  > c
  > c
  > a
  > a
  > b
  > a
  > a
  > c
  > c
  > EOF
  $ hg ci -Am adda
  adding a
  $ cat > a <<EOF
  > c
  > c
  > a
  > a
  > dd
  > a
  > a
  > c
  > c
  > EOF

  $ echo "[ui]" >> $HGRCPATH
  $ echo "interactive=true" >> $HGRCPATH
  $ echo "[extensions]" >> $HGRCPATH
  $ echo "hgshelve=" >> $HGRCPATH
  $ echo "[diff]" >> $HGRCPATH
  $ echo "git=True" >> $HGRCPATH
  $ echo "[defaults]" >> $HGRCPATH
  $ echo "shelve=" >> $HGRCPATH

Test shelve

  $ chmod 0755 a
  $ hg shelve --color=always a <<EOF
  > y
  > y
  > EOF
  \x1b[0;1mdiff --git a/a b/a\x1b[0m (esc)
  \x1b[0;36;1mold mode 100644\x1b[0m (esc)
  \x1b[0;36;1mnew mode 100755\x1b[0m (esc)
  1 hunks, 1 lines changed
  \x1b[0;33mexamine changes to 'a'? [Ynsfdaq?]\x1b[0m  (esc)
  \x1b[0;35m@@ -2,7 +2,7 @@\x1b[0m (esc)
   c
   a
   a
  \x1b[0;31m-b\x1b[0m (esc)
  \x1b[0;32m+dd\x1b[0m (esc)
   a
   a
   c
  \x1b[0;33mshelve this change to 'a'? [Ynsfdaq?]\x1b[0m  (esc)
  $ echo
  
