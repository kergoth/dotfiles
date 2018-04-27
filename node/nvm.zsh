if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    if [[ -n "$NODE_VERSION" ]]; then
        . "$NVM_DIR/nvm.sh" --no-use
        path=($NVM_DIR/versions/node/$NODE_VERSION/bin $path)
    else
        . "$NVM_DIR/nvm.sh"
    fi
fi
