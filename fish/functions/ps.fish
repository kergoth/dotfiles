if test $OS = darwin
    function ps
        command ps ux $argv
    end
else
    function ps
        command ps fux $argv
    end
end

