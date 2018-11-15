export ASDF_DATA_DIR="${ASDF_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/asdf}"
PATH="$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"
