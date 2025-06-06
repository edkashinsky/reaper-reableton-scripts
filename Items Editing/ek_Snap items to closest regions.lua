-- @description ek_Snap items to closest regions
-- @author Ed Kashinsky
-- @noindex
-- @readme_skip

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("snap-items") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

-- initing values --
for i, block in pairs(data) do
	data[i].value = EK_GetExtState(block.key, block.default)
end

reaper.Undo_BeginBlock()

local region = FindNearestMarker(SNAP_TO_REGIONS, GetMinPosition())
if region then
	SnapItems(SNAP_TO_REGIONS, region.num, data)
end

reaper.Undo_EndBlock(SCRIPT_NAME, -1)