if !exists('$XDG_CONFIG_HOME')
  let $XDG_CONFIG_HOME = $HOME . '/.config'
endif
set runtimepath^=~/.vim runtimepath+=~/.vim/after runtimepath^=$XDG_CONFIG_HOME/vim runtimepath+=$XDG_CONFIG_HOME/vim/after
let &packpath = &runtimepath
source $XDG_CONFIG_HOME/vim/vimrc
