-- @description ek_Toggle MIDI Editor window
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It remember MIDI Editor button for toggling docker window in MIDI Editor section
--
--   For correct work please install ek_Toggle last under docker window
-- @changelog
--   - Added core functions
-- @provides [main=midi_editor] .

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) return true else return false end
end

if not CoreFunctionsLoaded() then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

local function setStateForButton(prefixKey, state)
	local sectionID = reaper.GetExtState("ed_stuff", prefixKey .. "_section_id")
	local cmdID = reaper.GetExtState("ed_stuff", prefixKey .. "_command_id")
	
	if cmdID ~= '' and cmdID ~= nil then
		reaper.SetToggleCommandState(sectionID, cmdID, state)
		reaper.RefreshToolbar2(sectionID, cmdID)
	end
end

EK_ToggleLastGroupedDockerWindow()

local midieditor = reaper.MIDIEditor_GetActive()
local state = reaper.MIDIEditor_GetMode(midieditor)
setStateForButton("midi_editor", state ~= -1 and 1 or 0)

