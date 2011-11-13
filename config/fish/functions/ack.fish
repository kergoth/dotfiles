if begin have ack-grep; and not have ack; end
    function ack
        ack-grep $argv
    end
end
