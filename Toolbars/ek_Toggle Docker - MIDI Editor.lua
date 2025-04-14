-- @description ek_Toggle Docker - MIDI Editor
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

local actionId = 40716

local function isEditorAvailable()
	local editor = reaper.MIDIEditor_GetActive()
	local state = reaper.MIDIEditor_GetMode(editor)

	if state ~= -1 then return true end

	reaper.Main_OnCommand(actionId, 0)

	editor = reaper.MIDIEditor_GetActive()
	state = reaper.MIDIEditor_GetMode(editor)

	reaper.Main_OnCommand(actionId, 0)

	return state ~= -1
end

if not isEditorAvailable() then return end

TD_ToggleWindow("Edit MIDI", actionId)

local _, _, sectionID, cmdID = reaper.get_action_context()
local editor = reaper.MIDIEditor_GetActive()
local state = reaper.MIDIEditor_GetMode(editor)
local newState = state ~= -1 and 1 or 0

reaper.SetToggleCommandState(sectionID, cmdID, newState)
reaper.RefreshToolbar2(sectionID, cmdID)