#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"

init_floating_session(){
	tmux new-session -t floating -s floating -d 2> /dev/null
	tmux rename-window -t floating:1 float
}

set_bindings(){
	#for hiding and showing the repl
	tmux bind-key C-r run-shell "$CURRENT_DIR/scripts/hide_pane.sh repl"
	tmux bind-key M-r run-shell "$CURRENT_DIR/scripts/show_pane.sh repl"
	#for hiding and showing the editor
	tmux bind-key C-e run-shell "$CURRENT_DIR/scripts/hide_pane.sh editor"
	tmux bind-key M-e run-shell "$CURRENT_DIR/scripts/show_pane.sh editor"
	#for hiding and showing the aux pane
 	tmux bind-key C-h run-shell "$CURRENT_DIR/scripts/hide_pane.sh"
	tmux bind-key M-h run-shell "$CURRENT_DIR/scripts/show_pane.sh"
}

set_env(){
	# possible options are NORMAL CLOBBER and SWAP
	tmux set-environment -g "TMUX_FLOAT_MODE" "NORMAL"
	tmux set-environment "TMUX_SESSION_NAME" $(echo $(tmux display-message -p '#S'))
}

set_hooks(){
#	session_created
	tmux set-hook -g session-created "run '$CURRENT_DIR/scripts/hooks/session_created.sh'"
#	session-closed
	tmux set-hook -g session-closed "run '$CURRENT_DIR/scripts/hooks/session_deleted.sh'"
#	session-renamed	
	tmux set-hook -g session-renamed "run '$CURRENT_DIR/scripts/hooks/session_renamed.sh'"
}

main(){
	init_floating_session
	set_hooks
	set_env
	set_bindings
}

main
