-- @description ek_Smart renaming functions
-- @author Ed Kashinsky
-- @noindex

rename_types = {
    Nothing = 0,
    Marker = 1,
	Track = 2,
	Item = 3,
}

rename_advanced_types = {
    Replace = 1,
    Add = 2,
    Format = 3
}

rename_advanced_types_key = "sr_advanced_type"
rename_last_colors_list_key = "sr_last_colors_list"
rename_default_colors_list_key = "sr_default_colors_list"

rename_default_colors_config = {
    {
        key = "sr_dc_hue",
        title = "Hue",
        type = gui_input_types.NumberSlider,
        number_min = -1.0,
        number_max = 1.0,
        default = 0,
        number_precision = "%.2f",
        on_change = function() UpdateDefaultColorsPalette() end
    },
    {
        key = "sr_dc_saturation",
        title = "Saturation",
        type = gui_input_types.NumberSlider,
        number_min = -1,
        number_max = 1,
        default = 0,
        number_precision = "%.2f",
        on_change = function() UpdateDefaultColorsPalette() end
    },
    {
        key = "sr_dc_brightness",
        title = "Brightness",
        type = gui_input_types.NumberSlider,
        number_min = -1,
        number_max = 1,
        default = 0,
        number_precision = "%.2f",
        on_change = function() UpdateDefaultColorsPalette() end
    },
}

rename_advanced_config = {
	{
		id = rename_advanced_types.Replace,
		text = "Replace Text",
		fields = {
			{ key = "sr_replace_find", title = "Find", type = gui_input_types.Text },
			{ key = "sr_replace_replace", title = "Replace with", type = gui_input_types.Text }
		}
	},
	{
		id = rename_advanced_types.Add,
		text = "Add Text",
		fields = {
			{ key = "sr_add_prefix", title = "Prefix/Postfix", type = gui_input_types.Text },
			{ key = "sr_add_where", title = "Where", type = gui_input_types.Combo, default = 0, select_values = { "After name", "Before name" } }
		}
	},
	{
		id = rename_advanced_types.Format,
		text = "Format",
		fields = {
			{ key = "sr_format_title", title = "Name format", type = gui_input_types.Combo, default = 0, select_values = { "Name and Index", "Name and ID" } },
			{ key = "sr_format_custom", title = "Custom Name", type = gui_input_types.Text },
			{ key = "sr_format_where", title = "Where", type = gui_input_types.Combo, default = 0, select_values = { "After name", "Before name" } },
			{ key = "sr_format_start", title = "Start numbers at", type = gui_input_types.Text, default = 1 },
		}
	},
}

rename_advanced_config_common = {
    sr_trim = { key = "sr_trim", title = "Trim Whitespaces", type = gui_input_types.Checkbox, default = true },
    sr_close_after_action = { key = "sr_close_after_action", title = "Auto-Close on Rename", type = gui_input_types.Checkbox, default = true },
}

local advanced_format_iterator = 0
local tf_data = {}

local function UpdateTimelineFocusData()
    tf_data = {
        is_hovered = EK_IsWindowHoveredByClass(ek_js_wnd.classes.Timeline),
        count_tracks = reaper.CountSelectedTracks2(proj, true),
        count_items = reaper.CountSelectedMediaItems(proj),
        first_track = reaper.GetSelectedTrack(proj, 0),
        first_item = reaper.GetSelectedMediaItem(proj, 0),
        focus_window = reaper.JS_Window_GetFocus()
    }
end

local function TimelineSectionIsFocused()
    if isEmpty(tf_data) then UpdateTimelineFocusData() end

    if not tf_data.is_hovered then
        if EK_IsWindowHoveredByClass(ek_js_wnd.classes.Timeline) then
            UpdateTimelineFocusData()
        else
            return false
        end
    end

    if
        tf_data.first_item ~= reaper.GetSelectedMediaItem(proj, 0) or
        tf_data.first_track ~= reaper.GetSelectedTrack(proj, 0) or
        tf_data.focus_window ~= reaper.JS_Window_GetFocus() or
        tf_data.count_items ~= reaper.CountSelectedMediaItems(proj) or
        tf_data.count_tracks ~= reaper.CountSelectedTracks2(proj, true)
    then
        tf_data.is_hovered = false
    end

    return tf_data.is_hovered
end

local function GetRegionManager()
	local title = reaper.JS_Localize("Region/Marker Manager", "common")
	local arr = reaper.new_array({}, 1024)

	reaper.JS_Window_ArrayFind(title, true, arr)

	local adr = arr.table()
	for j = 1, #adr do
		local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
		if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
      		return hwnd
    	end
    end
