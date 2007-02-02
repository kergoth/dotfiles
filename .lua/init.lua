local home = os.getenv('HOME')
local function path(type, paths)
    local new = {}
    for k,v in ipairs(paths) do
        local base = string.format(v, type)
        if type == 'lib' then
            table.insert(new, base..'/?.so')
            table.insert(new, base..'/l?.so')
            table.insert(new, base..'/lib?.so')
        elseif type == 'share' then
            table.insert(new, base..'/?.lua')
            table.insert(new, base..'/?/init..lua')
        end
    end
    return table.concat(new, ';')
end

local _,_,maj,min = string.find(_VERSION, '%s(%d)%p(%d)')
if maj and min then
    if tonumber(maj) >= 5 then
        min = tonumber(min)
        local verstr = tostring(maj)..tostring(min)
        local dotverstr = tostring(maj)..'.'..tostring(min)
        local paths = {
            '.',
            home..'/.lua'..verstr,
            home..'/.lua/'..dotverstr,
            home..'/.root/%s/lua'..verstr,
            home..'/.root/%s/lua/'..dotverstr,
            '/usr/local/%s/lua'..verstr,
            '/usr/local/%s/lua/'..dotverstr,
            '/usr/%s/lua'..verstr,
            '/usr/%s/lua/'..dotverstr,
        }

        local home = os.getenv('HOME')
        if min < 1 then
            --require('compat-5.1')
            LUA_PATH = path('share', paths)
            LUA_CPATH = path('lib', paths)
        else
            package.path = path('share', paths)
            package.cpath = path('lib', paths)
        end
    end
end

pcall(require, 'init')
-- pcall(require, 'std')
