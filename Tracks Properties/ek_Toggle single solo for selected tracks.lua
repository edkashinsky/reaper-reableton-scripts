-- @description ek_Toggle single solo for selected tracks
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   Toggles selected track soloed
-- @provides [main=main,midi_editor] .
-- @changelog
--   When mouse on lane, it will be solo

reaper.Undo_BeginBlock()

proj = 0

local function isAllSelTrackSoloed()
	for i = 0, reaper.CountSelectedTracks(proj) - 1 do
		local track = reaper.GetSelectedTrack(proj, i)
	
		local isSolo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
		if isSolo == 0 then
			return false
		end
	end
	
	return true
end

if isAllSelTrackSoloed() then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40340), 0) -- Track: Unsolo all tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(7), 0) -- Track: Toggle solo for selected tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(7), 0) -- Track: Toggle solo for selected tracks
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40340), 0) -- Track: Unsolo all tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(7), 0) -- Track: Toggle solo for selected tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup(42478), 0) -- Track lanes: Select items in lane under mouse
end

reaper.Undo_EndBlock("Toggle single solo for selected tracks", -1)