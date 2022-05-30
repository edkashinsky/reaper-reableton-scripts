-- @description ek_Duplicate selected tracks or items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   If any item is selected, it duplicate item. In other case is duplicate track

reaper.Undo_BeginBlock()

local proj = 0
local countSelectedItems = reaper.CountSelectedMediaItems(proj)
	
if countSelectedItems > 0 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(41295), 0)
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40062), 0)
end

reaper.Undo_EndBlock("Duplicate selected tracks or items", -1)