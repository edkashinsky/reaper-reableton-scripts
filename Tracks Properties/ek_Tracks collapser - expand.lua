-- @author Ed Kashinsky
-- @noindex
-- @about ek_Tracks collapser - expand
-- @readme_skip

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

CoreFunctionsLoaded("ek_Tracks collapser functions.lua")

if GetHeightData == nil then return end

reaper.Undo_BeginBlock()

local envelope = reaper.GetSelectedTrackEnvelope(proj)

if envelope ~= nil then
	local height = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH")
	SetEnvelopeHeight(envelope, (height < heights[2].val) and heights[2].val or heights[3].val)
else
	for i = 0, reaper.CountSelectedTracks2(proj, true) - 1 do
		local track = reaper.GetSelectedTrack2(proj, i, true)
		local current_id, new_id = GetHeightData(track)
		local isLanesEnabled, isLanesExpanded = GetLanesStatus(track)
		local state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
		local isFolder = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

		if current_id == 1 and isFolder == 1 and state == tinyChildrenState then
			Log("EXPAND FOLDER", ek_log_levels.Important)
			reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)

			-- show children in MCP
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_SHOWMCP"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"), 0)
		elseif current_id == 1 and isLanesEnabled and not isLanesExpanded then
			Log("EXPAND LANES", ek_log_levels.Important)
			reaper.Main_OnCommand(reaper.NamedCommandLookup(42704), 0) -- Track properties: Make fixed item lanes big/small
		elseif current_id ~= new_id then
			Log("EXPAND HEIGHT: " .. current_id .. " => " .. new_id, ek_log_levels.Important)

			reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", heights[new_id].val)
			reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
			reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 0)
			reaper.TrackList_AdjustWindows(true)

			SetLastHeightId(track, new_id)

			-- todo учитывать настройку отображения автоматизаций
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SHOW_FX_ENV_SEL_TRACK"), 0) -- SWS/BR: Show all FX envelopes for selected tracks
		end
	end
end

reaper.Undo_EndBlock("Track collapser - expand", -1)
