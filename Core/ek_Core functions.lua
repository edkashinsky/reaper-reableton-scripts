-- @description ek_Core functions
-- @author Ed Kashinsky
-- @about Base functions used by ek-scripts.
-- @version 1.0.51
-- @provides
--   ek_Core functions v1.lua
--   ek_Core functions GUI.lua
--   [nomain] curl/*
--
-- @changelog
--    Small fixes of curl

local function CoreLoadFunctions()
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])

    dofile(script_path .. "ek_Core functions v1.lua")
    dofile(script_path .. "ek_Core functions GUI.lua")
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

CoreLoadFunctions()