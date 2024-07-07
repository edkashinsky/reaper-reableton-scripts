-- @description ek_Pin selected items to closest markers
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script pins selected items to closest markers for first selected item. It requires script "ek_Pin selected items at markers started from.lua"
-- @changelog
--   ReaImGui no longer need

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

CoreFunctionsLoaded("ek_Pin selected items functions.lua")

local min_position

for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

	if min_position == nil or position < min_position then
		min_position = position
	end
end

PinItems(FindNearestMarkerNum(min_position), true)