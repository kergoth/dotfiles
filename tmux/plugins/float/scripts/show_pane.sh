#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################
#########################################################################
# Show horizontally attach a floater pane to the current window
#########################################################################

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"
WINDOW_NAME=$(format_floating_name $1)
if [ "0" == "$(window_exists $1)" ]; then
	exit
else
	tmux join-pane -hs floating:$WINDOW_NAME
fi

