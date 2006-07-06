-- Fancy management of transcient windows in ion. Mix WIonWS and
-- WFloatWS on the same "workspace".

-- Written by Matthieu Moy <Matthieu.Moy@imag.fr> on February 17th 2005.

if not detach then
  detach = {
     -- default "passiveness" for the layer 2 floating workspace.
     passive = true,
     -- Whether transcient windows should automatically be made floating
     manage_transcient_with_float = true,
  }
end

-- Introduction:

-- This extension exploits some of ion3's new features: It is now
-- possible to attach objects on a second layer on the screen, which
-- allows you to have, for example, floating objects on top of a
-- traditional WIonWS workspace. See
-- http://www-verimag.imag.fr/~moy/ion/ion3/float-split.png if you
-- prefer images to explanations :-)

-- A simple setup is to put the following in your cfg_user.lua:
-- dopath("detach.lua")
-- detach.setup_hooks()

-- The layer 2 objects can be either passive or non passive. A passive
-- object will only take the focus when the mouse is over it, while a
-- non passive object will allways have the focus when shown. (The
-- scratchpad is an example of non passive object).

-- Layer 2 objects can be hidden. This way, a non passive object can
-- let the focus to the layer 1.

-- This script attaches two WFloatWS on the layer 2. One is passive,
-- the other not. The function detach.topmost_transient_to_float sends
-- a window (or the topmost transcient if the window has transcient)
-- to one of them (depending on the value of the 3rd parameter).

-- The function detach.toggle_floatws shows or hide the current layer
-- 2 floating workspace. This is very usefull to get rid of the non
-- passive WFloatWS, when it is active and you want to give the focus
-- to a layer 1 object.


--------------------
-- User functions --
--------------------


-- Call this function once and all transcient windows will be managed
-- as floating frame in layer 2. Additionally, you may define the
-- "float" winprop for other non transcient windows to manage as
-- floating frames like this
--
-- defwinprop  {
--    class = "Xawtv",
--    float = true,
-- }
--
-- the winprop "float_passive", if specified, overrides the
-- detach.passive setting. For example,
--
-- defwinprop {
--    class = "Gkrellm",
--    float = true,
--    float_passive = true
-- }
--
-- will make gkrellm start in a passive floating window. (this means
-- the window will not accept focus)
--
-- Note: Adding all the functions to hooks here may conflict with
-- other functions you could have added to the same hook somewhere
-- else. If you want to add your personal functions to
-- clientwin_do_manage_alt, I suggest not adding detach.manager, but
-- doing something like
--
--    if detach.manager(cwin, table) then
--       return true
--    end
--
-- at the beginning of function you'll use in clientwin_do_manage_alt.
function detach.setup_hooks ()
   ioncore.get_hook("clientwin_do_manage_alt"):add(detach.clientwin_manager)
   ioncore.get_hook("frame_managed_changed_hook"):add(detach.maybe_leave_layer2)
   ioncore.get_hook("region_do_warp_alt"):add(detach.skip_l2_warp)
end


-- Submenu to add to the WFrame menu:
-- Add the line
--     submenu("Attach",           "menudetach"),
-- to the definition defctxmenu("WFrame", { ... })
defmenu("menudetach", {
           menuentry("Topmost transient",
                     "detach.topmost_transient_to_reg(_sub)"),
           menuentry("To scratchpad",
                     "detach.topmost_transient_to_sp(_sub)"),
           menuentry("To passive float",
                     "detach.topmost_transient_to_float(_sub, nil, true)"),
           menuentry("To non passive float",
                     "detach.topmost_transient_to_float(_sub, nil, false)"),
        })


-- Can be called on any object defining screen_of(). shows or hide the
-- floating workspace on layer 2 of this screen. This applies to the
-- passive WFloatWS if the second argument is true, and to the non
-- passive one if it is false. (detach.passive is used if the argument
-- is nil)
function detach.toggle_floatws(obj, passive)
   local screen = obj:screen_of()
   local sp = detach.find_ws(screen, passive)
   if sp then
      screen:l2_set_hidden(sp, 'toggle')
   end
end

-- close (and relocate managed of) all layer2 WFloatWS on all screens.
-- You can call this function from you cfg_user.lua or equivalent to
-- avoid having layer 2 workspaces at startup.
function detach.close_all_floatws()
   local screen = ioncore.find_screen_id(0)
   local cur = screen
   repeat
      detach.close_floatws(cur)
      cur = ioncore.goto_next_screen()
   until (cur == screen or cur == nil)
end

---------------------------------------------------------
-- Normally, simple users shouldn't need to go further --
---------------------------------------------------------


-- Put the function "detach.topmost_transient(_sub)" in e.g.
-- defctxmenu("WFrame" {}) or ionframe_bindings to use this.
function detach.topmost_transient_to_reg(cwin)
    local to_detach = cwin:current()
    if to_detach==nil then
	return
    end
    while to_detach:current() do
	to_detach=to_detach:current()
    end
    cwin:manager():attach(to_detach,{switchto=true})
