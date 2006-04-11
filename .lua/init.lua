--if maj and tonumber(maj) >= 5 then
--	if min and tonumber(min) >= 1 then
--		local mt = getmetatable("")
--
--		function mt:__index(ind)
--			return string.sub(self, ind, ind)
--		end
--	end
--end


local _,_,maj,min = string.find(_VERSION, "%s(%d)%p(%d)")
if maj and min then
	if tonumber(maj) >= 5 then
		min = tonumber(min)

		local home = os.getenv("HOME")
		if min < 1 then
			--require("compat-5.1")
			LUA_PATH = "./?.lua;./?/init.lua;"..home.."/.lua50/?.lua;"..home.."/.lua50/?/init.lua;/usr/local/share/lua50/?.lua;/usr/local/share/lua50/?/init.lua;/usr/local/lib/lua50/?.lua;/usr/local/lib/lua50/?/init.lua;/usr/share/lua50/?.lua;/usr/share/lua50/?/init.lua;/usr/lib/lua50/?.lua;/usr/lib/lua50/?/init.lua"
			LUA_CPATH = "./?.so;./l?.so;./lib?.so;"..home.."/.lua50/?.so;"..home.."/.lua50/l?.so;"..home.."/.lua50/lib?.so;/usr/local/lib/lua50/?.so;/usr/local/lib/lua50/l?.so;/usr/local/lib/lua50/lib?.so;/usr/lib/lua50/?.so;/usr/lib/lua50/l?.so;/usr/lib/lua50/lib?.so"
		else
			package.path = "./?.lua;./?/init.lua;"..home.."/.lua51/?.lua;"..home.."/.lua51/?/init.lua;/usr/local/share/lua51/?.lua;/usr/local/share/lua51/?/init.lua;/usr/local/lib/lua51/?.lua;/usr/local/lib/lua51/?/init.lua;/usr/share/lua51/?.lua;/usr/share/lua51/?/init.lua;/usr/lib/lua51/?.lua;/usr/lib/lua51/?/init.lua"
			package.cpath = "./?.so;./l?.so;./lib?.so;"..home.."/.lua51/?.so;"..home.."/.lua51/l?.so;"..home.."/.lua51/lib?.so;/usr/local/lib/lua51/?.so;/usr/local/lib/lua51/l?.so;/usr/local/lib/lua51/lib?.so;/usr/lib/lua51/?.so;/usr/lib/lua51/l?.so;/usr/lib/lua51/lib?.so"
		end
	end
end

pcall(require, "init")
pcall(require, "std")
