-- getopt
-- Simplified getopt, based on Svenne Panne's Haskell GetOpt

require "std.import"
import "std.base"
import "std.string"
import "std.object"
import "std.io.env"


-- TODO: Sort out the packaging. getopt.Option is tedious to type, but
-- surely Option shouldn't be in the root namespace?
-- TODO: Wrap all messages; do all wrapping in processArgs, not
-- usageInfo; use sdoc-like library (see string.format todos)


-- Usage:

-- options = Options {Option {...} ...}
-- getopt.processArgs ()

-- Assumes prog = {name[, banner] [, purpose] [, notes] [, usage]}

-- options take a single dash, but may have a double dash
-- arguments may be given as -opt=arg or -opt arg
-- if an option taking an argument is given multiple times, only the
-- last value is returned; missing arguments are returned as 1

-- getOpt, usageInfo and dieWithUsage can be called directly (see
-- below, and the example at the end). Set _DEBUG.std to a non-nil
-- value to run the example.


getopt = {}


-- @func getopt.getOpt: perform argument processing
--   @param argIn: list of command-line args
--   @param options: options table
-- @returns
--   @param argOut: table of remaining non-options
--   @param optOut: table of option key-value list pairs
--   @param errors: table of error messages
function getopt.getOpt (argIn, options)
  local noProcess = nil
  local argOut, optOut, errors = {[0] = argIn[0]}, {}, {}
  -- get an argument for option opt
  local function getArg (o, opt, arg, oldarg)
    if o.type == nil then
      if arg ~= nil then
        table.insert (errors, getopt.errNoArg (opt))
      end
    else
      if arg == nil and argIn[1] and
        string.sub (argIn[1], 1, 1) ~= "-" then
        arg = argIn[1]
        table.remove (argIn, 1)
      end
      if arg == nil and o.type == "Req" then
        table.insert (errors, getopt.errReqArg (opt, o.var))
        return nil
      end
    end
    if o.func then
      return o.func (arg, oldarg)
    end
    return arg or 1 -- make sure arg has a value
  end
  -- parse an option
  local function parseOpt (opt, arg)
    local o = options.name[opt]
    if o ~= nil then
      optOut[o.name[1]] = getArg (o, opt, arg, optOut[o.name[1]])
    else
      table.insert (errors, getopt.errUnrec (opt))
    end
  end
  while argIn[1] do
    local v = argIn[1]
    table.remove (argIn, 1)
    local _, _, dash, opt = string.find (v, "^(%-%-?)([^=-][^=]*)")
    local _, _, arg = string.find (v, "=(.*)$")
    if v == "--" then
      noProcess = 1
    elseif dash == nil or noProcess then -- non-option
      table.insert (argOut, v)
    else -- option
      parseOpt (opt, arg)
    end
  end
  argOut.n = table.getn (argOut)
  return argOut, optOut, errors
end


-- Options table type

Option = Object {_init = {
    "name", -- list of names
    "desc", -- description of this option
    "type", -- type of argument (if any): Req (uired), Opt (ional)
    "var",  -- descriptive name for the argument
    "func"  -- optional function (newarg, oldarg) to convert argument
    -- into actual argument, (if omitted, argument is left as it
    -- is)
}}

-- Options table constructor: adds lookup tables for the option names
function Options (t)
  local name = {}
  for _, v in ipairs (t) do
    for j, s in pairs (v.name) do
      if name[s] then
        warn ("duplicate option '%s'", s)
      end
      name[s] = v
    end
  end
  t.name = name
  return t
end


-- Error and usage information formatting

-- @func getopt.errNoArg: argument when there shouldn't be one
--   @paramoptStr: option string
-- @returns
--   @param err: option error
function getopt.errNoArg (optStr)
  return "option `" .. optStr .. "' doesn't take an argument"
end

-- @func getopt.errReqArg: required argument missing
--   @param optStr: option string
--   @param desc: argument description
-- @returns
--   @param err: option error
function getopt.errReqArg (optStr, desc)
  return "option `" .. optStr .. "' requires an argument `" .. desc ..
    "'"
end

-- @func getopt.errUnrec: unrecognized option
--   @param optStr: option string
-- @returns
--   @param err: option error
function getopt.errUnrec (optStr)
  return "unrecognized option `-" .. optStr .. "'"
end