end


-- send either the topmost transcient or the window itself if it has
-- no transcient to the scratchpad
function detach.topmost_transient_to_sp(cwin)
    local to_detach = cwin
    while to_detach:current()~=nil do
	to_detach=to_detach:current()
    end

    -- search for the scratchpad
    local sp = nil
    for _,r in pairs(cwin:screen_of():llist(2)) do
       if (r:name() == "*scratchpad*") then
          sp = r
       end
    end
    sp:attach(to_detach,{switchto=true})
    cwin:goto()
end

function detach.ws_name(passive)
   local passive_loc = detach.passive
   if passive ~= nil then
      passive_loc = passive
   end
   if passive_loc then
      return "layer 2 float - passive"
   else
      return "layer 2 float - active"
   end
end

function detach.find_ws(screen, passive)
   local name = detach.ws_name(passive)
   local ws
   for _,r in pairs(screen:llist(2)) do
      if r:name() == name then
         ws = r
      end
   end
   return ws
end

function startswith(s, target)
      return string.sub(s, 0, string.len(target)) == target
end

function is_l2floatws(ws)
      return startswith(ws:name(), "layer 2 float - ")
end

-- send either the topmost transcient or the window itself if it has
-- no transcient to a floating workspace, on the second layer of the
-- screen.
-- the parameter "passive" overrides detach.passive if specified.

-- If "restricted" is true, then, the function will use
-- ioncore.defer(), and can be called in restricted mode. Otherwise,
-- the action is immediate.
function detach.topmost_transient_to_float(cwin, screen, passive, geom, restricted)
   local to_detach = cwin
   local l=cwin:managed_list()

   local scr = screen
   if scr == nil then
      scr = cwin:screen_of()
   end
   -- use a passive WFloatWS ?
   local passive_loc = detach.passive
   if passive ~= nil then
      passive_loc = passive
   end
   -- Find it if it already exists ...
   local name = detach.ws_name(passive_loc)
   local fws = detach.find_ws(scr, passive_loc)
   local geom_loc
   local oldgeom = to_detach:geom()
   local geom_scr = scr:geom()
   if geom == nil or (geom.x == 0 and geom.y == 0) then
      geom_loc = {
	 x = math.floor((geom_scr.w - oldgeom.w) / 2 + 5/10),
	 y = math.floor((geom_scr.h - oldgeom.h) / 2 + 5/10),
	 h = oldgeom.h,
	 w = oldgeom.w
      }
      --io.stderr:write("t:geom_loc={x="..geom_loc.x..",y="..geom_loc.y..",h="..geom_loc.h..",w="..geom_loc.w.."}\n")
   else
      geom_loc = {
	 x = geom.x,
	 y = geom.y,
	 h = oldgeom.h,
	 w = oldgeom.w
      }
      --io.stderr:write("f:geom_loc={x="..geom_loc.x..",y="..geom_loc.y..",h="..geom_loc.h..",w="..geom_loc.w.."}\n")
   end
   if not restricted then
      -- ... if not, create it
      if fws == nil then
         fws = scr:attach_new{
            type = "WFloatWS",
            name = name,
            layer = 2,
            passive = passive_loc,
            switchto = false,
         }
      end
      fws:attach(to_detach)
      fws:screen_of():l2_set_hidden(fws, 'false')
      to_detach:manager():rqgeom({x=geom_loc.x,y=geom_loc.y})
      to_detach:rqgeom({w=geom_loc.w,h=geom_loc.h})
      ioncore.defer(function()
                       to_detach:goto()
                    end)
   else
      ioncore.defer(function()
                       -- ... if not, create it
                       if fws == nil then
                          fws = scr:attach_new{
                             type = "WFloatWS",
                             name = name,
                             layer = 2,
                             passive = passive_loc,
                             switchto = false,
                          }
                       end
                       ioncore.defer(function()
                                        fws:screen_of():l2_set_hidden(fws, 'false') 
                                        fws:attach(to_detach)
                                        --   fws:goto()
                                        to_detach:manager():goto()
                                        to_detach:goto()
                                        
                                        to_detach:manager():rqgeom(geom_loc)
                                        ioncore.defer(function ()
                                                         to_detach:rqgeom({h=geom_loc.h})
                                                      end)
                                     end)
                    end)
   end
end

-- close the floating workspaces on layer 2 and relocate the floating
-- windows in the layer 1 workspace.
-- Usefull to change the settings of the workspace (passive or
-- not, ...)
function detach.close_floatws(region)
   local screen
   if region then
      screen = region:screen_of()
   end
   if (screen == nil) then
      screen = ioncore.find_screen_id(0)
   end
   for _,r in pairs(screen:llist(2)) do
      if obj_is(r, "WFloatWS") then
         local fws = r
         -- relocate windows to layer 1
         local dest = screen:lcurrent(1):current()
         for _,fframe in pairs(r:managed_list()) do
            for _,cwin in pairs(fframe:llist(1)) do
               dest:attach(cwin)
               cwin:goto()
            end
         end
         -- and close this workspace
         ioncore.defer(function () fws:rqclose() end)
      end
   end
