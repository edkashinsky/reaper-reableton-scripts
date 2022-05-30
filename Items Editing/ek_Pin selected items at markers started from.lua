-- @description ek_Pin selected items at markers started from
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/pin_items_to_markers_preview.gif)
--   This script pins selected items to markers started from specified number. It requires [Lokasenna_GUI](https://github.com/jalovatt/Lokasenna_GUI)
-- @changelog
--   - GUI updated to ReaImGui

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) return true else return false end
end

if not CoreFunctionsLoaded() then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

local closest_marker = 0
local start_marker = 0
local combo_selected_id = nil
local count_selected_items = reaper.CountSelectedMediaItems(proj)

local function getOnlyMarkers()
	local markers = {}
	local retval, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	
	-- collect only markers
	for i = 0, num_markers + num_regions - 1 do
		local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
		
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
	local retval, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	local prevMarkerNum
	local prevMarkerPos
	
	for i = 0, num_markers + num_regions - 1 do
		local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
		
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


local function setPositionForItem(i, start, markers)
	local item = reaper.GetSelectedMediaItem(proj, i)
	local cur = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		
	-- reaper.ShowConsoleMsg((start + i) .. " " .. cur .. " => " .. markers[start + i].position .. "\n")
	reaper.SetMediaItemInfo_Value(item, "D_POSITION", markers[start + i].position)
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
	local item = reaper.GetSelectedMediaItem(proj, 0)
	local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	if markers[startIndex].position <= position then
		for i = 0, count - 1 do
			setPositionForItem(i, startIndex, markers)
		end
	else
		for i = count - 1, 0, -1 do
			setPositionForItem(i, startIndex, markers)
		end
	end

	GUI_CloseMainWindow()
	reaper.UpdateArrange()
	reaper.Undo_EndBlock("Move selected items at markers started from", -1)
end

function frame()
	local markers = getOnlyMarkers()
	local combo_list = ''

	for i = 1, #markers do
		combo_list = combo_list .. markers[i].num .. '\31'

		if combo_selected_id == nil and markers[i].num == closest_marker then
			start_marker = markers[i].num
			combo_selected_id = i - 1
		end
	end

	reaper.ImGui_PushItemWidth(GUI_GetCtx(), 110)

	local r, value = reaper.ImGui_Combo(GUI_GetCtx(), "Start marker number", combo_selected_id, combo_list)

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
