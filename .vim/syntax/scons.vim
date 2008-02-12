" Vim syntax file
" Language:     SConscript
" Maintainer:   Xi Wang <xi.wang@gmail.com>
" Last Change:  2006 Nov 15

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Read the Python syntax to start with
if version < 600
  so <sfile>:p:h/python.vim
else
  runtime! syntax/python.vim
  unlet b:current_syntax
endif

" SConscript extentions
syn keyword sconsTarget		CFile CXXFile DVI Jar Java JavaH
syn keyword sconsTarget		Library LoadableModule M4 Moc
syn keyword sconsTarget		MSVSProject MSVSSolution Object
syn keyword sconsTarget		PCH PDF PostScript Program
syn keyword sconsTarget		RES RMIC RPCGenClient RPCGenHeader
syn keyword sconsTarget		RPCGenService RPCGenXDR
syn keyword sconsTarget		SharedLibrary SharedObject
syn keyword sconsTarget		StaticLibrary StaticObject
syn keyword sconsTarget		Tar TypeLibrary Uic Zip
syn keyword sconsEnv		Action AddPostAction AddPreAction
syn keyword sconsEnv		Alias AlwaysBuild Append AppendENVPath
syn keyword sconsEnv		AppendUnique BitKeeper
syn keyword sconsEnv		BuildDir Builder CacheDir Clean
syn keyword sconsEnv		Command Configure Clone Copy CVS
syn keyword sconsEnv		Default DefaultEnvironment
syn keyword sconsEnv		Depends Dictionary Dir Dump
syn keyword sconsEnv		EnsurePythonVersion EnsureSConsVersion
syn keyword sconsEnv		Environment Execute Exit Export
syn keyword sconsEnv		File FindFile Flatten
syn keyword sconsEnv		GetBuildPath GetLaunchDir GetOption
syn keyword sconsEnv		Help Ignore Import Install InstallAs
syn keyword sconsEnv		Literal Local MergeFlags NoClean
syn keyword sconsEnv		ParseConfig ParseDepends ParseFlags
syn keyword sconsEnv		Preforce Platform Precious
syn keyword sconsEnv		Prepend PrependENVPath PrependUnique
syn keyword sconsEnv		RCS Replace Repository Return
syn keyword sconsEnv		Scanner SCCS SConscript SConscriptChdir
syn keyword sconsEnv		SConsignFile SetDefault SetOption
syn keyword sconsEnv		SideEffect SourceCode SourceSignatures
syn keyword sconsEnv		Split TargetSignatures Tool
syn keyword sconsEnv		Value WhereIs
syn keyword sconsConf		Configure Finish
syn keyword sconsConf		CheckCHeader CheckCXXHeader CheckFun
syn keyword sconsConf		CheckLib CheckLibWithHeader CheckType
syn keyword sconsOpt		Options
syn match   sconsVar		/\<[A-Z_][A-Z0-9_]\+\>/

" Default highlighting
if version >= 508 || !exists("did_scons_syntax_inits")
  if version < 508
    let did_scons_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink sconsTarget	Keyword
  HiLink sconsEnv	Function
  HiLink sconsConf	Function
  HiLink sconsOpt	Function
  HiLink sconsVar	Special
  delcommand HiLink
endif

let b:current_syntax = "scons"
" vim: ts=8
