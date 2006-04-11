-------------------------------------------------------------------------------
-- $Id$
-- includes a new tostring function that handles tables recursively
--
-- Authors:
--   Danilo Tuler (tuler@ideais.com.br)
--   Andr� Carregal (carregal@keplerproject.org)
--   Thiago Costa Ponte (thiago@ideais.com.br)
--
-- Copyright (c) 2004 Kepler Project
-------------------------------------------------------------------------------

local Public, Private = {}, {}
logging = Public

-- Meta information
Public._COPYRIGHT = "Copyright (C) 2004 Kepler Project"
Public._DESCRIPTION = "A simple API to use logging features in Lua"
Public._NAME = "LuaLogging"
Public._VERSION = "1.1.0"

-- The DEBUG Level designates fine-grained instring.formational events that are most
-- useful to debug an application
Public.DEBUG = "DEBUG"

-- The INFO level designates instring.formational messages that highlight the
-- progress of the application at coarse-grained level
Public.INFO = "INFO"

-- The WARN level designates potentially harmful situations
Public.WARN = "WARN"

-- The ERROR level designates error events that might still allow the
-- application to continue running
Public.ERROR = "ERROR"

-- The FATAL level designates very severe error events that will presumably
-- lead the application to abort
Public.FATAL = "FATAL"

Private.LEVEL = {
	[Public.DEBUG] = 1,
	[Public.INFO]  = 2,
	[Public.WARN]  = 3,
	[Public.ERROR] = 4,
	[Public.FATAL] = 5,
}


-------------------------------------------------------------------------------
-- Creates a new logger object
-------------------------------------------------------------------------------
function Public.new(append)

        if type(append) ~= "function" then
            return nil, "Appender must be a function."
        end

	local logger = {}
	logger.level = Public.DEBUG
        logger.append = append

	logger.setLevel = function (self, level)
		assert(Private.LEVEL[level], string.format("undefined level `%s'", tostring(level)))
		self.level = level
	end

	logger.log = function (self, level, message)
		assert(Private.LEVEL[level], string.format("undefined level `%s'", tostring(level)))
		if Private.LEVEL[level] < Private.LEVEL[self.level] then
			return
		end
		if type(message) ~= "string" then
		  message = Public.tostring(message)
		end
		return logger:append(level, message)
	end

	logger.debug = function (logger, message) return logger:log(Public.DEBUG, message) end
	logger.info  = function (logger, message) return logger:log(Public.INFO,  message) end
	logger.warn  = function (logger, message) return logger:log(Public.WARN,  message) end
	logger.error = function (logger, message) return logger:log(Public.ERROR, message) end
	logger.fatal = function (logger, message) return logger:log(Public.FATAL, message) end
	return logger
end


-------------------------------------------------------------------------------
-- Prepares the log message
-------------------------------------------------------------------------------
function Public.prepareLogMsg(pattern, dt, level, message)

    local logMsg = pattern or "%date %level %message\n"
    logMsg = string.gsub(logMsg, "%%date", dt)
    logMsg = string.gsub(logMsg, "%%level", level)
    logMsg = string.gsub(logMsg, "%%message", message)
    return logMsg
end


-------------------------------------------------------------------------------
-- Converts a Lua value to a string
--
-- Converts Table fields in alphabetical order
-------------------------------------------------------------------------------
function Public.tostring(value)
  local str = ''

  if (type(value) ~= 'table') then
    if (type(value) == 'string') then
      if (string.find(value, '"')) then
        str = '[['..value..']]'
      else
        str = '"'..value..'"'
      end
    else
      str = tostring(value)
    end
  else
    local auxTable = {}
    table.foreach(value, function(i, v)
      if (tonumber(i) ~= i) then
        table.insert(auxTable, i)
      else
        table.insert(auxTable, tostring(i))
      end
    end)
    table.sort(auxTable)

    str = str..'{'
    local separator = ""
    local entry = ""
    table.foreachi (auxTable, function (i, fieldName)
      if ((tonumber(fieldName)) and (tonumber(fieldName) > 0)) then
        entry = Public.tostring(value[tonumber(fieldName)])
      else
        entry = fieldName.." = "..Public.tostring(value[fieldName])
      end
      str = str..separator..entry
      separator = ", "
    end)
    str = str..'}'
  end
  return str
end
