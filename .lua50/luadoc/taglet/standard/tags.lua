
-------------------------------------------------------------------------------
-- Handlers for several tags

module "luadoc.taglet.standard.tags"

local util = require "luadoc.util"

-------------------------------------------------------------------------------

local function description (tag, block, text)
	block[tag] = text
end

-------------------------------------------------------------------------------
-- Set the name of the comment block. If the block already has a name, issue
-- an error and do not change the previous value

local function name (tag, block, text)
	if block[tag] and block[tag] ~= text then
		luadoc.logger:error(string.format("block name conflict: `%s' -> `%s'", block[tag], text))
	end
	
	block[tag] = text
end

-------------------------------------------------------------------------------
-- Set the class of a comment block. Classes can be "module", "function", 
-- "table". The first two classes are automatic, extracted from the source code

local function class (tag, block, text)
	block[tag] = text
end

-------------------------------------------------------------------------------

local function ret (tag, block, text)
	tag = "ret"
	if type(block[tag]) == "string" then
		block[tag] = { block[tag], text }
	elseif type(block[tag]) == "table" then
		table.insert(block[tag], text)
	else
		block[tag] = text
	end
end

-------------------------------------------------------------------------------
-- @see ret

local function see (tag, block, text)
	-- see is always an array
	block[tag] = block[tag] or {}
	
	-- remove trailing "."
	text = string.gsub(text, "(.*)%.$", "%1")
	
	local s = util.split("%s*,%s*", text)			
	
	table.foreachi(s, function (_, v)
		table.insert(block[tag], v)
	end)
end

-------------------------------------------------------------------------------

local function param (tag, block, text)
	block[tag] = block[tag] or {}
	-- TODO: make this pattern more flexible, accepting empty descriptions
	local _, _, name, desc = string.find(text, "^([_%w%.]+)%s+(.*)")
	assert(name, "parameter name not defined")
	local i = table.foreachi(block[tag], function (i, v)
		if v == name then
			return i
		end
	end)
	if i == nil then
		luadoc.logger:warn(string.format("documenting undefined parameter `%s'", name))
		table.insert(block[tag], name)
	end
	block[tag][name] = desc
end

-------------------------------------------------------------------------------
-- @see ret

local function usage (tag, block, text)
	if type(block[tag]) == "string" then
		block[tag] = { block[tag], text }
	elseif type(block[tag]) == "table" then
		table.insert(block[tag], text)
	else
		block[tag] = text
	end
end

-------------------------------------------------------------------------------

local function field (tag, block, text)
	if block["class"] ~= "table" then
		luadoc.logger:warn("documenting `field' for block that is not a `table'")
	end
	block[tag] = block[tag] or {}

	local _, _, name, desc = string.find(text, "^([_%w%.]+)%s+(.*)")
	assert(name, "field name not defined")
	
	table.insert(block[tag], name)
	block[tag][name] = desc
end

-------------------------------------------------------------------------------

local handlers = {}
handlers["description"] = description
handlers["return"] = ret
handlers["see"] = see
handlers["param"] = param
handlers["usage"] = usage
handlers["name"] = name
handlers["class"] = class
handlers["field"] = field

-------------------------------------------------------------------------------

function handle (tag, block, text)
	if not handlers[tag] then
		luadoc.logger:error(string.format("undefined handler for tag `%s'", tag))
		return
	end
--	assert(handlers[tag], string.format("undefined handler for tag `%s'", tag))
	return handlers[tag](tag, block, text)
end
