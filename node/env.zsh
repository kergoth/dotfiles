NPM_PACKAGES=$XDG_DATA_HOME/npm
export NVM_DIR=$XDG_DATA_HOME/nvm
typeset -gxT NODE_PATH="$NODE_PATH" node_path
node_path=($NPM_PACKAGES/lib/node_modules $node_path)
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
