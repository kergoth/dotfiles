- Trim down the scripts directory

- Simplify the install scripts

    - Leverage iln to pare down the link script bits, perhaps

- fish:

    - Set up directory bookmarking

        - A very simple mechanism could be done the way markjump is:

            https://raw.github.com/gitaarik/markjump/master/markjump

    - Switch to fasd rather than z

        https://github.com/clvv/fasd

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
