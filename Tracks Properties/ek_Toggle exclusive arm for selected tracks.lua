-- @description Toggle exclusive arm for selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It just toggles exclusive arm for selected tracks

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
	if loaded == nil then  reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

local function isAllSelTrackArmed()
	for i = 0, reaper.CountSelectedTracks(proj) - 1 do
		local track = reaper.GetSelectedTrack(proj, i)

		if reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then return false end
	end

	return true
end

local notArmedTracks = {}
local allSelTrackArmed = isAllSelTrackArmed()

for i = 0, reaper.CountSelectedTracks(proj) - 1 do
	local track = reaper.GetSelectedTrack(proj, i)

	if not allSelTrackArmed or reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then
		local _, id = reaper.GetSetMediaTrackInfo_String(track, "GUID", "", false)
		table.insert(notArmedTracks, id)
	end
end

reaper.Main_OnCommand(reaper.NamedCommandLookup(40491), 0) -- Track: Unarm all tracks for recording

for _, value in pairs(notArmedTracks) do
	local track = EK_GetMediaTrackByGUID(value)

	if track then reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1) end
end