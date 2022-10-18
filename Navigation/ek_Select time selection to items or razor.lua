-- @description ek_Set time selection to razor edit or items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @wip
-- @about
--   If any item is selected, this script moves it to left by grid size. And moves cursor by grid in other case

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

if rStart and rEnd then
	reaper.GetSet_LoopTimeRange(true, true, rStart, rEnd, true)
else
	-- Time selection: Set time selection to items
    reaper.Main_OnCommand(40290, 0)
end

reaper.Undo_EndBlock("Set time selection to razor edit or items", -1)