-- @description ek_Edge silence cropper (no prompt)
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

if not CoreLibraryLoad("core") or not CoreLibraryLoad("edge-silence-cropper") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

reaper.Undo_BeginBlock()

local countSelectedItems = reaper.CountSelectedMediaItems(proj)

if countSelectedItems > 0 then
    local Cropper = EdgeCropper.new()

	if Cropper then
		for i = 0, countSelectedItems - 1 do
			local item = reaper.GetSelectedMediaItem(proj, i)
			Cropper.SetItem(item).Crop()
		end
	end

    reaper.UpdateArrange()
end

reaper.Undo_EndBlock("Edge silence cropper (no prompt)", -1)