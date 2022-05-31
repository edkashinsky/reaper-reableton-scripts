-- @description ek_Toggle monitoring fx plugin
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script helps to watching for monitoring plugins (Realphones, Reference 4 and etc). You can see state of enabling plugin by state of button on your toolbar.
--
--   For installation just add this script on toolbar and set "ek_Global Startup Functions" as global startup action via SWS.
--
--   If you want to change Realphones for another plugin, please put in "ek_Headphones monitoring functions"
-- @changelog
--   - Added core functions

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

reaper.Undo_BeginBlock()

local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

function toggleMonitoringFxOnMasterTrack()
	local masterTrack = reaper.GetMasterTrack(proj)
	local fxInd = EK_GetMonitoringFxIndexOnMasterTrack()
	local isEnabled = EK_GetMonitoringFxEnabledOnMasterTrack()
	local MonitoringFx = GA_GetSettingValue(ga_settings.monitoring_fx_plugin)
	local state
	
	if isEnabled == nil or fxInd == -1 then
		EK_ShowTooltip("Please add " .. MonitoringFx .. " on Monitoring FX tab")
		state = 0
	else
		reaper.TrackFX_SetEnabled(masterTrack, fxInd, not isEnabled)
		state = isEnabled and 0 or 1
	end

	reaper.SetToggleCommandState(sectionID, cmdID, state)
	reaper.RefreshToolbar2(sectionID, cmdID)

	-- update audio connection just in case
	reaper.Audio_Quit()
	reaper.Audio_Init()
end

toggleMonitoringFxOnMasterTrack()
GA_SetButtonForHighlight(ga_highlight_buttons.monitoring_fx, sectionID, cmdID)

reaper.Undo_EndBlock("Toggle Headphones monitoring on master track", -1)