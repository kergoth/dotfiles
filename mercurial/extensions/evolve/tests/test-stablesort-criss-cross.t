Test for stable ordering capabilities
=====================================

  $ . $TESTDIR/testlib/pythonpath.sh

  $ cat << EOF >> $HGRCPATH
  > [extensions]
  > hgext3rd.evolve =
  > [ui]
  > logtemplate = "{rev} {node|short} {desc} {tags}\n"
  > [alias]
  > showsort = debugstablesort --template="{node|short}\n"
  > EOF

  $ checktopo () {
  >     seen='null';
  >     for node in `hg showsort --rev "$1"`; do
  >         echo "=== checking $node ===";
  >         hg log --rev "($seen) and $node::";
  >         seen="${seen}+${node}";
  >     done;
  > }

  $ cat << EOF >> random_rev.py
  > import random
  > import sys
  > 
  > loop = int(sys.argv[1])
  > var = int(sys.argv[2])
  > for x in range(loop):
  >     print(x + random.randint(0, var))
  > EOF

Check criss cross merge
=======================

  $ hg init crisscross_A
  $ cd crisscross_A
  $ hg debugbuilddag '
  > ...:base         # create some base
  > # criss cross #1: simple
  > +3:AbaseA      # "A" branch for CC "A"
  > <base+2:AbaseB # "B" branch for CC "B"
  > <AbaseA/AbaseB:AmergeA
  > <AbaseB/AbaseA:AmergeB
  > <AmergeA/AmergeB:Afinal
  > # criss cross #2:multiple closes ones
  > .:BbaseA
  > <AmergeB:BbaseB
  > <BbaseA/BbaseB:BmergeA
  > <BbaseB/BbaseA:BmergeB
  > <BmergeA/BmergeB:BmergeC
  > <BmergeB/BmergeA:BmergeD
  > <BmergeC/BmergeD:Bfinal
  > # criss cross #2:many branches
  > <Bfinal.:CbaseA
  > <Bfinal+2:CbaseB
  > <Bfinal.:CbaseC
  > <Bfinal+5:CbaseD
  > <Bfinal.:CbaseE
  > <CbaseA/CbaseB+7:CmergeA
  > <CbaseA/CbaseC:CmergeB
  > <CbaseA/CbaseD.:CmergeC
  > <CbaseA/CbaseE:CmergeD
  > <CbaseB/CbaseA+2:CmergeE
  > <CbaseB/CbaseC:CmergeF
  > <CbaseB/CbaseD.:CmergeG
  > <CbaseB/CbaseE:CmergeH
  > <CbaseC/CbaseA.:CmergeI
  > <CbaseC/CbaseB:CmergeJ
  > <CbaseC/CbaseD+5:CmergeK
  > <CbaseC/CbaseE+2:CmergeL
  > <CbaseD/CbaseA:CmergeM
  > <CbaseD/CbaseB...:CmergeN
  > <CbaseD/CbaseC:CmergeO
  > <CbaseD/CbaseE:CmergeP
  > <CbaseE/CbaseA:CmergeQ
  > <CbaseE/CbaseB..:CmergeR
  > <CbaseE/CbaseC.:CmergeS
  > <CbaseE/CbaseD:CmergeT
  > <CmergeA/CmergeG:CmergeWA
  > <CmergeB/CmergeF:CmergeWB
  > <CmergeC/CmergeE:CmergeWC
  > <CmergeD/CmergeH:CmergeWD
  > <CmergeT/CmergeI:CmergeWE
  > <CmergeS/CmergeJ:CmergeWF
  > <CmergeR/CmergeK:CmergeWG
  > <CmergeQ/CmergeL:CmergeWH
  > <CmergeP/CmergeM:CmergeWI
  > <CmergeO/CmergeN:CmergeWJ
  > <CmergeO/CmergeN:CmergeWK
  > <CmergeWA/CmergeWG:CmergeXA
  > <CmergeWB/CmergeWH:CmergeXB
  > <CmergeWC/CmergeWI:CmergeXC
  > <CmergeWD/CmergeWJ:CmergeXD
  > <CmergeWE/CmergeWK:CmergeXE
  > <CmergeWF/CmergeWA:CmergeXF
  > <CmergeXA/CmergeXF:CmergeYA
  > <CmergeXB/CmergeXE:CmergeYB
  > <CmergeXC/CmergeXD:CmergeYC
  > <CmergeYA/CmergeYB:CmergeZA
  > <CmergeYC/CmergeYB:CmergeZB
  > <CmergeZA/CmergeZB:Cfinal
  > '
  $ hg log -G
  o    94 01f771406cab r94 Cfinal tip
  |\
  | o    93 84d6ec6a8e21 r93 CmergeZB
  | |\
  o | |  92 721ba7c5f4ff r92 CmergeZA
  |\| |
  | | o    91 8ae32c3ed670 r91 CmergeYC
  | | |\
  | o \ \    90 8b79544bb56d r90 CmergeYB
  | |\ \ \
  o \ \ \ \    89 041e1188f5f1 r89 CmergeYA
  |\ \ \ \ \
  | o \ \ \ \    88 2472d042ec95 r88 CmergeXF
  | |\ \ \ \ \
  | | | | o \ \    87 c7d3029bf731 r87 CmergeXE
  | | | | |\ \ \
  | | | | | | | o    86 469c700e9ed8 r86 CmergeXD
  | | | | | | | |\
  | | | | | | o \ \    85 28be96b80dc1 r85 CmergeXC
  | | | | | | |\ \ \
  | | | o \ \ \ \ \ \    84 dbde319d43a3 r84 CmergeXB
  | | | |\ \ \ \ \ \ \
  o | | | | | | | | | |  83 b3cf98c3d587 r83 CmergeXA
  |\| | | | | | | | | |
  | | | | | | o | | | |    82 1da228afcf06 r82 CmergeWK
  | | | | | | |\ \ \ \ \
  | | | | | | +-+-------o  81 0bab31f71a21 r81 CmergeWJ
  | | | | | | | | | | |
  | | | | | | | | | o |    80 cd345198cf12 r80 CmergeWI
  | | | | | | | | | |\ \
  | | | | o \ \ \ \ \ \ \    79 82238c0bc950 r79 CmergeWH
  | | | | |\ \ \ \ \ \ \ \
  o \ \ \ \ \ \ \ \ \ \ \ \    78 89a0fe204177 r78 CmergeWG
  |\ \ \ \ \ \ \ \ \ \ \ \ \
  | | | o \ \ \ \ \ \ \ \ \ \    77 97d19fc5236f r77 CmergeWF
  | | | |\ \ \ \ \ \ \ \ \ \ \
  | | | | | | | | o \ \ \ \ \ \    76 37ad3ab0cddf r76 CmergeWE
  | | | | | | | | |\ \ \ \ \ \ \
  | | | | | | | | | | | | | | | o    75 790cdfecd168 r75 CmergeWD
  | | | | | | | | | | | | | | | |\
  | | | | | | | | | | | | o \ \ \ \    74 698970a2480b r74 CmergeWC
  | | | | | | | | | | | | |\ \ \ \ \
  | | | | | o \ \ \ \ \ \ \ \ \ \ \ \    73 31d7b43cc321 r73 CmergeWB
  | | | | | |\ \ \ \ \ \ \ \ \ \ \ \ \
  | | o \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \    72 eed373b0090d r72 CmergeWA
  | | |\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
  | | | | | | | | | | | o \ \ \ \ \ \ \ \    71 4f3b41956174 r71 CmergeT
  | | | | | | | | | | | |\ \ \ \ \ \ \ \ \
  | | | | | o | | | | | | | | | | | | | | |  70 c3c7fa726f88 r70 CmergeS
  | | | | | | | | | | | | | | | | | | | | |
  | | | | | o-------------+ | | | | | | | |  69 d917f77a6439 r69
  | | | | | | | | | | | | | | | | | | | | |
  | o | | | | | | | | | | | | | | | | | | |  68 fac9e582edd1 r68 CmergeR
  | | | | | | | | | | | | | | | | | | | | |
  | o | | | | | | | | | | | | | | | | | | |  67 e4cfd6264623 r67
  | | | | | | | | | | | | | | | | | | | | |
  | o---------------------+ | | | | | | | |  66 d99e0f7dad5b r66
  | | | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | o-----+ | | | | | | | |  65 c713eae2d31f r65 CmergeQ
  | | | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | | | +-+-----------o | |  64 b33fd5ad4c0c r64 CmergeP
  | | | | | | | | | | | | | | | | | |  / /
  | | | | | +-----------+-----o | | | / /  63 bf6593f7e073 r63 CmergeO
  | | | | | | | | | | | | | |  / / / / /
  | | | | | | | | | | | | | o | | | | |  62 3871506da61e r62 CmergeN
  | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | | | | | o | | | | |  61 c84da74cf586 r61
  | | | | | | | | | | | | | | | | | | |
  | | | | | | | | | | | | | o | | | | |  60 5eec91b12a58 r60
  | | | | | | | | | | | | | | | | | | |
  | +-------------------+---o | | | | |  59 0484d39906c8 r59
  | | | | | | | | | | | | |  / / / / /
  | | | | | | | | | +---+-------o / /  58 29141354a762 r58 CmergeM
  | | | | | | | | | | | | | | |  / /
  | | | | | | | | o | | | | | | | |  57 e7135b665740 r57 CmergeL
  | | | | | | | | | | | | | | | | |
  | | | | | | | | o | | | | | | | |  56 c7c1497fc270 r56
  | | | | | | | | | | | | | | | | |
  | | | | | +-----o-------+ | | | |  55 76151e8066e1 r55
  | | | | | | | |  / / / / / / / /
  o | | | | | | | | | | | | | | |  54 9a67238ad1c4 r54 CmergeK
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  53 c37e7cd9f2bd r53
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  52 0d153e3ad632 r52
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  51 97ac964e34b7 r51
  | | | | | | | | | | | | | | | |
  o | | | | | | | | | | | | | | |  50 900dd066a072 r50
  | | | | | | | | | | | | | | | |
  o---------+---------+ | | | | |  49 673f5499c8c2 r49
   / / / / / / / / / / / / / / /
  +-----o / / / / / / / / / / /  48 8ecb28746ec4 r48 CmergeJ
  | | | |/ / / / / / / / / / /
  | | | | | | | o | | | | | |  47 d6c9e2d27f14 r47 CmergeI
  | | | | | | | | | | | | | |
  | | | +-------o | | | | | |  46 bfcfd9a61e84 r46
  | | | | | | |/ / / / / / /
  +---------------+-------o  45 40553f55397e r45 CmergeH
  | | | | | | | | | | | |
  | | o | | | | | | | | |  44 d94da36be176 r44 CmergeG
  | | | | | | | | | | | |
  +---o---------+ | | | |  43 4b39f229a0ce r43
  | |  / / / / / / / / /
  +---+---o / / / / / /  42 43fc0b77ff07 r42 CmergeF
  | | | |  / / / / / /
  | | | | | | | | o |  41 88eace5ce682 r41 CmergeE
  | | | | | | | | | |
  | | | | | | | | o |  40 d928b4e8a515 r40
  | | | | | | | | | |
  +-------+-------o |  39 88714f4125cb r39
  | | | | | | | |  /
  | | | | +---+---o  38 e3e6738c56ce r38 CmergeD
  | | | | | | | |
  | | | | | | | o  37 32b41ca704e1 r37 CmergeC
  | | | | | | | |
  | | | | +-+---o  36 01e29e20ea3f r36
  | | | | | | |
  | | | o | | |  35 1f4a19f83a29 r35 CmergeB
  | | |/|/ / /
  | o | | | |  34 722d1b8b8942 r34 CmergeA
  | | | | | |
  | o | | | |  33 47c836a1f13e r33
  | | | | | |
  | o | | | |  32 2ea3fbf151b5 r32
  | | | | | |
  | o | | | |  31 0c3f2ba59eb7 r31
  | | | | | |
  | o | | | |  30 f3441cd3e664 r30
  | | | | | |
  | o | | | |  29 b9c3aa92fba5 r29
  | | | | | |
  | o | | | |  28 3bdb00d5c818 r28
  | | | | | |
  | o---+ | |  27 2bd677d0f13a r27
  |/ / / / /
  | | | | o  26 de05b9c29ec7 r26 CbaseE
  | | | | |
  | | | o |  25 ad46a4a0fc10 r25 CbaseD
  | | | | |
  | | | o |  24 a457569c5306 r24
  | | | | |
  | | | o |  23 f2bdd828a3aa r23
  | | | | |
  | | | o |  22 5ce588c2b7c5 r22
  | | | | |
  | | | o |  21 17b6e6bac221 r21
  | | | |/
  | o---+  20 b115c694654e r20 CbaseC
  |  / /
  o | |  19 884936b34999 r19 CbaseB
  | | |
  o---+  18 9729470d9329 r18
   / /
  o /  17 4f5078f7da8a r17 CbaseA
  |/
  o    16 3e1560705803 r16 Bfinal
  |\
  | o    15 55bf3fdb634f r15 BmergeD
  | |\
  o---+  14 39bab1cb1cbe r14 BmergeC
  |/ /
  | o    13 f7c6e7bfbcd0 r13 BmergeB
  | |\
  o---+  12 26f59ee8b1d7 r12 BmergeA
  |/ /
  | o  11 3e2da24aee59 r11 BbaseA
  | |
  | o  10 5ba9a53052ed r10 Afinal
  |/|
  o |    9 07c648efceeb r9 AmergeB BbaseB
  |\ \
  +---o  8 c81423bf5a24 r8 AmergeA
  | |/
  | o  7 65eb34ffc3a8 r7 AbaseB
  | |
  | o  6 0c1445abb33d r6
  | |
  o |  5 c8d03c1b5e94 r5 AbaseA
  | |
  o |  4 bebd167eb94d r4
  | |
  o |  3 2dc09a01254d r3
  |/
  o  2 01241442b3c2 r2 base
  |
  o  1 66f7d451a68b r1
  |
  o  0 1ea73414a91b r0
  

