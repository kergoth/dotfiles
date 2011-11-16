compiler pylint
setlocal commentstring=#\ %s
setlocal sw=4 ts=4 sts=4 et
if exists('+omnifunc')
  set ofu=pythoncomplete#Complete
endif
set isk+=.
setlocal fdm=syntax
setlocal fdl=1
set suffixesadd=.py

" Execute the selected lines of python code
python << EOL
import vim
def EvaluateCurrentRange():
    eval(compile('\n'.join(vim.current.range),'','exec'),globals())
EOL
map <C-h> :py EvaluateCurrentRange()<CR>

" Add python sys.path to vim's file search path for 'gf'
if has('python')
python << EOF
import os
import sys
import vim
for p in sys.path:
    if os.path.isdir(p):
        vim.command(r"set path+=%s" % (p.replace(" ", r"\ ")))
EOF
endif
