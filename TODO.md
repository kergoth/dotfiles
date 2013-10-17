- Trim down the scripts directory

- Simplify the install scripts

    - Leverage iln to pare down the link script bits, perhaps

- zsh:

    - determine why tab completion seems to fail miserably for the bits in
      executables in scripts/

- resurrect tmux and go back to using it instead of dtach+dvtm

- vim:

    - Consider resurrection of the vim-kergoth repo

- XDG Locations:

    - Do the vim bundles belong in .config or .local/share?
    - Move these from .config to .cache

        - zcompcache, zcompdump, zhistory
        - bpython/history
        - viminfo
        - vim/tmp

    - Move these from .local/share to .cache

        - fasd env and data
        - lesshst

    - Move these from .config to .local/share

        - zprezto

          This would require patching/forking zprezto, as it hardcodes its own
          location relative to ZDOTDIR
