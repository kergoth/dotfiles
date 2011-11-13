function is-git
    have git; and env git rev-parse --git-dir ^/dev/null >/dev/null
end
