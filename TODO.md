# TODO

- zsh: alter promptline prompt to show user/host when SSH_CLIENT is set
- zsh: add git push/pull status to promptline. The full git status slows things
  down too much, but I'd at least like to see if I'm ahead/behind upstream at
  a glance.
- zsh: also `fo` and `fv` functions to accept base path as `$2`. Be conscious
  of the fact that the paths may be returned as relative

- Consider importing pyenv/nvm/stack/etc with peru rather than having the install
  scripts clone them to other locations

## colors

- git: consider altering the particular colors used in git log to use colors
  which are more obviously from my base16 theme than red and green. For
  example the light blue, off-yellow, and greys.
- tmux: change the active window style to highlight with light blue the way i3
  does, if possible, as improved emphasis
- dvtm: switch the colors to align with base16-tomorrow-night
- dvtm: align the dvtm statusline with airline/tmux, if possible. currently it
  seems ansi color codes sent over the pipe don't get displayed
- Fix base16-fzf to not look horrible
- Try to improve base16-baycomb to be more usable. This would be easier if
  I install the vim plugin that syntax highlights color codes in files
- Symlink base16/scripts/base16-tomorrow-night.sh to .base16_theme, or store
  the name in a text file
  - zsh
  - vim
  - Write scripts to update files/configs in the repo based on .base16_theme

    - fzf
    - Run base16-builder to generate the i3-style theme, then run i3-style to
      update the i3 config with the new theme
      ```
      $ base16-builder -t i3-style -b dark -s tomorrow >base16-tomorrow.yaml
      $ i3-style ./base16-tomorrow.yaml -o ~/.config/i3/config -r
      ```
    - Alter i3/rofi.config to use the appropriate rofi theme
    - `PYGMENTIZE_FORMATTER` for less syntax highlighting in `less/less.zsh`

## System Setup Scripts

- In addition to install-{cabal,node,python,pipsi} and rustup, there's also
  authentication for asciinema, gist, and hub to do on a new system

## Reference

- [XDG Base Directory support](https://wiki.archlinux.org/index.php/XDG_Base_Directory_support)
