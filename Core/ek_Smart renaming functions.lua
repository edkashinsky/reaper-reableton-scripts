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
rename_advanced_config = {
	{
		id = rename_advanced_types.Replace,
		text = "Replace Text",
		fields = {
			{ key = "sr_replace_find", title = "Find", type = gui_widget_types.Text },
			{ key = "sr_replace_replace", title = "Replace with", type = gui_widget_types.Text }
		}
	},
	{
		id = rename_advanced_types.Add,
		text = "Add Text",
		fields = {
			{ key = "sr_add_prefix", title = "Prefix", type = gui_widget_types.Text },
			{ key = "sr_add_where", title = "Where", type = gui_widget_types.Combo, default = 0, select_values = { "After name", "Before name" } }
		}
	},
	{
		id = rename_advanced_types.Format,
		text = "Format",
		fields = {
			{ key = "sr_format_title", title = "Name format", type = gui_widget_types.Combo, default = 0, select_values = { "Name and Index", "Name and ID" } },
			{ key = "sr_format_custom", title = "Custom Format", type = gui_widget_types.Text },
			{ key = "sr_format_where", title = "Where", type = gui_widget_types.Combo, default = 0, select_values = { "After name", "Before name" } },
			{ key = "sr_format_start", title = "Start numbers at", type = gui_widget_types.Text, default = 1 },
		}
	},
}

local advanced_format_iterator = 0

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

local function IsRegionManagerFocused()
	local hWnd = GetRegionManager()
	local focusWnd = reaper.JS_Window_GetFocus()

	if hWnd == nil or focusWnd == nil then return false end

	local isFocus = hWnd == focusWnd
	local parentWnd = reaper.JS_Window_GetParent(focusWnd)

	while isFocus == false and parentWnd ~= nil do
		if hWnd == parentWnd then isFocus = true end

		parentWnd = reaper.JS_Window_GetParent(parentWnd)
	end

	return isFocus
end

local function GetHeaderLabel(title, count)
    if count == 1 then
        return title
    else
         return count .. " selected elements"
    end
end

local function GetProjectMarkerByNumber(number, is_region)
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)

	for i = 0, num_markers + num_regions - 1 do
        local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(proj, i)

        if is_region == isrgn and number == markrgnindexnumber then
            return pos, rgnend, name, markrgnindexnumber, color
        end
    end
end

function GetProcessedTitleByAdvanced(title, id)
    local config = {}
    local type = EK_GetExtState(rename_advanced_types_key, rename_advanced_types.Replace)

    for _, a_config in pairs(rename_advanced_config) do
        if type == a_config.id then
            for _, f_config in pairs(a_config.fields) do
                config[f_config.key] = EK_GetExtState(f_config.key, f_config.default)
            end

            goto end_looking
        end
	end

    ::end_looking::

    if type == rename_advanced_types.Replace then
        local find = config.sr_replace_find
        local replace = config.sr_replace_replace

        if not find or not replace then return title end

        local str, _ = string.gsub(title, find, replace)

        return str
    elseif type == rename_advanced_types.Add then
        local prefix = config.sr_add_prefix
        local where = config.sr_add_where

        if not prefix then return title end

        if where == 0 then -- after name
            return title .. prefix
        else
            return prefix .. title
        end
    elseif type == rename_advanced_types.Format then
        local format = config.sr_format_title
        local custom = config.sr_format_custom
        local where = config.sr_format_where
        local index = tonumber(config.sr_format_start)
        local newTitle = custom ~= nil and custom or title
        local prefix

        if not custom then return title end
        if not index then index = 1 end

        index = index + advanced_format_iterator

        if format == 0 then -- Name and index
            prefix = index
        elseif format == 1 then -- Name and ID
            prefix = id
        end

        if where == 0 then -- after name
            return newTitle .. prefix
        else
            return prefix .. newTitle
        end
    end
end