end

local function GetSelectedMarkers()
	local result = {}
	local hWnd = GetRegionManager()
	if hWnd == nil then return result end

	local container = reaper.JS_Window_FindChildByID(hWnd, 1071)
	local sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)

	if sel_count == 0 then return result end

	local i = 0
	for index in string.gmatch(sel_indexes, '[^,]+') do
		i = i + 1
		result[i] = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
	end

	return result
end

local function GetHeaderLabel(type, title, count)
    if count == 1 then
        return title
    else
        local typeTitle

        if type == rename_types.Item then typeTitle = "items"
        elseif type == rename_types.Track then typeTitle = "tracks"
        elseif type == rename_types.Marker then typeTitle = "markers/regions"
        else typeTitle = "elements" end

        return count .. " selected " .. typeTitle
    end
end

local function GetProjectMarkerByNumber(number, is_region)
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)

	for i = 0, num_markers + num_regions - 1 do
        local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(proj, i)

        if is_region == isrgn and number == markrgnindexnumber then
            return pos, rgnend, name, markrgnindexnumber, color, i
        end
    end
end

function GetProcessedTitleByAdvanced(title, id)
    local config = {}
    local a_type = EK_GetExtState(rename_advanced_types_key, rename_advanced_types.Replace)

    for _, a_config in pairs(rename_advanced_config) do
        if a_type == a_config.id then
            for _, f_config in pairs(a_config.fields) do
                config[f_config.key] = EK_GetExtState(f_config.key, f_config.default)
            end

            break
        end
	end

    if a_type == rename_advanced_types.Replace then
        local find = config.sr_replace_find
        local replace = config.sr_replace_replace

        if not find then return title end
        if not replace then replace = "" end

        find = escape_regexp_chars(find)

        local str, _ = string.gsub(title, find, replace)

        return str
    elseif a_type == rename_advanced_types.Add then
        local prefix = config.sr_add_prefix
        local where = config.sr_add_where

        if not prefix then return title end

        if where == 0 then -- after name
            return title .. prefix
        else
            return prefix .. title
        end
    elseif a_type == rename_advanced_types.Format then
        local format = config.sr_format_title
        local custom = config.sr_format_custom
        local where = config.sr_format_where
        local index = config.sr_format_start
        local initIndexMask, startIterator, curIndex, initDigitCount
        local newTitle = custom ~= nil and custom or title
        local value = ""
        local prefix

        if not index then index = 1 end

        -- to add abititty "_007"
        initIndexMask = string.gsub(index, "[^0-9]+", "") -- "007"
        startIterator = tonumber(initIndexMask) -- "7"

        if not startIterator then startIterator = 1 end

        initDigitCount = string.len(initIndexMask)

        curIndex = startIterator + advanced_format_iterator

        if initDigitCount > string.len(tostring(curIndex)) then
            for _ = 1, initDigitCount - string.len(tostring(curIndex)) do value = value .. "0" end
        end

        value = value .. curIndex

        if format == 0 then -- Name and index
            if not isEmpty(initIndexMask) then
                prefix = string.gsub(index, initIndexMask, value)
            else
                prefix = ""
            end
        elseif format == 1 then -- Name and ID
            prefix = " " .. id
        end

        if where == 0 then -- after name
            return newTitle .. prefix
        else
            return prefix .. newTitle
        end
    end
end

local function GetRegionOrTCPWindowFocusedData()
    local wnd = reaper.JS_Window_GetFocus()
    local result = {
        region_manager = false,
        tcp = false,
        gui = false
    }

	local UpdateFocusData = function(f_wnd)
        local className = reaper.JS_Window_GetClassName(f_wnd)
        local title = reaper.JS_Window_GetTitle(f_wnd)

        if className == ek_js_wnd.classes.TCP then
            result.tcp = true
        end

        if title == ek_js_wnd.titles.RegionManager then
            result.region_manager = true
        end

        if title == ek_js_wnd.titles.ScriptSmartRenaming then
            result.gui = true
        end
	end

	while wnd ~= nil do
        UpdateFocusData(wnd)
        if result.region_manager or result.tcp or result.gui then return result end

		wnd = reaper.JS_Window_GetParent(wnd)
	end

	return result
end

