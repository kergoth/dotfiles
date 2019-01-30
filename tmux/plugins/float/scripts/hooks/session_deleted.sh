#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/../helpers.sh"

#get existing sessions and compare against current floating sessions
contains(){
	local -r NEEDLE=$1
	local -ra HAYSTACK=( "${@:2}" )
	local V
	for V in "${HAYSTACK[@]}"; do
		if [ "$V" == "$NEEDLE" ]; then
			echo 0
			exit
		fi
	done
	echo 1
}

get_sessions(){
	s=()
	tmux list-sessions -F '#S' | (while read SESSION;
	do
			s+=($SESSION)
	done
	echo ${s[@]})
}

SESSIONS=$(get_sessions)
tmux list-windows -t floating -F '#W' | (while read w;
do
	IFS='_' read s float<<< "$w"
	EXISTS=$(contains $s $SESSIONS) 
	if [ ! -z $float ] && [ "1" == "$(contains $s $SESSIONS)" ]; then
		1 
		tmux kill-window -t floating:$w
	fi
	echo >> /tmp/deleteLog
done)

