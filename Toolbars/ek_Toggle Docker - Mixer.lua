-- @description ek_Toggle Docker: Mixer
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It remember Render Matrix button for toggling docker window
--
--   For work please install ek_Toggle last under docker window
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
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not reaper.APIExists("JS_ReaScriptAPI_Version") then
	reaper.MB("Please, install JS_ReaScriptAPI for this script to function. Thanks!", "JS_ReaScriptAPI is not installed", 0)
	return
end

TD_ToggleWindow("Mixer", 40078)