-- @description ek_Auto grid for MIDI Editor
-- @version 1.0.4
-- @author Ed Kashinsky
-- @about
--   It changes grid depending on zoom level in MIDI Editor.
--   For installation:
--     1. Create custom action
--     2. Add to it:
--       - View: Zoom horizontally (MIDI relative/mousewheel)
--       - This script (ek_Auto grid for MIDI Editor)
--     3. Add to this custom script MultiZoom shortcut hotkey
--     4. Have fun!
-- @changelog
--    Improved stability
-- @provides [main=midi_editor] .

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded("ek_Core functions.lua")
if not loaded then
	if loaded == nil then  reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not CoreFunctionsLoaded("ek_Core functions startup.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

local MidiEditor = reaper.MIDIEditor_GetActive()
if not MidiEditor then return end

local zoom_level = GA_GetHZoomLevelForMidiEditor()
if not zoom_level then return end

local id = EK_GetExtState(ga_settings.midi_grid_setting.key, ga_settings.midi_grid_setting.default)
local settings = GA_GetGridSettings(id)
local grid

if settings.is_adapt then
	grid = GA_GetAdaptiveGridValue(math.floor(zoom_level))
	grid = grid * settings.ratio
else
	grid = settings.ratio
end

-- Log(zoom_level .. " " .. order .. " " .. getNoteDivision(order))

reaper.SetMIDIEditorGrid(0, grid)