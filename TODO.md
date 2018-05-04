# TODO

- tmux

  - Swipe recent useful bits from some other folks tmux.conf
  - Handle xclip vs pbpaste/pbcopy, likely via wrapper script(s)
  - Check into next/previous pane bindings rather than directional for the
    common case, possibly rebinding jk.
  - tmx: fix to switch to the currently selected window when spawning the new
    session bound to the base session
  - Investigate vim/tmux integration bits, particularly window navigation

- Consider importing pyenv/nvm/stack/etc with peru rather than having the install
  scripts clone them to other locations

## System Setup Scripts

- In addition to install-{cabal,node,python,pipsi} and rustup, there's also
  authentication for asciinema, gist, and hub to do on a new system

## Reference

- [XDG Base Directory support](https://wiki.archlinux.org/index.php/XDG_Base_Directory_support)
