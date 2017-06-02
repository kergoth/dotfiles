  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > metaedit=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [alias]
  > qlog = log --template='{rev} - {node|short} {desc} ({phase})\n'
  > [diff]
  > git = 1
  > unified = 0
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "$1"
  > }

  $ mkstack() {
  >    # Creates a stack of commit based on $1 with messages from $2, $3 ..
  >    hg update $1 -C
  >    shift
  >    mkcommits $*
  > }

  $ glog() {
  >   hg glog --template '{rev}:{node|short}@{branch}({phase}) {desc|firstline}\n' "$@"
  > }

  $ shaof() {
  >   hg log -T {node} -r "first(desc($1))"
  > }

  $ mkcommits() {
  >   for i in $@; do mkcommit $i ; done
  > }

##########################
importing Parren test
##########################

  $ cat << EOF >> $HGRCPATH
  > [ui]
  > logtemplate = "{rev}\t{bookmarks}: {desc|firstline} - {author|user}\n"
  > EOF

HG METAEDIT
===============================

Setup the Base Repo
-------------------

We start with a plain base repo::

  $ hg init $TESTTMP/metaedit; cd $TESTTMP/metaedit
  $ mkcommit "ROOT"
  $ hg phase --public "desc(ROOT)"
  $ mkcommit "A"
  $ mkcommit "B"
  $ hg up "desc(A)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit "C"
  created new head
  $ mkcommit "D"
  $ echo "D'" > D
  $ hg amend -m "D2"
  $ hg up "desc(C)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ mkcommit "E"
  created new head
  $ mkcommit "F"

Test
----

  $ hg log -G
  @  8	: F - test
  |
  o  7	: E - test
  |
  | o  6	: D2 - test
  |/
  o  3	: C - test
  |
  | o  2	: B - test
  |/
  o  1	: A - test
  |
  o  0	: ROOT - test
  
  $ hg update --clean .
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg metaedit -r 0
  abort: cannot edit commit information for public revisions
  [255]
  $ hg metaedit --fold
  abort: revisions must be specified with --fold
  [255]
  $ hg metaedit -r 0 --fold
  abort: cannot fold public revisions
  [255]
  $ hg metaedit 'desc(C) + desc(F)' --fold
  abort: cannot fold non-linear revisions (multiple roots given)
  [255]
  $ hg metaedit "desc(C)::desc(D2) + desc(E)" --fold
  abort: cannot fold non-linear revisions (multiple heads given)
  [255]
check that metaedit respects allowunstable
  $ hg metaedit '.^' --config 'experimental.evolution=createmarkers, allnewcommands'
  abort: cannot edit commit information in the middle of a stack
  (587528abfffe will become unstable and new unstable changes are not allowed)
  [255]
  $ hg metaedit 'desc(A)::desc(B)' --fold --config 'experimental.evolution=createmarkers, allnewcommands'
  abort: cannot fold chain not ending with a head or with branching
  (new unstable changesets are not allowed)
  [255]
  $ hg metaedit --user foobar
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log --template '{rev}: {author}\n' -r 'desc(F):' --hidden
  5: test
  6: test
  7: test
  8: test
  9: foobar
  $ hg log --template '{rev}: {author}\n' -r .
  9: foobar

TODO: support this
  $ hg metaedit '.^::.'
  abort: editing multiple revisions without --fold is not currently supported
  [255]

  $ HGEDITOR=cat hg metaedit '.^::.' --fold
  HG: This is a fold of 2 changesets.
  HG: Commit message of changeset 7.
  
  E
  
  HG: Commit message of changeset 9.
  
  F
  
  
  
  HG: Enter commit message.  Lines beginning with 'HG:' are removed.
  HG: Leave message empty to abort commit.
  HG: --
  HG: user: test
  HG: branch 'default'
  HG: added E
  HG: added F
  2 changesets folded
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ glog -r .
  @  10:a08d35fd7d9d@default(draft) E
  |
  ~

no new commit is created here because the date is the same
  $ HGEDITOR=cat hg metaedit
  E
  
  
  F
  
  
  HG: Enter commit message.  Lines beginning with 'HG:' are removed.
  HG: Leave message empty to abort commit.
  HG: --
  HG: user: test
  HG: branch 'default'
  HG: added E
  HG: added F
  nothing changed

  $ glog -r '.^::.'
  @  10:a08d35fd7d9d@default(draft) E
  |
  o  3:3260958f1169@default(draft) C
  |
  ~

TODO: don't create a new commit in this case, we should take the date of the
old commit (we add a default date with a value to show that metaedit is taking
the current date to generate the hash, this way we still have a stable hash
but highlight the bug)
  $ hg metaedit --config defaults.metaedit= --config devel.default-date="42 0"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -r '.^::.' --template '{rev}: {desc|firstline}\n'
  3: C
  11: E

  $ hg up .^
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ hg metaedit --user foobar2 tip
  $ hg log --template '{rev}: {author}\n' -r "user(foobar):" --hidden
  9: foobar
  10: test
  11: test
  12: foobar2
  $ hg diff -r "10" -r "11" --hidden

'fold' one commit
  $ hg metaedit "desc(D2)" --fold --user foobar3
  1 changesets folded
  $ hg log -r "tip" --template '{rev}: {author}\n'
  13: foobar3
