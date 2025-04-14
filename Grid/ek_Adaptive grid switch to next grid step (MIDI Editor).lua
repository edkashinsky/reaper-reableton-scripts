-- @author Ed Kashinsky
-- @noindex
-- @about ek_Adaptive grid switch to next grid step (MIDI Editor)
-- @readme_skip

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

if not CoreLibraryLoad("corebg") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Global startup action")
	return
end

local MidiEditor = reaper.MIDIEditor_GetActive()
if not MidiEditor then return end

AG_QuickToggleGrid(true, true)

if AG_IsSyncedWithMidiEditor() then
	local _, id = AG_GetCurrentGrid(true)
	AG_SetCurrentGrid(false, id)
end