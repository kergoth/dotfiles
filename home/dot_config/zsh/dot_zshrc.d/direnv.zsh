if (( ${+commands[direnv]} )); then
    if [ "$home_nix" = 1 ] && [ $commands[direnv] = $HOME/.nix/shims/direnv ]; then
        emulate zsh -c "$(nixrun direnv hook zsh | sed -e "s#\"/nix#nixrun \"/nix#g")"
    else
        emulate zsh -c "$(direnv hook zsh)"
    fi

    # Add zsh function paths from nix shell environment paths
    function update_fpath_from_native_build_inputs() {
      # Remove existing /nix/ paths from fpath
      fpath=(${fpath:#/nix/*})

      # Check if nativeBuildInputs is set (should be space-separated paths)
      if [[ -n "$nativeBuildInputs" ]]; then
        for buildpath in ${(z)nativeBuildInputs}; do
          sitefuncs="$buildpath/share/zsh/site-functions"
          if [[ -d "$sitefuncs" ]]; then
            fpath+=("$sitefuncs")
          fi
        done
      fi
    }

    if (( ! ${precmd_functions[(I)update_fpath_from_native_build_inputs]} )); then
      precmd_functions=($precmd_functions update_fpath_from_native_build_inputs )
    fi
    typeset -ag chpwd_functions
    if (( ! ${chpwd_functions[(I)update_fpath_from_native_build_inputs]} )); then
      chpwd_functions=($chpwd_functions update_fpath_from_native_build_inputs)
    fi
fi
