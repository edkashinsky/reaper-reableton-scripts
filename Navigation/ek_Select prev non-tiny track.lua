-- @description ek_Select prev non-tiny track
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script helps to navigate by tracks and shown envelopes by hotkeys.
--
--   I usually attach this script to up arrow and it goes up throw project and select previous track/envelope lane if it visible
-- @changelog
--   - Small fixes

local proj = 0
local tinyChildrenState = 2

-- MASTER is a track also
local countSelectedTracks = reaper.CountSelectedTracks2(proj, true)
local firstSelectedTrack = reaper.GetSelectedTrack2(proj, 0, true)

-- IF take is selected, navigated by it
local showAllTakesOption = reaper.SNM_GetIntConfigVar("projtakelane", 0) & 1 == 1 -- Show all takes in lane (when room)
local firstSelectedItem = reaper.GetSelectedMediaItem(proj, 0)
local numTakesFirstSelectedItems = 0
if firstSelectedItem ~= nil then
	numTakesFirstSelectedItems = reaper.CountTakes(firstSelectedItem)
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
	local countTracks = reaper.CountTracks(proj)
	local sIndex
	
	for i = 0, countTracks - 1 do	
		local track = reaper.GetTrack(proj, i)
		
		if track == firstSelectedTrack then
			sIndex = i
			break
		end
	end
	
	if (sIndex == nil or sIndex == 0) then
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
	
	return reaper.GetTrack(proj, sIndex or countTracks - 1)
end

-- Automation lane
local function isEnvelopeVisible(env)
	return env ~= nil and reaper.GetEnvelopeInfo_Value(env, "I_TCPH_USED") > 0
end

local function getFirstVisibleEnvelopeReverse(track, startedFrom)
	local countEnvs = reaper.CountTrackEnvelopes(track)
	
	if countEnvs == 0 or countEnvs - startedFrom < 0 then
		return nil
	end
	
	for i = startedFrom, 0, -1 do
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

local prevEnvelope
local selectedEnvelope = reaper.GetSelectedEnvelope(proj)
local useFirstSelectedTrack = false

if selectedEnvelope == nil and firstSelectedTrack ~= nil and reaper.GetMediaTrackInfo_Value(firstSelectedTrack,  "IP_TRACKNUMBER") ~= -1 then
	local track = GetPrevTrack()
	
	prevEnvelope = getFirstVisibleEnvelopeReverse(track, reaper.CountTrackEnvelopes(track))
elseif isEnvelopeVisible(selectedEnvelope) then
	local idx = getEnvelopeIdx(selectedEnvelope) - 1
	local track = reaper.GetEnvelopeInfo_Value(selectedEnvelope, "P_TRACK")
	
	prevEnvelope = getFirstVisibleEnvelopeReverse(track, idx)
	
	if prevEnvelope == nil then
		firstSelectedTrack = track
		countSelectedTracks = 1
		useFirstSelectedTrack = true
	end
end
	
---

if showAllTakesOption and numTakesFirstSelectedItems > 1 then
	reaper.Main_OnCommand(40126, 0) -- Take: Switch items to previous take
else
	reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_UNSELMASTER"), 0) -- SWS: Unselect master track
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_UNSEL_ENV"), 0) -- SWS/BR: Unselect envelope
	
	if countSelectedTracks > 1 then	
		reaper.SetTrackSelected(firstSelectedTrack, true)
	elseif isEnvelopeVisible(prevEnvelope) then
		reaper.SetCursorContext(2, prevEnvelope)
	else
		local track
		
		if useFirstSelectedTrack == true then
			track = firstSelectedTrack
		else
			track = GetPrevTrack()
		end
	
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

