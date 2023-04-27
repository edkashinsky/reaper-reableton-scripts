-- @description ek_Smart split items by mouse cursor
-- @version 1.0.3
-- @author Ed Kashinsky
-- @about
--   Remake of amazing script by AZ and it works a bit different way. You can split by edit cursor if mouse position on it (or in Tolerance range in pixels).
--   If you move mouse on transport panel and execute script, you will see settings window
-- @changelog
--   GUI Refactoring
-- @provides
--   ../Core/ek_Smart split items by mouse cursor functions.lua

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

CoreFunctionsLoaded("ek_Smart split items by mouse cursor functions.lua")

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

local window, _, _ = reaper.BR_GetMouseCursorContext()
if window == "transport" then
	local settings = EK_SortTableByKey(split_settings)

	function frame()
		reaper.ImGui_PushItemWidth(GUI_GetCtx(), 224)
		GUI_DrawSettingsTable(settings)
		reaper.ImGui_PopItemWidth(GUI_GetCtx())
	end

	GUI_ShowMainWindow(610, 0)
	return
end

local eCurPxInaccuracy = EK_GetExtState(split_settings.inaccuracy.key, split_settings.inaccuracy.default)
local curOffset = EK_GetExtState(split_settings.offset.key, split_settings.offset.default)

local proj = 0
local eCurPosition = reaper.GetCursorPosition()
local countSelectedItems = reaper.CountSelectedMediaItems(proj)
local x, y = reaper.GetMousePosition()
local MainHwnd = reaper.GetMainHwnd()
local ArrangeHwnd = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
local zoom = reaper.GetHZoomLevel()
local _, scrollOffsetPx = reaper.JS_Window_GetScrollInfo(ArrangeHwnd, "h")
local scrollOffsetTime = scrollOffsetPx / zoom
local arr_x, arr_y = reaper.JS_Window_ScreenToClient(ArrangeHwnd, x, y)
local eCurOffsetPx = (eCurPosition - scrollOffsetTime) * zoom
local finalCutPosition

local function processEditCursorCutting()
	local isCutDone = false

	if countSelectedItems > 0 then
		-- Has any selected items
		for i = 0, countSelectedItems - 1 do
			local item = reaper.GetSelectedMediaItem(proj, i)

			if IsPositionOnItem(item, eCurPosition) then
				reaper.SplitMediaItem(item, eCurPosition)
				local track = reaper.GetMediaItemTrack(item)

				SelectItemsOnEdge(track, eCurPosition, true)
				isCutDone = true

				finalCutPosition = eCurPosition
			end
		end
	end

	if not isCutDone then
		-- Has no selected items
		if CutAllItemsOnPosition(eCurPosition) then
			finalCutPosition = eCurPosition
		end
	end
end

reaper.Undo_BeginBlock()

if HasAnyRazorEdit() then
    for i = 0, reaper.CountTracks(proj) - 1 do
	    local track = reaper.GetTrack(proj, i)
	    local _, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

        if string.len(razorStr) > 0 then
			local razor = split(razorStr, " ")
			local rStart = tonumber(razor[1])
    		local rEnd = tonumber(razor[2])
			local curCut = rStart

			::try_to_razor_cut::

			for j = 0, reaper.CountTrackMediaItems(track) - 1 do
				local item = reaper.GetTrackMediaItem(track, j)

				if IsMediaItemInRazorEdit(item, rStart, rEnd) then
					reaper.SplitMediaItem(item, curCut)

					if curCut ~= rEnd then
						curCut = rEnd
						goto try_to_razor_cut
					end

					finalCutPosition = rStart
				end
			end

			reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", true)
			SelectItemsOnTrackInRange(track, rStart, rEnd)
        end
    end

	goto done
end

-- if mouse X coord is around edit cursor then use edit cursor
if arr_x > eCurOffsetPx - eCurPxInaccuracy and arr_x < eCurOffsetPx + eCurPxInaccuracy then
	-- USE EDIT CURSOR
	processEditCursorCutting()
else
	-- USE MOUSE POSITION
	local mousePosition = scrollOffsetTime + (arr_x / zoom)
	local isCutDone = false

	for i = 0, reaper.CountTracks(proj) - 1 do
		local track = reaper.GetTrack(proj, i)
		local trackY = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
		local trackHeight = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")

		if arr_y > trackY and arr_y < trackY + trackHeight then
			for j = 0, reaper.CountTrackMediaItems(track) - 1 do
				local item = reaper.GetTrackMediaItem(track, j)

				if IsPositionOnItem(item, mousePosition) then
					reaper.SplitMediaItem(item, mousePosition)
					SelectItemsOnEdge(track, mousePosition)
					isCutDone = true
					finalCutPosition = mousePosition
				end
			end
		end
    end

	if not isCutDone then
		processEditCursorCutting()
	end
end

::done::

if finalCutPosition and curOffset ~= 0 then
	reaper.SetEditCurPos(finalCutPosition + curOffset, true, true)
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("ek_Smart split items by mouse cursor", -1)