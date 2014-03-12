function source_sh
	sh -c '. "$@" && exec fish --login' source $argv
end
