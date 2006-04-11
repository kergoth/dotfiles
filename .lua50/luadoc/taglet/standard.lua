
module 'luadoc.taglet.standard'

require "lfs"
require "luadoc"
local util = require "luadoc.util"
local tags = require "luadoc.taglet.standard.tags"

-------------------------------------------------------------------------------
-- Creates an iterator for an array base on a class type.
-- @param t array to iterate over
-- @param class name of the class to iterate over

function class_iterator (t, class)
	return function ()
		local i = 1
		return function ()
			while t[i] and t[i].class ~= class do
				i = i + 1
			end
			local v = t[i]
			i = i + 1
			return v
		end
	end
end

-------------------------------------------------------------------------------
-- Checks if the line contains a function definition
-- @param line string with line text
-- @return function information or nil if no function definition found

local function check_function (line)
	line = util.trim(line)

	local patterns = {
		"^()function%s+([^%(%s]+)%s*%(%s*(.-)%s*%)",
		"^(local)%s+function%s+([^%(%s]+)%s*%(*s*(.-)%s*%)",
	}
	
	local info = table.foreachi(patterns, function (_, pattern)
		local r, _, l, id, param = string.find(line, pattern)
		if r ~= nil then
			return {
				name = id,
				private = (l == "local"),
				param = util.split("%s*,%s*", param),
			}
		end
	end)

	-- TODO: remove these assert's?
	if info ~= nil then
		assert(info.name, "function name undefined")
		assert(info.param, string.format("undefined parameter list for function `%s'", info.name))
	end

	return info
end

-------------------------------------------------------------------------------
-- Checks if the line contains a module definition.
-- @param line string with line text
-- @param currentmodule module already found, if any
-- @return the name of the defined module, or nil if there is no module 
-- definition

local function check_module (line, currentmodule)
	line = util.trim(line)
	
	-- module"x.y"
	-- module'x.y'
	-- module[[x.y]]
	-- module("x.y")
	-- module('x.y')
	-- module([[x.y]])
	-- module(...)

	-- TODO: support all the above formats
	local r, _, modulename = string.find(line, "^module%s*[\"'](.-)[\"']")
	if r then
		-- found module definition
		luadoc.logger:debug(string.format("found module `%s'", modulename))
		return modulename
	end
	return currentmodule
end

-------------------------------------------------------------------------------
-- Extracts summary information from a description. The first sentence of each 
-- doc comment should be a summary sentence, containing a concise but complete 
-- description of the item. It is important to write crisp and informative 
-- initial sentences that can stand on their own
-- @param description text with item description
-- @return summary string or nil if description is nil

local function parse_summary (description)
	-- summary is never nil...
	description = description or ""
	
	-- append an " " at the end to make the pattern work in all cases
	description = string.gsub(description, "(.)$", "%1 ")

	-- read until the first period followed by a space or tab	
	local _, _, summary = string.find(description, "([^%.]*%.)[%s\t]")
	
	-- if pattern did not find the first sentence, summary is the whole description
	summary = summary or description
	
	return summary
end

-------------------------------------------------------------------------------
-- @param f file handle
-- @param line current line being parsed
-- @param modulename module already found, if any
-- @return current line
-- @return code block
-- @return modulename if found

local function parse_code (f, line, modulename)
	local code = {}
	while line ~= nil do
		if string.find(line, "^%-%-%-") then
			-- reached another luadoc block, end this parsing
			return line, code, modulename
		else
			-- look for a module definition
			modulename = check_module(line, modulename)
			
			table.insert(code, line)
			line = f:read()
		end
	end
	-- reached end of file
	return line, code, modulename
end

-------------------------------------------------------------------------------
-- Parses the information inside a block comment
-- @param block block with comment field
-- @return block parameter

local function parse_comment (block)

	-- get the first non-empty line of code
	local code = table.foreachi(block.code, function(_, line)
		if not util.line_empty(line) then
			return line
		end
	end)
	
	-- parse first line of code
	if code ~= nil then
		local func_info = check_function(code)
		local module_name = check_module(code)
		
		if func_info then
			block.class = "function"
			block.name = func_info.name
			block.param = func_info.param
		elseif module_name then
			block.class = "module"
			block.name = module_name
			block.param = {}
		else
			block.param = {}
		end
	else
		-- TODO: comment without any code. Does this means we are dealing
		-- with a file comment?
	end

	-- parse @ tags
	local currenttag = "description"
	local currenttext
	
	table.foreachi(block.comment, function (_, line)
		line = util.trim_comment(line)
		
		local r, _, tag, text = string.find(line, "@([_%w%.]+)%s+(.*)")
		if r ~= nil then
			-- found new tag, add previous one, and start a new one
			-- TODO: what to do with invalid tags? issue an error? or log a warning?
			tags.handle(currenttag, block, currenttext)
			
			currenttag = tag
			currenttext = text
		else
			currenttext = util.concat(currenttext, line)
			assert(string.sub(currenttext, 1, 1) ~= " ", string.format("`%s', `%s'", currenttext, line))
		end
	end)
	tags.handle(currenttag, block, currenttext)

	-- extracts summary information from the description
	block.summary = parse_summary(block.description)
	assert(string.sub(block.description, 1, 1) ~= " ", string.format("`%s'", block.description))
	
	return block
end

-------------------------------------------------------------------------------
-- Parses a block of comment, started with ---. Read until the next block of
-- comment.
-- @param f file handle
-- @param line being parsed
-- @param modulename module already found, if any
-- @return line
-- @return block parsed
-- @return modulename if found

