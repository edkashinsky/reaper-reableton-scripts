-- @description ek_Pin selected items at markers started from
-- @version 1.0.10
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/pin_items_to_markers_preview.gif)
--   This script pins selected items to markers started from specified number. It requires ReaImGui extension.
-- @changelog
--   Added opportunity to pin items to regions
-- @provides
--   ../Core/ek_Pin selected items functions.lua
--   [main=main] ek_Pin selected items to closest markers.lua
--   [main=main] ek_Pin selected items to closest regions.lua

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

CoreFunctionsLoaded("ek_Pin selected items functions.lua")

local start_marker = nil
local count_on_track = nil
local save_relative_position = true

local gui_sel_marker = nil
local gui_sel_count = 0
local gui_pin_to = 0
local pin_types = { "Markers", "Regions" }
local markers

function frame(ImGui, ctx)
	markers = GetMarkersOrRegions(gui_pin_to == 1)

	local gui_markers_list = {}
	local gui_count_list = { "No limit" }
	local gui_sel_maker_position = 0
	local gui_count_i = 1

	for i = 1, #markers do
		table.insert(gui_markers_list, markers[i].num)
		if markers[i].num == start_marker then
			gui_sel_marker = i - 1
			gui_sel_maker_position = markers[i].position
		end
	end

	for i = 1, #markers do
		if markers[i].position > gui_sel_maker_position then
			table.insert(gui_count_list, gui_count_i)
			gui_count_i = gui_count_i + 1
		end
	end

	ImGui.PushItemWidth(ctx, 110)
	local value

	_, value = ImGui.Combo(ctx, "Pin to", gui_pin_to, join(pin_types, "\0") .. "\0")
	if value ~= gui_pin_to then
		gui_pin_to = value
	end

	_, value = ImGui.Combo(ctx, gui_pin_to == 1 and "Start region number" or "Start marker number", gui_sel_marker, join(gui_markers_list, "\0") .. "\0")
	if value ~= gui_sel_marker then
		start_marker = gui_markers_list[value + 1]
		gui_sel_marker = value
	end

	_, value = ImGui.Combo(ctx, "Count items on track", gui_sel_count, join(gui_count_list, "\0") .. "\0")
	if value ~= gui_sel_count then
		count_on_track = gui_count_list[value + 1] == "No limit" and nil or gui_count_list[value + 1]
		gui_sel_count = value
	end

	_, value = ImGui.Checkbox(ctx, 'Group piled items', save_relative_position)
    if value ~= save_relative_position then
        save_relative_position = value
    end

	GUI_DrawGap(7)

	ImGui.Indent(ctx, 45)

	GUI_DrawButton('Pin items', function()
		reaper.Undo_BeginBlock()

		PinItems(gui_pin_to == 1, start_marker, save_relative_position, count_on_track)

		GUI_CloseMainWindow()

		reaper.UpdateArrange()
		reaper.Undo_EndBlock("Move selected items at markers started from", -1)
	end, gui_buttons_types.Action, true)

    ImGui.SameLine(ctx)

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

local item = reaper.GetSelectedMediaItem(proj, 0)

if item then
	local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

	start_marker = FindNearestMarkerNum(gui_pin_to == 1, position)
end

GUI_ShowMainWindow(260, 0)
