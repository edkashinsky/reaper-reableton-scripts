-- @description ek_Smart renaming depending on focus
-- @version 1.0.21
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   Renaming stuff for takes, items, markers, regions and tracks depending on focus
-- @changelog
--   Support of new UI features
-- @provides
--   ../Core/data/smart-renaming_*.dat

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("smart-renaming") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

SR_ShowGui()