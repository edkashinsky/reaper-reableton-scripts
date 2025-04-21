-- @author Ed Kashinsky
-- @noindex
-- @about ek_Tracks collapser - collapse
-- @readme_skip

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("tracks-collapser") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

if GetHeightData == nil then return end

reaper.Undo_BeginBlock()

local envelope = reaper.GetSelectedTrackEnvelope(proj)

if envelope ~= nil then
	local height = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH")
	SetEnvelopeHeight(envelope, height > heights[2].val and heights[2].val or heights[1].val)
else
	for i = 0, reaper.CountSelectedTracks2(proj, true) - 1 do
		local track = reaper.GetSelectedTrack2(proj, i, true)
		local current_id, new_id = GetHeightData(track, true)
		local isLanesEnabled, isLanesExpanded = GetLanesStatus(track)
		local isFolder = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
		local state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")

		if current_id == 1 and isLanesEnabled and isLanesExpanded then
			Log("COLLAPSE LANES", ek_log_levels.Important)
			reaper.Main_OnCommand(reaper.NamedCommandLookup(42704), 0) -- Track properties: Make fixed item lanes big/small
		elseif current_id == 1 and isFolder == 1 and state ~= tinyChildrenState then
			Log("COLLAPSE FOLDER", ek_log_levels.Important)
			reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", tinyChildrenState)

			-- hide children in MCP
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_HIDEMCP"), 0)
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"), 0)
		elseif current_id ~= new_id then
			Log("COLLAPSE HEIGHT: " .. current_id .. " => " .. new_id, ek_log_levels.Important)

			reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", heights[new_id].val)
			reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
			reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 0)
			reaper.TrackList_AdjustWindows(false)

			SetLastHeightId(track, new_id)

			-- todo учитывать настройку отображения автоматизаций
			-- reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_HIDE_ALL_BUT_ACTIVE_SEL"), 0) -- SWS/BR: Hide all but selected track envelope for selected tracks
		end
	end
end

reaper.Undo_EndBlock("Track collapser - collapse", -1)