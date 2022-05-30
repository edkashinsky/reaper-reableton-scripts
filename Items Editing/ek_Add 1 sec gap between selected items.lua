-- @description ek_Add 1 sec gap between selected items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Script just adds 1 second gap between selected items without any GUI
-- @changelog
--   - Fixed for toolbar on Windows

reaper.Undo_BeginBlock()

local proj = 0
local gap = 1
local count = reaper.CountSelectedMediaItems(proj)

local function add_gap()
	local tracks = {}
	
	-- group items by tracks
	for i = 0, count - 1 do
		local item = reaper.GetSelectedMediaItem(proj, i)
		local i_id = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")
		
		local track = reaper.GetMediaItemTrack(item)
		local t_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
		
		if tracks[t_id] == nil then
			tracks[t_id] = {}
		end
		
		table.insert(tracks[t_id], i_id)
	end
	
	for t_id, i_ids in pairs(tracks) do 
		local track = reaper.GetTrack(proj, t_id - 1)
		
		for i = #i_ids, 2, -1 do
			local item = reaper.GetTrackMediaItem(track, i_ids[i])
			
			local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	 		reaper.SetMediaItemPosition(item, position + (gap * (i - 1)), i == 0)
		end
	end
end

if count > 1 then
	add_gap()
	reaper.UpdateArrange()
else
	local x, y = reaper.GetMousePosition()

	if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
		x = x - 30
		y = y + 50
	end

	reaper.TrackCtl_SetToolTip("Select 2 items at least", x, y, true)
end

reaper.Undo_EndBlock("Add 1 sec gap between selected items", -1)