-- @description ek_Move cursor or selected items left by pixel
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   If any item is selected, this script moves to left it by pixel. And moves cursor by pixel in other case

reaper.Undo_BeginBlock()

local proj = 0

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
	
if countSelectedItems > 0 then
	-- Item edit: Move items/envelope points left
	reaper.Main_OnCommand(40120, 0)
else
	-- View: Move cursor left one pixel
	reaper.Main_OnCommand(40104, 0)
end

reaper.Undo_EndBlock("Move cursor or selected items left by pixel", -1)