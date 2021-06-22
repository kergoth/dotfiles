# Dracula theme for Kakoune
# https://draculatheme.com/kakoune

# Color palette
# https://github.com/dracula/dracula-theme#color-palette
declare-option str black 'rgb:282a36'
declare-option str gray 'rgb:44475a'
declare-option str white 'rgb:f8f8f2'
declare-option str blue 'rgb:6272a4'
declare-option str cyan 'rgb:8be9fd'
declare-option str green 'rgb:50fa7b'
declare-option str orange 'rgb:ffb86c'
declare-option str pink 'rgb:ff79c6'
declare-option str purple 'rgb:bd93f9'
declare-option str red 'rgb:ff5555'
declare-option str yellow 'rgb:f1fa8c'

declare-option str background %opt{black}
declare-option str dimmed_background %opt{gray}
declare-option str foreground %opt{white}

# Template: https://github.com/mawww/kakoune/blob/master/colors/default.kak
# Documentation: https://github.com/mawww/kakoune/blob/master/doc/pages/faces.asciidoc

# For code
set-face global value "%opt{green}"
set-face global type "%opt{purple}"
set-face global variable "%opt{red}"
set-face global module "%opt{red}"
set-face global function "%opt{red}"
set-face global string "%opt{yellow}"
set-face global keyword "%opt{cyan}"
set-face global operator "%opt{orange}"
set-face global attribute "%opt{pink}"
set-face global comment "%opt{blue}+i"
set-face global documentation 'comment'
set-face global meta "%opt{red}"
set-face global builtin "%opt{white}+b"

# For markup
set-face global title "%opt{red}"
set-face global header "%opt{orange}"
set-face global mono "%opt{green}"
set-face global block "%opt{cyan}"
set-face global link "%opt{green}"
set-face global bullet "%opt{green}"
set-face global list "%opt{white}"

# Builtin faces
set-face global Default "%opt{white},%opt{black}"
set-face global PrimarySelection "%opt{black},%opt{pink}+fg"
set-face global SecondarySelection "%opt{black},%opt{purple}+fg"
set-face global PrimaryCursor "%opt{black},%opt{cyan}+fg"
set-face global SecondaryCursor "%opt{black},%opt{orange}+fg"
set-face global PrimaryCursorEol "%opt{black},%opt{cyan}+fg"
set-face global SecondaryCursorEol "%opt{black},%opt{orange}+fg"
set-face global MenuForeground "%opt{blue},%opt{white}+b"
set-face global MenuBackground "%opt{white},%opt{blue}"
set-face global MenuInfo "%opt{cyan},%opt{blue}"
set-face global Information "%opt{yellow},%opt{gray}"
set-face global Error "%opt{black},%opt{red}"
set-face global StatusLine "%opt{white},%opt{black}"
set-face global StatusLineMode "%opt{black},%opt{green}"
set-face global StatusLineInfo "%opt{purple},%opt{black}"
set-face global StatusLineValue "%opt{orange},%opt{black}"
set-face global StatusCursor "%opt{white},%opt{blue}"
set-face global Prompt "%opt{black},%opt{green}"
set-face global BufferPadding "%opt{gray},%opt{black}"

# Builtin highlighter faces
set-face global LineNumbers "%opt{gray},%opt{black}"
set-face global LineNumberCursor "%opt{white},%opt{gray}+b"
set-face global LineNumbersWrapped "%opt{gray},%opt{black}+i"
set-face global MatchingChar "%opt{black},%opt{blue}"
set-face global Whitespace "%opt{gray},%opt{black}+f"
set-face global WrapMarker 'Whitespace'
