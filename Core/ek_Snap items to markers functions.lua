-- @author Ed Kashinsky
-- @noindex

SNAP_TO_MARKERS = 0
SNAP_TO_REGIONS = 1

BEHAVIOUR_TYPE_SINGLE = 0
BEHAVIOUR_TYPE_STEM = 1
BEHAVIOUR_TYPE_OVERLAPPED = 2

POSITION_BEGIN = 0
POSITION_SNAP_OFFSET = 1
POSITION_FIRST_CUE = 2
POSITION_PEAK = 3

data = {
	snap_to = { key = 'sn_snap_to', default = SNAP_TO_MARKERS, value = nil, },
	start_marker = { key = 'sn_start', default = 1, value = nil, },
	count_on_track = { key = 'sn_count', default = 1, value = nil, },
	behaviour = { key = 'sn_behaviour', default = BEHAVIOUR_TYPE_SINGLE, value = nil, },
	position = { key = 'sn_position', default = POSITION_BEGIN, value = nil, },
	ignore_when_unavailable = { key = 'sn_ignore_when_unavailable', default = true, value = nil, },
}

local cur_track_index = 0

local function BuildSamplesBuffer(item, isPortioned, Callback)
	local take = reaper.GetActiveTake(item)

	if not take then return end

	local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	local starttime_sec, startBlock, endBlock, iterBlock
	local PCM_source = reaper.GetMediaItemTake_Source(take)
	local samplerate = reaper.GetMediaSourceSampleRate(PCM_source)
	local audio = reaper.CreateTakeAudioAccessor(take)
	local n_channels = reaper.GetMediaSourceNumChannels(PCM_source)
	local item_len_spls = math.floor(length * samplerate)
	local max_block_size = 4194303
	local block_size = isPortioned and samplerate or math.floor(item_len_spls)

	if block_size > max_block_size / n_channels then
		block_size = math.floor(max_block_size / n_channels)
	elseif block_size > item_len_spls then
		block_size = item_len_spls
	end

	local n_blocks = math.floor(item_len_spls / block_size)

	if n_blocks < 1 then n_blocks = 1 end

	local extra_spls = item_len_spls - block_size * n_blocks
	local samplebuffer = reaper.new_array(block_size * n_channels)

	starttime_sec = 0
	startBlock = 0
	endBlock = n_blocks
	iterBlock = 1

	Log("=== SEARCH " .. startBlock .. " -> " .. endBlock .. " by " .. iterBlock .. " [" .. item_len_spls .. "spl.][" .. round(length, 3) .. "s.][" .. samplerate .. "Hz] ===", ek_log_levels.Warning)

	for cur_block = startBlock, endBlock, iterBlock do
		local block = cur_block == endBlock and extra_spls or block_size

		if block == 0 then goto end_looking end

		samplebuffer.clear()

		-- Loads 'samplebuffer' with the next block
		reaper.GetAudioAccessorSamples(audio, samplerate, n_channels, starttime_sec, block, samplebuffer)

		Log("\t" .. cur_block .. " block: [" .. n_channels .. "ch.][" .. block .. "spl.][" .. round((starttime_sec + (block / samplerate)) - starttime_sec, 3) .. "s.] " .. round(starttime_sec, 3) .. " - " .. round(starttime_sec + (block / samplerate), 3) .. "s.", ek_log_levels.Warning)

		if Callback(samplebuffer, block, samplerate, n_channels, starttime_sec) then
			goto end_looking
		end

		starttime_sec = starttime_sec + (block / samplerate)
	end

	::end_looking::

	-- Tell r we're done working with this item, so the memory can be freed
	reaper.DestroyAudioAccessor(audio)
end

