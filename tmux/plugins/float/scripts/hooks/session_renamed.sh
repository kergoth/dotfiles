#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################

#########################################################################
# Hooks for renamed, and killed (MURDER, MURDER IS SAY!!!) sessions
#########################################################################

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/../helpers.sh"

echo $TMUX_SESSION_NAME >> /tmp/renameLog

for WIN_NAME in $(get_floating_windows);
	do
		IFS=$SESSION_NAME_IFS read NAME <<< "$WIN_NAME"
		IFS="_" read -ra FLOAT <<< "$NAME"
		if [ "${FLOAT[0]}" == "$TMUX_SESSION_NAME" ]; then
				tmux rename-window -t floating:$(echo $TMUX_SESSION_NAME)_${FLOAT[1]} $(get_session)_${FLOAT[1]}
		fi
	done

tmux set-environment "TMUX_SESSION_NAME" $(get_session)




