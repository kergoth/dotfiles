syn region gitcommitDiff start=/\%(^diff --\%(git\|cc\|combined\) \)\@=/ end=/^$\|^#\@=/ contains=@gitcommitDiff fold
