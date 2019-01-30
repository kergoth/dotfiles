#/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright 2017
#########################################################################

#TODO make these tests into functiosn to keep the actual testing logic more readable
#	  and make things a bit more documentable

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=/vagrant
FLOATING_SESSION=floating

# bash helpers provided by 'tmux-test'
source "$CURRENT_DIR/helpers/helpers.sh"
# Plugin helpers
source "$ROOT_DIR/scripts/helpers.sh"

install_tmux_plugin_under_test_helper
#creating floating session
tmux new -t floating -s floating -d
#creating testing session
tmux new -d
tmux set-environment -g "TMUX_FLOAT_MODE" "NORMAL"

session_name="$(tmux list-sessions -F "#{session_name}")"

tmux set-environment -g "TMUX_FLOATING_CLOBBER" "0"

float_aux_pane(){
	tmux run-shell "$ROOT_DIR/scripts/hide_pane.sh"
}

join_aux_pane(){
	tmux run-shell "$ROOT_DIR/scripts/show_pane.sh"
}

float_repl_pane(){
	tmux run-shell "$ROOT_DIR/scripts/hide_pane.sh repl"
}

join_repl_pane(){
	tmux run-shell "$ROOT_DIR/scripts/show_pane.sh repl"
}

search_pane(){
	echo $(tmux capture-pane -S 0 -E 4 -p | grep -c "$1")
}

print_error(){
	echo ============$2============
	echo $1
	echo ===========$2==============
}

print_success(){
	echo ---------------------------
	echo $1
	echo
}

print_test_barrier(){
echo
echo '*********************************'
echo $1
echo ---------------------------------
echo $2
echo '*********************************'
echo
}

print_test_barrier "Finished test setup" "Starting single pane tests"

tmux split-window

if [ 2 != $(count_panes) ]; then
	fail_helper "$(print_error 'Panes did not split' 'split error')"
else
	print_success "window successfully split"
fi
##float pane as an aux floater
float_aux_pane
if [ 1 != $(count_panes) ]; then
	fail_helper "$(print_error 'floater did not float' 'float error')"
else
	print_success "aux pane successfully floated"
fi

##try to float a second aux pane
tmux split-window
float_aux_pane >> /dev/null
echo $TMUX_FLOAT_MODE
if [ 2 != $(count_panes) ] ; then
	fail_helper "$(print_error 'aux pane clobber floater when TMUX_FLOATING_MODE is NORMAL' 'float mode error')"
else
	print_success "aux no clobber test passed"
fi

tmux set-environment -g "TMUX_FLOAT_MODE" "CLOBBER"

float_aux_pane >> /dev/null

if [ 1 != $(count_panes) ]; then
	fail_helper "$(print_error 'aux pane did not clobber floater when TMUX_FLOAT_MODE is CLOBBER' 'float mode error')"
else
	print_success "aux pane successfully floated"
fi

##Test swaping windows
tmux set-environment -g "TMUX_FLOAT_MODE" "SWAP"
SPLIT_MESSAGE=$(cat /proc/sys/kernel/random/uuid)
tmux split-window
tmux send-keys $SPLIT_MESSAGE
float_aux_pane

if [ 2 != $(count_panes) ]; then
	fail_helper "$(print_error 'the aux floater was overwritten when TMUX_FLOAT_MODE is swap' 'float mode error')"
fi

float_aux_pane

if [ 2 != $(count_panes) ]; then
	fail_helper "$(print_error 'the aux floater was overwritten' 'float error')"
else
	print_success "aux floater swapped test passed"
fi

if [ 1 != $(search_pane $SPLIT_MESSAGE) ]; then
	fail_helper "$(print_error 'the aux floater did not swap with the current pane' 'swap error')"
else
	print_success "aux floater swap verification test passed!"
fi

tmux set-environment -g "TMUX_FLOAT_MODE" "NORMAL"

if [ 1 != $(window_exists aux) ]; then
	fail_helper "$(print_error 'The aux floater was not found' 'existence error')"
else
	print_success "aux floater found in floating session"
fi
BEFORE_JOIN_COUNT=$(count_panes)
join_aux_pane
if [ "$BEFORE_JOIN_COUNT" == "$(count_panes)" ]; then
	fail_helper "$(print_error 'aux floater did not join window' 'join error')"
else
	print_success "aux floater successfully joined to window"
fi
unset BEFORE_JOIN_COUNT
## clean up the panes
tmux kill-pane -a -t 1
print_test_barrier "Finished single floater test" "Starting multi floater test"

tmux split-window
float_repl_pane

if [ 1 != $(count_panes) ]; then
	fail_helper "$(print_error 'repl pane did not float from window' 'float error')"