local function parse_block (f, line, modulename)
	local block = {
		comment = {},
		code = {},
	}
	
	while line ~= nil do
		if string.find(line, "^%-%-") == nil then
			-- reached end of comment, read the code below it
			-- TODO: allow empty lines
			line, block.code, modulename = parse_code(f, line, modulename)
			
			-- parse information in block comment
			block = parse_comment(block)
			
			return line, block, modulename
		else
			table.insert(block.comment, line)
			line = f:read()
		end
	end
	-- reached end of file
	
	-- parse information in block comment
	block = parse_comment(block)
	
	return line, block, modulename
end

-------------------------------------------------------------------------------
-- Parses a file documented following luadoc format.
-- @param filepath full path of file to parse
-- @param doc table with documentation
-- @return table with documentation

function parse_file (filepath, doc)
	local blocks = {}
	local modulename = nil
	
	-- read each line
	local f = io.open(filepath, "r")
	local i = 1
	local line = f:read()
	while line ~= nil do
		if string.find(line, "^%-%-%-") then
			-- reached a luadoc block
			local block
			line, block, modulename = parse_block(f, line, modulename)
			table.insert(blocks, block)
		else
			-- look for a module definition
			modulename = check_module(line, modulename)
			
			-- TODO: keep beginning of file somewhere
			
			line = f:read()
		end
		i = i + 1
	end
	f:close()
	
	-- store blocks in file hierarchy
	assert(doc.files[filepath] == nil, string.format("doc for file `%s' already defined", filepath))
	table.insert(doc.files, filepath)
	doc.files[filepath] = {
		type = "file",
		name = filepath,
		doc = blocks,
--		functions = class_iterator(blocks, "function"),
--		tables = class_iterator(blocks, "table"),
	}
	
	-- if module definition is found, store in module hierarchy
	if modulename ~= nil then
		if doc.modules[modulename] ~= nil then
			-- module is already defined, just add the blocks
			table.foreachi(blocks, function (_, v)
				table.insert(doc.modules[modulename].doc, v)
			end)
		else
			-- TODO: put this in a different module
			table.insert(doc.modules, modulename)
			doc.modules[modulename] = {
				type = "module",
				name = modulename,
				doc = blocks,
--				functions = class_iterator(blocks, "function"),
--				tables = class_iterator(blocks, "table"),
			}
			
			-- find module description
			doc.modules[modulename].description = ""
			doc.modules[modulename].summary = ""
			for m in class_iterator(blocks, "module")() do
				doc.modules[modulename].description = util.concat(
					doc.modules[modulename].description, 
					m.description)
				doc.modules[modulename].summary = util.concat(
					doc.modules[modulename].summary, 
					m.summary)
			end
		end
		
		-- make functions table
		doc.modules[modulename].functions = {}
		for f in class_iterator(blocks, "function")() do
			table.insert(doc.modules[modulename].functions, f.name)
			doc.modules[modulename].functions[f.name] = f
		end
		
		-- make tables table
		doc.modules[modulename].tables = {}
		for t in class_iterator(blocks, "table")() do
			table.insert(doc.modules[modulename].tables, t.name)
			doc.modules[modulename].tables[t.name] = t
		end
	end
	
	-- make functions table
	doc.files[filepath].functions = {}
	for f in class_iterator(blocks, "function")() do
		table.insert(doc.files[filepath].functions, f.name)
		doc.files[filepath].functions[f.name] = f
	end
	
	-- make tables table
	doc.files[filepath].tables = {}
	for t in class_iterator(blocks, "table")() do
		table.insert(doc.files[filepath].tables, t.name)
		doc.files[filepath].tables[t.name] = t
	end
	
	return doc
end

-------------------------------------------------------------------------------
-- Checks if the file is terminated by ".lua" or ".luadoc" and calls the 
-- function that does the actual parsing
-- @param filepath full path of the file to parse
-- @param doc table with documentation
-- @return table with documentation
-- @see parse_file

function file (filepath, doc)
	local patterns = { "%.lua$", "%.luadoc$" }
	local valid = table.foreachi(patterns, function (_, pattern)
		if string.find(filepath, pattern) ~= nil then
			return true
		end
	end)
	
	if valid then
		luadoc.logger:info(string.format("processing file `%s'", filepath))
		doc = parse_file(filepath, doc)
	end
	
	return doc
end

-------------------------------------------------------------------------------
-- Recursively iterates through a directory, parsing each file
-- @param path directory to search
-- @param doc table with documentation
-- @return table with documentation

function directory (path, doc)
	for f in lfs.dir(path) do
		local fullpath = path .. "/" .. f
		local attr = lfs.attributes(fullpath)
		assert(attr, string.format("error stating file `%s'", fullpath))
		
		if attr.mode == "file" then
			doc = file(fullpath, doc)
		elseif attr.mode == "directory" and f ~= "." and f ~= ".." then
			doc = directory(fullpath, doc)
		end
	end
	return doc
end

function start (files, doc)
	assert(files, "file list not specified")
	
	-- Create an empty document, or use the given one
	doc = doc or {
		files = {},
		modules = {},
	}
	assert(doc.files, "undefined `files' field")
	assert(doc.modules, "undefined `modules' field")
	
	table.foreachi(files, function (_, path)
		local attr = lfs.attributes(path)
		assert(attr, string.format("error stating path `%s'", path))
		
		if attr.mode == "file" then
			doc = file(path, doc)
		elseif attr.mode == "directory" then
			doc = directory(path, doc)
		end
	end)
	
	-- order arrays alphabetically
	table.sort(doc.files)
	table.sort(doc.modules)
		
	return doc
end