function GetFocusedElement()
    local x, y = reaper.GetMousePosition()
    local hoveredWnd = reaper.JS_Window_FromPoint(x, y)

    ---------------------------------------------------------------
    ---              MARKERS/REGIONS (Region Manager)
    ---------------------------------------------------------------
    local selectedMarkersInManager = GetSelectedMarkers()
    if (IsRegionManagerFocused() and #selectedMarkersInManager > 0) then
        local number, isRegion, name, color
        local data = {}

        for i = 1, #selectedMarkersInManager do
            number = tonumber(string.sub(selectedMarkersInManager[i], 2))
            isRegion = string.sub(selectedMarkersInManager[i], 1, 1) == "R"

            if i == 1 then
                _, _, name, _, color = GetProjectMarkerByNumber(number, isRegion)
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
            title = GetHeaderLabel(name, #selectedMarkersInManager),
            color = color,
            data = data,
        }
    end

    ---------------------------------------------------------------
    ---           MARKERS/REGIONS (hovered on timeline)
    ---------------------------------------------------------------
    if EK_IsWindow(hoveredWnd, ek_js_wnd_classes.Timeline) then
        local s_isrgn, s_pos, s_rgnend, s_name, s_markrgnindexnumber, s_color
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
                title = s_name,
                color = s_color,
                data = data,
            }
        end
    end

    ---------------------------------------------------------------
    ---                       TRACKS
    ---------------------------------------------------------------
    local countSelectedTracks = reaper.CountSelectedTracks2(proj, true)
    local countSelectedItems = reaper.CountSelectedMediaItems(proj)

    if countSelectedTracks > 0 and (countSelectedItems == 0 or EK_IsWindow(hoveredWnd, ek_js_wnd_classes.TCP)) then
        local value, title, color
        local data = {}
        for i = 0, countSelectedTracks - 1 do
            local track = reaper.GetSelectedTrack2(proj, i, true)
            local guid = reaper.GetTrackGUID(track)

            if i == 0 then
                _, title = reaper.GetTrackName(track)
                value = title
                color = reaper.GetTrackColor(track)
            end

            table.insert(data, guid)
        end

        return {
            type = rename_types.Track,
            typeTitle = countSelectedTracks == 1 and "Track" or "Tracks",
            value = value,
            title = GetHeaderLabel(title, countSelectedTracks),
            color = color,
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

                title = reaper.GetTakeName(take)
                value = title
                color = reaper.GetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR")

                if color == 0 then
                    color = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
                end
            end

            table.insert(data, guid)
        end

        return {
            type = rename_types.Item,
            typeTitle = countSelectedItems == 1 and "Item" or "Items",
            value = value,
            title = GetHeaderLabel(title, countSelectedItems),
            color = color,
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

function SaveData(element, isColorSet, isAdvanced)
    for _, guid in pairs(element.data) do
        if element.type == rename_types.Marker then
            ---------------------------------------------------------------
            ---                   MARKERS/REGIONS
            ---------------------------------------------------------------
            local pos, rgnend, name, markrgnindexnumber, _ = GetProjectMarkerByNumber(guid.number, guid.isRegion)
            local newTitle

            if isAdvanced then
                newTitle = GetProcessedTitleByAdvanced(name, markrgnindexnumber)
                advanced_format_iterator = advanced_format_iterator + 1
            else
                newTitle = element.value
            end

            if isColorSet then
                reaper.SetProjectMarker3(proj, markrgnindexnumber, guid.isRegion, pos, rgnend, newTitle, element.color | 0x1000000)
            else
                reaper.SetProjectMarker2(proj, markrgnindexnumber, guid.isRegion, pos, rgnend, newTitle)
            end
        elseif element.type == rename_types.Track then
            ---------------------------------------------------------------
            ---                     TRACKS
            ---------------------------------------------------------------
            local track = EK_GetMediaTrackByGUID(guid)
            local newTitle

            if track ~= nil then
                if isAdvanced then
                    local _, title = reaper.GetTrackName(track)
                    local id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

                    newTitle = GetProcessedTitleByAdvanced(title, id)
                    advanced_format_iterator = advanced_format_iterator + 1
                else
                    newTitle = element.value
                end

                reaper.GetSetMediaTrackInfo_String(track, "P_NAME", newTitle, true)

                if isColorSet then
                    reaper.SetTrackColor(track, element.color)
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
                    local title = reaper.GetTakeName(take)
                    local id = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")

                    newTitle = GetProcessedTitleByAdvanced(title, id)
                else
                    newTitle = element.value
                end

                for i = 0, reaper.CountTakes(item) - 1 do
                    local i_take = reaper.GetTake(item, i)

                    if element.applyToAllTakes or i_take == take then
                        reaper.GetSetMediaItemTakeInfo_String(i_take, "P_NAME", newTitle, true)

                        if isColorSet then
                            reaper.SetMediaItemTakeInfo_Value(i_take, "I_CUSTOMCOLOR", element.color | 0x1000000)

                            if element.applyToAllTakes then
                                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", element.color | 0x1000000)
                            end
                        end
                    end
                end
            end
        end

        if isAdvanced then
            advanced_format_iterator = advanced_format_iterator + 1
        end
    end
end