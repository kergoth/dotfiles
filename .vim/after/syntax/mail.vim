" Email signatures generally start with '-- '.  Adjust the
" RedundantWhitespace match for the 'mail' filetype to not
" highlight that particular trailing space in red.
match RedundantWhitespace /\(^--\)\@<!\s\+$/
