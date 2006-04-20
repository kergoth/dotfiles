local home = os.getenv('HOME')
local function path()
    return './?.lua;./?/init.lua;'..home..'/.lua50/?.lua;'..home..'/.lua50/?/init.lua;/usr/local/share/lua50/?.lua;/usr/local/share/lua50/?/init.lua;/usr/local/lib/lua50/?.lua;/usr/local/lib/lua50/?/init.lua;/usr/share/lua50/?.lua;/usr/share/lua50/?/init.lua;/usr/lib/lua50/?.lua;/usr/lib/lua50/?/init.lua'
end
local function cpath()
    return './?.so;./l?.so;./lib?.so;'..home..'/.lua50/?.so;'..home..'/.lua50/l?.so;'..home..'/.lua50/lib?.so;/usr/local/lib/lua50/?.so;/usr/local/lib/lua50/l?.so;/usr/local/lib/lua50/lib?.so;/usr/lib/lua50/?.so;/usr/lib/lua50/l?.so;/usr/lib/lua50/lib?.so'
end

local _,_,maj,min = string.find(_VERSION, '%s(%d)%p(%d)')
if maj and min then
    if tonumber(maj) >= 5 then
        min = tonumber(min)

        local home = os.getenv('HOME')
        if min < 1 then
            --require('compat-5.1')
            LUA_PATH = path()
            LUA_CPATH = cpath()
        else
            package.path = path()
            package.cpath = cpath()
        end
    end
end

pcall(require, 'init')
-- pcall(require, 'std')
