-- @description ek_Switch to prev grid step (MIDI Editor)
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   Switching to prev grid step settings in MIDI Editor depending on adaptive or not
-- @changelog
--   Small fixes
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

if not EK_IsGlobalActionEnabled() then
	reaper.MB('Please add "ek_Global startup action" as Global startup action (Extenstions -> Startup Actions -> Set global startup action) for realtime highlighting of this button', '', 0)
end

local MidiEditor = reaper.MIDIEditor_GetActive()
if not MidiEditor then return end

local s_config = ga_settings.midi_grid_setting
local values = s_config.select_values
local value = EK_GetExtState(s_config.key, s_config.default)
local isAdaptive = in_array(s_config.adaptive_grid_values, value)
local newValue = value - 1
local availableValues = {}

for i = 0, #values - 1 do
	if isAdaptive and in_array(s_config.adaptive_grid_values, i) then
		table.insert(availableValues, i)
	elseif not isAdaptive and not in_array(s_config.adaptive_grid_values, i) then
		table.insert(availableValues, i)
	end
end

if in_array(availableValues, newValue) then
	EK_SetExtState(s_config.key, newValue)
	Log("Set midi grid: " .. newValue)

	local zoom_level = math.floor(GA_GetHZoomLevelForMidiEditor())
	local id = EK_GetExtState(s_config.key, s_config.default)
	local settings = GA_GetGridSettings(id)
	local grid

	if settings.is_adapt then
		grid = GA_GetAdaptiveGridValue(zoom_level)
		grid = grid * settings.ratio
	else
		grid = settings.ratio
	end

	---Log(zoom_level .. " " .. grid)

	reaper.SetMIDIEditorGrid(0, grid)
end