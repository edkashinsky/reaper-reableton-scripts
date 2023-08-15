-- @author Ed Kashinsky
-- @noindex
-- @about ek_Adaptive grid monitor MIDI Editor
-- @readme_skip

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

if not CoreFunctionsLoaded("ek_Core functions.lua") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

if not CoreFunctionsLoaded("ek_Adaptive grid functions.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

local MidiEditor = reaper.MIDIEditor_GetActive()
if not MidiEditor then return end

local grid = AG_GetCurrentGridValue(true)
if grid == nil then return end

-- Log(zoom_level .. " " .. order .. " " .. getNoteDivision(order))

reaper.SetMIDIEditorGrid(0, grid)