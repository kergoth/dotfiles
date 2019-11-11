DNTW_DIR="${DNTW_DIR:-${XDG_DATA_HOME:-~/.local/share}/dntw}"

if (( $+commands[nvim] )) && [[ -e "$DNTW_DIR" ]]; then
    . "$DNTW_DIR/dntw.sh"

    # Invoke `dntw_edit` with an explicit `$DNTW_NVIM_CMD` since this function's
    # name conflicts with the real `nvim`.
    DNTW_NVIM_CMD="$(/usr/bin/env command -v nvim)"

    nvim () {
        if [ "$TERM_PROGRAM" = "vscode" ]; then
            # If we typed "nvim" while inside the integrated Visual Studio Code terminal,
            # open the file in Code instead.
            code "$@"
        else
            dntw_edit "$@"
        fi
    }

    # These convenience aliases simply invoke the function above.
    alias vi='nvim'
    alias vim='nvim'
    alias e='nvim'

    # Ensure our tmux sessions make the id available
    dntw_id () {
        export DNTW_ID=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c16)
    }

    alias tmux="dntw_id; tmux -u2 -f $XDG_CONFIG_HOME/tmux/config"
    alias tmx="dntw_id; tmx"
    alias attach-workspace="dntw_id; attach-workspace"
    alias att="dntw_id; att"
fi
