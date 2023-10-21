-- @description ek_Tracks collapser
-- @author Ed Kashinsky
-- @noindex

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded("ek_Core functions.lua")
if not loaded then
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not reaper.APIExists("JS_ReaScriptAPI_Version") then
	local answer = reaper.MB("You have to install JS_ReaScriptAPI for this script to work. Would you like to open the relative web page in your browser?", "JS_ReaScriptAPI not installed", 4 )

	if answer == 6 then reaper.CF_ShellExecute("https://forum.cockos.com/showthread.php?t=212174") end

	return reaper.defer(function() end)
end

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

	local _, id = reaper.GetSetMediaTrackInfo_String(track, "GUID", "", false)
	local current_id = EK_GetExtState(key_last_height .. ":" .. id, 2)
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