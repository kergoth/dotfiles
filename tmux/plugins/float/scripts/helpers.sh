#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################

#########################################################################
# Helper functions for floating panes
# included either transitively in all other scripts
#########################################################################

SESSION_NAME_IFS=' |*|-|#|!|~|M|Z| '

#########################################################################
## Get all currently floating windows
#########################################################################
get_floating_windows(){
	local WINDOW_SET=()
	tmux list-windows -t floating -F '#W' | (while read WIN_NAME;
	do
		WINDOW_SET[(${#WINDOW_SET[@]})]=$WIN_NAME
	done
	echo ${WINDOW_SET[@]})
}

#########################################################################
## Get the session for the current window
#########################################################################
get_session(){
	echo $(tmux display-message -p '#S')
}
#########################################################################
## $1 : Optional floater type, defaults to aux
#########################################################################
format_floating_name(){
	if [ -z $1 ]; then
		WINDOW_NAME=aux
	else
		WINDOW_NAME=$1
	fi
	echo $(get_session)_$WINDOW_NAME
}
#########################################################################
## $1 : optional floater type, defaults to aux
#########################################################################
window_exists(){
	local WINDOW_NAME=$(format_floating_name $1)
	local WINDOW_SET=$(get_floating_windows)

	for WINDOW in $WINDOW_SET; do
	if [ "$WINDOW_NAME" == "$WINDOW" ]; then
		echo 1
		return
	fi
	done
	echo 0
}
#########################################################################
## Count the number of panes for the current window
#########################################################################
count_panes(){
	local PANE_COUNT=0
	tmux list-panes | (while IFS=' ' read PANE_NUM;
	do
			((PANE_COUNT++))
	done
	echo $PANE_COUNT)
}
#########################################################################
## $1 optional name of a session
#########################################################################
get_floaters_for_session(){
	local SESSION=$(tmux display-message -p '#S')
	if [ ! -z $1 ]; then
		SESSION=$1
	fi
	local FLOATERS=()
	for WIN_NAME in $(get_floating_windows); 
	do
		IFS=$SESSION_NAME_IFS read NAME <<< "$WIN_NAME"
			IFS='_' read -ra FLOAT <<< "$NAME"
			if [ "${FLOAT[0]}" == "$SESSION" ]; then
				FLOATERS[(${#FLOATERS[@]})]=$NAME
			fi
	done
	echo ${FLOATERS[@]}
}

#API calls for testing 
if [ ! -z $1 ]; then
	case $1 in
		get_session)
				echo $(get_session);;
		floaters)
				echo $(get_floaters_for_session $2)
	esac
fi
