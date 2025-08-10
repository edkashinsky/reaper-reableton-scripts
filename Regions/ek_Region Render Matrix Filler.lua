-- @description ek_Region Render Matrix Filler
-- @version 1.0.8
-- @author Ed Kashinsky
-- @about
--   Region Render Matrix Filler significantly speeds up the process of filling the Render Matrix in REAPER, especially in projects with a large number of regions. It’s particularly useful for tasks like layer-based sound rendering, gameplay VO synced to video, voiceover exports, and other scenarios where batch rendering is needed.
--   Features:
--      - Automatic track assignment in the Render Matrix based on settings
--      - Optional automatic channel count detection based on region name
--      - Region and track preview with navigation
--      - Manual override of track assignment for individual regions
--      - Ability to rename regions or tracks
-- @links
--   Documentation https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Render-Region-Matrix-Filler
--   Forum Thread https://forum.cockos.com/showthread.php?t=300927
--   Buy Licence https://ekscripts.gumroad.com/l/rrm-filler
-- @changelog
--  • New Length field for regions – Displays and allows editing of region length.
--	• Improved script performance – Runs faster and more efficiently.
--	• Bug fix: Overridden track not always highlighted in the table.
--	• Bug fix: Track hierarchy for override not always displayed correctly.
--	• Hierarch Offset field redesigned – Now supports drag-and-drop adjustment. No need to enter -1 for Master; simply drag to set the desired value.
--  • ImGui 0.10 Support
--	• "Close window after action" option moved – This setting is now located in the About window.
--	• Improved keyboard navigation – Use Tab / Shift+Tab or the Left/Right arrow keys to move focus between input fields. Use the Up/Down arrow keys to perform actions.
--	• Dynamic font updates in the About window – Font changes now apply instantly without reopening the window.
--	• New Help button in About – Provides quick access to documentation and the related forum thread.
--	• Better link display – Links are now easier to read and click.
--	• Improved tooltips – More readable and better positioned.
--	• Enhanced input field behavior – More consistent and user-friendly across different types of fields.
--  • Library dependency check added – The application now verifies that all required libraries are present before running.
-- @provides
--   ../Core/data/rrm-filler_*.dat
--   [main=main] ek_Region Render Matrix Filler (no prompt).lua

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

if not CoreLibraryLoad("core") or not CoreLibraryLoad("rrm-filler") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages). \nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

GUI_SetAboutLinks({
	{'Documentation', 'https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Render-Region-Matrix-Filler'},
	{'Forum thread', 'https://forum.cockos.com/showthread.php?t=300927'}
})

RRM_ShowGui()