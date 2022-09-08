-- @description ek_Expand selected tracks
-- @version 1.0.2
-- @author Ed Kashinsky
-- @about
--   It expands selected tracks/envelope lanes between 2 states: small, large. Put height values you like to 'Extensions' -> 'Command parameters' -> 'Track Height A' (for small size) and 'Track Height B' (for large size)
-- @changelog
--   - Small fixes

reaper.Undo_BeginBlock()

local retval, dpi = reaper.ThemeLayout_GetLayout("mcp", -3) -- get the current dpi
--Now we need to tell the gfx-functions, that Retina/HiDPI is available(512)
if dpi == "512" then -- if dpi==retina, set the gfx.ext_retina to 1, else to 0
   gfx.ext_retina = 1 -- Retina
   else
   gfx.ext_retina = 0 -- no Retina
end

local proj = 0
local minHeight = gfx.ext_retina == 0 and 30 or 30 * 2
local tinyChildrenState = 2

local envelope = reaper.GetSelectedTrackEnvelope(proj)

if envelope ~= nil then
	local height = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH_USED")
	
	if height < 80 then
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_WOL_APPHSELENVSLOT2"), 0) -- SWS/wol: Apply height to selected envelope, slot 2
	else 
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_WOL_APPHSELENVSLOT3"), 0) -- SWS/wol: Apply height to selected envelope, slot 3
	end
else
	for i = 0, reaper.CountSelectedTracks2(proj, true) - 1 do
		local track = reaper.GetSelectedTrack2(proj, i, true)
	
		local height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
		local state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
		local isFolder = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
		local isMaster = reaper.GetMediaTrackInfo_Value(track,  "IP_TRACKNUMBER") == -1
		
		if isMaster then
			reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 80)
			reaper.TrackList_AdjustWindows(false)
		elseif isFolder == 1 and state == tinyChildrenState then
			reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)
		
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"), 0)           -- SWS: Save current track selection
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0)          -- SWS: Select only children of selected folders
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_BOTH"), 0)               -- SWS: Show selected track(s) in TCP and MCP
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"), 0)          -- SWS: Restore saved track selection
		elseif height <= minHeight then
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELTRAXHEIGHTB"), 0) -- Xenakios/SWS: Set selected tracks heights to B
		end
	end
end

reaper.Undo_EndBlock("Expand selected tracks", -1)