Basic check
-----------

  $ hg showsort --rev 'Afinal'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  $ checktopo Afinal
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===
  === checking c81423bf5a24 ===
  === checking 5ba9a53052ed ===
  $ hg showsort --rev 'AmergeA'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  c81423bf5a24
  $ checktopo AmergeA
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking c81423bf5a24 ===
  $ hg showsort --rev 'AmergeB'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  $ checktopo AmergeB
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===

close criss cross
  $ hg showsort --rev 'Bfinal'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  3e2da24aee59
  26f59ee8b1d7
  f7c6e7bfbcd0
  39bab1cb1cbe
  55bf3fdb634f
  3e1560705803
  $ checktopo Bfinal
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===
  === checking c81423bf5a24 ===
  === checking 5ba9a53052ed ===
  === checking 3e2da24aee59 ===
  === checking 26f59ee8b1d7 ===
  === checking f7c6e7bfbcd0 ===
  === checking 39bab1cb1cbe ===
  === checking 55bf3fdb634f ===
  === checking 3e1560705803 ===

many branches criss cross

  $ hg showsort --rev 'Cfinal'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  3e2da24aee59
  26f59ee8b1d7
  f7c6e7bfbcd0
  39bab1cb1cbe
  55bf3fdb634f
  3e1560705803
  17b6e6bac221
  5ce588c2b7c5
  f2bdd828a3aa
  a457569c5306
  ad46a4a0fc10
  4f5078f7da8a
  01e29e20ea3f
  32b41ca704e1
  29141354a762
  9729470d9329
  884936b34999
  0484d39906c8
  5eec91b12a58
  c84da74cf586
  3871506da61e
  2bd677d0f13a
  3bdb00d5c818
  b9c3aa92fba5
  f3441cd3e664
  0c3f2ba59eb7
  2ea3fbf151b5
  47c836a1f13e
  722d1b8b8942
  4b39f229a0ce
  d94da36be176
  eed373b0090d
  88714f4125cb
  d928b4e8a515
  88eace5ce682
  698970a2480b
  b115c694654e
  1f4a19f83a29
  43fc0b77ff07
  31d7b43cc321
  673f5499c8c2
  900dd066a072
  97ac964e34b7
  0d153e3ad632
  c37e7cd9f2bd
  9a67238ad1c4
  8ecb28746ec4
  bf6593f7e073
  0bab31f71a21
  1da228afcf06
  bfcfd9a61e84
  d6c9e2d27f14
  de05b9c29ec7
  40553f55397e
  4f3b41956174
  37ad3ab0cddf
  c7d3029bf731
  76151e8066e1
  c7c1497fc270
  e7135b665740
  b33fd5ad4c0c
  cd345198cf12
  28be96b80dc1
  c713eae2d31f
  82238c0bc950
  dbde319d43a3
  8b79544bb56d
  d917f77a6439
  c3c7fa726f88
  97d19fc5236f
  2472d042ec95
  d99e0f7dad5b
  e4cfd6264623
  fac9e582edd1
  89a0fe204177
  b3cf98c3d587
  041e1188f5f1
  721ba7c5f4ff
  e3e6738c56ce
  790cdfecd168
  469c700e9ed8
  8ae32c3ed670
  84d6ec6a8e21
  01f771406cab
  $ checktopo Cfinal
  === checking 1ea73414a91b ===
  === checking 66f7d451a68b ===
  === checking 01241442b3c2 ===
  === checking 0c1445abb33d ===
  === checking 65eb34ffc3a8 ===
  === checking 2dc09a01254d ===
  === checking bebd167eb94d ===
  === checking c8d03c1b5e94 ===
  === checking 07c648efceeb ===
  === checking c81423bf5a24 ===
  === checking 5ba9a53052ed ===
  === checking 3e2da24aee59 ===
  === checking 26f59ee8b1d7 ===
  === checking f7c6e7bfbcd0 ===
  === checking 39bab1cb1cbe ===
  === checking 55bf3fdb634f ===
  === checking 3e1560705803 ===
  === checking 17b6e6bac221 ===
  === checking 5ce588c2b7c5 ===
  === checking f2bdd828a3aa ===
  === checking a457569c5306 ===
  === checking ad46a4a0fc10 ===
  === checking 4f5078f7da8a ===
  === checking 01e29e20ea3f ===
  === checking 32b41ca704e1 ===
  === checking 29141354a762 ===
  === checking 9729470d9329 ===
  === checking 884936b34999 ===
  === checking 0484d39906c8 ===
  === checking 5eec91b12a58 ===
  === checking c84da74cf586 ===
  === checking 3871506da61e ===
  === checking 2bd677d0f13a ===
  === checking 3bdb00d5c818 ===
  === checking b9c3aa92fba5 ===
  === checking f3441cd3e664 ===
  === checking 0c3f2ba59eb7 ===
  === checking 2ea3fbf151b5 ===
  === checking 47c836a1f13e ===
  === checking 722d1b8b8942 ===
  === checking 4b39f229a0ce ===
  === checking d94da36be176 ===
  === checking eed373b0090d ===
  === checking 88714f4125cb ===
  === checking d928b4e8a515 ===
  === checking 88eace5ce682 ===
  === checking 698970a2480b ===
  === checking b115c694654e ===
  === checking 1f4a19f83a29 ===
  === checking 43fc0b77ff07 ===
  === checking 31d7b43cc321 ===
  === checking 673f5499c8c2 ===
  === checking 900dd066a072 ===
  === checking 97ac964e34b7 ===
  === checking 0d153e3ad632 ===
  === checking c37e7cd9f2bd ===
  === checking 9a67238ad1c4 ===
  === checking 8ecb28746ec4 ===
  === checking bf6593f7e073 ===
  === checking 0bab31f71a21 ===
  === checking 1da228afcf06 ===
  === checking bfcfd9a61e84 ===
  === checking d6c9e2d27f14 ===
  === checking de05b9c29ec7 ===
  === checking 40553f55397e ===
  === checking 4f3b41956174 ===
  === checking 37ad3ab0cddf ===
  === checking c7d3029bf731 ===
  === checking 76151e8066e1 ===
  === checking c7c1497fc270 ===
  === checking e7135b665740 ===
  === checking b33fd5ad4c0c ===
  === checking cd345198cf12 ===
  === checking 28be96b80dc1 ===
  === checking c713eae2d31f ===
  === checking 82238c0bc950 ===
  === checking dbde319d43a3 ===
  === checking 8b79544bb56d ===
  === checking d917f77a6439 ===
  === checking c3c7fa726f88 ===
  === checking 97d19fc5236f ===
  === checking 2472d042ec95 ===
  === checking d99e0f7dad5b ===
  === checking e4cfd6264623 ===
  === checking fac9e582edd1 ===
  === checking 89a0fe204177 ===
  === checking b3cf98c3d587 ===
  === checking 041e1188f5f1 ===
  === checking 721ba7c5f4ff ===
  === checking e3e6738c56ce ===
  === checking 790cdfecd168 ===
  === checking 469c700e9ed8 ===
  === checking 8ae32c3ed670 ===
  === checking 84d6ec6a8e21 ===
  === checking 01f771406cab ===

