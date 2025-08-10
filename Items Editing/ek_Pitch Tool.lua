-- @author Ed Kashinsky
-- @description ek_Pitch Tool
-- @version 2.0.4
-- @about
--    Pitch tool brings Ableton workflow for pitch manipulations of audio clips.
--		- Ableton-style pitch shifting for intuitive and musical pitch control
--		- Detailed pitch-stretching adjustments with a user-friendly interface
--		- Multi-mode control for adjusting the pitch of an unlimited number of items
--		- Flexible window docking, plus the option to display the tool contextually above selected items
--		- Theme-adaptive interface that matches your REAPER theme for seamless visual integration
-- @changelog
--  • Added support for élastique v2 modes on Windows
--	• Improved Tooltip version – Now more compact and significantly faster.
--	• New setting: Pitch Range – Allows adjusting the pitch range.
--	• New Tooltip settings – Includes Min item width for showing, Opacity when inactive, and Keep tooltip focused after action.
--	• New unfocused mode for Tooltip – When enabled, the script returns focus to the REAPER window after an action, instead of keeping it.
--	• GUI: Improved knob display – Knobs now look cleaner and more consistent.
--  • GUI: ImGui 0.10 Support
--	• GUI: "Close window after action" option moved – This setting is now located in the About window.
--	• GUI: Improved keyboard navigation – Use Tab / Shift+Tab or the Left/Right arrow keys to move focus between input fields. Use the Up/Down arrow keys to perform actions.
--	• GUI: Dynamic font updates in the About window – Font changes now apply instantly without reopening the window.
--	• GUI: New Help button in About – Provides quick access to documentation and the related forum thread.
--	• GUI: Better link display – Links are now easier to read and click.
--	• GUI: Improved tooltips – More readable and better positioned.
--	• GUI: Enhanced input field behavior – More consistent and user-friendly across different types of fields.
--  • GUI: Library dependency check added – The application now verifies that all required libraries are present before running.
-- @links
--   Documentation https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Pitch-Tool
--   Buy Licence https://ekscripts.gumroad.com/l/pitch-tool
-- @provides
--   ../Core/data/pitch-tool_*.dat
--   [main=main] ek_Pitch Tool - Tooltip (background).lua

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