-- @description ek_Toggle MIDI Editor window in arrange
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   It remember MIDI Editor button for toggling docker window in arrange view
--
--   For correct work please install ek_Toggle last under docker window
-- @changelog
--   - Added core functions
-- @provides [main] .

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

CoreFunctionsLoaded("ek_Core functions startup.lua")

-- View: Toggle show MIDI editor windows
local actionId = 40716
local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

GA_SetButtonForHighlight(ga_highlight_buttons.midi_editor, sectionID, cmdID)
EK_StoreLastGroupedDockerWindow(sectionID, cmdID, actionId)
EK_ToggleLastGroupedDockerWindow()

local midieditor = reaper.MIDIEditor_GetActive()
local state = reaper.MIDIEditor_GetMode(midieditor)
local newState = state ~= -1 and 1 or 0

reaper.SetToggleCommandState(sectionID, cmdID, newState)	
reaper.RefreshToolbar2(sectionID, cmdID)

