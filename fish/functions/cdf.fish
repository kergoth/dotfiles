if test $OS = darwin
    # cd to front-most Finder window
    function cdf
        cd (osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')
    end
end
