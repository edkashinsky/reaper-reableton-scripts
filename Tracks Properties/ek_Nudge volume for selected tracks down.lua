-- @description ek_Nudge volume for selected tracks down
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It decrease volume for selected track a bit and shows tooltip with set volume
-- @provides [main=main,midi_editor] .
-- @changelog
--   - Small fixes

reaper.Undo_BeginBlock()

local proj = 0

local function getVolumeLine(track, isMultiplyMode)
	local retval, volume, pan = reaper.GetTrackUIVolPan(track)
	local volInDb = 20 * math.log(volume, 10)
	
	if isMultiplyMode == true then
		local retval, name = reaper.GetTrackName(track)
		
		return name .. ": " .. string.format("%.2f", volInDb) .. "db"
	else
		return "Volume: " .. string.format("%.2f", volInDb) .. "db"
	end
end

local function showToolbar()
	local message = ""
	local countSelectedTracks = reaper.CountSelectedTracks(proj)
	
	if countSelectedTracks > 0 then
		for i = 0, countSelectedTracks - 1 do
			local track = reaper.GetSelectedTrack(proj, i)
			
			message = message .. getVolumeLine(track, countSelectedTracks > 1) .. "\n"
		end
		
		local x, y = reaper.GetMousePosition()
		reaper.TrackCtl_SetToolTip(message, x, y, true)
	end
end

reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_NUDGSELTKVOLDOWN"), 0) -- Xenakios/SWS: Nudge volume of selected tracks down
showToolbar()

reaper.Undo_EndBlock("Nudge volume for selected tracks down", -1)