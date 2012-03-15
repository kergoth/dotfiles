set -e fish_greeting

if status --is-interactive
    function fish_greeting
        if have t.py
            if test (t | wc -l) -ne 0
                echo Tasks:
                t | sed 's/^/  /'
            end

            if test (h | wc -l) -ne 0
                echo Personal tasks:
                h | sed 's/^/  /'
            end
        else
            echo >&2 "Warning: ~/bin is not in the PATH"
        end
    end
end
