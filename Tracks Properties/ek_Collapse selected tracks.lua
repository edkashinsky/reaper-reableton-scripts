-- @description ek_Collapse selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It collapses selected tracks/envelope lanes between 3 states: small, medium, large
-- @changelog
--   - Small fixes

reaper.Undo_BeginBlock()

local proj = 0
local minHeight = 30
local tinyChildrenState = 2
local envelope = reaper.GetSelectedTrackEnvelope(proj)

if envelope ~= nil then
	local height = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH_USED")
	
	if height > 80 then
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_WOL_APPHSELENVSLOT2"), 0) -- SWS/wol: Apply height to selected envelope, slot 2
	else 
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_WOL_APPHSELENVSLOT1"), 0) -- SWS/wol: Apply height to selected envelope, slot 3
	end
else
	for i = 0, reaper.CountSelectedTracks2(proj, true) - 1 do
		local track = reaper.GetSelectedTrack2(proj, i, true)
	
		local height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
		local state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
		local isFolder = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
		local isMaster = reaper.GetMediaTrackInfo_Value(track,  "IP_TRACKNUMBER") == -1
	
		if isMaster then
			reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 1)
			reaper.TrackList_AdjustWindows(false)
		elseif height > minHeight then
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELTRAXHEIGHTA"), 0) -- Xenakios/SWS: Set selected tracks heights to A
			--reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MINTRACKS"), 0) -- SWS: Minimize selected track(s)
		elseif isFolder == 1 and state ~= tinyChildrenState then
			reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", tinyChildrenState)
		
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"), 0)
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0)
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup(41593), 0)
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"), 0)		
		end
	end
	
end

reaper.Undo_EndBlock("Collapse selected tracks", -1)