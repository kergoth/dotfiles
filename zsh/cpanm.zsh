CPANM_LOCALDIR=${CPANM_LOCALDIR:-$HOME/perl5}

cpanm() {
    if [[ ! -e $CPANM_LOCALDIR/lib/perl5/local/lib.pm ]]; then
        command cpanm -l $CPANM_LOCALDIR local::lib
    fi
    eval $(perl -I $CPANM_LOCALDIR/lib/perl5 -Mlocal::lib=$CPANM_LOCALDIR)
    command cpanm "$@"
}
