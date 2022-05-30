-- @description ek_Toggle trim mode for selected trackes
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Toggles trim mode for selected tracks and shows current state as button highlight
-- @changelog
--   - Added core functions

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

if not EK_IsGlobalActionEnabled() then
	reaper.MB('Please add "ek_Global startup action" as Global startup action (Extenstions -> Startup Actions -> Set global startup action) for realtime highlighting of this button', '', 0)
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