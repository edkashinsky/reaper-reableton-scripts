-- @description ek_Move cursor to start of item under mouse
-- @author Ed Kashinsky
-- @noindex
-- @about It just moves edit cursor to start of selected item
-- @readme_skip

reaper.Undo_BeginBlock()

local proj = 0
local x, y = reaper.GetMousePosition()
local item, _ = reaper.GetItemFromPoint(x, y, false)

if not item then return end

reaper.Main_OnCommand(reaper.NamedCommandLookup(40289), 0) -- Item: Unselect (clear selection of) all items
reaper.SetMediaItemSelected(item, true)

local start_time, end_time = reaper.GetSet_ArrangeView2(proj, false, 0, 0, 0, 0)
local play_cursor = reaper.GetCursorPosition()
local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local new_position = play_cursor - position

reaper.MoveEditCursor(-new_position, false)
reaper.GetSet_ArrangeView2(proj, true, 0, 0, start_time, end_time)

reaper.Undo_EndBlock("Move cursor to start of item under mouse", -1)