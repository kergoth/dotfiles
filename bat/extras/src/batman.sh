#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090 disable=SC2155
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")/../lib" && pwd)"
if [[ -n "${MANPAGER}" ]]; then BAT_PAGER="$MANPAGER"; fi
source "${LIB}/constants.sh"
source "${LIB}/pager.sh"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hooks.sh"
# -----------------------------------------------------------------------------
hook_color
hook_pager
hook_version
# -----------------------------------------------------------------------------
MAN_ARGS=()
BAT_ARGS=()

while shiftopt; do MAN_ARGS+=("$OPT"); done
if "$OPT_COLOR"; then
	BAT_ARGS=("--color=always --decorations=always")
else
	BAT_ARGS=("--color=never --decorations=never")
fi
# -----------------------------------------------------------------------------
export MANPAGER='sh -c "col -bx | '"$(printf "%q" "$EXECUTABLE_BAT")"' --language=man --style=grid '"${BAT_ARGS[*]}"'"'
export MANROFFOPT='-c'

if [[ -n "${SCRIPT_PAGER_CMD}" ]]; then
	export BAT_PAGER="$(printf "%q " "${SCRIPT_PAGER_CMD[@]}" "${SCRIPT_PAGER_ARGS[@]}")"
else
	unset BAT_PAGER
fi

command man "${MAN_ARGS[@]}"
exit $?
