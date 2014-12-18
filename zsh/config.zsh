export LSCOLORS="exfxcxdxbxegedabagacad"
export CLICOLOR=true

autoload -U $ZSH/functions/*(N:t)

HISTFILE=$XDG_DATA_HOME/zsh/history
HISTSIZE=10000
SAVEHIST=10000

# Show running time for commands which take longer than 10 seconds
REPORTTIME=5

# Reduce mode change delay
KEYTIMEOUT=1

setopt NO_BG_NICE # don't nice background tasks
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS # allow functions to have local options
setopt LOCAL_TRAPS # allow functions to have local traps
setopt HIST_VERIFY
setopt SHARE_HISTORY # share history between sessions ???
setopt EXTENDED_HISTORY # add timestamps to history
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD
setopt IGNORE_EOF
setopt EXTENDED_GLOB

setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# don't expand aliases _before_ completion has finished
#   like: git comm-[tab]
setopt complete_aliases

# Let ^W only erase individual path components, as bash does
autoload -U select-word-style
select-word-style bash

# "Magic" escaping
autoload -U url-quote-magic
zle -N self-insert url-quote-magic

autoload -Uz git-escape-magic
git-escape-magic

# Keybinds
bindkey '^[^N' newtab
bindkey '^?' backward-delete-char

autoload edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# zaw binds
bindkey '^R' zaw-history

# Display red dots when autocompleting with the tab key
expand-or-complete-with-dots() {
    echo -n "\e[31m…………\e[0m"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

# Zaw interface configuration
zstyle ':filter-select:highlight' matched fg=green
zstyle ':filter-select' max-lines 10 # don't fill the screen
zstyle ':filter-select' case-insensitive yes # enable case-insensitive
zstyle ':filter-select' extended-search yes # see below
