// https://github.com/onivim/oni/wiki/Configuration

const activate = (oni) => {
    oni.input.bind("<c-enter>", () => console.log("Control+Enter was pressed"))

    // Or remove the default bindings here by uncommenting the below line:
    // oni.input.unbind("<c-p>")
}

const deactivate = () => {
    console.log("config deactivated")
}

module.exports = {
    activate,
    deactivate,

    "oni.loadInitVim": true,
    //"oni.bookmarks": ["~/Documents"],

    "editor.fontSize": "14px",
    //"editor.fontFamily": "Input Mono Narrow",
    "editor.fontFamily": "InputMonoNarrow-Thin",

    "environment.additionalPaths": [
        "/Users/kergoth/Dropbox/dotfiles/scripts",
        "/Users/kergoth/.local/bin",
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin"
    ],

    "ui.colorscheme": "base16-tomorrow-night",
    "ui.animations.enabled": true,
    "ui.fontSmoothing": "auto"
}