local function GetMaxPeakPosition(item)
	local CallbackEEL = reaper.ImGui_CreateFunctionFromEEL([[
		i = 0;
		maxDb = -150;
		maxAmpl = 0;
		position = -1;

		while (i < block_size) (
			while (i < block_size) (
				// Loop through each channel separately
				j = 1;

				loop(n_channels,
					spl = samplebuffer[(i * n_channels) + j];
					ampl = abs(spl);

					maxAmpl = max(maxAmpl, ampl);
					maxDb = ampl != 0 && ampl == maxAmpl ? 20 * log10(ampl) : maxDb;
					position = ampl != 0 && ampl == maxAmpl ? i / samplerate : position;

					j += 1;
				);

				i += 1;
			);
		);
	]])

	local maxDb = -150
	local position = -1

	BuildSamplesBuffer(item, false, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
		-- Use EEL to read from the array
		reaper.ImGui_Function_SetValue(CallbackEEL, 'block_size', block_size)
		reaper.ImGui_Function_SetValue(CallbackEEL, 'n_channels', n_channels)
		reaper.ImGui_Function_SetValue_Array(CallbackEEL, 'samplebuffer', samplebuffer)
		reaper.ImGui_Function_SetValue(CallbackEEL, 'samplerate', samplerate)
		reaper.ImGui_Function_Execute(CallbackEEL)

		local curMaxDb = reaper.ImGui_Function_GetValue(CallbackEEL, 'maxDb')
		local curPosition = reaper.ImGui_Function_GetValue(CallbackEEL, 'position')

		maxDb = math.max(maxDb, curMaxDb)
		if maxDb == curMaxDb then
			position = starttime_sec + curPosition
		end
	end)

	return maxDb, position
end

local function GetPeakThresholdPosition(item, threshold)
	local CallbackEEL = reaper.ImGui_CreateFunctionFromEEL([[
		i = (reverse == 1) ? block_size : 0;
		maxDb = -150;
		position = -1;

		while ((reverse == 1 && i > 0) || (reverse != 1 && i < block_size)) (
			// Loop through each channel separately
			j = 1;

			loop(n_channels,
				spl = samplebuffer[(i * n_channels) + j];
				db = maxDb != -150 || spl == 0 ? -150 : 20 * log10(abs(spl));

				maxDb = maxDb == -150 && db >= threshold ? db : maxDb;
				position = position == -1 && db >= threshold ? i / samplerate : position;

				j += 1;
			);

			i = (reverse == 1) ? i - 1 : i + 1;
		);
	]])

	local maxDb = -150
	local pos = -1

	BuildSamplesBuffer(item, true, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
		-- Use EEL to read from the array
		reaper.ImGui_Function_SetValue(CallbackEEL, 'block_size', block_size)
		reaper.ImGui_Function_SetValue(CallbackEEL, 'n_channels', n_channels)
		reaper.ImGui_Function_SetValue_Array(CallbackEEL, 'samplebuffer', samplebuffer)
		reaper.ImGui_Function_SetValue(CallbackEEL, 'samplerate', samplerate)
		reaper.ImGui_Function_SetValue(CallbackEEL, 'reverse', isReverse and 1 or 0)
		reaper.ImGui_Function_SetValue(CallbackEEL, 'threshold', threshold)
		reaper.ImGui_Function_Execute(CallbackEEL)

		local curMaxDb = reaper.ImGui_Function_GetValue(CallbackEEL, 'maxDb')
		local curPos = reaper.ImGui_Function_GetValue(CallbackEEL, 'position')

		if curPos ~= -1 then
			maxDb = curMaxDb
			pos = starttime_sec + curPos

			return true
		end
	end)

	if pos >= 0 then
		return maxDb, pos
	else
		return nil
	end
end

function GetMarkersOrRegions(snap_to)
	local markers = {}
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)

	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)

		if (snap_to == SNAP_TO_MARKERS and not isrgn) or (snap_to == SNAP_TO_REGIONS and isrgn) then
			table.insert(markers, {
				num = markrgnindexnumber,
				title = name,
				position = pos,
				rgnend = rgnend
			})
		end
	end
	
	return markers
end

local function FindIndexByMarkerNumber(markers, number)
	if number == nil then
		return nil
	end
	
	for i = 1, #markers do
		if markers[i].num == number then
			return i
		end
	end
	
	return nil
