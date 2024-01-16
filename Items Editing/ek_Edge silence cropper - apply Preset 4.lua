-- @description ek_Edge silence cropper - apply Preset 1
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
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

CoreFunctionsLoaded("ek_Edge silence cropper functions.lua")

reaper.Undo_BeginBlock()

ApplyQuickPreset(4)

reaper.Undo_EndBlock("Edge silence cropper - apply Preset 4", -1)