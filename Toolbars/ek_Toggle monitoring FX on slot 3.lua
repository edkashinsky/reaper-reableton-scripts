-- @description ek_Toggle monitoring fx plugin on slot 3
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'
-- @changelog
--   - Added script

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
	reaper.MB('Please add "ek_Global startup action" as Global startup action (Extensions -> Startup Actions -> Set global startup action) for realtime highlighting of this button', '', 0)
end

reaper.Undo_BeginBlock()

local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()
GA_ToggleMfxBtnOnSlot(ga_mfx_slots.mfx_slot_3, ga_highlight_buttons.mfx_slot_3, sectionID, cmdID)

reaper.Undo_EndBlock("Toggle monitoring fx plugin on slot 3", -1)