# TODO

- Add install-cabal script

    1. Install `stack` via static binary to ~/.local/bin
    2. `stack install cabal-install`
    3. Write ghc wrapper that appends to PATH via `stack exec env`

- Move to XDG paths where possible

    - .gist - [Pending](https://github.com/defunkt/gist/pull/189)
    - .mitmproxy

## Reference

- [XDG Base Directory support](https://wiki.archlinux.org/index.php/XDG_Base_Directory_support)
