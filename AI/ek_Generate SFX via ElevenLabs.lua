-- @description ek_Generate SFX via ElevenLabs
-- @version 1.1.8
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   Script uses ElevenLabs API to generate sound effects and inserts them into the project.
-- @changelog
--   UI updates
--   dat-file support
--   new UI support
-- @provides
--   ../Core/data/ai-11-labs-sfx_*.dat

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("ai-11-labs-sfx") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

AI_ShowGui()