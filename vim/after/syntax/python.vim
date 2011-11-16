" NOTE: python's comment group should really be converted to a cluster to make
" it easier to mark up its contents.
syn match   pythonComment	"#.*$" contains=pythonTodo,vimModeline

syn match   pythonDecorator "@[a-zA-Z_][a-zA-Z0-9_.]*$" skipwhite

syn clear pythonStatement
syn keyword pythonStatement	as assert break continue del exec global
syn keyword pythonStatement	lambda nonlocal pass print return with yield

syn match   pythonDefStatement /^\s*\%(def\|class\)/
  \ nextgroup=pythonFunction skipwhite
hi def link pythonDefStatement pythonStatement

syn region  pythonFunctionFold	start="^\z(\s*\)\%(def\|class\)\>"
  \ end="\ze\%(\s*\n\)\+\%(\z1\s\)\@!." fold transparent
syn match   pythonFunction	"[a-zA-Z_][a-zA-Z0-9_]*" contained

if !exists("python_no_comment_fold")
  syn match   pythonMultiLineComment "\(^\s*#.*\n\)\{2,}" contains=pythonComment transparent fold
endif

if !exists("python_no_import_fold")
  syn clear pythonInclude
  syn match pythonInclude "\(import\|from\)"

  syn match pythonImport "import .*" contains=pythonInclude,pythonStatement
  syn match pythonImportFrom "from .*" contains=pythonInclude
  syn match pythonMultiLineImport "\(^\s*import .*\n\|\n\n\|from .*\n\)\{2,}"
        \ contains=pythonImport,pythonImportFrom transparent fold
endif
