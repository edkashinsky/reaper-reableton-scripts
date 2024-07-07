-- @author Ed Kashinsky
-- @noindex

local items_map = {}

function GetMarkers()
	local markers = {}
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	
	-- collect only markers
	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, _, _, markrgnindexnumber = reaper.EnumProjectMarkers(i)
		
		if isrgn == false then
			table.insert(markers, {
				num = markrgnindexnumber,
				position = pos
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

function FindNearestMarkerNum(position)
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	local prevMarkerNum = 0
	local prevMarkerPos = 0

	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, _, _, markrgnindexnumber = reaper.EnumProjectMarkers(i)

		if isrgn == false then
			if pos > position then
				local prevDist = position - prevMarkerPos
				local curDist = pos - position
				return curDist < prevDist and markrgnindexnumber or prevMarkerNum
			end

			if i == num_markers + num_regions - 1 then
				return markrgnindexnumber
			end

			prevMarkerNum = markrgnindexnumber
			prevMarkerPos = pos
		end
	end
end

function PinItems(marker_num, save_relative_position, items_on_track)
	local markers = GetMarkers()
	local startIndex = FindIndexByMarkerNumber(markers, marker_num)

	if startIndex == nil then
		EK_ShowTooltip("Please enter correct number of marker.")
		return
	end

	items_map = EK_GetSelectedItemsAsGroupedStems()

	local curIndex = startIndex

	for i = 1, #items_map do
		local position

		if not markers[curIndex] or (items_on_track and i > items_on_track) then
			for j = i, #items_map do
				CreateNewTracksForItemsGroup(j)
			end
			curIndex = startIndex
		end

		if save_relative_position then
			local markerPosition = markers[curIndex].position
			local minPosition = GetMinPosition(items_map[i])
			local deltaPosition = markerPosition > minPosition and markerPosition - minPosition or minPosition - markerPosition

			position = markerPosition > minPosition and deltaPosition or -deltaPosition
		else
			position = markers[curIndex].position
		end

		for j = 1, #items_map[i] do
			local item = EK_GetMediaItemByGUID(items_map[i][j].item_id)

			if item ~= nil then
				local newPosition

				if save_relative_position then
					newPosition = items_map[i][j].position + position
				else
					newPosition = position
				end

				newPosition = newPosition - items_map[i][j].offset

				reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPosition)
			end
		end

		curIndex = curIndex + 1
	end
end
