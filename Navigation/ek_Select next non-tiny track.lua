-- @description ek_Select next non-tiny track
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script helps to navigate by tracks and shown envelopes by hotkeys.
--
--   I usually attach this script to down arrow and it goes down throw project and select next track/envelope lane if it visible
-- @changelog
--   - Small fixes

local proj = 0
local tinyChildrenState = 2

-- MASTER is a track also
local countSelectedTracks = reaper.CountSelectedTracks2(proj, true)
local lastSelectedTrack = reaper.GetSelectedTrack2(proj, countSelectedTracks - 1, true)

-- IF take is selected, navigated by it
local showAllTakesOption = reaper.SNM_GetIntConfigVar("projtakelane", 0) & 1 == 1 -- Show all takes in lane (when room)
local firstSelectedItem = reaper.GetSelectedMediaItem(proj, 0)
local numTakesFirstSelectedItems = 0
if firstSelectedItem ~= nil then
	numTakesFirstSelectedItems = reaper.CountTakes(firstSelectedItem)
end

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

local function GetNextTrack()
	local countTracks = reaper.CountTracks(proj)
	local sIndex
	
	for i = 0, countTracks - 1 do	
		local track = reaper.GetTrack(proj, i)
		
		if track == lastSelectedTrack then
			sIndex = i
			break
		end
	end
	
	if sIndex ~= nil and countTracks - 1 >= sIndex + 1 then 
		for i = sIndex + 1, countTracks - 1 do	
			local track = reaper.GetTrack(proj, i)
			
			if isAnyParentTiny(track) == false then
				return track
			end
		end
	end
	
	return reaper.GetTrack(proj, sIndex or 0)
end

-- Automation lane
local function isEnvelopeVisible(env)
	return env ~= nil and reaper.GetEnvelopeInfo_Value(env, "I_TCPH_USED") > 0
end

local function getFirstVisibleEnvelope(track, startedFrom)
	local countEnvs = reaper.CountTrackEnvelopes(track)
	
	if countEnvs == 0 then
		return nil
	end
	
	for i = startedFrom, countEnvs do
		local env = reaper.GetTrackEnvelope(track, i)
		
		if isEnvelopeVisible(env) then
			return env
		end
	end
	
	return nil
end

local function getEnvelopeIdx(env)
	local track = reaper.GetEnvelopeInfo_Value(env, "P_TRACK")
	local countEnvs = reaper.CountTrackEnvelopes(track)
	
	if countEnvs == 0 then
		return -1
	end
	
	for i = 0, countEnvs do
		local e = reaper.GetTrackEnvelope(track, i)
		
		if e == env then
			return i
		end
	end
	
	return -1
end

local nextEnvelope
local firstSelectedEnvelope = reaper.GetSelectedEnvelope(proj)

if firstSelectedEnvelope == nil and lastSelectedTrack ~= nil then
	firstSelectedEnvelope = getFirstVisibleEnvelope(lastSelectedTrack, 0)
	
	nextEnvelope = firstSelectedEnvelope
elseif isEnvelopeVisible(firstSelectedEnvelope) then
	local idx = getEnvelopeIdx(firstSelectedEnvelope) + 1
	local track = reaper.GetEnvelopeInfo_Value(firstSelectedEnvelope, "P_TRACK")
	
	nextEnvelope = getFirstVisibleEnvelope(track, idx)
	
	if nextEnvelope == nil then
		if reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") == reaper.CountTracks(proj) then
			nextEnvelope = firstSelectedEnvelope
		else
			lastSelectedTrack = track
			countSelectedTracks = 1
		end
	end
end
	
---

if showAllTakesOption and numTakesFirstSelectedItems > 1 then
	reaper.Main_OnCommand(40125, 0) -- Take: Switch items to next take
else
	reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_UNSELMASTER"), 0) -- SWS: Unselect master track
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_UNSEL_ENV"), 0) -- SWS/BR: Unselect envelope
	
	if countSelectedTracks > 1 then
		reaper.SetTrackSelected(lastSelectedTrack, true)
	elseif isEnvelopeVisible(nextEnvelope) then
		reaper.SetCursorContext(2, nextEnvelope)
	else
		-- switch to next track
		local track = GetNextTrack()
		
		-- local retval, buf = reaper.GetTrackName(track)
		-- local num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
		-- reaper.ShowConsoleMsg("Next track is: " .. buf  .. " (" .. num .. ")\n")
		
		if track ~= nil then
			reaper.SetTrackSelected(track, true)
			
			-- need for update move cursor focus
			local num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
			
			if num <= 1 then
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACK"), 0) -- Xenakios/SWS: Select next tracks
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACK"), 0) -- Xenakios/SWS: Select previous tracks
			else
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACK"), 0) -- Xenakios/SWS: Select previous tracks
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACK"), 0) -- Xenakios/SWS: Select next tracks
			end
		end
	end
	
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40913), 0) -- Track: Vertical scroll selected tracks into view
end 