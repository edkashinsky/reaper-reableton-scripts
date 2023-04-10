-- @description ek_Collapse selected tracks
-- @version 1.0.4
-- @author Ed Kashinsky
-- @about
--   It collapses selected tracks/envelope lanes between 3 states: small, large. Put height values you like to 'Extensions' -> 'Command parameters' -> 'Track Height A' (for small size) and 'Track Height B' (for large size)
-- @changelog
--   toggle displaying of tracks in MCP

reaper.Undo_BeginBlock()

local retval, dpi = reaper.ThemeLayout_GetLayout("tcp", -3)
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
	gfx.ext_retina = dpi >= "512" and 1 or 0
else
	gfx.ext_retina = dpi > "512" and 1 or 0
end

local proj = 0
local minHeight = gfx.ext_retina == 0 and 30 or 30 * 2
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

			if height == reaper.GetMediaTrackInfo_Value(track, "I_TCPH") then
				reaper.MB('Please set heights for track states.\n\nGo to "Extensions" -> "Command parameters" and set "Track height A" for collapsed state (as usual equals 1) and "Track height B" for extended state (as usual 80 or more)', 'ek_Collapse selected tracks', 0)
			end

			-- todo учитывать настройку отображения автоматизаций
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_HIDE_ALL_BUT_ACTIVE_SEL"), 0) -- SWS/BR: Hide all but selected track envelope for selected tracks
		elseif isFolder == 1 and state ~= tinyChildrenState then
			reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", tinyChildrenState)

			-- hide children in MCP
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_HIDEMCP"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"), 0)
		end
	end
end

reaper.Undo_EndBlock("Collapse selected tracks", -1)