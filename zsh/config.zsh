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
setopt EXTENDED_GLOB

# More useful with manydots-magic
setopt auto_cd

# Append to history incrementally, but don't auto-import from the shared
# history, as I don't want to lose context
setopt INC_APPEND_HISTORY
setopt NO_SHARE_HISTORY

setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# don't expand aliases _before_ completion has finished
#   like: git comm-[tab]
setopt complete_aliases

# Allow comments in an interactive shell, this is helpful when pasting
setopt interactive_comments

# Disable the prompt for rm * or rm foo/*, as I use rm -I by default
setopt rm_star_silent

# Let ^W only erase individual path components, as bash does
autoload -U select-word-style
select-word-style normal
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

source $ZSH/plugins/syntax-highlighting/zsh-syntax-highlighting.zsh
# autosuggestions must be loaded before history-substring-search
source $ZSH/plugins/autosuggestions/zsh-autosuggestions.zsh
# history-substring-search must be loaded after syntax-highlighting
source $ZSH/plugins/history-substring-search/zsh-history-substring-search.zsh

# Add history-substring-search-* widgets to list of widgets that clear the autosuggestion
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-substring-search-up history-substring-search-down)

# Work around https://github.com/tarruda/zsh-autosuggestions/issues/118
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(expand-or-complete)

if autoload -Uz bracketed-paste-magic; then
    zle -N bracketed-paste bracketed-paste-magic
fi

if autoload -Uz bracketed-paste-url-magic; then
    zle -N bracketed-paste bracketed-paste-url-magic
elif autoload -U url-quote-magic; then
    zle -N self-insert url-quote-magic
    zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}=&'
fi

if autoload -Uz manydots-magic; then
    manydots-magic
fi

if autoload -Uz git-escape-magic; then
    git-escape-magic
fi

# Keybinds

autoload edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Display red dots when autocompleting with the tab key
expand-or-complete-with-dots() {
    echo -n "\e[31m…………\e[0m"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

# Completion menu
zstyle ':completion:*' menu select

# Case-insensitive completion (after trying normal first)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Zaw interface configuration
zstyle ':filter-select:highlight' matched fg=green
zstyle ':filter-select' max-lines 10 # don't fill the screen
zstyle ':filter-select' case-insensitive yes # enable case-insensitive
zstyle ':filter-select' extended-search yes # see below
