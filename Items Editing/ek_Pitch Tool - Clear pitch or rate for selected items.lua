-- @description ek_Clear pitch or rate for selected items
-- @author Ed Kashinsky
-- @about
--    This script resets any pitch, rate and length info for selected items and makes as default
-- @noindex
-- @readme_skip

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

for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

	local itemTake = reaper.GetMediaItemTake(item, takeInd)

	clearPitchForTake(itemTake)
end

reaper.Undo_EndBlock("Clear pitch or rate", -1)