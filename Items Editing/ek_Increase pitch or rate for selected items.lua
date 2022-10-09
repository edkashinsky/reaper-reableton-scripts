-- @description ek_Increase pitch or rate for selected items
-- @version 1.0.2
-- @author Ed Kashinsky
-- @about
--   This script increases pitch or rate of selected items depending on "Preserve Pitch" option.
--
--   If option is on, script increases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)
--
--   This script normally adds 1 semitone, but if you hold ctrl/cmd it adds 0.1 semitone
-- @changelog
--   - Added core functions

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

reaper.Undo_BeginBlock()

local proj = 0
local delta = 1

-- ctrl/cmd is pressed (smoother changes)
if reaper.JS_Mouse_GetState(4) > 0 then
	delta = 0.1
end

for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

	local itemTake = reaper.GetMediaItemTake(item, takeInd)
	local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "B_PPITCH")

	changePitchForTake(itemTake, delta, mode == 1, true)
end

reaper.Undo_EndBlock("Increase pitch or rate", -1)