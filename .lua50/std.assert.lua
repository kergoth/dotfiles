-- Assertions and warnings

require "std.import"
import "std.io.io"


-- @func assert: Extend to allow formatted arguments
--   @param v: value
--   @param ...: arguments for format
-- @returns
--   @param v: value
function assert (v, ...)
  if not v then
    if arg.n == 0 then
      table.insert (arg, "")
    end
    error (string.format (unpack (arg)))
  end
  return v
end

-- @func warn: Give warning with the name of program and file (if any)
--   @param ...: arguments for format
function warn (...)
  if prog.name then
    io.stderr:write (prog.name .. ":")
  end
  if prog.file then
    io.stderr:write (prog.file .. ":")
  end
  if prog.line then
    io.stderr:write (tostring (prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    io.stderr:write (" ")
  end
  io.writeLine (io.stderr, string.format (unpack (arg)))
end

-- @func die: Die with error
--   @param ...: arguments for format
function die (...)
  warn (unpack (arg))
  error (false)
end
