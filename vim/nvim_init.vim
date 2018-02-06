if !exists('$XDG_DATA_HOME')
  let $XDG_DATA_HOME = $HOME . '/.config'
endif
set runtimepath^=~/.vim runtimepath+=~/.vim/after runtimepath+=$XDG_CONFIG_HOME/vim
let &packpath = &runtimepath
source $XDG_CONFIG_HOME/vim/vimrc
