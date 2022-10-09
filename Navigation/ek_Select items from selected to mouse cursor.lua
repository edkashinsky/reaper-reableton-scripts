-- @description ek_Select items from selected to mouse cursor
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script extends selection of items from selected to mouse cursor. As usual this action attaches in mouse modifiers on media item section

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded("ek_Core functions.lua")
if not loaded then
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not CoreFunctionsLoaded("ek_Core functions startup.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

reaper.Undo_BeginBlock()

local current_s_item = reaper.GetSelectedMediaItem(proj, 0)
local prev_s_item = getDfiItem()

if not current_s_item or not prev_s_item then return end

local c_track = reaper.GetMediaItemInfo_Value(current_s_item, "P_TRACK")
local c_track_ind = reaper.GetMediaTrackInfo_Value(c_track, "IP_TRACKNUMBER")
local c_position = reaper.GetMediaItemInfo_Value(current_s_item, "D_POSITION")
local c_length = reaper.GetMediaItemInfo_Value(current_s_item, "D_LENGTH")

local p_track = reaper.GetMediaItemInfo_Value(prev_s_item, "P_TRACK")
local p_track_ind = reaper.GetMediaTrackInfo_Value(p_track, "IP_TRACKNUMBER")
local p_position = reaper.GetMediaItemInfo_Value(prev_s_item, "D_POSITION")
local p_length = reaper.GetMediaItemInfo_Value(prev_s_item, "D_LENGTH")

local start = c_track_ind > p_track_ind and p_track_ind or c_track_ind
local finish = c_track_ind > p_track_ind and c_track_ind or p_track_ind
local start_position = c_position > p_position and p_position or c_position
local finish_position = c_position + c_length > p_position + p_length and c_position + c_length or p_position + p_length

for i = start - 1, finish - 1 do
	local track = reaper.GetTrack(proj, i)

	for j = 0, reaper.GetTrackNumMediaItems(track) - 1 do
		local item = reaper.GetTrackMediaItem(track, j)
		local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

		reaper.SetMediaItemSelected(item, position >= start_position and position + length <= finish_position)
	end
end

reaper.Undo_EndBlock("Select items from selected to mouse cursor", -1)