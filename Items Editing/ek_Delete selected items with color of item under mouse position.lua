-- @description ek_Delete selected items with color of item under mouse position
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/delete_selected_items_with_color_of_item_under_mouse_position.gif)
--   This script deletes selected items with the same color of item under mouse position

local proj = 0
local countSelectedItems = reaper.CountSelectedMediaItems(proj)

local function GetColor(item)
    if not item then return nil end
    local color = reaper.GetDisplayedMediaItemColor(item)

    if color == 0 then
        local track = reaper.GetMediaItem_Track(item)

        return reaper.GetTrackColor(track)
    else
        return color
    end
end

if countSelectedItems == 0 then return end

local x, y = reaper.GetMousePosition()
local rootItem, _ = reaper.GetItemFromPoint(x, y, false)
local rootColor = GetColor(rootItem)
local itemsToDelete = {}

reaper.Undo_BeginBlock()

for i = 0, countSelectedItems - 1 do
    local item = reaper.GetSelectedMediaItem(proj, i)
    local color = GetColor(item)

    if color == rootColor then
        table.insert(itemsToDelete, item)
    end
end

for _, item in pairs(itemsToDelete) do
    local track = reaper.GetMediaItem_Track(item)
    reaper.DeleteTrackMediaItem(track, item)
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("Delete selected items with color of item under mouse position", -1)