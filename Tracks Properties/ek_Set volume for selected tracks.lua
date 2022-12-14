-- @description ek_Set volume for selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Script shows window with input to set volume
-- @changelog
--   - Added core functions

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

local track = reaper.GetSelectedTrack2(proj, 0, true)
local _, current_volume, _ = reaper.GetTrackUIVolPan(track)

local result = EK_AskUser("Volume Adjustment", {
	{"Enter volume value (in db):", EK_Vol2Db(current_volume, 2) }
})

if not result or not result[1] then return end

local volume = tonumber(result[1])
if not volume then return end

for i = 0, reaper.CountSelectedTracks2(proj, true) - 1 do
	track = reaper.GetSelectedTrack2(proj, i, true)
	reaper.SetMediaTrackInfo_Value(track, "D_VOL", EK_Db2Vol(volume));
end

reaper.Undo_BeginBlock()

reaper.Undo_EndBlock("Toggle automation mode for all tracks", -1)