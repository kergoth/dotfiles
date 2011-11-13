if test (uname -s) = Darwin
    function ps
        command ps ux $argv
    end
else
    function ps
        command ps fux $argv
    end
end
