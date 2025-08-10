-- @description ek_Edge silence cropper
-- @version 1.3.0
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.
--
--   Also it provides UI for configuration
-- @changelog
--  • Gumroad integration – The script is now connected to Gumroad. To use it, you must obtain a free license from the website.
-- 	• Improved stability and performance – The script runs more reliably and efficiently.
--  • GUI: ImGui 0.10 Support
-- 	• GUI: Added "Close window after action" option to the About window.
--	• GUI: Improved keyboard navigation – Use Tab / Shift+Tab or the Left/Right arrow keys to move focus between input fields. Use the Up/Down arrow keys to perform actions.
--	• GUI: Dynamic font updates in the About window – Font changes now apply instantly without reopening the window.
--	• GUI: New Help button in About – Provides quick access to documentation and the related forum thread.
--	• GUI: Better link display – Links are now easier to read and click.
--	• GUI: Improved tooltips – More readable and better positioned.
--	• GUI: Enhanced input field behavior – More consistent and user-friendly across different types of fields.
--  • GUI: Library dependency check added – The application now verifies that all required libraries are present before running.
-- @provides
--   ../Core/data/edge-silence-cropper_*.dat
--   [main=main] ek_Edge silence cropper (no prompt).lua
--   [main=main] ek_Edge silence cropper - apply Preset 1.lua
--   [main=main] ek_Edge silence cropper - apply Preset 2.lua
--   [main=main] ek_Edge silence cropper - apply Preset 3.lua
--   [main=main] ek_Edge silence cropper - apply Preset 4.lua
--   [main=main] ek_Edge silence cropper - apply Preset 5.lua

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

if not CoreLibraryLoad("core") or not CoreLibraryLoad("edge-silence-cropper") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages). \nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

GUI_SetAboutLinks({
	{'Documentation', 'https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Edge-Silence-Cropper'},
	{'Forum thread', 'https://forum.cockos.com/showthread.php?t=271671'}
})

ESC_ShowGui()