end

local function GetMinPosition(item)
	local minPosition = nil

	for i = 1, #item do
		if minPosition == nil or item[i].position < minPosition then
			minPosition = item[i].position
		end
	end

	return minPosition
end

local function CreateNewTracksForItemsGroup(index)
	local curItemGroup = items_map[index]
	local getNewTrackIndex = function()
		local prevItemGroup = items_map[index - 1]
		local lastTrackInPrevItemGroup = EK_GetMediaTrackByGUID(prevItemGroup[#prevItemGroup].track_id)

		return reaper.GetMediaTrackInfo_Value(lastTrackInPrevItemGroup, "IP_TRACKNUMBER")
	end

	local newTrackIndex = getNewTrackIndex()

	for i = 1, #curItemGroup do
		local track = EK_GetMediaTrackByGUID(curItemGroup[i].track_id)
		local item = EK_GetMediaItemByGUID(curItemGroup[i].item_id)

		reaper.InsertTrackAtIndex(newTrackIndex, false)
		local newTrack = reaper.GetTrack(proj, newTrackIndex)

		if reaper.MoveMediaItemToTrack(item, newTrack) then
			local _, trackName = reaper.GetTrackName(track)
			local trackColor = reaper.GetTrackColor(track)

			reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", trackName .. " (" .. i .. ")", true)
			reaper.SetMediaTrackInfo_Value(newTrack, "B_MUTE", 1)
			reaper.SetTrackColor(newTrack, trackColor)

			for j = 0, reaper.TrackFX_GetCount(track) do
				reaper.TrackFX_CopyToTrack(track, j, newTrack, j, false)
			end

			local newTrack_guid = reaper.GetTrackGUID(newTrack)

			items_map[index][i].track_id = newTrack_guid
		end

		newTrackIndex = newTrackIndex + 1
	end
end

local function isSnapPlaceBusyForItem(marker, item)
	if not marker or not item then return false end

	local startRange = marker.position
	local endRange = marker.position + item.length
	local track = EK_GetMediaTrackByGUID(item.track_id)

	for i = 0, reaper.CountTrackMediaItems(track) - 1 do
		local cur_item = reaper.GetTrackMediaItem(track, i)
		local startPosition = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
		local length = reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
		local endPosition = startPosition + length

		if not reaper.IsMediaItemSelected(cur_item) and (not (endPosition < startRange or startPosition > endRange)) and (not (startPosition == item.position and length == item.length)) then
			return true
		end
	end

	return false
end

local function CreateNewTrackForItem(item)
	reaper.InsertTrackAtIndex(cur_track_index, false)

	local track = reaper.GetMediaItemTrack(item)
	local newTrack = reaper.GetTrack(proj, cur_track_index)

	if reaper.MoveMediaItemToTrack(item, newTrack) then
		local _, trackName = reaper.GetTrackName(track)
		local trackColor = reaper.GetTrackColor(track)

		reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", trackName, true)
		reaper.SetMediaTrackInfo_Value(newTrack, "B_MUTE", 1)
		reaper.SetTrackColor(newTrack, trackColor)

		for j = 0, reaper.TrackFX_GetCount(track) do
			reaper.TrackFX_CopyToTrack(track, j, newTrack, j, false)
		end
	end

	cur_track_index = cur_track_index + 1
end

function FindNearestMarker(snap_to, position)
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	local prevMarker = { num = 0, position = 0, rgnend = 0, title = "" }
	local currentMarker = prevMarker

	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)

		if (snap_to == SNAP_TO_MARKERS and not isrgn) or (snap_to == SNAP_TO_REGIONS and isrgn) then
			currentMarker = {
				num = markrgnindexnumber,
				position = pos,
				rgnend = rgnend,
				title = name
			}

			if pos >= position then
				local prevDist = position - prevMarker.position
				local curDist = pos - position
				return curDist < prevDist and currentMarker or prevMarker
			end

			prevMarker = currentMarker
		end

		if i == (num_markers + num_regions - 1) then
			return currentMarker
		end
	end
end

local function GetItemOffset(type, item)
	if not item then return 0 end

	local take = reaper.GetActiveTake(item)

	if type == POSITION_SNAP_OFFSET then
		return reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
	elseif type == POSITION_FIRST_CUE and not reaper.TakeIsMIDI(take) then
		local source = reaper.GetMediaItemTake_Source(take)
		local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
		local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local ret = 1
		local relTime, time
		local index = 0

		while ret > 0 and not relTime do
			ret, time, _, _, _, _ = reaper.CF_EnumMediaSourceCues(source, index)
			if ret > 0 and time >= offset and time <= offset + length then
				relTime = time - offset
			end

			index = index + 1
		end

		return relTime or 0
	elseif type == POSITION_PEAK and not reaper.TakeIsMIDI(take) then
		local db = GetMaxPeakPosition(item)
		local threshold = 95 -- %
        local abs_percent = 10 ^ (db / 40)
        local rel_db = 40 * log10(abs_percent * (threshold / 100))
		local _, position = GetPeakThresholdPosition(item, rel_db)

		return position
	end

	return 0
end

local mIndex = 1
local iIndex = 1

local function HandleItemSnapping(item_data, markers, data, startIndex)
	local item = EK_GetMediaItemByGUID(item_data.item_id)
	local isMarkerAvailable = markers[mIndex] and (data.count_on_track.value == 0 or iIndex <= data.count_on_track.value)

	if not isMarkerAvailable then
		if data.ignore_when_unavailable.value then
			Log("End of avalible markers...", ek_log_levels.Important)
			return
		else
			Log("Marker #" .. mIndex .. " is not available...", ek_log_levels.Important)
			mIndex = startIndex
			iIndex = 1
		end
	end

	local isPlaceBusy = isSnapPlaceBusyForItem(markers[mIndex], item_data)
	local isMovingAvailable = not isPlaceBusy

	Log("================", ek_log_levels.Important)
	Log("ITEM: \"" .. reaper.GetTakeName(reaper.GetActiveTake(item)) .. "\" Marker index: " .. mIndex .. ", Item index: " .. iIndex, ek_log_levels.Important)
	Log("Busy: " .. tostring(isPlaceBusy) .. ", Available: " .. tostring(isMarkerAvailable), ek_log_levels.Important)

	if isPlaceBusy and not data.ignore_when_unavailable.value then
		Log("Is busy, new track creating...", ek_log_levels.Important)
		CreateNewTrackForItem(item)
		isMovingAvailable = true
	end

	if isMovingAvailable then
		local newPosition = markers[mIndex].position -  GetItemOffset(data.position.value, item)
		Log("Setting position: " .. markers[mIndex].position .. ", offset: " ..  GetItemOffset(data.position.value, item), ek_log_levels.Important)
		reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPosition)
		item_data.position = newPosition
	end

	mIndex = mIndex + 1
	iIndex = iIndex + 1
