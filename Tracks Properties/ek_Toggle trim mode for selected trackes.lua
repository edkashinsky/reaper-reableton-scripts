-- @description ek_Toggle trim mode for selected trackes
-- @version 1.0.2
-- @author Ed Kashinsky
-- @about
--   Toggles trim mode for selected tracks and shows current state as button highlight
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
	reaper.MB('Please execute script "ek_Global startup action settings" and enable "Enable global action" checkbox in the window', '', 0)
	return
end

reaper.Undo_BeginBlock()

local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

local function toggleAutomationMode()
	local countSelectedTracks = reaper.CountSelectedTracks(proj)
	
	if countSelectedTracks > 0 then
		local state = reaper.GetToggleCommandStateEx(sectionID, cmdID);
		
		for i = 0, countSelectedTracks - 1 do
			local newValue
			local track = reaper.GetSelectedTrack(proj, i)
			
			if state == 2 then
				newValue = 0
			else
				newValue = 2
			end
			
			reaper.SetMediaTrackInfo_Value(track, "I_AUTOMODE", newValue)
			reaper.SetToggleCommandState(sectionID, cmdID, newValue)
			reaper.RefreshToolbar2(sectionID, cmdID)
		end
	end
end

toggleAutomationMode()
GA_SetButtonForHighlight(ga_highlight_buttons.trim_mode, sectionID, cmdID)

reaper.Undo_EndBlock("Toggle automation mode for selected trackes", -1)