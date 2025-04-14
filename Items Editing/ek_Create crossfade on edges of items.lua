-- @description ek_Create crossfade on edges of items
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script creates crossfade on edges of tracks. It useful when you don't use overlap on crossfades for better precise but anyway want to create crossfades
--
--   Installation for better experience:
--      1. Open **Preferences** -> **Editing Behavior** -> **Mouse Modifiers**
--      2. In **Context** field choose **Media item edge** and **double click** in right one
--      3. Choose this script in field **Default action**
--      4. Done! It means that when you double click on edge between media items, you create crossfade between them
-- @changelog
--   Fixed bug when no any selected track

reaper.Undo_BeginBlock()

local proj = 0
local retval, div = reaper.GetSetProjectGrid(proj, false)
local crossfade_length = 2 * div
local can_crossfade = false
local selected_track = reaper.GetSelectedTrack(proj, 0)

if crossfade_length < 0.0001 then
    crossfade_length = 0.0001
end

function prepareCrossfadeItems(left_item, right_item)
    if left_item == nil then return false end

    local cursor_position = reaper.GetCursorPosition()
    local half_length = crossfade_length / 2
    local left_position = reaper.GetMediaItemInfo_Value(left_item, "D_POSITION")
    local left_length = reaper.GetMediaItemInfo_Value(left_item, "D_LENGTH")
    local right_take = reaper.GetActiveTake(right_item)
    local right_offset = reaper.GetMediaItemTakeInfo_Value(right_take, "D_STARTOFFS")
    local right_position = reaper.GetMediaItemInfo_Value(right_item, "D_POSITION")

    if left_position + left_length ~= cursor_position then return false end
    if right_position ~= cursor_position then return false end

    -- left item
    reaper.SetMediaItemInfo_Value(left_item, "D_LENGTH", left_length + half_length)

    -- right item
    reaper.SetMediaItemInfo_Value(right_item, "D_POSITION", right_position - half_length)
    reaper.SetMediaItemTakeInfo_Value(right_take, "D_STARTOFFS", right_offset - half_length)

    return true
end

if selected_track ~= nil then
    for i = 0, reaper.CountTrackMediaItems(selected_track) - 1 do
        local item = reaper.GetTrackMediaItem(selected_track, i)
        local prev_item = reaper.GetTrackMediaItem(selected_track, i - 1)

        if prepareCrossfadeItems(prev_item, item) then
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESELITEMS1"), 0) -- SWS: Save selected track(s) selected item(s), slot 1

            reaper.SetMediaItemSelected(item, true)
            reaper.SetMediaItemSelected(prev_item, true)

            can_crossfade = true
            break
        end
    end
end

if can_crossfade then
    reaper.Main_OnCommand(reaper.NamedCommandLookup(41059), 0) -- Item: Crossfade any overlapping items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTSELITEMS1"), 0) -- SWS: Restore selected track(s) selected item(s), slot 1
end

reaper.Undo_EndBlock("Create crossfade on edges of items", -1)