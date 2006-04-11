syn cluster vimCommentGroup add=vimModeline
syn match vimModeline contained /vim:\s*set[^:]\{-1,\}:/
hi def link vimModeline Special
