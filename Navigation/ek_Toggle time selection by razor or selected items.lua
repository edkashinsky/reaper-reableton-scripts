-- @description ek_Toggle time selection by razor or selected items
-- @version 1.0.2
-- @author Ed Kashinsky
-- @changelog
--   Added toggle behaviour like in Ableton (thanks @tvm79 for feature request)
-- @about
--   This script toggle time selection by razor or selected items. Also it toggles transport repeat like in Ableton

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

		if not rStart or razor[1] < rStart then
			rStart = razor[1]
		end

		if not rEnd or razor[2] > rEnd then
			rEnd = razor[2]
		end
	end
end

local sStart, sEnd = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)

ToggleTransportRepeat(true)

if rStart and rEnd then
	reaper.GetSet_LoopTimeRange(true, true, rStart, rEnd, true)
elseif (reaper.CountSelectedMediaItems(proj) > 0) then
	-- Time selection: Set time selection to items
	reaper.Main_OnCommand(40290, 0)
else
	-- take current position
	local cursorPosition = reaper.GetCursorPosition()
	local endPosition = cursorPosition + 10

	reaper.GetSet_LoopTimeRange(true, true, cursorPosition, endPosition, true)
end

local sStartNew, sEndNew = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)

-- toggle if needs
if sEnd ~= 0 and (sStart == sStartNew or sEnd == sEndNew) then
	ToggleTransportRepeat(false)
	-- Time selection: Remove (unselect) time selection
    reaper.Main_OnCommand(40635, 0)
end

reaper.Undo_EndBlock("Toggle time selection by razor or selected items", -1)