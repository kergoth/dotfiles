CPANM_LOCALDIR=${CPANM_LOCALDIR:-$XDG_DATA_HOME/cpanm}
if [ -e "$CPANM_LOCALDIR/lib/perl5" ]; then
    local perllocal_cache="$XDG_DATA_HOME/zsh/perllocal.zsh"
    if [[ ! -e $perllocal_cache ]]; then
        mkdir -p $XDG_DATA_HOME/perllocal
        perl -I $CPANM_LOCALDIR/lib/perl5 -Mlocal::lib=$CPANM_LOCALDIR >$perllocal_cache
    fi
    source $perllocal_cache
fi
