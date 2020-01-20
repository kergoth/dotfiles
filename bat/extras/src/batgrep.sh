#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" && pwd)/../lib"
BAT="bat"
source "${LIB}/print.sh"
source "${LIB}/pager.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hooks.sh"
source "${LIB}/version.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_color
hook_pager
# -----------------------------------------------------------------------------
# Options:
# -----------------------------------------------------------------------------
RG_ARGS=()
BAT_ARGS=()
PATTERN=""
FILES=()
OPT_CASE_SENSITIVITY=''
OPT_CONTEXT_BEFORE=2
OPT_CONTEXT_AFTER=2
OPT_FOLLOW=true
OPT_SNIP=""
OPT_HIGHLIGHT=true
OPT_SEARCH_PATTERN=false
OPT_FIXED_STRINGS=false
BAT_STYLE="header,numbers"

# Set options based on the bat version.
if version_compare "$(bat_version)" -gt "0.12"; then
	OPT_SNIP=",snip"
fi

# Parse arguments.
while shiftopt; do
	case "$OPT" in

		# Ripgrep Options
		-i|--ignore-case)              OPT_CASE_SENSITIVITY="--ignore-case";;
		-s|--case-sensitive)           OPT_CASE_SENSITIVITY="--case-sensitive";;
		-S|--smart-case)               OPT_CASE_SENSITIVITY="--smart-case";;
		-A|--after-context)  shiftval; OPT_CONTEXT_AFTER="$OPT_VAL";;
		-B|--before-context) shiftval; OPT_CONTEXT_BEFORE="$OPT_VAL";;
		-C|--context)        shiftval; OPT_CONTEXT_BEFORE="$OPT_VAL";
			                           OPT_CONTEXT_AFTER="$OPT_VAL";;

		-F|--fixed-strings) OPT_FIXED_STRINGS=true; RG_ARGS+=("$OPT");;

		-U|--multiline|\
		-P|--pcre2|\
		-z|--search-zip|\
		-w|--word-regexp|\
		--one-file-system|\
		--multiline-dotall|\
		--ignore|--no-ignore|\
		--crlf|--no-crlf|\
		--hidden|--no-hidden)          RG_ARGS+=("$OPT");;

		-E|--encoding|\
		-g|--glob|\
		-t|--type|\
		-T|--type-not|\
		-m|--max-count|\
		--max-depth|\
		--iglob|\
		--ignore-file)       shiftval; RG_ARGS+=("$OPT" "$OPT_VAL");;

		# Bat Options

		# Script Options
		--no-follow)                   OPT_FOLLOW=false;;
		--no-snip)                     OPT_SNIP="";;
		--no-highlight)                OPT_HIGHLIGHT=false;;
		-p|--search-pattern)           OPT_SEARCH_PATTERN=true;;
		--no-search-pattern)           OPT_SEARCH_PATTERN=false;;

		# Option Forwarding
		--rg:*) {
			if [[ "${OPT:5:1}" = "-" ]]; then
				RG_ARGS+=("${OPT:5}")
			else
				RG_ARGS+=("--${OPT:5}")
			fi
			if [[ -n "$OPT_VAL" ]]; then
				RG_ARGS+=("$OPT_VAL")
			fi
		};;

		# ???
		-*) {
			printc "%{RED}%s: unknown option '%s'%{CLEAR}\n" "$PROGRAM" "$OPT" 1>&2
			exit 1
		};;

		# Search
		*) {
			if [ -z "$PATTERN" ]; then
				PATTERN="$OPT"
			else
				FILES+=("$OPT")
			fi
		};;		
	esac
done

if [[ -z "$PATTERN" ]]; then
	print_error "no pattern provided"
	exit 1
fi

# Generate separator.
COLS="$(tput cols)"
SEP="$(printc "%{DIM}%${COLS}s%{CLEAR}" | sed "s/ /─/g")"

# Append ripgrep and bat arguments.
if [[ -n "$OPT_CASE_SENSITIVITY" ]]; then
	RG_ARGS+=("$OPT_CASE_SENSITIVITY")
fi

if "$OPT_FOLLOW"; then
	RG_ARGS+=("--follow")	
fi

if "$OPT_COLOR"; then
	BAT_ARGS+=("--color=always")
else
	BAT_ARGS+=("--color=never")
fi

if [[ "$OPT_CONTEXT_BEFORE" -eq 0 && "$OPT_CONTEXT_AFTER" -eq 0 ]]; then
	OPT_SNIP=""
	OPT_HIGHLIGHT=false
fi

# Handle the --search-pattern option.
if "$OPT_SEARCH_PATTERN"; then
	if is_pager_less; then
		if "$OPT_FIXED_STRINGS"; then
			# This strange character is a ^R, or Control-R, character. This instructs
			# less to NOT use regular expressions, which is what the -F flag does for
			# ripgrep. If we did not use this, then less would match a different pattern
			# than ripgrep searched for. See man less(1).
			SCRIPT_PAGER_ARGS+=(-p $'\x12'"$PATTERN")
		else
			SCRIPT_PAGER_ARGS+=(-p "$PATTERN")
		fi
	elif is_pager_disabled; then
		print_error "$(
			echo "The -p/--search-pattern option requires a pager, but" \
			     "the pager was explicitly disabled by \$BAT_PAGER or the" \
                 "--paging option."
		)"
		exit 1
	else
		print_error "Unsupported pager '%s' for option -p/--search-pattern" \
		            "$(pager_name)"
		exit 1
	fi
fi

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
main() {
	FOUND_FILES=()
	FOUND=0
	FIRST_PRINT=true
	LAST_LR=()
	LAST_LH=()
	LAST_FILE=''

	do_print() {
		[[ -z "$LAST_FILE" ]] && return 0

		# Print the separator.
		"$FIRST_PRINT" && echo "$SEP"
		FIRST_PRINT=false

		# Print the file.
		"$BAT" "${BAT_ARGS[@]}" \
			   "${LAST_LR[@]}" \
			   "${LAST_LH[@]}" \
			   --style="${BAT_STYLE}${OPT_SNIP}" \
			   --paging=never \
			   --terminal-width="$COLS" \
			   "$LAST_FILE"

		# Print the separator.
		echo "$SEP"
	}

	while IFS=':' read -r file line column; do
		((FOUND++))

		if [[ "$LAST_FILE" != "$file" ]]; then
			do_print
			LAST_FILE="$file"
			LAST_LR=()
			LAST_LH=()
		fi
		
		# Calculate the context line numbers.
		line_start=$((line - OPT_CONTEXT_BEFORE))
		line_end=$((line + OPT_CONTEXT_AFTER))
		[[ "$line_start" -gt 0 ]] || line_start=''

		LAST_LR+=("--line-range=${line_start}:${line_end}")
		[[ "$OPT_HIGHLIGHT" = "true" ]] && LAST_LH+=("--highlight-line=${line}")
	done < <(rg --with-filename --vimgrep "${RG_ARGS[@]}" --sort path "$PATTERN" "${FILES[@]}")
	do_print

	# Exit.
	if [[ "$FOUND" -eq 0 ]]; then
		exit 2
	fi
}

pager_exec main
exit $?

