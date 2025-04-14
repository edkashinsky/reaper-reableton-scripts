-- @author Ed Kashinsky
-- @noindex
-- @about ek_Tracks navigator - go to prev track
-- @readme_skip

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("tracks_navigator") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

-- IF take is selected, navigated by it
local showAllTakesOption = reaper.SNM_GetIntConfigVar("projtakelane", 0) & 1 == 1 -- Show all takes in lane (when room)
local firstSelectedItem = reaper.GetSelectedMediaItem(proj, 0)
local numTakesFirstSelectedItems = 0
if firstSelectedItem ~= nil then
	numTakesFirstSelectedItems = reaper.CountTakes(firstSelectedItem)
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

