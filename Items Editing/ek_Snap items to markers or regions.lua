-- @description ek_Snap items to markers or regions
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/pin_items_to_markers_preview.gif)
--   This script snaps selected items to markers or regions started from specified number. It requires ReaImGui extension.
-- @changelog
--   Added opportunity to snap items to regions
--   UI update
-- @provides
--   ../Core/ek_Snap items to markers functions.lua
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
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

CoreFunctionsLoaded("ek_Snap items to markers functions.lua")

local start_marker
local count_on_track
local save_relative_position = true
local window_open = true

local gui_sel_marker
local gui_sel_count = 0
local gui_snap_to = 0
local gui_snap_types = { "Markers", "Regions" }
local gui_markers_list = {}
local gui_count_list = {}
local gui_count_i = 0

local function UpdateMarkersLis()
	local markers = GetMarkersOrRegions(gui_snap_to == 1)
	local sel_marker_position = 0
	local marker_is_found = false

	gui_markers_list = {}
	gui_count_list = { "No limit" }
	gui_count_i = 1

	for i = 1, #markers do
		table.insert(gui_markers_list, markers[i].num)
		if markers[i].num == start_marker then
			gui_sel_marker = i - 1
			sel_marker_position = markers[i].position
			marker_is_found = true
		end
	end

	if isEmpty(gui_markers_list) then
		gui_markers_list = { gui_snap_to == 1 and "No regions" or "No markers" }
		gui_sel_marker = 0
	elseif not marker_is_found then
		start_marker = markers[1].num
		gui_sel_marker = 0
		sel_marker_position = markers[1].position
	end

	for i = 1, #markers do
		if markers[i].position > sel_marker_position then
			table.insert(gui_count_list, gui_count_i)
			gui_count_i = gui_count_i + 1
		end
	end

	return window_open
end

function frame(ImGui, ctx)
	ImGui.PushItemWidth(ctx, 140)
	local value

	value = GUI_DrawInput(gui_input_types.Combo, "Snap to", gui_snap_to, { select_values = gui_snap_types })
	if value ~= gui_snap_to then
		gui_snap_to = value
	end

	value = GUI_DrawInput(gui_input_types.Combo, gui_snap_to == 1 and "Start region number" or "Start marker number", gui_sel_marker, { select_values = gui_markers_list })
	if value ~= gui_sel_marker then
		start_marker = gui_markers_list[value + 1]
		gui_sel_marker = value
	end

	value = GUI_DrawInput(gui_input_types.Combo, "Count items on track", gui_sel_count, { select_values = gui_count_list })
	if value ~= gui_sel_count then
		if gui_count_list[value + 1] == "No limit" then count_on_track = nil
		else count_on_track = gui_count_list[value + 1]
		end

		gui_sel_count = value
	end

	value = GUI_DrawInput(gui_input_types.Checkbox, "Group items on different tracks", save_relative_position)
    if value ~= save_relative_position then
        save_relative_position = value
    end

	GUI_DrawGap(7)

	ImGui.Indent(ctx, 60)

	GUI_DrawButton('Snap items', function()
		reaper.Undo_BeginBlock()

		SnapItems(gui_snap_to == 1, start_marker, save_relative_position, count_on_track)

		GUI_CloseMainWindow()

		reaper.Undo_EndBlock(SCRIPT_NAME, -1)
	end, gui_buttons_types.Action, true)

    ImGui.SameLine(ctx)

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

local item = reaper.GetSelectedMediaItem(proj, 0)

if item then
	local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

	start_marker = FindNearestMarkerNum(gui_snap_to == 1, position)
end

EK_DeferWithCooldown(UpdateMarkersLis, { last_time = 0, cooldown = 0.5 })
GUI_ShowMainWindow()

function GUI_OnWindowClose()
    window_open = false;
end