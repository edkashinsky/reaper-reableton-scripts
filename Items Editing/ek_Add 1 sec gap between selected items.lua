-- @description ek_Add 1 sec gap between selected items
-- @version 1.1.0
-- @author Ed Kashinsky
-- @about
--   <img src="/Assets/images/add_gap_between_items.gif" alt="add_gap_between_items" width="500"/>
--
--   Script adds 1 second gap between selected items. Press CMD/CTRL to add 0.1 seconds gap.
-- @changelog
--   - small bug fix

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

reaper.Undo_BeginBlock()

local gap = 1
local stems = EK_GetSelectedItemsAsGroupedStems()

-- ctrl/cmd is pressed (smoother changes)
if reaper.JS_Mouse_GetState(4) > 0 then
	gap = 0.1
end

local function add_gap()
	for i = 2, #stems do
		for j = 1, #stems[i] do
			local item = EK_GetMediaItemByGUID(stems[i][j].item_id)

			if item ~= nil then
				reaper.SetMediaItemInfo_Value(item, "D_POSITION", stems[i][j].position + (gap * (i - 1)))
			end
		end
	end
end

if #stems > 1 then
	add_gap()
	reaper.UpdateArrange()
else
	EK_ShowTooltip("Select 2 separated items at least")
end

reaper.Undo_EndBlock("Add 1 sec gap between selected items", -1)