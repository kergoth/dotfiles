set -e fish_greeting

if status --is-interactive
    function fish_greeting
        if test (t | wc -l) -ne 0
            echo Tasks:
            t | sed 's/^/  /'
        end

        if test (h | wc -l) -ne 0
            echo Personal tasks:
            h | sed 's/^/  /'
        end
    end
end
