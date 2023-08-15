-- @description ek_Collapse selected tracks
-- @version 1.0.7
-- @author Ed Kashinsky
-- @about
--   It collapses selected tracks/envelope lanes between 3 states: small, large. Put height values you like to 'Extensions' -> 'Command parameters' -> 'Track Height A' (for small size) and 'Track Height B' (for large size)
-- @changelog
--   small fixes

reaper.Undo_BeginBlock()

local minHeight
local defaultMinHeight = 25
local _, dpi = reaper.ThemeLayout_GetLayout("tcp", -3)
dpi = tonumber(dpi)

if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
	gfx.ext_retina = dpi >= 512 and 1 or 0
	minHeight = defaultMinHeight * (dpi / 256)
else
	gfx.ext_retina = dpi > 512 and 1 or 0
	minHeight = defaultMinHeight
end

local proj = 0
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

		if height > minHeight then
			reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 18)
			reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
			reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 0)
			reaper.TrackList_AdjustWindows(false)

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