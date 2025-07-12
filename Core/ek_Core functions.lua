-- @description ek_Core functions
-- @author Ed Kashinsky
-- @about Base functions used by ek-scripts.
-- @version 1.1.13
-- @changelog
--  • Fixed a bug where pressing Enter while an element was focused would close the window
--	• Fixed a bug where closing a window didn’t update the toolbar state
--	• Merged Drag and Slider into a new custom drag element with value display, like in Ableton. It also supports vertical drag to change the value
--	• Fixed a bug where window height was sometimes calculated incorrectly
--	• Added a secret message in the About window for licensed users
--	• Fixed a bug where double-clicking a knob didn’t reset the value to 0
--	• Re-enabled vertical drag to change knob values
--	• Improved keyboard navigation
-- @provides
--   data/core_*.dat
--   [nomain] curl/*
--   images/logo-black.png
--   images/logo-white.png


local function CoreLoadFunctions()
    local sep = package.config:sub(1,1)
    local version = string.match(_VERSION, "%d+%.?%d*")
    local info = debug.getinfo(1,'S')
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) .. "data" .. sep .. "core_" .. version .. ".dat"
    local file = io.open(script_path, 'r')

    if file then file:close() dofile(script_path) return true else return false end
end

if not reaper.APIExists("SNM_SetIntConfigVar") then
    reaper.MB('Please install SWS extension via https://sws-extension.org', '', 0)
	return
end

if not reaper.APIExists("JS_Mouse_GetState") then
    reaper.MB('Please install "js_ReaScriptAPI: API functions for ReaScripts" via ReaPack', '', 0)
    reaper.ReaPack_BrowsePackages("js_ReaScriptAPI: API functions for ReaScripts")
	return
end

if not CoreLoadFunctions() then
    reaper.MB("Your version of Lua does not support.\n Your version is: " .. _VERSION, '', 0)
end