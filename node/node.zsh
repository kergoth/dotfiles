NPM_PACKAGES="$XDG_DATA_HOME/npm"

typeset -gxT NODE_PATH="$NODE_PATH" node_path
node_path=($NPM_PACKAGES/lib/node_modules $node_path)

path=($NPM_PACKAGES/bin $path)
