-- @description ek_Insert new track
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   It just inserts track or inserts it in the end of list depending on situation
-- @changelog
--   When selected track is folder, track will be created at the end of track list

local proj = 0
local tinyChildrenState = 2

-- MASTER is a track also
local countSelectedTracks = reaper.CountSelectedTracks2(proj, true)
local lastSelectedTrack = reaper.GetSelectedTrack2(proj, countSelectedTracks - 1, true)

local function isAnyParentTiny(track)
	local parentTrack = track

	-- local retval, buf = reaper.GetTrackName(track)
	-- reaper.ShowConsoleMsg("Looking parent for: " .. buf .. "\n")

	while parentTrack ~= nil do
		parentTrack = reaper.GetParentTrack(parentTrack)

		if parentTrack ~= nil then
			local isFolder = reaper.GetMediaTrackInfo_Value(parentTrack, "I_FOLDERCOMPACT")

			-- local retval, buf = reaper.GetTrackName(parentTrack)
			-- reaper.ShowConsoleMsg("\t" .. buf .. ": " .. isFolder .. "\n")

			if isFolder == tinyChildrenState then
				-- reaper.ShowConsoleMsg("TRUE\n")
				return true
			end
		end
	end

	return false
end

local function IsLastSelectedTrackTiny()
	if not lastSelectedTrack then return false end
	
	local isFolder = reaper.GetMediaTrackInfo_Value(lastSelectedTrack, "I_FOLDERCOMPACT")
	
	if isFolder == tinyChildrenState then
		return true
	end
	
	if isAnyParentTiny(lastSelectedTrack) == true then
		return true
	end
	
	return false
end

if IsLastSelectedTrackTiny() or countSelectedTracks == 0 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40702), 0) -- Track: Insert new track at end of track list
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_INSRTTRKABOVE"), 0) -- SWS: Insert track above selected tracks
end