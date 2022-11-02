if (( $+commands[jira] )); then
    jira_cache="$XDG_CACHE_HOME/zsh/completions/_jira"
    if [[ ! -e $jira_cache ]]; then
        jira completion zsh > "$jira_cache"
    fi
fi
