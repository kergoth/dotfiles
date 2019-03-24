export LESSHISTFILE=$XDG_DATA_HOME/less/lesshist
if (( $+commands[less] )); then
    export PAGER=less
fi
