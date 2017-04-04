  $ cat >> $HGRCPATH <<EOF
  > [web]
  > push_ssl = false
  > allow_push = *
  > [phases]
  > publish=False
  > [alias]
  > odiff=diff --rev 'limit(obsparents(.),1)' --rev .
  > [extensions]
  > hgext.graphlog=
  > EOF
  $ mkcommit() {
  >    echo "$1" > "$1"
  >    hg add "$1"
  >    hg ci -m "add $1"
  > }

create commit

  $ hg init repo
  $ cd repo
  $ mkcommit a
  $ mkcommit b
  $ hg up -q 0
  $ mkcommit c
  created new head

forge old style relation files

  $ hg log -r 2 --template='{node} ' > .hg/obsolete-relations
  $ hg log -r 1 --template='{node}' >> .hg/obsolete-relations

enable the extensions

  $ echo "obsolete=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/legacy.py" >> $HGRCPATH

  $ hg glog
  abort: old format of obsolete marker detected!
  run `hg debugconvertobsolete` once.
  [255]
  $ hg debugconvertobsolete --traceback
  1 obsolete marker converted
  $ hg glog
  @  changeset:   2:d67cd0334eee
  |  tag:         tip
  |  parent:      0:1f0dee641bb7
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add c
  |
  o  changeset:   0:1f0dee641bb7
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add a
  
  $ hg debugobsolete
  7c3bad9141dcb46ff89abf5f61856facd56e476c d67cd0334eeecfded222fed9009f0db4beb57585 0 (*) {'user': 'test'} (glob)
  $ hg debugconvertobsolete
  nothing to do
  0 obsolete marker converted

Convert json

  $ cat > .hg/store/obsoletemarkers << EOF
  > [
  >     {
  >         "reason": "import from older format.", 
  >         "subjects": [
  >             "3218406b50ed13480765e7c260669620f37fba6e"
  >         ], 
  >         "user": "Pierre-Yves David <pierre-yves.david@ens-lyon.org>", 
  >         "date": [
  >             1336503323.9768269, 
  >             -7200
  >         ], 
  >         "object": "3e03d82708d4da97a92158558dd13386d8f09ad5", 
  >         "id": "4743f676eaf3923cb98c921ee06b2e91052c365b"
  >     }, 
  >     {
  >         "reason": "import from older format.", 
  >         "user": "Pierre-Yves David <pierre-yves.david@logilab.fr>", 
  >         "date": [
  >             1336557472.7875929, 
  >             -7200
  >         ], 
  >         "object": "5c722672795c3a2cb94d0cc9a821c394c1475f87", 
  >         "id": "1fd90a84b7225d2e3062b7e1b3100aa2e060fc72"
  >     }, 
  >     {
  >         "reason": "import from older format.", 
  >         "subjects": [
  >             "0000000000000000000000000000000000000000"
  >         ], 
  >         "user": "Pierre-Yves David <pierre-yves.david@logilab.fr>", 
  >         "date": [
  >             1336557472.784307, 
  >             -7200
  >         ], 
  >         "object": "2c3784e102bb34ccc93862af5bd6d609ee30c577", 
  >         "id": "7d940c5ee1f886c8a6c0d805b43e522cb3ef7a15"
  >     }
  > ]
  > EOF
  $ hg glog
  abort: old format of obsolete marker detected!
  run `hg debugconvertobsolete` once.
  [255]
  $ hg debugconvertobsolete --traceback
  3 obsolete marker converted
  $ hg debugobsolete
  7c3bad9141dcb46ff89abf5f61856facd56e476c d67cd0334eeecfded222fed9009f0db4beb57585 0 (*) {'user': 'test'} (glob)
  3e03d82708d4da97a92158558dd13386d8f09ad5 3218406b50ed13480765e7c260669620f37fba6e 0 (Tue May 08 20:55:23 2012 +0200) {'user': 'Pierre-Yves David <pierre-yves.david@ens-lyon.org>'}
  5c722672795c3a2cb94d0cc9a821c394c1475f87 0 (Wed May 09 11:57:52 2012 +0200) {'user': 'Pierre-Yves David <pierre-yves.david@logilab.fr>'}
  2c3784e102bb34ccc93862af5bd6d609ee30c577 0 (Wed May 09 11:57:52 2012 +0200) {'user': 'Pierre-Yves David <pierre-yves.david@logilab.fr>'}