end

local function SnapItemsAsSingleType(markers, startIndex, items_map, data)
	mIndex = startIndex
	iIndex = 1

	for i = 1, #items_map do
		for j = 1, #items_map[i] do
			HandleItemSnapping(items_map[i][j], markers, data, startIndex)
		end
	end
end

local function SnapItemsAsStemType(markers, startIndex, items_map, data)
	local items_by_tracks = {}
	for i = 1, #items_map do
		for j = 1, #items_map[i] do
			if not items_by_tracks[items_map[i][j].track_id] then
				items_by_tracks[items_map[i][j].track_id] = {}
			end

			table.insert(items_by_tracks[items_map[i][j].track_id], items_map[i][j])
		end
	end

	for _, items in pairs(items_by_tracks) do
		mIndex = startIndex
		iIndex = 1

		for i = 1, #items do
			HandleItemSnapping(items[i], markers, data, startIndex)
		end
	end
end

local function SnapItemsAsOverlappedType(markers, startIndex, items_map, data)
	mIndex = startIndex
	iIndex = 1

	for i = 1, #items_map do
		local isMarkerAvailable = markers[mIndex] and (data.count_on_track.value == 0 or iIndex <= data.count_on_track.value)
		if not isMarkerAvailable then
			if data.ignore_when_unavailable.value then
				Log("End of avalible markers...", ek_log_levels.Important)
				goto end_snap_overlapped
			else
				Log("Marker #" .. mIndex .. " is not available...", ek_log_levels.Important)
				mIndex = startIndex
				iIndex = 1
			end
		end

		local isPlaceBusy = false
		for j = 1, #items_map[i] do
			if isSnapPlaceBusyForItem(markers[mIndex], items_map[i][j]) then
				isPlaceBusy = true
			end
		end

		local root_item = EK_GetMediaItemByGUID(items_map[i][1].item_id)
		local originalRootPosition = reaper.GetMediaItemInfo_Value(root_item, "D_POSITION")
		local newRootPosition

		for j = 1, #items_map[i] do
			local item = EK_GetMediaItemByGUID(items_map[i][j].item_id)
			local isMovingAvailable = not isPlaceBusy

			Log("================", ek_log_levels.Important)
			Log("ITEM: \"" .. reaper.GetTakeName(reaper.GetActiveTake(item)) .. "\" Marker index: " .. mIndex .. ", Item index: " .. iIndex, ek_log_levels.Important)
			Log("Busy: " .. tostring(isPlaceBusy) .. ", Available: " .. tostring(isMarkerAvailable), ek_log_levels.Important)

			if isPlaceBusy and not data.ignore_when_unavailable.value then
				Log("Is busy, new track creating...", ek_log_levels.Important)
				CreateNewTrackForItem(item)
				isMovingAvailable = true
			end

			if isMovingAvailable then
				local newPosition
				local offset = GetItemOffset(data.position.value, item)
				if j == 1 then
					newPosition = markers[mIndex].position - offset
					newRootPosition = newPosition
				else
					local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
					newPosition = position - (originalRootPosition - newRootPosition)
				end

				Log("Setting position: " .. newPosition .. ", offset: " .. offset, ek_log_levels.Important)
				reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPosition)
				items_map[i][j].position = newPosition
			end
		end

		mIndex = mIndex + 1
		iIndex = iIndex + 1
	end

	::end_snap_overlapped::
