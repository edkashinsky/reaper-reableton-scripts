--[[
@description ek_Core functions
@author Ed Kashinsky
@about Base functions used by ek-scripts.
@version 1.2.2
@changelog
    * ImGui 0.10 Support
    * History for text fields – A new history button appears on the right side of certain text fields. Click it to view previously entered queries. You can also navigate through the history using the Up/Down arrow keys while the text field is focused.
    * "Close window after action" option moved – This setting is now located in the About window.
    * Improved keyboard navigation – Use Tab / Shift+Tab or the Left/Right arrow keys to move focus between input fields. Use the Up/Down arrow keys to perform actions.
    * Consistent text field navigation – All text fields now follow the same navigation rules.
    * Dynamic font updates in the About window – Font changes now apply instantly without reopening the window.
    * New Help button in About – Provides quick access to documentation and the related forum thread.
    * Better link display – Links are now easier to read and click.
    * Improved tooltips – More readable and better positioned.
    * Enhanced input field behavior – More consistent and user*friendly across different types of fields.
    * Library dependency check added – The application now verifies that all required libraries are present before running.
 @provides
    data/core_*.dat
    [nomain] curl/*
    images/logo-black.png
    images/logo-white.png
]]--

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

if not reaper.APIExists("ImGui_GetVersion") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
    reaper.ReaPack_BrowsePackages("ReaImGui: ReaScript binding for Dear ImGui")
	return
end

if not CoreLoadFunctions() then
    reaper.MB("Your version of Lua does not support.\n Your version is: " .. _VERSION, '', 0)
end