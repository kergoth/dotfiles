evolve --rev reordering
-----------------------

  $ cat >> $HGRCPATH <<EOF
  > [defaults]
  > amend=-d "0 0"
  > fold=-d "0 0"
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish = False
  > [diff]
  > git = 1
  > unified = 0
  > [ui]
  > logtemplate = {rev}:{node|short}@{branch}({phase}) {desc|firstline}\n
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

  $ mkstack() {
  >    # Creates a stack of commit based on $1 with messages from $2, $3 ..
  >    hg update "$1" -C
  >    shift
  >    mkcommits $*
  > }

  $ mkcommits() {
  >   for i in $@; do mkcommit $i ; done
  > }

Initial setup
  $ hg init testrevorder
  $ cd testrevorder
  $ mkcommits p _a _b _c
  $ hg phase --public 0
  $ hg up 'desc(_a)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ echo "aaa" > _a
  $ hg amend
  2 new unstable changesets
  $ hg log -G
  @  5:12d519679175@default(draft) add _a
  |
  | o  3:4d156641b718@default(draft) add _c
  | |
  | o  2:4d7242ebb004@default(draft) add _b
  | |
  | x  1:2d73fcd7f07d@default(draft) add _a
  |/
  o  0:f92638be10c7@default(public) add p
  

evolve --rev reorders the rev to solve instability, trivial case 2 revs wrong order
  $ hg evolve --rev 'desc(_c) + desc(_b)'
  move:[2] add _b
  atop:[5] add _a
  move:[3] add _c
  atop:[6] add _b
  working directory is now at 52b8f9b04f83

evolve --rev reorders the rev to solve instability. Harder case, obsolescence
accross three stacks in growing rev numbers.
  $ hg up "desc(_c)"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ mkcommit _d
  $ hg up "desc(_a)"
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg amend -m "aprime"
  3 new unstable changesets
  $ hg evolve --rev "desc(_b)"
  move:[6] add _b
  atop:[9] aprime
  working directory is now at 476c9c052aae
  $ hg up "desc(_b) - obsolete()"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg amend -m "bprime"
  $ hg up "desc(aprime)"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ hg amend -m "asecond"
  1 new unstable changesets
  $ hg log -G
  @  12:9a584314f3f3@default(draft) asecond
  |
  | o  11:a59c79776f7c@default(draft) bprime
  | |
  | x  9:81a687b96d4d@default(draft) aprime
  |/
  | o  8:464731bc0ed0@default(draft) add _d
  | |
  | o  7:52b8f9b04f83@default(draft) add _c
  | |
  | x  6:59476c3836ef@default(draft) add _b
  | |
  | x  5:12d519679175@default(draft) add _a
  |/
  o  0:f92638be10c7@default(public) add p
  
  $ hg evolve --rev "unstable()"
  move:[11] bprime
  atop:[12] asecond
  move:[7] add _c
  atop:[13] bprime
  move:[8] add _d
  atop:[14] add _c
  working directory is now at 739f18ac1d03
  $ hg log -G
  @  15:739f18ac1d03@default(draft) add _d
  |
  o  14:e5960578d158@default(draft) add _c
  |
  o  13:4ad33fa88946@default(draft) bprime
  |
  o  12:9a584314f3f3@default(draft) asecond
  |
  o  0:f92638be10c7@default(public) add p
  

Evolve --rev more complex case: two sets of stacks one with prune an no successor, the other one
partially solvable
 
First set of stack:
  $ mkstack "desc(_d)" c1_ c2_ c3_ c4_ >/dev/null
  $ mkstack "desc(_d)" c1prime c2prime >/dev/null
  $ mkstack "desc(_d)" c1second >/dev/null
  $ hg prune "desc(c1_)" -s "desc(c1prime)"
  1 changesets pruned
  3 new unstable changesets
  $ hg prune "desc(c2_)" -s "desc(c2prime)"
  1 changesets pruned
  $ hg prune "desc(c1prime)" -s "desc(c1second)"
  1 changesets pruned
  1 new unstable changesets
  $ hg log -G -r "desc(_d)::"
  @  22:dcf786e878fd@default(draft) add c1second
  |
  | o  21:507d52d715f6@default(draft) add c2prime
  | |
  | x  20:c995cb124ddc@default(draft) add c1prime
  |/
  | o  19:d096a2437fd0@default(draft) add c4_
  | |
  | o  18:cde95c6cba7a@default(draft) add c3_
  | |
  | x  17:e0d9f7a099fe@default(draft) add c2_
  | |
  | x  16:43b7c338b1f8@default(draft) add c1_
  |/
  o  15:739f18ac1d03@default(draft) add _d
  |
  ~

