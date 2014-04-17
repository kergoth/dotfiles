function source_sh
	bash -c '. "$@" && exec fish --login' source $argv
end
