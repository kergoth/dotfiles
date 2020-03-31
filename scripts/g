#!/bin/sh

usage() {
    cat <<END >&2
${0##*/} [options..] PATTERN [PATH ...]

Run a smart recursive grep if such a tool is available.
Prefers, in this order: batgrep, rg, pt, ag, ack, grep -r
Color defaults to auto.

Options:
  -c WHEN When to show color. Options: auto|always|never
  -t TOOL Specify the underlying tool to run
  -S   Case sensitive, no smart-case
  -i   Case insensitive
  -u   Unrestricted. Do not respect ignore files
  -l   Only print the paths with at least one match
  -w   Only match whole words
  -V   Vim-style
  -v   Verbose. Show the search command to be run
  -h   Show usage
END
    exit 2
}

parse_args() {
    color=auto
    tool=
    function=
    smart_case=1
    no_smart_case=
    ignore_case=
    unrestricted=
    files_with_matches=
    word_regexp=
    vimgrep=
    verbose=0
    while getopts c:t:SiulwVvh opt; do
        case "$opt" in
            c)
                color="$OPTARG"
                case "$color" in
                    auto|always|never)
                        ;;
                    *)
                        echo >&2 "Invalid value for -c: $OPTARG. Valid values: auto, always, never."
                        exit 2
                        ;;
                esac
                ;;
            t)
                tool="$OPTARG"
                if ! has "$tool"; then
                    echo >&2 "Specified tool $tool not found in the PATH."
                    exit 1
                fi
                case "$tool" in
                    batgrep|rg|pt|ag|ack|grep)
                        function="$tool"
                        ;;
                    *)
                        function=tool
                        ;;
                esac
                ;;
            S)
                smart_case=
                no_smart_case=1
                ignore_case=
                ;;
            i)
                smart_case=
                no_smart_case=
                ignore_case=1
                ;;
            u)
                unrestricted=1
                ;;
            l)
                files_with_matches=1
                ;;
            w)
                word_regexp=1
                ;;
            V)
                vimgrep=1
                ;;
            v)
                verbose=1
                ;;
            \? | h)
                usage
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ $# -eq 0 ]; then
        usage
    fi

    if [ "$tool" = batgrep ]; then
        if [ -n "$files_with_matches" ]; then
            echo >&2 "Error: -l is incompatible with -t batgrep. Use rg instead."
            exit 2
        elif [ -n "$vimgrep" ]; then
            echo >&2 "Error: -V is incompatible with -t batgrep. Use rg instead."
            exit 2
        elif [ "$color" = always ] && ! [ -t 1 ]; then
            echo >&2 "Error: -c always is incompatible with -t batgrep. Use rg instead."
            exit 2
        fi
    elif [ -z "$tool" ]; then
        if has rg; then
            if [ -t 1 ] && [ -z "$files_with_matches" ] && [ -z "$vimgrep" ] && has bat && has batgrep; then
                tool=batgrep
            else
                tool=rg
            fi
        else
            for tool in pt ag ack grep; do
                if has "$tool"; then
                    break
                fi
            done
        fi
        function="$tool"
    fi

    force_color=
    force_no_color=
    paged=
    if [ "$color" = never ]; then
        force_no_color=1
    elif [ -t 1 ]; then
        if [ "$color" = auto ]; then
            force_color=1
        fi
        paged=1
    elif [ "$color" = always ]; then
        force_color=1
    fi
}

has() {
    command -v "$1" >/dev/null 2>&1
}

pager() {
    if [ -n "$paged" ]; then
        if [ -n "$PAGER" ]; then
            case "$PAGER" in
                less*)
                    $PAGER -R
                    ;;
                *)
                    $PAGER
                    ;;
            esac
        elif has less; then
            less -R
        else
            more
        fi
    else
        cat
    fi
}

run() {
    if [ $verbose -eq 1 ]; then
        echo >&2 "RUN $*"
    fi
    command "$@"
}

run_batgrep() {
    run batgrep ${force_color:+--color} ${force_no_color:+--no-color} ${unrestricted:+--rg:unrestricted} ${smart_case:+--smart-case} "$@"
}

run_rg() {
    run rg ${force_color:+--color=always} ${force_no_color:+--color=never} ${vimgrep:+--vimgrep} ${unrestricted:+--unrestricted} ${smart_case:+--smart-case} ${paged:+--pretty} --line-number "$@" | pager
}

run_pt() {
    run pt ${force_color:+--color} ${force_no_color:+--nocolor} ${vimgrep:+--column} ${unrestricted:+--skip-vcs-ignores} ${smart_case:+--smart-case} ${paged:+--group} "$@" | pager
}

run_ag() {
    run ag ${force_color:+--color} ${force_no_color:+--nocolor} ${vimgrep:+--vimgrep} ${unrestricted:+--skip-vcs-ignores} ${smart_case:+--smart-case} ${no_smart_case:+--case-sensitive} ${paged:+--group} "$@" | pager
}

run_ack() {
    if command -v ack-grep; then
        alias ack=ack-grep
    fi
    run ack ${force_color:+--color} ${force_no_color:+--nocolor} ${vimgrep:+--column} ${smart_case:+--smart-case} ${paged:+--group} "$@" | pager
}

run_grep() {
    if [ $# -eq 1 ]; then
        set -- "$@" .
    fi
    run grep ${force_color:+--color=always} ${force_no_color:+--color=never} --line-number --recursive ${smart_case:+--ignore-case} -I "$@" | pager
}

run_tool() {
    if [ $# -eq 1 ]; then
        set -- "$@" .
    fi
    run "$tool" "$@" | pager
}

parse_args "$@"
shift $((OPTIND - 1))
if [ "$tool" != tool ]; then
    # Add args common to all supported commands
    set -- ${word_regexp:+--word-regexp} ${ignore_case:+--ignore-case} ${files_with_matches:+--files-with-matches} "$@"
fi
# shellcheck disable=SC2046
set -- $(eval 'echo "$G_'"$(echo "$tool" | tr '[:lower:]' '[:upper:]')"'_ARGS"') "$@"
run_"$function" "$@"