local function FindFocusedElement(focused_data)
    ---------------------------------------------------------------
    ---              MARKERS/REGIONS (Region Manager)
    ---------------------------------------------------------------
    local selectedMarkersInManager = GetSelectedMarkers()
    if #selectedMarkersInManager > 0 and focused_data.region_manager then
        local number, isRegion, name, markrgnindexnumber, color, title
        local data = {}

        for i = 1, #selectedMarkersInManager do
            number = tonumber(string.sub(selectedMarkersInManager[i], 2))
            isRegion = string.sub(selectedMarkersInManager[i], 1, 1) == "R"

            if i == 1 then
                _, _, name, markrgnindexnumber, color = GetProjectMarkerByNumber(number, isRegion)
                title = not isEmpty(name) and name or ((isRegion and "Region" or "Marker") .. " #" .. markrgnindexnumber)
            end

            table.insert(data, {
                number = number,
                isRegion = isRegion
            })
        end

        return {
            type = rename_types.Marker,
            typeTitle = #selectedMarkersInManager == 1 and (isRegion and "Region" or "Marker") or "Markers/regions",
            value = name,
            title = GetHeaderLabel(rename_types.Marker, title, #selectedMarkersInManager),
            color = reaper.ImGui_ColorConvertNative(color) & ~0x1000000,
            data = data,
        }
    end

    ---------------------------------------------------------------
    ---           MARKERS/REGIONS (hovered on timeline)
    ---------------------------------------------------------------
    if TimelineSectionIsFocused() then
        local s_isrgn, s_pos, s_rgnend, s_name, s_markrgnindexnumber, s_color, title
        local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
        local cursorPosition = reaper.GetCursorPosition()

        for i = 0, num_markers + num_regions - 1 do
            local _, isrgn, pos, rgnend, name, markrgnindexnumber, clr = reaper.EnumProjectMarkers3(proj, i)

            if pos == cursorPosition then
                s_markrgnindexnumber = markrgnindexnumber
                s_isrgn = isrgn
                s_pos = pos
                s_rgnend = rgnend
                s_name = name
                s_color = clr
                title = not isEmpty(s_name) and s_name or ((s_isrgn and "Region" or "Marker") .. " #" .. s_markrgnindexnumber)
            end
        end

        if s_markrgnindexnumber ~= nil then
            local data = {}

            table.insert(data, {
                number = s_markrgnindexnumber,
                isRegion = s_isrgn
            })

            return {
                type = rename_types.Marker,
                typeTitle = s_isrgn and "Region" or "Marker",
                value = s_name,
                title = title,
                color = reaper.ImGui_ColorConvertNative(s_color) & ~0x1000000,
                data = data,
            }
        end
    end

    ---------------------------------------------------------------
    ---                       TRACKS
    ---------------------------------------------------------------
    local countSelectedTracks = reaper.CountSelectedTracks2(proj, true)
    local countSelectedItems = reaper.CountSelectedMediaItems(proj)

    if countSelectedTracks > 0 and (countSelectedItems == 0 or focused_data.tcp) then
        local value, title, color
        local data = {}
        for i = 0, countSelectedTracks - 1 do
            local track = reaper.GetSelectedTrack2(proj, i, true)
            local guid = reaper.GetTrackGUID(track)

            if i == 0 then
                _, title = reaper.GetTrackName(track)
                _, value = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                color = reaper.GetTrackColor(track)
            end

            table.insert(data, guid)
        end

        return {
            type = rename_types.Track,
            typeTitle = countSelectedTracks == 1 and "Track" or "Tracks",
            value = value,
            title = GetHeaderLabel(rename_types.Track, title, countSelectedTracks),
            color = reaper.ImGui_ColorConvertNative(color) & ~0x1000000,
            data = data,
        }
    end

    ---------------------------------------------------------------
    ---                       ITEMS
    ---------------------------------------------------------------
    if countSelectedItems > 0 then
        local value, title, color
        local data = {}
        for i = 0, countSelectedItems - 1 do
            local item = reaper.GetSelectedMediaItem(proj, i)
            local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)

            if i == 0 then
                local take = reaper.GetActiveTake(item)

                if take then
                    title = reaper.GetTakeName(take)
                else
                     _, title = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
                end

                value = title
                color = take and reaper.GetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR") or nil

                if isEmpty(color) then
                    color = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
                end

                 if isEmpty(title) then
                    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    title = "Item at " .. round(pos, 2) .. "s"
                end
            end

            table.insert(data, guid)
        end

        return {
            type = rename_types.Item,
            typeTitle = countSelectedItems == 1 and "Item" or "Items",
            value = value,
            title = GetHeaderLabel(rename_types.Item, title, countSelectedItems),
            color = reaper.ImGui_ColorConvertNative(color) & ~0x1000000,
            data = data,
        }
    end

    ---------------------------------------------------------------
    ---                      NOT FOUND
    ---------------------------------------------------------------
    return {
        type = rename_types.Nothing,
        typeTitle = "No focus",
        value = "",
        title = "Nothing",
        color = 0,
        data = {},
    }
