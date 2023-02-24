-- @description ek_Pin selected items at markers started from
-- @version 1.0.7
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/pin_items_to_markers_preview.gif)
--   This script pins selected items to markers started from specified number. It requires ReaImGui extension.
-- @changelog
--   - Small fix
-- @provides
--   ../Core/ek_Pin selected items functions.lua

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

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

CoreFunctionsLoaded("ek_Pin selected items functions.lua")

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

local markers = GetMarkers()
local start_marker = nil
local count_on_track = nil
local save_relative_position = true
local count_selected_items = reaper.CountSelectedMediaItems(proj)

local gui_sel_marker = nil
local gui_sel_count = 0

function frame()
	markers = GetMarkers()

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

	reaper.ImGui_PushItemWidth(GUI_GetCtx(), 110)
	local value

	_, value = reaper.ImGui_Combo(GUI_GetCtx(), "Start marker number", gui_sel_marker, join(gui_markers_list, "\0") .. "\0")
	if value ~= gui_sel_marker then
		start_marker = gui_markers_list[value + 1]
		gui_sel_marker = value
	end

	_, value = reaper.ImGui_Combo(GUI_GetCtx(), "Count items on track", gui_sel_count, join(gui_count_list, "\0") .. "\0")
	if value ~= gui_sel_count then
		count_on_track = gui_count_list[value + 1] == "No limit" and nil or gui_count_list[value + 1]
		gui_sel_count = value
	end

	_, value = reaper.ImGui_Checkbox(GUI_GetCtx(), 'Group piled items', save_relative_position)
    if value ~= save_relative_position then
        save_relative_position = value
    end

	reaper.ImGui_Indent(GUI_GetCtx(), 35)

	GUI_DrawButton('Pin to marker', function()
		reaper.Undo_BeginBlock()

		PinItems(start_marker, save_relative_position, count_on_track)

		GUI_CloseMainWindow()

		reaper.UpdateArrange()
		reaper.Undo_EndBlock("Move selected items at markers started from", -1)
	end, gui_buttons_types.Action, true)

    reaper.ImGui_SameLine(GUI_GetCtx())

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

if #markers == 0 then
	EK_ShowTooltip("There is no markers for pinning")
else
	local item = reaper.GetSelectedMediaItem(proj, 0)

	if item then
		local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

		start_marker = FindNearestMarkerNum(position)
	end

	GUI_ShowMainWindow(270, 140)
end