Second set of stack with no successor for b2_:
  $ mkstack "desc(_d)" b1_ b2_ b3_ b4_ >/dev/null
  $ mkstack "desc(_d)" b1prime b3prime >/dev/null
  $ hg prune "desc(b1_)" -s "desc(b1prime)"
  1 changesets pruned
  3 new unstable changesets
  $ hg prune "desc(b3_)" -s "desc(b3prime)"
  1 changesets pruned
  $ hg prune "desc(b2_)"
  1 changesets pruned

  $ hg log -G -r "desc(_d)::"
  @  28:b253ff5b65d1@default(draft) add b3prime
  |
  o  27:4acf61f11dfb@default(draft) add b1prime
  |
  | o  26:594e1fbbd61f@default(draft) add b4_
  | |
  | x  25:be27500cfc76@default(draft) add b3_
  | |
  | x  24:b54f77dc5831@default(draft) add b2_
  | |
  | x  23:0e1eba27e9aa@default(draft) add b1_
  |/
  | o  22:dcf786e878fd@default(draft) add c1second
  |/
  | o  21:507d52d715f6@default(draft) add c2prime
  | |
  | x  20:c995cb124ddc@default(draft) add c1prime
  |/
  | o  19:d096a2437fd0@default(draft) add c4_
  | |
  | o  18:cde95c6cba7a@default(draft) add c3_
  | |
  | x  17:e0d9f7a099fe@default(draft) add c2_
  | |
  | x  16:43b7c338b1f8@default(draft) add c1_
  |/
  o  15:739f18ac1d03@default(draft) add _d
  |
  ~

Solve the full second stack and only part of the first one
  $ echo "(desc(_d)::) - desc(c3_)"
  (desc(_d)::) - desc(c3_)
  $ hg evolve --rev "(desc(_d)::) - desc(c3_)"
  cannot solve instability of d096a2437fd0, skipping
  move:[21] add c2prime
  atop:[22] add c1second
  move:[26] add b4_
  atop:[28] add b3prime
  working directory is now at ea93190a9cd1

Cleanup
  $ hg evolve --rev "(desc(_d)::)"
  move:[18] add c3_
  atop:[29] add c2prime
  move:[19] add c4_
  atop:[31] add c3_
  working directory is now at 35e7b797ace5
  $ hg log -G -r "desc(_d)::"
  @  32:35e7b797ace5@default(draft) add c4_
  |
  o  31:0b9488394e89@default(draft) add c3_
  |
  | o  30:ea93190a9cd1@default(draft) add b4_
  | |
  o |  29:881b9c092e53@default(draft) add c2prime
  | |
  | o  28:b253ff5b65d1@default(draft) add b3prime
  | |
  | o  27:4acf61f11dfb@default(draft) add b1prime
  | |
  o |  22:dcf786e878fd@default(draft) add c1second
  |/
  o  15:739f18ac1d03@default(draft) add _d
  |
  ~

Test multiple revision with some un-evolvable because parent is splitted
------------------------------------------------------------------------

  $ hg up 'desc(c2prime)'
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  $ mkcommit c3part1
  created new head
  $ hg prev
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  [29] add c2prime
  $ mkcommit c3part2
  created new head
  $ hg prune -s 'desc(c3part1)' 'desc(c3_)'
  1 changesets pruned
  1 new unstable changesets
  $ hg prune -s 'desc(c3part2)' 'desc(c3_)'
  1 changesets pruned
  2 new divergent changesets
  $ hg up 'desc(b3prime)'
  2 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ hg amend -m 'b3second'
  1 new unstable changesets
  $ hg evolve --rev 'unstable()'
  move:[30] add b4_
  atop:[35] b3second
  skipping 0b9488394e89: divergent rewriting. can't choose destination
  working directory is now at 31809a198477

