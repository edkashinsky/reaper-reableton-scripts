-- @description ek_Snap items to markers or regions
-- @version 1.1.0
-- @author Ed Kashinsky
-- @about
--   This script snaps selected items to markers or regions started from specified number. It requires ReaImGui extension.
--   It has 3 behaviours: simple, stems, consider overlapped items. You can see how it works shematically on pictograms in GUI
--   You can set custom offset depends on your need: just begin of item, snap offset, first cue marker, peak of item
--   Script gives posibility to limit markers/regions snapping. For example only 2 markers after specified.
-- @readme_skip
-- @changelog
--   Added brand new snapping behaviours: simple, stems, consider overlapped items
--   Also there is flexible offset: just begin of item, snap offset, first cue marker, peak of item
-- @provides
--   ../Core/ek_Snap items to markers functions.lua
--   ../Core/images/marker_overlapped.png
--   ../Core/images/marker_single.png
--   ../Core/images/marker_stems.png
--   ../Core/images/region_overlapped.png
--   ../Core/images/region_single.png
--   ../Core/images/region_stems.png
--   [main=main] ek_Snap items to closest markers.lua
--   [main=main] ek_Snap items to closest regions.lua

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded("ek_Core functions.lua")
if not loaded then
	if loaded == nil then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
	end
	return
end

CoreFunctionsLoaded("ek_Snap items to markers functions.lua")

local window_open = true
local markers_list = { "No markers" }
local count_list = {}

local gui_config = {
	{
		type = gui_input_types.Combo,
		key = data.snap_to.key,
		title = "Snap to",
		select_values =  {
			[SNAP_TO_MARKERS] = "Markers",
			[SNAP_TO_REGIONS] = "Regions"
		},
		default = data.snap_to.default
	},
	{
		type = gui_input_types.Combo,
		key = data.start_marker.key,
		title = function()
			return data.snap_to.value == SNAP_TO_MARKERS and "Start marker number" or "Start region number"
		end,
		select_values = function()
			return markers_list
		end,
		default = data.start_marker.default
	},
	{
		type = gui_input_types.Combo,
		key = data.count_on_track.key,
		title = function()
			return data.snap_to.value == SNAP_TO_MARKERS and "Number of markers from starting" or "Number of regions from starting"
		end,
		select_values = function()
			return count_list
		end,
		default = data.count_on_track.default
	},
	{
		type = gui_input_types.Combo,
		key = data.position.key,
		title = "Snap position",
		select_values = {
			[POSITION_BEGIN] = "Beginning of leading item",
			[POSITION_SNAP_OFFSET] = "Snap offset of leading item",
			[POSITION_FIRST_CUE] = "First cue marker in leading item",
			[POSITION_PEAK] = "Peak of leading item"
		},
		default = data.position.default
	},
	{
		type = gui_input_types.ComboImages,
		key = data.behaviour.key,
		title = "Snapping behaviour",
		select_values = function()
			local rootPath = CORE_PATH .. "images" .. dir_sep
			local prefix = data.snap_to.value == SNAP_TO_MARKERS and "marker" or "region"
			return {
				{
					id = BEHAVIOUR_TYPE_SINGLE,
					title = "One item per marker",
					image = rootPath .. prefix .. "_single.png",
				},
				{
					id = BEHAVIOUR_TYPE_STEM,
					title = "Items on different tracks to one marker",
					image = rootPath .. prefix .. "_stems.png",
				},
				{
					id = BEHAVIOUR_TYPE_OVERLAPPED,
					title = "Consider overlapping items",
					image = rootPath .. prefix .. "_overlapped.png",
				}
			}
		end,
		default = data.behaviour.default,
		gap_top = 7
	},
	{
	type = gui_input_types.Checkbox,
		key = data.ignore_when_unavailable.key,
		title = "Ignore items when no available markers",
		default = data.ignore_when_unavailable.default,
		hint = "If unchecked, it creates new tracks, when there are more items than available markers/regions"
	},
}

-- initing values --
for i, block in pairs(data) do
	data[i].value = EK_GetExtState(block.key, block.default)
end

local function SetDataValue(setting, value)
	if not setting then return end

	setting.value = value
	EK_SetExtState(setting.key, setting.value)

	GUI_ClearValuesCache()
end

local function GetStartMarkerTitle(marker)
	if string.len(marker.title) > 0 then
		return "#" .. marker.num .. " (" .. marker.title .. ")"
	else
		return "#" .. marker.num
	end
end

local function UpdateMarkersList()
	local new_marker_list = {}
	local new_count_list = { "No limit" }
	local markers = GetMarkersOrRegions(data.snap_to.value)
	local started_marker_position
	local gui_sel_marker = 0
	local gui_count_i = 1
	local start_marker = markers_list[data.start_marker.value + 1]
	local count_is_exists = false

	for i = 1, #markers do
		local title = GetStartMarkerTitle(markers[i])
		table.insert(new_marker_list, title)

		if title == start_marker then
			gui_sel_marker = i - 1
			started_marker_position = markers[i].position
		end
	end

	if not started_marker_position and markers[1] then
		started_marker_position = markers[1].position
	end

	for i = 1, #markers do
		if markers[i].position >= started_marker_position then
			if data.count_on_track.value == gui_count_i then
				count_is_exists = true
			end
			table.insert(new_count_list, gui_count_i)
			gui_count_i = gui_count_i + 1
		end
	end

	if #markers_list ~= #new_marker_list then
		SetDataValue(data.start_marker, gui_sel_marker)
	end

	if not count_is_exists then
		SetDataValue(data.count_on_track, 0)
	end

	count_list = new_count_list
	markers_list = #new_marker_list > 0 and new_marker_list or { data.snap_to.value == SNAP_TO_MARKERS and "No markers" or "No regions" }

	return window_open
end

function frame(ImGui, ctx, is_first_frame)
	if is_first_frame then
		local min_position

		for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
			local item = reaper.GetSelectedMediaItem(proj, i)
			local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

			if not min_position or position < min_position then
				min_position = position
			end
		end

		local marker = FindNearestMarker(data.snap_to.value, min_position or 0)
		if marker then
			for i = 1, #markers_list do
				if markers_list[i] == GetStartMarkerTitle(marker) then
					SetDataValue(data.start_marker, i - 1)
				end
			end
		end
	end

	ImGui.PushItemWidth(ctx, 220)

	GUI_DrawSettingsTable(gui_config, data)

	GUI_DrawGap(7)

	GUI_SetCursorCenter({'Snap items', 'Cancel'})

	GUI_DrawButton('Snap items', function()
		reaper.Undo_BeginBlock()

		local markers = GetMarkersOrRegions(data.snap_to.value)
		local marker_num = 0
		for i = 1, #markers do
			if markers_list[data.start_marker.value + 1] == GetStartMarkerTitle(markers[i]) then
				marker_num = markers[i].num
			end
		end

		SnapItems(data.snap_to.value, marker_num, data)

		GUI_CloseMainWindow()

		reaper.Undo_EndBlock(SCRIPT_NAME, -1)
	end, gui_buttons_types.Action, true)

    ImGui.SameLine(ctx)

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

EK_DeferWithCooldown(UpdateMarkersList, { last_time = 0, cooldown = 0.5 })
GUI_ShowMainWindow()

function GUI_OnWindowClose()
    window_open = false;
end