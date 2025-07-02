-- @description ek_Edge silence cropper
-- @version 1.2.12
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.
--
--   Also it provides UI for configuration
-- @changelog
--   Support of new UI features
-- @provides
--   ../Core/data/edge-silence-cropper_*.dat
--   [main=main] ek_Edge silence cropper (no prompt).lua
--   [main=main] ek_Edge silence cropper - apply Preset 1.lua
--   [main=main] ek_Edge silence cropper - apply Preset 2.lua
--   [main=main] ek_Edge silence cropper - apply Preset 3.lua
--   [main=main] ek_Edge silence cropper - apply Preset 4.lua
--   [main=main] ek_Edge silence cropper - apply Preset 5.lua

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("edge-silence-cropper") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

ESC_ShowGui()