-- @author Ed Kashinsky
-- @description ek_Pitch Tool
-- @version 2.0.0
-- @about
--    Pitch tool brings Ableton workflow for pitch manipulations of audio clips.
--		- Ableton-style pitch shifting for intuitive and musical pitch control
--		- Detailed pitch-stretching adjustments with a user-friendly interface
--		- Multi-mode control for adjusting the pitch of an unlimited number of items
--		- Flexible window docking, plus the option to display the tool contextually above selected items
--		- Theme-adaptive interface that matches your REAPER theme for seamless visual integration
-- @links
--   Documentation https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Pitch-Tool
--   Buy Licence https://ekscripts.gumroad.com/l/pitch-tool
-- @provides
--   ../Core/data/pitch-tool_*.dat
--   [main=main] ek_Pitch Tool - Tooltip (background).lua

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("pitch-tool") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

PT_ShowGui()