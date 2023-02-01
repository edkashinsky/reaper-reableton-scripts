-- @description ek_Create region depending on selection
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Create region based on razor, selected items or time selection

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

local function createRegionAndEdit(startTime, endTime)
	reaper.GetSet_LoopTimeRange(true, true, startTime, endTime, true)

	-- Markers: Insert region from time selection and edit...
    reaper.Main_OnCommand(40306, 0)
end

local countSelItems = reaper.CountSelectedMediaItems(proj)
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

local tStart, tEnd = reaper.GetSet_LoopTimeRange(false, true, 0, 0, true)

if rStart and rEnd then
	-- razor
	createRegionAndEdit(rStart, rEnd)
elseif countSelItems > 0 then
	-- selected items
	local iStart, iEnd

	for i = 0, countSelItems - 1 do
		local item = reaper.GetSelectedMediaItem(proj, i)
		local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

		if not iStart or iStart > position then iStart = position end
		if not iEnd or iEnd < position + length then iEnd = position + length end
	end

	createRegionAndEdit(iStart, iEnd)
elseif tStart and tEnd then
	-- time selection
	createRegionAndEdit(tStart, tEnd)
end

if tStart and tEnd then
	reaper.GetSet_LoopTimeRange(true, true, tStart, tEnd, true)
end

reaper.Undo_EndBlock("Create region based on razor, selected items or time selection", -1)