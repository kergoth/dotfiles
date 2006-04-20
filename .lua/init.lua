local home = os.getenv('HOME')
local function path(min,maj)
    local verstr = tostring(maj)..tostring(min)
    return './?.lua;./?/init.lua;'..home..'/.lua'..verstr..'/?.lua;'..home..'/.lua'..verstr..'/?/init.lua;/usr/local/share/lua'..verstr..'/?.lua;/usr/local/share/lua'..verstr..'/?/init.lua;/usr/local/lib/lua'..verstr..'/?.lua;/usr/local/lib/lua'..verstr..'/?/init.lua;/usr/share/lua'..verstr..'/?.lua;/usr/share/lua'..verstr..'/?/init.lua;/usr/lib/lua'..verstr..'/?.lua;/usr/lib/lua'..verstr..'/?/init.lua'
end
local function cpath(min,maj)
    local verstr = tostring(maj)..tostring(min)
    return './?.so;./l?.so;./lib?.so;'..home..'/.lua'..verstr..'/?.so;'..home..'/.lua'..verstr..'/l?.so;'..home..'/.lua'..verstr..'/lib?.so;/usr/local/lib/lua'..verstr..'/?.so;/usr/local/lib/lua'..verstr..'/l?.so;/usr/local/lib/lua'..verstr..'/lib?.so;/usr/lib/lua'..verstr..'/?.so;/usr/lib/lua'..verstr..'/l?.so;/usr/lib/lua'..verstr..'/lib?.so'
end

local _,_,maj,min = string.find(_VERSION, '%s(%d)%p(%d)')
if maj and min then
    if tonumber(maj) >= 5 then
        min = tonumber(min)

        local home = os.getenv('HOME')
        if min < 1 then
            --require('compat-5.1')
            LUA_PATH = path(min, maj)
            LUA_CPATH = cpath(min, maj)
        else
            package.path = path(min, maj)
            package.cpath = cpath(min, maj)
        end
    end
end

pcall(require, 'init')
-- pcall(require, 'std')
