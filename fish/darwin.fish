set PATH /opt/homebrew/sbin /opt/homebrew/bin $PATH

if have mvim
    alias vim 'mvim -v'
end

for dir in ~/Library/Python/*/bin
    if test -e $dir
        set PATH $dir $PATH
    end
end