end

function SaveData(element, isTitleSet, isColorSet, isAdvanced)
    local color = isColorSet and reaper.ImGui_ColorConvertNative(element.color) or 0
    local isTrim = EK_GetExtState(rename_advanced_config_common.sr_trim.key, rename_advanced_config_common.sr_trim.default)

    for _, guid in pairs(element.data) do
        if element.type == rename_types.Marker then
            ---------------------------------------------------------------
            ---                   MARKERS/REGIONS
            ---------------------------------------------------------------
            local pos, rgnend, name, markrgnindexnumber, _, i = GetProjectMarkerByNumber(guid.number, guid.isRegion)
            local newTitle

            if isTitleSet then
                newTitle = isAdvanced and GetProcessedTitleByAdvanced(name, markrgnindexnumber) or element.value
            else
                newTitle = name
            end

            if isTrim then newTitle = trim(newTitle) end

            if isColorSet then
                if color == 0 then
                    reaper.DeleteProjectMarkerByIndex(proj, i)
                    reaper.AddProjectMarker(proj, guid.isRegion, pos, rgnend, newTitle, math.max(markrgnindexnumber, 1))
                else
                    reaper.SetProjectMarker3(proj, markrgnindexnumber, guid.isRegion, pos, rgnend, newTitle, color | 0x1000000)
                end
            else
                reaper.SetProjectMarker2(proj, markrgnindexnumber, guid.isRegion, pos, rgnend, newTitle)
            end

            if isEmpty(newTitle) then
                reaper.SetProjectMarker4(proj, markrgnindexnumber, guid.isRegion, pos, rgnend, newTitle, 0, 0x1)
            end
        elseif element.type == rename_types.Track then
            ---------------------------------------------------------------
            ---                     TRACKS
            ---------------------------------------------------------------
            local track = EK_GetMediaTrackByGUID(guid)
            local newTitle

            if track ~= nil then
                if isTitleSet then
                    if isAdvanced then
                        local _, title = reaper.GetTrackName(track)
                        local id = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))

                        newTitle = GetProcessedTitleByAdvanced(title, id)
                    else
                        newTitle = element.value
                    end

                    if isTrim then newTitle = trim(newTitle) end

                    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", newTitle, true)
                end

                if isColorSet then
                    if color ~= 0 then color = color | 0x1000000 end

                    reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", color)
                end
            end
        elseif element.type == rename_types.Item then
            ---------------------------------------------------------------
            ---                     ITEMS
            ---------------------------------------------------------------
            local item = EK_GetMediaItemByGUID(guid)
            local newTitle

            if item ~= nil then
                local take = reaper.GetActiveTake(item)

                if isAdvanced then
                    local title = take and reaper.GetTakeName(take) or ""
                    local id = math.floor(reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")) + 1

                    newTitle = GetProcessedTitleByAdvanced(title, id)
                else
                    newTitle = element.value
                end

                if isTrim then newTitle = trim(newTitle) end

                for i = 0, reaper.CountTakes(item) - 1 do
                    local i_take = reaper.GetTake(item, i)

                    if element.applyToAllTakes or i_take == take then
                        if isTitleSet then
                            reaper.GetSetMediaItemTakeInfo_String(i_take, "P_NAME", newTitle, true)
                        end

                        if isColorSet then
                            if color ~= 0 then color = color | 0x1000000 end

                            reaper.SetMediaItemTakeInfo_Value(i_take, "I_CUSTOMCOLOR", color)

                            if element.applyToAllTakes then
                                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
                            end
                        end
                    end
                end

                if (reaper.CountTakes(item) == 0) then
                    if isTitleSet then
                        reaper.GetSetMediaItemInfo_String(item, "P_NOTES", newTitle, true)
                    end

                    if isColorSet then
                        if color ~= 0 then color = color | 0x1000000 end

                        if element.applyToAllTakes then
                            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
                        end
                    end
                end
            end
        end

        if isAdvanced then
            advanced_format_iterator = advanced_format_iterator + 1
        end

        Log("SAVING DATA", ek_log_levels.Notice)
        Log(element, ek_log_levels.Notice)
    end
end

local cached_element
function GetFocusedElement()
    local focused_data = GetRegionOrTCPWindowFocusedData()

    if focused_data.gui and not isEmpty(cached_element) then return cached_element end

    cached_element = FindFocusedElement(focused_data)

    return cached_element
end