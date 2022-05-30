-- @description ek_Smart horizontal zoom in
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script helps live with Project Limit option is on. It makes zoom available to places behind limits

reaper.Undo_BeginBlock()

--
--  1. Set zoom mode "Center of view"
--
local center_view_option = 2
local zoommode = reaper.SNM_GetIntConfigVar("zoommode", 3) -- The horizontal zoom center
local project_length = reaper.SNM_GetIntConfigVar("projmaxlenuse", 1) -- Limit projectlength, stop playback/recording at:
reaper.SNM_SetIntConfigVar("zoommode", center_view_option)
reaper.SNM_SetIntConfigVar("projmaxlenuse", 0)


-- 
--  2. Zoom in action 
--
reaper.Main_OnCommand(reaper.NamedCommandLookup(1012), 0) -- View: Zoom in horizontal


--
-- 3. Return default zoom mode
--
reaper.SNM_SetIntConfigVar("zoommode", zoommode)
reaper.SNM_SetIntConfigVar("projmaxlenuse", project_length)

reaper.Undo_EndBlock("Smart horizontal zoom in", -1)