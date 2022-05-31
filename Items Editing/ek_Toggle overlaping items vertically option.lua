-- @description ek_Toggle overlaping items vertically option
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script toggles option of editing multiple items on one track at the same time

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

local commandId = 40507 -- Options: Offset overlapping media items vertically

reaper.Main_OnCommand(commandId, 0)

local state = reaper.GetToggleCommandState(commandId)
local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

if state == 1 then
    reaper.Main_OnCommand(reaper.NamedCommandLookup(41121), 0) -- Options: Disable trim content behind media items when editing
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_XFDOFF"), 0) -- SWS: Set auto crossfade off
else
    reaper.Main_OnCommand(reaper.NamedCommandLookup(41120), 0) -- Options: Enable trim content behind media items when editing
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_XFDON"), 0) -- SWS: Set auto crossfade on
end

reaper.SetToggleCommandState(sectionID, cmdID, state)
GA_SetButtonForHighlight(ga_highlight_buttons.overlaping_items_vertically, sectionID, cmdID)
