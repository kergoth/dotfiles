-- $Id: formatter.lua,v 1.2 2005/07/11 15:03:46 uid20006 Exp $

-------------------------------------------------------------------------------
-- Doclet to format source code according to LuaDoc standard tags. This doclet
-- (re)write .lua files adding missing standard tags. Texts are formatted to
-- 80 columns and function parameters are added based on code analysis.

module "luadoc.doclet.formatter"

local util = require "luadoc.util"

options = {
	output_dir = "./",
}

-------------------------------------------------------------------------------
-- Assembly the output filename for an input file.
-- TODO: change the name of this function
function out_file (filename)
	local h = filename
	h = options.output_dir..h
	return h
end

-------------------------------------------------------------------------------
-- Generate a new lua file for each input lua file. Is the user does not 
-- specify a different output directory input files will be rewritten.
-- @param doc documentation table

function start (doc)
	local todo = "<TODO>"
	
	-- Process files
	-- TODO: change to ipairs(doc.files)
	for i, file_doc in doc.files do
		-- assembly the filename
		local filename = out_file(file_doc.name)
		luadoc.logger:info(string.format("generating file `%s'", filename))

		-- TODO: confirm file overwrite
		local f = lfs.open(filename, "w")
		assert(f, string.format("could not open `%s' for writing", filename))

		for _, block in ipairs(file_doc.doc) do

			-- write reorganized comments
			f:write(string.rep("-", 80).."\n")
			
			-- description
			f:write(util.comment(util.wrap(block.description, 77)))
			f:write("\n")
			
			if block.class == "function" then
				-- parameters
				table.foreachi(block.param, function (_, param_name)
					f:write(util.comment(util.wrap(string.format("@param %s %s", param_name, block.param[param_name] or todo), 77)))
					f:write("\n")
				end)
				
				-- return
				if type(block.ret) == "table" then
					table.foreachi(block.ret, function (_, ret)
						f:write(util.comment(util.wrap(string.format("@return %s", ret), 77)).."\n")
					end)
				else
					f:write(util.comment(util.wrap(string.format("@return %s", block.ret or todo), 77)).."\n")
				end
			end
			
			-- TODO: usage
			-- TODO: see

			-- write code
			for _, line in ipairs(block.code) do
				f:write(line.."\n")
			end
		end
		
		f:close()
	end
end
