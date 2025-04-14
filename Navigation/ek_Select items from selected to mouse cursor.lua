-- @description ek_Select items from selected to mouse cursor
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script extends selection of items from selected to mouse cursor. As usual this action attaches in mouse modifiers on media item section
-- @changelog
--   Support of core dat-files

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

if not CoreLibraryLoad("corebg") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Global startup action")
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