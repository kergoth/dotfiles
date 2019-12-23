for cmd in ${${(M)commands:#*/csv*}:t}; do
    case "$cmd" in
        *(json|look|py|stat|sum))
            # These commands don't output csv
            continue
            ;;
    esac

    function "$cmd" () {
        case "$@" in
            -V|--version|-h|--help)
                command "$0" "$@"
                ;;
            *)
                command "$0" "$@" | \
                    if [ -t 1 ]; then
                        csvlook
                    else
                        cat
                    fi
                ;;
        esac
    }
done
