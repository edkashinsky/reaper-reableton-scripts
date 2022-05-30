-- @description ek_Toggle random color for selected items or tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It changes color for items or tracks depending on focus

reaper.Undo_BeginBlock()

local proj = 0

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
	
if countSelectedItems > 0 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(41332), 0) -- Take: Set active take to one random color
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_e2dfbf52ef604fcab3836124c001c5aa"), 0) -- Custom: SWS: Set tracks/items to one random color with children
end

reaper.Undo_EndBlock("Toggle random color for selected items or tracks", -1)