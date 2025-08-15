--[[
@author Ed Kashinsky
@description ek_Pitch Tool
@version 2.0.8
@about Pitch Tool is a script for REAPER that allows you to adjust pitch quickly and flexibly. It inherits the convenient pitch workflow features from Ableton while also introducing its own unique enhancements for an even smoother experience.
@changelog
	* Fixed tooltip display for the first track
	* Tooltip now takes items on lanes into account
@links
	Documentation https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Pitch-Tool
	Forum thread https://forum.cockos.com/showthread.php?t=301698
	Buy Licence https://ekscripts.gumroad.com/l/pitch-tool
@provides
	../Core/data/pitch-tool_*.dat
	[main=main] ek_Pitch Tool - Tooltip (background).lua
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

if not CoreLibraryLoad("core") or not CoreLibraryLoad("pitch-tool") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages). \nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

GUI_SetAboutLinks({
	{'Documentation', 'https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Pitch-Tool'},
	{'Forum thread', 'https://forum.cockos.com/showthread.php?t=301698'}
})

PT_ShowGui()