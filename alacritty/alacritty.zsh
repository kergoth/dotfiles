if [[ $OSTYPE =~ darwin ]]; then
    alacritty() {
        local app=$(locate_app_by_id io.alacritty | head -n 1)
        "$app/Contents/MacOS/alacritty" --working-directory "$PWD" "$@"
    }
else
    alias alacritty='alacritty --working-directory "$PWD"'
fi
