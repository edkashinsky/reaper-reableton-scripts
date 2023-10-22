-- @description ek_Move cursor or selected items right by pixel
-- @author Ed Kashinsky
-- @noindex
-- @about If any item is selected, this script moves it to right by pixel. And moves cursor by pixel in other case
-- @readme_skip

reaper.Undo_BeginBlock()

local proj = 0

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
	
if countSelectedItems > 0 then
	-- Item edit: Move items/envelope points right
	reaper.Main_OnCommand(40119, 0)
else
	-- View: Move cursor right one pixel
	reaper.Main_OnCommand(40105, 0)
end

reaper.Undo_EndBlock("Move cursor or selected items right by pixel", -1)