Test stability of this mess
---------------------------

  $ hg log -r tip
  94 01f771406cab r94 Cfinal tip
  $ hg showsort --rev 'all()' > ../crisscross.source.order
  $ cd ..

  $ hg clone crisscross_A crisscross_random --rev 0
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd crisscross_random
  $ for x in `python ../random_rev.py 50 44`; do
  >   # using python to benefit from the random seed
  >   hg pull -r $x --quiet
  > done;
  $ hg pull --quiet

  $ hg showsort --rev 'all()' > ../crisscross.random.order
  $ python "$RUNTESTDIR/md5sum.py" ../crisscross.*.order
  d9aab0d1907d5cf64d205a8b9036e959  ../crisscross.random.order
  d9aab0d1907d5cf64d205a8b9036e959  ../crisscross.source.order
  $ diff -u ../crisscross.*.order
  $ hg showsort --rev 'all()'
  1ea73414a91b
  66f7d451a68b
  01241442b3c2
  0c1445abb33d
  65eb34ffc3a8
  2dc09a01254d
  bebd167eb94d
  c8d03c1b5e94
  07c648efceeb
  c81423bf5a24
  5ba9a53052ed
  3e2da24aee59
  26f59ee8b1d7
  f7c6e7bfbcd0
  39bab1cb1cbe
  55bf3fdb634f
  3e1560705803
  17b6e6bac221
  5ce588c2b7c5
  f2bdd828a3aa
  a457569c5306
  ad46a4a0fc10
  4f5078f7da8a
  01e29e20ea3f
  32b41ca704e1
  29141354a762
  9729470d9329
  884936b34999
  0484d39906c8
  5eec91b12a58
  c84da74cf586
  3871506da61e
  2bd677d0f13a
  3bdb00d5c818
  b9c3aa92fba5
  f3441cd3e664
  0c3f2ba59eb7
  2ea3fbf151b5
  47c836a1f13e
  722d1b8b8942
  4b39f229a0ce
  d94da36be176
  eed373b0090d
  88714f4125cb
  d928b4e8a515
  88eace5ce682
  698970a2480b
  b115c694654e
  1f4a19f83a29
  43fc0b77ff07
  31d7b43cc321
  673f5499c8c2
  900dd066a072
  97ac964e34b7
  0d153e3ad632
  c37e7cd9f2bd
  9a67238ad1c4
  8ecb28746ec4
  bf6593f7e073
  0bab31f71a21
  1da228afcf06
  bfcfd9a61e84
  d6c9e2d27f14
  de05b9c29ec7
  40553f55397e
  4f3b41956174
  37ad3ab0cddf
  c7d3029bf731
  76151e8066e1
  c7c1497fc270
  e7135b665740
  b33fd5ad4c0c
  cd345198cf12
  28be96b80dc1
  c713eae2d31f
  82238c0bc950
  dbde319d43a3
  8b79544bb56d
  d917f77a6439
  c3c7fa726f88
  97d19fc5236f
  2472d042ec95
  d99e0f7dad5b
  e4cfd6264623
  fac9e582edd1
  89a0fe204177
  b3cf98c3d587
  041e1188f5f1
  721ba7c5f4ff
  e3e6738c56ce
  790cdfecd168
  469c700e9ed8
  8ae32c3ed670
  84d6ec6a8e21
  01f771406cab
