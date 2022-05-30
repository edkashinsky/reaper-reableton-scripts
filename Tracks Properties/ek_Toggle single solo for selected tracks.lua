-- @description ek_Toggle single solo for selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Toggles selected track soloed
-- @provides [main=main,midi_editor] .
-- @changelog
--   - Small fixes

reaper.Undo_BeginBlock()

proj = 0

local function isAllTrackSoloed()
	local isAllTracksSoloed = true
	
	for i = 0, reaper.CountSelectedTracks(proj) - 1 do
		local track = reaper.GetSelectedTrack(proj, i)
	
		local isSolo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
		if isSolo == 0 then
			isAllTracksSoloed = false
			break
		end
	end
	
	return isAllTracksSoloed
end

if isAllTrackSoloed() then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40340), 0) -- Track: Unsolo all tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(7), 0) -- Track: Toggle solo for selected tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(7), 0) -- Track: Toggle solo for selected tracks
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40340), 0) -- Track: Unsolo all tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(7), 0) -- Track: Toggle solo for selected tracks
end

reaper.Undo_EndBlock("Toggle single solo for selected tracks", -1)