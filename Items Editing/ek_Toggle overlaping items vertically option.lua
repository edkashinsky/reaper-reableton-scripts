-- @description ek_Toggle overlaping items vertically option
-- @version 1.0.2
-- @author Ed Kashinsky
-- @about
--   This script toggles option of editing multiple items on one track at the same time
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

local commandId = 40507 -- Options: Offset overlapping media items vertically

reaper.Main_OnCommand(commandId, 0)

local state = reaper.GetToggleCommandState(commandId)
local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

if state == 1 then
    reaper.Main_OnCommand(reaper.NamedCommandLookup(41121), 0) -- Options: Disable trim content behind media items when editing
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_XFDOFF"), 0) -- SWS: Set auto crossfade off
else
    reaper.Main_OnCommand(reaper.NamedCommandLookup(41120), 0) -- Options: Enable trim content behind media items when editing
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_XFDON"), 0) -- SWS: Set auto crossfade on
end

reaper.SetToggleCommandState(sectionID, cmdID, state)
GA_SetButtonForHighlight(ga_highlight_buttons.overlaping_items_vertically, sectionID, cmdID)
