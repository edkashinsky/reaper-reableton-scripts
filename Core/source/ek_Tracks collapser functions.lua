-- @description ek_Tracks collapser
-- @author Ed Kashinsky
-- @noindex

local key_last_height = "tc_last_height"
local key = "tc_config"
heights = {
	{ key = key .. 1, val = EK_GetExtState(key .. 1, 20) },
	{ key = key .. 2, val = EK_GetExtState(key .. 2, 100) },
	{ key = key .. 3, val = EK_GetExtState(key .. 3, 250) },
}
tinyChildrenState = 2
local height_not_set = EK_GetExtState(heights[1].key) == nil

local window, _, _ = reaper.BR_GetMouseCursorContext()
if window == "transport" or height_not_set then
	EK_AskUser("Tracks collapser settings", {
		{ "Collapsed height", heights[1].val },
		{ "Standart height", heights[2].val },
		{ "Expand height", heights[3].val },
	}, function(result)
		if not result then return end

		if result[1] and tonumber(result[1]) > 0 then EK_SetExtState(heights[1].key, tonumber(result[1])) end
		if result[2] and tonumber(result[2]) > 0 then EK_SetExtState(heights[2].key, tonumber(result[2])) end
		if result[3] and tonumber(result[3]) > 0 then EK_SetExtState(heights[3].key, tonumber(result[3])) end

		if height_not_set then
			reaper.MB("Heights has been saved. If you want to change them, please execute this script on transport panel.", "Tracks collapser settings", 0)
		end
		return
	end)

	return
end

function GetHeightData(track, for_collapse)
	if not track then return 0 end

	local current_id
	local height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")

	for i = 1, #heights do
		if height <= heights[i].val then
			current_id = i
			break
		end
	end

	if not current_id then current_id = #heights end

	local new_id = current_id

	if for_collapse then new_id = new_id - 1
	else new_id = new_id + 1 end

	if not heights[new_id] then new_id = current_id end

	return current_id, new_id
end

function SetLastHeightId(track, value)
	if not track then return end

	local _, id = reaper.GetSetMediaTrackInfo_String(track, "GUID", "", false)
	EK_SetExtState(key_last_height .. ":" .. id, value, false, true)
end

function GetLanesStatus(track)
	if true then return false, false end

	local _, str = reaper.GetTrackStateChunk(track, "", false)

	local settings = string.sub(str, 7, string.find(str, "\n<"))
	for v1, v2, v3 in string.gmatch(settings or "", "FIXEDLANES (%w+) (%w+) (%w+)\n") do
		local isLanesEnabled = tonumber(v1) & 4 > 0
		local isLanesOpen = tonumber(v1) & 8 > 0

		return isLanesEnabled, isLanesOpen
	end

	return false, false
end

function SetEnvelopeHeight(envelope, height)
	local _, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)

	for _, val in string.gmatch(chunk, "LANEHEIGHT (%w+) (%w+)\n") do
		chunk = string.gsub(chunk, "LANEHEIGHT (%w+) (%w+)\n", "LANEHEIGHT " .. height .. " " .. val .. "\n")
	end

	reaper.SetEnvelopeStateChunk(envelope, chunk, false)
end