# See https://github.com/fish-shell/fish-shell/issues/117
function time --description "Wrapper for time. Note that there's additional overhead due to spawning another fish process"
	command time -p fish -c "$argv"
end
