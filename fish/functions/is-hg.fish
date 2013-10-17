function is-hg
    if not have hg
        return 1
    end

    hg status ^/dev/null >/dev/null
end
