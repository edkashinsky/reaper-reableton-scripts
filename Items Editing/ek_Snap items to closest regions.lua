-- @description ek_Snap items to closest regions
-- @author Ed Kashinsky
-- @noindex
-- @readme_skip

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
	if loaded == nil then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
	end
	return
end

CoreFunctionsLoaded("ek_Snap items to markers functions.lua")

-- initing values --
for i, block in pairs(data) do
	data[i].value = EK_GetExtState(block.key, block.default)
end

reaper.Undo_BeginBlock()

local region = FindNearestMarker(SNAP_TO_REGIONS, GetMinPosition())
if region then
	SnapItems(SNAP_TO_REGIONS, region.num, data)
end

reaper.Undo_EndBlock(SCRIPT_NAME, -1)