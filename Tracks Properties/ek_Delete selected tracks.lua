-- @description ek_Delete selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   If item has several takes and option "Show all takes in lane (when room)" is on, we gonna delete active take. And in other case it deletes track and select previous available track
-- @changelog
--   - Small fixes

reaper.Undo_BeginBlock()

local proj = 0
local tinyChildrenState = 2

local sIndex
local firstSelectedTrack
local firstSelectedItemCountTakes
local showAllTakesOption = reaper.SNM_GetIntConfigVar("projtakelane", 0) & 1 == 1 -- Show all takes in lane (when room)

local function fetchFirstSelectedTrack()
	firstSelectedTrack = reaper.GetSelectedTrack(proj, 0)
	
	if showAllTakesOption then
		local firstSelectedItem = reaper.GetSelectedMediaItem(proj, 0)
		if firstSelectedItem ~= nil then
			firstSelectedItemCountTakes = reaper.CountTakes(firstSelectedItem)
		end
	end
	
	for i = 0, reaper.CountTracks(proj) - 1 do	
		local track = reaper.GetTrack(proj, i)
		
		if track == firstSelectedTrack then
			sIndex = i
			break
		end
	end
end

local function isAnyParentTiny(track)
	local parentTrack = track

	while parentTrack ~= nil do
		parentTrack = reaper.GetParentTrack(parentTrack)

		if parentTrack ~= nil then
			local isFolder = reaper.GetMediaTrackInfo_Value(parentTrack, "I_FOLDERCOMPACT")

			if isFolder == tinyChildrenState then
				return true
			end
		end
	end

	return false
end

local function GetPrevTrack()
	if sIndex == nil or sIndex == 0 then
		return reaper.GetMasterTrack(proj)
	end
	
	if sIndex - 1 >= 0 then 
		for i = sIndex - 1, 0, -1 do
			local track = reaper.GetTrack(proj, i)
			
			if isAnyParentTiny(track) == false then
				return track
			end
		end
	end
	
	return reaper.GetTrack(proj, sIndex or 0)
end

fetchFirstSelectedTrack()

-- IF item has several takes and option "Show all takes in lane (when room)" is on, we gonna delete active take
if showAllTakesOption and firstSelectedItemCountTakes > 1 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40129), 0) -- Take: Delete active take from items
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40184), 0) -- Remove items/tracks/envelope points (depending on focus) - no prompting

	local new_selected_track = reaper.GetSelectedTrack(proj, 0)

	if new_selected_track == nil then
		local track = GetPrevTrack()

		if track ~= nil then
			reaper.SetTrackSelected(track, true)
		end
	end
end

reaper.Undo_EndBlock("Delete selected tracks", -1)