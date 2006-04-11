-- @module Debugging

require "std.import"
import "std.io.io"
import "std.string.string"


-- _DEBUG is either any true value (equivalent to {level = 1}), or a
-- table with the following members:

-- level: debugging level [1]
-- call: do call trace debugging
-- std: do standard library debugging (run examples & test code)


-- @func debug.say: Print a debugging message
--   @param [n]: debugging level [1]
--   ...: objects to print (as for print)
function debug.say (...)
  local level = 1
  if type (arg[1]) == "number" then
    level = arg[1]
    table.remove (arg, 1)
  end
  if _DEBUG and
    ((type (_DEBUG) == "table" and type (_DEBUG.level) == "number" and
      _DEBUG.level >= level)
       or level <= 1) then
    io.writeLine (io.stderr, table.concat (list.map (tostring, arg), "\t"))
  end
end

-- Expose debug.say as debug
setmetatable (debug,
              {__call = function (self, ...)
                          debug.say (unpack (arg))
                        end})

-- @func debug.traceCall: Trace function calls
--   @param event: event causing the call
-- Use: debug.sethook (traceCall, "cr"), as below
-- based on test/trace-calls.lua from the Lua 5.0 distribution
local level = 0

function debug.traceCall (event)
  local t = debug.getinfo (3)
  local s = " >>> " .. string.rep(" ",level)
  if t ~= nil and t.currentline >= 0 then
    s = s .. t.short_src .. ":" .. t.currentline .. " "
  end
  t = debug.getinfo (2)
  if event == "call" then
    level = level + 1
  else
    level = max (level - 1, 0)
  end
  if t.what == "main" then
    if event == "call" then
      s = s .. "begin " .. t.short_src
    else
      s = s .. "end " .. t.short_src
    end
  elseif t.what == "Lua" then
    s = s .. event .. " " .. (t.name or "(Lua)") .. " <" ..
      t.linedefined .. ":" .. t.short_src .. ">"
  else
    s = s .. event .. " " .. (t.name or "(C)") .. " [" .. t.what .. "]"
  end
  io.writeLine (io.stderr, s)
end

-- Set hooks according to _DEBUG
if type (_DEBUG) == "table" and _DEBUG.call then
  debug.sethook (debug.traceCall, "cr")
end
