-- @description ek_Decrease pitch or rate for selected items
-- @version 1.0.4
-- @author Ed Kashinsky
-- @about
--   This script decreases pitch or rate of selected items depending on "Preserve Pitch" option.
--
--   If option is on, script decreases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)
--
--   If you hold special keys with mouse click, you get additional opportunities
--
--   Hotkeys:
--      - CMD/CTRL: Adjusting by 0.1 semitone (and 1 semitone without hotkey)
--      - SHIFT: You can enter absolute value for pitch
-- @changelog
--   - Now you can enter absolute pitch value by clicking on button + pressing Shift key. Also press Cmd/Ctrl for smoothing changes

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded()
if not loaded then
	if loaded == nil then  reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

reaper.Undo_BeginBlock()

local proj = 0
local delta = -1
local isDelta = true
local count_selected_items = reaper.CountSelectedMediaItems(proj)

if count_selected_items == 0 then return end

-- ctrl/cmd is pressed (smoother changes)
if reaper.JS_Mouse_GetState(4) > 0 then
	delta = -0.1
end

-- Shift is pressed (enter value)
if reaper.JS_Mouse_GetState(8) > 0 then
	local result = EK_AskUser("Pitch Adjustment", {
		{"Enter value for pitch (in semitones):", "" }
	})

	if not result or not result[1] then return end

	delta = tonumber(result[1])
	if not delta then return end

	delta = -math.abs(delta)
	isDelta = false
end

for i = 0, count_selected_items - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

	local itemTake = reaper.GetMediaItemTake(item, takeInd)
	local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "B_PPITCH")

	changePitchForTake(itemTake, delta, mode == 1, isDelta)
end

reaper.Undo_EndBlock("Decrease Pitch or Rate", -1)