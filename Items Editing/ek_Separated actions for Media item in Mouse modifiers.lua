-- @description ek_Separated actions for Media item in Mouse modifiers
-- @version 1.1.6
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   This script gives opportunity to attach 2 different actions on Media item context in Mouse modifiers - when we click on header of media item and part between header and middle of it.
--   For installation open "Mouse Modifiers" preferences, find "Media item" context and select this script in any section. Also you can copy this script and use it in different hotkey-sections and actions.
--   Script works in workflows depends on option "Draw labels above the item when media item height is more than":
--		- If option enabled, header label is positioned above the item and "header part" calculates as 1/4 of the upper part of the item
--      - If option disabled, header label is positioned on item and header part calculates as header label height
-- @changelog
--   Move action to dat-file
-- @provides
--   ../Core/data/dual-header-action_*.dat

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

if not CoreLibraryLoad("core") or not CoreLibraryLoad("dual-header-action") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages). \nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

DHA_Action()