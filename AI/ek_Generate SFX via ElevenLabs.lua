--[[
@description ek_Generate SFX via ElevenLabs
@version 1.2.3
@author Ed Kashinsky
@readme_skip
@about
   This script allows you to generate sounds via Eleven Labs directly from Reaper. Simply enter a prompt describing the sound you want to create - whether it’s the crackle of fire or an alarm signal on an orbital station. The script will generate the sound and insert it directly onto the timeline.
@changelog
   * Added Loop field
   * Improved performance
   * Improved settings popup
@links
	Documentation https://github.com/edkashinsky/reaper-reableton-scripts/wiki/ElevenLabs-SFX-Generator
	Forum thread https://forum.cockos.com/showthread.php?t=292807
	Buy Licence https://ekscripts.gumroad.com/l/ai-11-labs-sfx
@provides
	../Core/data/ai-11-labs-sfx_*.dat
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

if not CoreLibraryLoad("core") or not CoreLibraryLoad("ai-11-labs-sfx") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages).\nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

GUI_SetAboutLinks({
	{'Documentation', 'https://github.com/edkashinsky/reaper-reableton-scripts/wiki/ElevenLabs-SFX-Generator'},
	{'Forum thread', 'https://forum.cockos.com/showthread.php?t=292807'}
})

AI_ShowGui()