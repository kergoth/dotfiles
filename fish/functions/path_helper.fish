if test $OS = darwin
    function path_helper -d 'helper for constructing PATH environment variable on OSX'
        set -l new_path (cat /etc/paths) (cat /etc/paths.d/*)
        for element in $PATH
            if contains $element $new_path
                continue
            end
            set new_path $new_path $element
        end
        printf "set -gx PATH %s;\n" "$new_path"

        set -l new_manpath (cat /etc/manpaths) (cat /etc/manpaths.d/*)
        for element in $MANPATH
            if contains $element $new_manpath
                continue
            end
            set new_manpath $new_manpath $element
        end
        printf "set -gx MANPATH %s;\n" "$new_manpath"
    end
end
