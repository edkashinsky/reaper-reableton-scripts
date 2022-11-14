-- @description ek_Pin selected items at markers started from
-- @version 1.0.4
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/pin_items_to_markers_preview.gif)
--   This script pins selected items to markers started from specified number. It requires ReaImGui extension.
-- @changelog
--   - Small fixes

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded()
if not loaded then
	if loaded == nil then  reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

local closest_marker = 0
local start_marker = 0
local combo_selected_id = nil
local count_selected_items = reaper.CountSelectedMediaItems(proj)

local function getOnlyMarkers()
	local markers = {}
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	
	-- collect only markers
	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, _, _, markrgnindexnumber = reaper.EnumProjectMarkers(i)
		
		if isrgn == false then
			table.insert(markers, {
				num = markrgnindexnumber,
				position = pos
			})
		end
	end
	
	return markers
end

local function findIndexByMarkerNumber(markers, number)
	if number == nil then
		return nil
	end
	
	for i = 1, #markers do
		if markers[i].num == number then
			return i
		end
	end
	
	return nil
end

local function findNearestMarkerNum(position)
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	local prevMarkerNum = 0
	local prevMarkerPos = 0
	
	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, _, _, markrgnindexnumber = reaper.EnumProjectMarkers(i)
		
		if isrgn == false then
			if pos > position then
				local prevDist = position - prevMarkerPos
				local curDist = pos - position
				return curDist < prevDist and markrgnindexnumber or prevMarkerNum
			end
			
			if i == num_markers + num_regions - 1 then
				return markrgnindexnumber
			end
		
			prevMarkerNum = markrgnindexnumber
			prevMarkerPos = pos
		end
	end
end

local function pin_items()
	reaper.Undo_BeginBlock()

	local count = reaper.CountSelectedMediaItems(proj)
	local markers = getOnlyMarkers()
	local startIndex = findIndexByMarkerNumber(markers, start_marker)

	if startIndex == nil then
		EK_ShowTooltip("Please enter correct number of marker.")
		return
	end

	if count > #markers - startIndex + 1 then
		EK_ShowTooltip("You have no available markers for pinning.")
		return
	end

	-- count direction
	local itemIds = {}
	for i = 0, reaper.CountTracks(proj) - 1 do
		local curIndex = startIndex
		local track = reaper.GetTrack(proj, i)

		for j = 0, reaper.CountTrackMediaItems(track) - 1 do
			local item = reaper.GetTrackMediaItem(track, j)

			if reaper.IsMediaItemSelected(item) then
				local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
				itemIds[guid] = markers[curIndex].position
				curIndex = curIndex + 1
			end
		end
	end

	for i = 0, reaper.CountTracks(proj) - 1 do
		local track = reaper.GetTrack(proj, i)

		for j = 0, reaper.CountTrackMediaItems(track) - 1 do
			local item = reaper.GetTrackMediaItem(track, j)
			local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)

			if itemIds[guid] then
				reaper.SetMediaItemInfo_Value(item, "D_POSITION", itemIds[guid])
			end
		end
	end

	GUI_CloseMainWindow()
	reaper.UpdateArrange()
	reaper.Undo_EndBlock("Move selected items at markers started from", -1)
end

function frame()
	local markers = getOnlyMarkers()
	local combo_list = {}

	for i = 1, #markers do
		table.insert(combo_list, markers[i].num)

		if combo_selected_id == nil and markers[i].num == closest_marker then
			start_marker = markers[i].num
			combo_selected_id = i - 1
		end
	end

	reaper.ImGui_PushItemWidth(GUI_GetCtx(), 110)

	local _, value = reaper.ImGui_Combo(GUI_GetCtx(), "Start marker number", combo_selected_id, join(combo_list, "\0") .. "\0")

	if value ~= combo_selected_id then
		start_marker = markers[value + 1].num
		combo_selected_id = value
	end

	GUI_DrawGap()

	reaper.ImGui_Indent(GUI_GetCtx(), 35)

	GUI_DrawButton('Pin to marker', function()
		pin_items()
	end, gui_buttons_types.Action, true)

    reaper.ImGui_SameLine(GUI_GetCtx())

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

if count_selected_items == 0 then
	EK_ShowTooltip("Select any item.")
elseif #getOnlyMarkers() == 0 then
	EK_ShowTooltip("There is no markers for pinning")
else
	local item = reaper.GetSelectedMediaItem(proj, 0)
	local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

	closest_marker = findNearestMarkerNum(position)

	GUI_ShowMainWindow(270, 120)
end
