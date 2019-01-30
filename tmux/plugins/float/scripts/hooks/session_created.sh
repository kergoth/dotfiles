#!/usr/bin/env bash

#########################################################################
# Author: Jacob Rahme <jacob@jrahme.ca>
# Website: git.jrahme.ca
# License: LGPL 3.0 included in repository as COPYING and COPYING.LESSER
# Copyright Jacob Rahme 2017
#########################################################################

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/../helpers.sh"

tmux set-environment "TMUX_SESSION_NAME" $(get_session)
