# TODO

- Switch back from dvtm+dtach to tmux

  - Swipe recent useful bits from some other folks tmux.conf
  - Consider using a top tab bar, like the vim buffers display I'm using
  - Switch the colors to align with base16-tomorrow-night
  - Handle xclip vs pbpaste/pbcopy, likely via wrapper script(s)
  - Fix the binding to launch man to show with colors, if possible
  - Switch from C-f to C-g to avoid conflict with zsh inline completion

- Consider importing pyenv/nvm/stack/etc with peru rather than having the install
  scripts clone them to other locations

## System Setup Scripts

- In addition to install-{cabal,node,python,pipsi} and rustup, there's also
  authentication for asciinema, gist, and hub to do on a new system

## Reference

- [XDG Base Directory support](https://wiki.archlinux.org/index.php/XDG_Base_Directory_support)
