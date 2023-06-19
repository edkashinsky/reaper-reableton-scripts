-- @description ek_Smart split items by mouse cursor functions
-- @author Ed Kashinsky
-- @noindex

local proj = 0

split_settings = {
    offset = {
        key = "ss_offset",
        type = gui_input_types.NumberDrag,
        number_precision = '%.2f',
        title = "Offset of edit cursor after split (in seconds)",
        description = "You can put edit cursor in front of the first split item. If number is negative, edit cursor moves to left",
        default = 0,
        order = 1,
    },
    selectAfter = {
        key = "ss_selectAfter",
        type = gui_input_types.Combo,
        title = "Resulting item selection",
        description = "Choose which side of the cut line the items will be selected after split",
        select_values = {
			"Left-side items", "Right-side items", "No change selection",
		},
        default = 1,
        order = 2,
    },
    inaccuracy = {
        key = "ss_inaccuracy",
        type = gui_input_types.NumberDrag,
        number_min = 0,
        title = "Tolerance between mouse position and edit cursor (in pixels)",
        description = "Enter how far from edit cursor you can click so that the cut line is on edit cursor (not on mouse position)",
        default = 10,
        order = 3,
    }
}

function IsPositionOnItem(item, position)
    if not item then return false end

    local iPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local iLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    return position > iPos and position < iPos + iLen
end

function GetItemIdsByGroupId(groupId)
    local result = {}

    if groupId == 0 then return result end

    for i = 0, reaper.CountMediaItems(proj) - 1 do
        local item = reaper.GetMediaItem(proj, i)

        if reaper.GetMediaItemInfo_Value(item, "I_GROUPID") == groupId then
             local _, id = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)

            table.insert(result, id)
        end
    end

    return result
end

function SplitItem(item, position)
    reaper.SplitMediaItem(item, position)

    local groupId = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if groupId ~= 0 then
        local itemIds = GetItemIdsByGroupId(groupId)

        for _, guid in pairs(itemIds) do
            local groupItem = EK_GetMediaItemByGUID(guid)

            if groupItem ~= nil and groupItem ~= item and IsPositionOnItem(groupItem, position) then
                reaper.SplitMediaItem(groupItem, position)
            end
        end
    end
end

function HasAnyRazorEdit()
    for i = 0, reaper.CountTracks(proj) - 1 do
	    local track = reaper.GetTrack(proj, i)
	    local _, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

        if string.len(razorStr) > 0 then return true end
    end

    return false
end

function IsMediaItemInRazorEdit(item, rStart, rEnd)
    return IsPositionOnItem(item, rStart) or IsPositionOnItem(item, rEnd)
end

function SelectItemsOnTrackInRange(track, rStart, rEnd)
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        if position >= rStart and position + length <= rEnd then
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

function SelectItemsOnEdge(track, position, selectByMousePosition)
    local s_config = split_settings.selectAfter
    local selectAfter = EK_GetExtState(s_config.key, s_config.default)

    -- For cursor cutting use mouse position
    if selectAfter ~= 2 and selectByMousePosition == true then
        local MainHwnd = reaper.GetMainHwnd()
        local ArrangeHwnd = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
        local zoom = reaper.GetHZoomLevel()
        local _, scrollOffsetPx = reaper.JS_Window_GetScrollInfo(ArrangeHwnd, "h")
        local scrollOffsetTime = scrollOffsetPx / zoom

        local eCurPosition = reaper.GetCursorPosition()
        local x, y = reaper.GetMousePosition()
        local arr_x, _ = reaper.JS_Window_ScreenToClient(ArrangeHwnd, x, y)
        local eCurOffsetPx = (eCurPosition - scrollOffsetTime) * zoom

        if (arr_x > eCurOffsetPx) then
            selectAfter = 1 -- RIGHT SIDE
        else
            selectAfter = 0 -- LEFT SIDE
        end
    end

    local needToSelect = selectAfter == 0 or selectAfter == 1

    for j = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, j)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        if (selectAfter == 1 and pos == position) or (selectAfter == 0 and pos + length == position) then
            reaper.SetMediaItemSelected(item, true)
        elseif needToSelect then
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function CutAllItemsOnPosition(position)
    local isAnyCutDone = false

    for i = 0, reaper.CountTracks(proj) - 1 do
        local track = reaper.GetTrack(proj, i)

        for j = 0, reaper.CountTrackMediaItems(track) - 1 do
            local item = reaper.GetTrackMediaItem(track, j)

            if IsPositionOnItem(item, position) then
                reaper.SplitMediaItem(item, position)
                SelectItemsOnEdge(track, position, true)
                isAnyCutDone = true
            end
        end
    end

    return isAnyCutDone
end