-- @func getopt.usageInfo: produce usage info for the given options
--   @param.header: header string
--   @param.optDesc: option descriptors
--   @param.pageWidth: width to format to [78]
-- @returns
--   @param.mess: formatted string
function getopt.usageInfo (header, optDesc, pageWidth)
  pageWidth = pageWidth or 78
  -- format the usage info for a single option
  -- @returns {opts, desc}: options, description
  local function fmtOpt (opt)
    local function fmtName (o)
      return "-" .. o
    end
    local function fmtArg ()
      if opt.type == nil then
        return ""
      elseif opt.type == "Req" then
        return "=" .. opt.var
      else
        return "[=" .. opt.var .. "]"
      end
    end
    local textName = list.map (fmtName, opt.name)
    textName[1] = textName[1] .. fmtArg ()
    return {table.concat ({table.concat (textName, ", ")}, ", "),
      opt.desc}
  end
  local function sameLen (xs)
    local n = math.max (list.map (string.len, xs))
    for i, v in pairs (xs) do
      xs[i] = string.sub (v .. string.rep (" ", n), 1, n)
    end
    return xs, n
  end
  local function paste (x, y)
    return "  " .. x .. "  " .. y
  end
  local function wrapper (w, i)
    return function (s)
             return string.wrap (s, w, i, 0)
           end
  end
  local optText = ""
  if table.getn (optDesc) > 0 then
    local cols = list.unzip (list.map (fmtOpt, optDesc))
    local width
    cols[1], width = sameLen (cols[1])
    cols[2] = list.map (wrapper (pageWidth, width + 4), cols[2])
    optText = "\n\n" ..
      table.concat (list.mapWith (paste, list.unzip ({sameLen
                                                       (cols[1]),
                                                       cols[2]})),
                    "\n")
  end
  return header .. optText
end

-- @func getopt.dieWithUsage: die emitting a usage message
function getopt.dieWithUsage ()
  local name = prog.name
  prog.name = nil
  local usage, purpose, notes = "[OPTION...] FILE...", "", ""
  if prog.usage then
    usage = prog.usage
  end
  if prog.purpose then
    purpose = "\n" .. prog.purpose
  end
  if prog.notes then
    notes = "\n\n"
    if not string.find (prog.notes, "\n") then
      notes = notes .. string.wrap (prog.notes)
    else
      notes = notes .. prog.notes
    end
  end
  die (getopt.usageInfo ("Usage: " .. name .. " " .. usage .. purpose,
                         options)
         .. notes)
end


-- @func getopt.processArgs: simple getOpt wrapper
-- adds -version/-v and -help/-h/-? automatically; stops program
-- if there was an error or -help was used
function getopt.processArgs ()
  local totArgs = table.getn (arg)
  options = Options (list.concat (options or {},
                                  {Option {{"version", "v"},
                                      "show program version"},
                                    Option {{"help", "h", "?"},
                                      "show this help"}}
                              ))
  local errors
  arg, opt, errors = getopt.getOpt (arg, options)
  if (opt.version or opt.help) and prog.banner then
    io.stderr:write (prog.banner .. "\n")
  end
  if table.getn (errors) > 0 or opt.help then
    local name = prog.name
    prog.name = nil
    if table.getn (errors) > 0 then
      warn (table.concat (errors, "\n") .. "\n")
    end
    prog.name = name
    getopt.dieWithUsage ()
  elseif opt.version and table.getn (arg) == 0 then
    os.exit ()
  end
end


-- A small and hopefully enlightening example:
if type (_DEBUG) == "table" and _DEBUG.std then
  
  function out (o)
    return o or io.stdout
  end

  options = Options {
    Option {{"verbose", "v"}, "verbosely list files"},
    Option {{"version", "release", "V", "?"}, "show version info"},
    Option {{"output", "o"}, "dump to FILE", "Opt", "FILE", out},
    Option {{"name", "n"}, "only dump USER's files", "Req", "USER"},
  }

  function test (cmdLine)
    local nonOpts, opts, errors = getopt.getOpt (cmdLine, options)
    if table.getn (errors) == 0 then
      print ("options=" .. tostring (opts) ..
             "  args=" .. tostring (nonOpts) .. "\n")
    else
      print (table.concat (errors, "\n") .. "\n" ..
             getopt.usageInfo ("Usage: foobar [OPTION...] FILE...",
                               options))
    end
  end

  prog = {name = "foobar"} -- in case of errors
  -- example runs:
  test {"foo", "-v"}
  -- options={verbose=1}  args={1=foo,n=1}
  test {"foo", "--", "-v"}
  -- options={}  args={1=foo,2=-v,n=2}
  test {"-o", "-?", "-name", "bar", "--name=baz"}
  -- options={output=userdata(?): 0x????????,version=1,name=baz}  args={}
  test {"-foo"}
  -- unrecognized option `foo'
  -- Usage: foobar [OPTION...] FILE...
  --   -verbose, -v                verbosely list files
  --   -version, -release, -V, -?  show version info
  --   -output[=FILE], -o          dump to FILE
  --   -name=USER, -n              only dump USER's files

end
