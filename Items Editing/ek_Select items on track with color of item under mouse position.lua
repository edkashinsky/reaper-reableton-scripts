-- @description ek_Select items on track with color of item under mouse position
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script selects items with the same color and on same track of item under mouse position

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

local x, y = reaper.GetMousePosition()
local rootItem, _ = reaper.GetItemFromPoint(x, y, false)

if not rootItem then return end

local rootTrack = reaper.GetMediaItem_Track(rootItem)
local rootColor = GetColor(rootItem)

reaper.Undo_BeginBlock()

for i = 0, reaper.CountTrackMediaItems(rootTrack) - 1 do
    local item = reaper.GetTrackMediaItem(rootTrack, i)
    local color = GetColor(item)

    if color == rootColor then
         reaper.SetMediaItemSelected(item, true)
    end
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("Select items on track with color of item under mouse position", -1)