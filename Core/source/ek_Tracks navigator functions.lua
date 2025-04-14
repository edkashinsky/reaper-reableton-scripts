-- @description ek_Tracks navigator functions
-- @author Ed Kashinsky
-- @noindex

proj = 0
tinyChildrenState = 2

-- MASTER is a track also
countSelectedTracks = reaper.CountSelectedTracks2(proj, true)
firstSelectedTrack = reaper.GetSelectedTrack2(proj, 0, true)
lastSelectedTrack = reaper.GetSelectedTrack2(proj, countSelectedTracks - 1, true)

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

function GetNextTrack()
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

function GetPrevTrack()
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
function isEnvelopeVisible(env)
	return env ~= nil and reaper.GetEnvelopeInfo_Value(env, "I_TCPH_USED") > 0
end

function getFirstVisibleEnvelope(track, startedFrom)
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

function getFirstVisibleEnvelopeReverse(track, startedFrom)
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

function getEnvelopeIdx(env)
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