end

-- Brings a Frame back to the layer 1
function detach.float_to_layer1 (cwin)
   local screen = cwin:screen_of()
   if screen == nil then
      screen = ioncore.find_screen_id(0)
   end
   screen:lcurrent(1):current():attach(cwin)
   ioncore.defer(function () cwin:goto() end)
end

-- detach.toggle_float (_sub) to call on a WFrame
-- Takes a frame from a WIonWS to a WFloatWS in the second layer.
function detach.toggle_float (cwin)
   if obj_is(cwin:manager(), "WFloatFrame") then
      detach.float_to_layer1(cwin)
   else
      detach.topmost_transient_to_float(cwin)
   end
end

-- candidate for clientwin_do_manage_alt to manage transient. See
-- documentation for detach.manage_transcient_with_float for details.
function detach.manager(cwin, table)
   local wp=ioncore.getwinprop(cwin)
   if detach.manage_transcient_with_float
      and table.tfor
      and not obj_is(table.tfor:manager(), "WFloatWS") then
      
      local manager = table.tfor:manager()
      detach.topmost_transient_to_float(cwin, 
                                        manager:screen_of(),
                                        (wp and wp.float_passive),
                                        table.geom)
      table.tfor:goto()
      return true
   end
   if (wp and wp.float) then
      local screen = (ioncore.current() and ioncore.current():screen_of()) or
                     (ioncore.find_screen_id(0))
      detach.topmost_transient_to_float(cwin,
                                        screen,
                                        (wp and wp.float_passive),
                                        table.geom)
      return true
   end
   return false
end

-- DEPRECATED. detach.manager() does all this now.
-- candidate for ionws_placement_alt to manage windows with the
-- "float" winprop.
function detach.ionws_manager(cwin, ws, table)
   local wp=ioncore.getwinprop(cwin)
   if wp.float then
      detach.topmost_transient_to_float(cwin,
                                        ws:screen_of(),
                                        (wp and wp.float_passive),
                                        table.geom,
                                        true)
      return true
   end
   return false
end

-- candidate for frame_managed_changed_hook.
--
-- If the action is a "remove", and the layer 2 workspace is empty, hide it.
-- This prevents an empty (and thus invisible) layer 2 floating workspace from
-- having the focus after its last managed frame is closed, so that focus
-- returns to layer 1.
function detach.maybe_leave_layer2(tbl)
   if tbl.mode == "remove" then
      local mgr = tbl.reg:manager()
      if is_l2floatws(mgr) then
         local l = mgr:managed_list()
	 -- The region will be empty if the only managed region is the one
	 -- currently being removed.
	 if table.getn(l) == 1 and l[1] == tbl.reg then
            ioncore.defer(function () mgr:screen_of():l2_set_hidden(mgr, 'true') end)
         end
      end
   end
end

function detach.skip_l2_warp(reg)
   n = reg:manager():manager():name()
   if is_l2floatws(reg:manager():manager()) then
	return true
   end
   return false
end

function detach.clientwin_manager(cwin, table)
   if detach.manager(cwin, table) then
      return true
   elseif not table.dockapp then
      local sp = nil
      local screen = (ioncore.current() and ioncore.current():screen_of()) or
                     (ioncore.find_screen_id(0))
      for _,r in pairs(screen:llist(2)) do
	 if (r:name() == "*scratchpad*") then
	    sp = r
	 end
      end
      if sp and sp:is_active() then
	 sp:attach(cwin)
	 cwin:goto()
	 return true
      end
      if screen:lcurrent(1):current():manager() and obj_is(screen:lcurrent(1):current():manager(), "WFloatWS") then
	 screen:lcurrent(1):current():manager():attach(cwin)
      else
	 screen:lcurrent(1):current():attach(cwin)
      end
      ioncore.defer(function () cwin:goto() end)
      return true
   end
   return false

end


-- canaan added 2005-02-02
-- moves focus between l1, passive l2, and active l2.
--
function detach.rotate_layer(reg)
    local screen=reg:screen_of()
    local ws=screen:current()
    local wspassive=detach.find_ws(screen, true)
    local wsactive=detach.find_ws(screen, false)
    local wsL1=screen:lcurrent(1)
    if ws==wspassive or (ws==wsactive and table.getn(wspassive:managed_list())==0) then
        wsL1:goto()
    elseif ws==wsactive or (ws==wsL1 and table.getn(wsactive:managed_list())==0 and 
      table.getn(wspassive:managed_list())>0) then
        wspassive:goto()
    elseif table.getn(wsactive:managed_list())>0 then
        wsactive:goto()
    end
end
