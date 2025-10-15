--[[
@description ek_Snap items to markers or regions
@version 1.2.3
@author Ed Kashinsky
@about
   This script snaps selected items to markers or regions started from specified number. It requires ReaImGui extension.
   It has 3 behaviours: simple, stems, consider overlapped items. You can see how it works shematically on pictograms in GUI
   You can set custom offset depends on your need: just begin of item, snap offset, first cue marker, peak of item
   Script gives posibility to limit markers/regions snapping. For example only 2 markers after specified.
@readme_skip
@changelog
   * Added detailed message on error crash
   * Fixed curl crash for Reaper 5 + Win 10
@provides
   ../Core/data/smart-snap_*.dat
   ../Core/images/smart-snap/*
   [main=main] ek_Snap items to closest markers.lua
   [main=main] ek_Snap items to closest regions.lua
]]--

local CONTEXT = ({reaper.get_action_context()})
local SCRIPT_NAME = CONTEXT[2]:match("([^/\\]+)%.lua$"):gsub("ek_", "")
local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not reaper.APIExists("SNM_SetIntConfigVar") then
    reaper.MB('Please install SWS extension via https://sws-extension.org', SCRIPT_NAME, 0)
	return
end

if not reaper.APIExists("JS_Mouse_GetState") then
    reaper.MB('Please install "js_ReaScriptAPI: API functions for ReaScripts" via ReaPack', SCRIPT_NAME, 0)
    reaper.ReaPack_BrowsePackages("js_ReaScriptAPI: API functions for ReaScripts")
	return
end

if not reaper.APIExists("ImGui_GetVersion") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', SCRIPT_NAME, 0)
    reaper.ReaPack_BrowsePackages("ReaImGui: ReaScript binding for Dear ImGui")
	return
end

xpcall(function()
	if not CoreLibraryLoad("core") or not CoreLibraryLoad("smart-snap") then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages). \nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
		return
	end

	SI_ShowGui()
end, function(err)
	local _, _, imGuiVersion = reaper.ImGui_GetVersion()

	reaper.ShowConsoleMsg("\nERROR: " .. err .. "\n\n")
	reaper.ShowConsoleMsg("Stack traceback:\n")
	reaper.ShowConsoleMsg("\t" .. debug.traceback() .. "\n\n")
	reaper.ShowConsoleMsg("Reaper: " .. reaper.GetAppVersion() .. "\n")
	reaper.ShowConsoleMsg("Platform: " .. reaper.GetOS() .. "\n")
	reaper.ShowConsoleMsg("Lua: " .. _VERSION .. "\n")
	reaper.ShowConsoleMsg("ReaImGui: " .. imGuiVersion .. "\n")

	if EK_GetScriptVersion ~= nil then
		reaper.ShowConsoleMsg("Version: " .. tostring(EK_GetScriptVersion()) .. "\n")
		reaper.ShowConsoleMsg("Core: " .. tostring(EK_GetScriptVersion(pathJoin(CORE_PATH, "ek_Core functions.lua"))) .. "\n")
	end
end)