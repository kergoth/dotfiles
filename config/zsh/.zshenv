#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

#
# Editors
#

if [[ -n $commands[vim] ]]; then
    export EDITOR=vim
else
    export EDITOR=vi
fi
export VISUAL=$EDITOR
export PAGER='less'

#
# Language
#

if [[ -z "$LANG" ]]; then
  eval "$(locale)"
fi

#
# Paths
#

typeset -gU cdpath fpath mailpath manpath path

# Set the the list of directories that cd searches.
# cdpath=(
#   $cdpath
# )

# Set the list of directories that Zsh searches for programs.
path=(
  $HOME/bin
  /opt/homebrew/bin
  /opt/homebrew/share/python
  /usr/local/{bin,sbin}
  $path
)

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-~/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-~/.local/share}

export INPUTRC=${XDG_CONFIG_HOME}/readline/inputrc
export TERMINFO=${XDG_CONFIG_HOME}/ncurses/terminfo
export CURL_HOME=${XDG_CONFIG_HOME}/curl
export PIP_DOWNLOAD_CACHE=${XDG_CACHE_HOME}/pip
export ACKRC=.ackrc

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
if (( $+commands[lesspipe.sh] )); then
  export LESSOPEN='| /usr/bin/env lesspipe.sh %s 2>&-'
fi

export LESSHISTFILE=$XDG_CONFIG_HOME/less/lesshist

#
# Temporary Files
#

if [[ -d "$TMPDIR" ]]; then
  export TMPPREFIX="${TMPDIR%/}/zsh"
  if [[ ! -d "$TMPPREFIX" ]]; then
    mkdir -p "$TMPPREFIX"
  fi
fi

