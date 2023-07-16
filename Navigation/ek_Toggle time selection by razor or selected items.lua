-- @description ek_Toggle time selection by razor or selected items
-- @version 1.0.7
-- @author Ed Kashinsky
-- @changelog
--   Now script follows the option "Options: Move edit cursor to start of time selection, when time selection changes". If it's true, edit cursor moves to start of time selection after script execution
-- @about
--   This script toggle time selection by razor or selected items. Actually it works with loop points, so it supports behaviour when loop points and time selection is unlinked. Also it toggles transport repeat like in Ableton

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
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

reaper.Undo_BeginBlock()

local function ToggleTransportRepeat(enable)
	local state = reaper.GetToggleCommandState(1068) -- Transport: Toggle repeat

	if (enable == true and state == 0) or (enable ~= true and state == 1) then
		-- Transport: Toggle repeat
		reaper.Main_OnCommand(1068, 0)
	end
end

local proj = 0
local rStart, rEnd

for i = 0, reaper.CountTracks(proj) - 1 do
	local track = reaper.GetTrack(proj, i)
	local _, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

	if string.len(razorStr) > 0 then
		local razor = split(razorStr, " ")

		for j = 1, #razor do
			if razor[j] ~= nil and (j - 1) % 3 == 0 and (not rStart or razor[j] < rStart) then
				rStart = razor[j]
			end

			if razor[j] ~= nil and (j + 1) % 3 == 0 and (not rEnd or razor[j] > rEnd) then
				rEnd = razor[j]
			end
		end
	end
end

local sStartTS, sEndTS = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local sStart, sEnd = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)
local needToLinkTS = false
local availableForToggle = true
local lastSelection = EK_GetExtState("last_selected_ts", {}, true)

if sEndTS ~= 0 and (sStartTS ~= sStart or sEndTS ~= sEnd) then
	--- Link loop points and time selection
	reaper.GetSet_LoopTimeRange(true, true, sStartTS, sEndTS, true)
elseif rStart and rEnd then
	--- Razor edit
	reaper.GetSet_LoopTimeRange(true, true, rStart, rEnd, true)

	needToLinkTS = true
elseif (reaper.CountSelectedMediaItems(proj) > 0) then
	--- Selected items
	-- Loop points: Set loop points to items
	reaper.Main_OnCommand(41039, 0)

	needToLinkTS = true
elseif sEnd == 0 and lastSelection[2] ~= nil then
	--- Link loop points and time selection
	reaper.GetSet_LoopTimeRange(true, true, lastSelection[1], lastSelection[2], true)
elseif sEnd == 0 then
	availableForToggle = false
end

local sStartNew, sEndNew = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)
EK_SetExtState("last_selected_ts", {sStartNew, sEndNew}, true, true)

--- Disable if needs
if availableForToggle then
	ToggleTransportRepeat(true)

	if sEnd ~= 0 and (sStart == sStartNew and sEnd == sEndNew) then
		ToggleTransportRepeat(false)
		-- Loop points: Remove (unselect) loop point selection
		reaper.Main_OnCommand(40634, 0)
	elseif reaper.GetToggleCommandState(40276) == 1 then
		-- Options: Move edit cursor to start of time selection, when time selection changes
		reaper.SetEditCurPos(sStartNew, false, false)
	end
end

if needToLinkTS then
	-- Time selection: Copy loop points to time selection
	reaper.Main_OnCommand(40623, 0)
end

reaper.Undo_EndBlock("Toggle time selection by razor or selected items", -1)