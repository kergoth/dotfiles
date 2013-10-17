function ip -d 'return the current external ip, courtesy opendns'
    dig +short myip.opendns.com @resolver1.opendns.com
end
