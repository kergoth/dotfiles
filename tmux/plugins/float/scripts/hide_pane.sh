#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################

#########################################################################
# Place a pane in the floating session with a name indicating the type
# of pane being placed (repl, editor, aux) and the session the pane
# belongs to
#########################################################################

#the only floating windows that should exist for a session are repl, editor, and anon

#if floating window name already exists check the TMUX_FLOATING_CLOBBER env var if it should be left alone or not
#if it has a value of 1 the floating window will be destroyed and replaced
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"
if [ 1 -eq $(count_panes) ]; then
	exit
fi

float_pane(){
		tmux break-pane -n $1 -t floating: > /dev/null
}

WINDOW_NAME=$(format_floating_name $1)
WINDOW_EXISTS=$(window_exists $1)
case $TMUX_FLOAT_MODE in
			"NORMAL") 
					if [ "1" == "$WINDOW_EXISTS" ]; then
						echo "A pane is already using the $FLOAT for float for this session"
					else
						float_pane $WINDOW_NAME
					fi;;
			"CLOBBER")
					tmux kill-window -t floating:$WINDOW_NAME
					float_pane $WINDOW_NAME;;
			"SWAP") 
					TMP_NAME=$(cat /proc/sys/kernel/random/uuid)
					tmux rename-window -t floating:$WINDOW_NAME $TMP_NAME
					float_pane $WINDOW_NAME
					tmux join-pane -hs floating:$TMP_NAME
					;;
	esac