end

function SnapItems(snap_to, marker_num, data)
	local markers = GetMarkersOrRegions(snap_to)
	if isEmpty(markers) then
		EK_ShowTooltip(snap_to == SNAP_TO_MARKERS and "There is no any marker in the project." or "There is no any region in the project.")
		return
	end

	local count_sel_items = reaper.CountSelectedMediaItems(proj)
    if count_sel_items == 0 then
        EK_ShowTooltip("There is no any selected item.")
		return
    end

	local startIndex = FindIndexByMarkerNumber(markers, marker_num)
	if startIndex == nil then
		EK_ShowTooltip("Please enter correct number of marker.")
		return
	end

	local items_map = EK_GetSelectedItemsAsGroupedStems()
	if isEmpty(items_map) then
		EK_ShowTooltip("There is no any selected item.")
		return
	end

	for i = 0, count_sel_items - 1 do
		local item = reaper.GetSelectedMediaItem(proj, i)
		local track = reaper.GetMediaItemTrack(item)
		local track_num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

		if track_num > cur_track_index then
			cur_track_index = track_num
		end
	end

	Log("Snapping to #" .. marker_num .. " (" .. startIndex .. "), " .. data.count_on_track.value, ek_log_levels.Important)

	if data.behaviour.value == BEHAVIOUR_TYPE_SINGLE then
		SnapItemsAsSingleType(markers, startIndex, items_map, data)
	elseif data.behaviour.value == BEHAVIOUR_TYPE_STEM then
		SnapItemsAsStemType(markers, startIndex, items_map, data)
	elseif data.behaviour.value == BEHAVIOUR_TYPE_OVERLAPPED then
		SnapItemsAsOverlappedType(markers, startIndex, items_map, data)
	end
end
