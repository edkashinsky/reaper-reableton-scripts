-- @description ek_Move cursor or selected items left by grid
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   If any item is selected, this script moves it to left by grid size. And moves cursor by grid in other case

reaper.Undo_BeginBlock()

local proj = 0

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
	
if countSelectedItems > 0 then
	-- Item edit: Move items/envelope points left by grid size
	reaper.Main_OnCommand(40793, 0)
else
	-- View: Move cursor left to grid division
	reaper.Main_OnCommand(40646, 0)
end

reaper.Undo_EndBlock("Move cursor or selected items left by grid", -1)