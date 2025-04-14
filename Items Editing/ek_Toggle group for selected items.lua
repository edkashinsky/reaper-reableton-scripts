-- @description ek_Toggle group for selected items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script makes group disable, if any selected item is grouped and otherwise if not.

reaper.Undo_BeginBlock()

local proj = 0
local isAnySelectedItemGrouped = false

for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)

	if reaper.GetMediaItemInfo_Value(item, "I_GROUPID") ~= 0 then
		isAnySelectedItemGrouped = true
		break
	end
end

if isAnySelectedItemGrouped then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40033), 0) -- Item grouping: Remove items from group
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40032), 0) -- Item grouping: Group items
end

reaper.Undo_EndBlock("Toggle group for selected items", -1)