else
	print_success "repl pane floated"
fi

if [ 1 != $(window_exists repl) ]; then
	fail_helper "$(print_error 'The repl floater was not found' 'existence error')"
else
	print_success "repl window found in floating session"
fi

tmux split-window

float_repl_pane >> /dev/null

if [ 2 != $(count_panes) ] ; then
	fail_helper "$(print_error 'repl pane clobbered floater when TMUX_FLOAT_MODE is NORMAL' 'float mode error')"
else
	print_success "repl no clobber test passed"
fi

tmux set-environment -g "TMUX_FLOAT_MODE" "CLOBBER" 

float_repl_pane >> /dev/null

if [ 1 != $(count_panes) ]; then
	fail_helper "$(print_error 'repl pane did not clobber floater when TMUX_FLOAT_MODE is CLOBBER' 'float mode error')"
else
	print_success "repl clobber test passed"
fi

tmux set-environment -g "TMUX_FLOAT_MODE" "NORMAL"

join_repl_pane

if [ 2 != $(count_panes) ]; then
	fail_helper "$(print_error 'repl floater did not join window' 'join error')"
else
	print_success "repl floater joining test passed"
fi

print_test_barrier "Finished multi floater tests" "Starting multi session tests"

PANE_MESSAGE_1=$(cat /proc/sys/kernel/random/uuid)
PANE_MESSAGE_2=$(cat /proc/sys/kernel/random/uuid)
PANE_MESSAGE_3=$(cat /proc/sys/kernel/random/uuid)
PANE_MESSAGE_4=$(cat /proc/sys/kernel/random/uuid)
SPLIT_MESSAGE=$(cat /proc/sys/kernel/random/uuid)
#send PANE_MESSAGE_1 to the current pane
tmux send-keys "$PANE_MESSAGE_1"
float_repl_pane
tmux new -s ts1 -d
#send PANE_MESSAGE_2 to the current singular pane
tmux send-keys "$PANE_MESSAGE_2"
tmux split-window
#send PANE_MESSAGE_3 to the newly split window (to be the repl window)
tmux send-keys "$PANE_MESSAGE_3"
float_repl_pane
#split pane for the aux window and send PANE_MESSAGE_4 to it
tmux split-window
tmux send-keys "$PANE_MESSAGE_4"
float_aux_pane

#The new pane is selected when a pane split is done
#So the message we expect to be checking for when we do the comparison
#should be $PANE_MESSAGE_3

if [ 1 != $(count_panes) ]; then
	fail_helper "$(print_error 'repl pane did not float, with another sessions repl pane in floating session' 'multi session float error')"
else
	print_success "multi session float test passed"
fi

join_repl_pane

if [ "2" -lt "$(count_panes)" ]; then
	fail_helper "$(print_error 'multiple panes joined instead of just this sessions repl pane' 'multi session join error')"
else
	print_success "multi session join test passed"
fi

if [ $(search_pane $PANE_MESSAGE_3) != 1 ]; then
	fail_helper "$(print_error 'incorrect pane rejoined to session' 'pane joining error')"
else
	print_success "multi session join pane verification test passed"
fi

#test swapping panes
float_repl_pane
tmux split
tmux send-keys $SPLIT_MESSAGE
echo setting env to swap 2
tmux set-environment -g "TMUX_FLOAT_MODE" "SWAP"
float_repl_pane

if [ $(search_pane $PANE_MESSAGE_3) != 1 ]; then
	fail_helper "$(print_error 'multiple pane swap test passed' 'swap error')"
else
	print_success "multiple pane swap test passed"
fi

#test session rename
SESSION=$(get_session)
tmux rename-session ts2
FAILED=0
#check windows
tmux list-windows -t floating -F '#W' | (while read W;
do
	IFS='_' read s float <<< "$W"	
	if [ "$SESSION" == "$s" ]; then
		FAILED=1
		break
	fi
done)

if [ "$FAILED" -eq "1" ]; then
	fail_helper "$(print_error 'A floating session was not renamed' 'session rename error')"
else
	print_success "Session Rename test passed"
fi
FAILED=0

tmux attach-session -t ts1
tmux kill-session -t ts2

tmux list-windows -t floating -F '#W' | (while read W;
do
	IFS='_' read s float <<< "$W"
	if [ "$s" == "ts2" ]; then
		FAILED=1
		break
	fi
done)

if [ "$FAILED" -eq "1" ]; then
	fail_helper "$(print_error 'floating windows were not deleted with session' 'session delete error')"
else
	print_success "Session Deletion Test passed!"
fi

print_test_barrier "Finished multi session tests" "Finished all tests"

exit_helper
