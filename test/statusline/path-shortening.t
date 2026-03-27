Test fish-style unique prefix path shortening:

  $ . "$TESTDIR"/helpers.sh && source_functions

Set up temp directory tree:

  $ mkdir -p "$CRAMTMP/home/Workspace/pano-ops/pano-ec"
  $ mkdir -p "$CRAMTMP/home/Workspace/pano-platform/backend"
  $ mkdir -p "$CRAMTMP/home/Workspace/personal/dotfiles"
  $ mkdir -p "$CRAMTMP/home/.config/nvim"
  $ mkdir -p "$CRAMTMP/home/.claude/projects"
  $ mkdir -p "$CRAMTMP/home/.cargo/bin"
  $ mkdir -p "$CRAMTMP/outside/usr/local/bin"

Basename is never shortened:

  $ shorten_path "$CRAMTMP/home/Workspace/pano-ops/pano-ec" "$CRAMTMP/home"
  W/pano-o/pano-ec

Siblings with shared prefix get unique prefixes:

  $ shorten_path "$CRAMTMP/home/Workspace/pano-platform/backend" "$CRAMTMP/home"
  W/pano-p/backend

No ambiguity — single char is enough:

  $ shorten_path "$CRAMTMP/home/Workspace/personal/dotfiles" "$CRAMTMP/home"
  W/pe/dotfiles

Dot-prefixed dirs work:

  $ shorten_path "$CRAMTMP/home/.config/nvim" "$CRAMTMP/home"
  .co/nvim

Multiple dot-prefixed siblings disambiguate:

  $ shorten_path "$CRAMTMP/home/.claude/projects" "$CRAMTMP/home"
  .cl/projects

  $ shorten_path "$CRAMTMP/home/.cargo/bin" "$CRAMTMP/home"
  .ca/bin

Path outside home shortens intermediates but keeps leading / and full basename:

  $ shorten_path "$CRAMTMP/outside/usr/local/bin" "$CRAMTMP/home"
  /*/o/u/l/bin (glob)

Single segment under home:

  $ mkdir -p "$CRAMTMP/home/myproject"
  $ shorten_path "$CRAMTMP/home/myproject" "$CRAMTMP/home"
  myproject

Path is home itself:

  $ shorten_path "$CRAMTMP/home" "$CRAMTMP/home"
  ~
