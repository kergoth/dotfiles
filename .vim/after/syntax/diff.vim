" Diff context begins with a space, so blank lines of context
" are being inadvertantly flagged as redundant whitespace.
" Adjust the match to exclude the first column.
match RedundantWhitespace /\%>1c\(\s\+$\| \+\ze\t\)/
