function __fish_tm_sessions
    if test -z "$TMPDIR"
        set TMPDIR /tmp
    end
    set DVTM_TMPDIR $TMPDIR/dvtm-$LOGNAME
    ls -1 $DVTM_TMPDIR/*-session $DVTM_TMPDIR/*/*-session 2>/dev/null | sed "s,^$DVTM_TMPDIR/,,; s,-session\$,,"
end

complete -c tm -f -a '(__fish_tm_sessions)'
