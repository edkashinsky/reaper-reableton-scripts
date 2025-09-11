--[[
@description ek_Core functions
@author Ed Kashinsky
@about Base functions used by ek-scripts.
@version 1.2.7
@changelog
    * Improved cURL support
    * Added JSON support
    * Improved search for cyrrilic characters
    * Added new UI elements: multiline text input, tags, new buttons and other
    * Added images sets support
    * Improved navigation by Tab/Shift+Tab
    * When work with drag elements, mouse is hiding
    * Improved work with modal popups
    * Improved UI for links
 @provides
    data/core_*.dat
    [nomain] curl/*
    images/core/*
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