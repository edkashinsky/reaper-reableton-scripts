-- @description ek_Region Render Matrix Filler
-- @version 1.0.0
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
--   Buy Licence https://ekscripts.gumroad.com/l/rrm-filler
-- @provides
--   ../Core/data/rrm-filler_*.dat
--   [main=main] ek_Region Render Matrix Filler (no prompt).lua

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("rrm-filler") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

RRM_ShowGui()