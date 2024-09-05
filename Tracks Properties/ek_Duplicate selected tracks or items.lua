-- @description ek_Duplicate selected tracks or items
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   If any item is selected, it duplicate item. In other case is duplicate track
-- @changelog
--   If there is some razor edit, it will be duplicated

reaper.Undo_BeginBlock()

local proj = 0
local countSelectedItems = reaper.CountSelectedMediaItems(proj)

local function HasAnyRazorEdit()
    for i = 0, reaper.CountTracks(proj) - 1 do
	    local track = reaper.GetTrack(proj, i)
	    local _, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

        if string.len(razorStr) > 0 then return true end
    end

    return false
end

if HasAnyRazorEdit() then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(41296), 0) -- Item: Duplicate selected area of items
elseif countSelectedItems > 0 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup(41295), 0) -- Item: Duplicate items
else
	reaper.Main_OnCommand(reaper.NamedCommandLookup(40062), 0) -- Track: Duplicate tracks
end

reaper.Undo_EndBlock("Duplicate selected tracks or items", -1)