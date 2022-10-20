-- @description ek_Toggle MIDI Editor window in arrange
-- @version 1.0.0
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

if not reaper.APIExists("JS_ReaScriptAPI_Version") then
	reaper.MB("Please, install JS_ReaScriptAPI for this script to function. Thanks!", "JS_ReaScriptAPI is not installed", 0)
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