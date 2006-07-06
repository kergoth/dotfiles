-- statusbar_workspace.lua
--
-- Show current workspace name or number in the statusbar.
-- 
-- Put any of these in cfg_statusbar.lua's template-line:
--  %workspace_name
--  %workspace_frame
--  %workspace_pager
--
-- This is an internal statusbar monitor and does NOT require
-- a dopath statement (effective after a 2006-02-12 build).
--
-- version 1
-- author: Rico Schiekel <fire at paranetic dot de>
--
-- version 2
-- added 2006-02-14 by Canaan Hadley-Voth:
--  * %workspace_pager shows a list of workspace numbers 
--    with the current one indicated:
--
--    1i  2i  [3f]  4p  5c
--
--    i=WIonWS, f=WFloatWS, p=WPaneWS, c=WClientWin/other
--
--  * %workspace_frame - name of the active frame.
--
--  * Added statusbar_ to the filename (since it *is*
--    an internal statusbar monitor) so that it works without
--    a "dopath" call.
--
--  * Removed timer.  Only needs to run on hook.
--    Much faster this way.
--

local function update_frame()
    local fr
    ioncore.defer( function() 
	local cur=ioncore.current()
	if obj_is(cur, "WClientWin") and
	  obj_is(cur:parent(), "WMPlex") then
	    cur=cur:parent()
	end
	fr=cur:name()
	mod_statusbar.inform('workspace_frame', fr)
	mod_statusbar.update()
    end)
end

local function update_workspace()
    local scr=ioncore.find_screen_id(0)
    local curws = scr:current()
    local wstype, c
    local pager=""
    local curindex = scr:get_index(curws)+1
    n = scr:lcount(1)
    for i=1,n do
	wstype=obj_typename(scr:lnth(1, i-1))
	if wstype=="WIonWS" then
	    c="i"
	elseif wstype=="WFloatWS" then
	    c="f"
	elseif wstype=="WPaneWS" then
	    c="p"
	else
	    c="c"
	end
	if i==curindex then
	    pager=pager.." ["..(i)..c.."] "
	else
	    pager=pager.." "..(i)..c.." "
	end
    end

    local fr,cur

    -- Older versions without an ioncore.current() should
    -- skip update_frame.
    update_frame()

    ioncore.defer( function()
	mod_statusbar.inform('workspace_pager', pager)
	mod_statusbar.inform('workspace_name', curws:name())
	mod_statusbar.update()
    end)
end

ioncore.get_hook("region_activated_hook"):add(update_workspace)
