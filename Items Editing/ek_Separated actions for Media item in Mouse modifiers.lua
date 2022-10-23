-- @description ek_Separated actions for Media item in Mouse modifiers
-- @version 1.0.5
-- @author Ed Kashinsky
-- @about
--   This script gives opportunity to attach 2 different actions on Media item context in Mouse modifiers - when we click on header of media item and part between header and middle of it.
--   For installation open "Mouse Modifiers" preferences, find "Media item" context and select this script in any section. Also you can copy this script and use it in different hotkey-sections and actions.
-- @changelog
--   Bug fixes: script follows to "Draw labels above the item, rather than within the item" setting

if not reaper.APIExists("JS_ReaScriptAPI_Version") then
	local answer = reaper.MB("You have to install JS_ReaScriptAPI for this script to work. Would you like to open the relative web page in your browser?", "JS_ReaScriptAPI not installed", 4 )

	if answer == 6 then reaper.CF_ShellExecute("https://forum.cockos.com/showthread.php?t=212174") end

	return reaper.defer(function() end)
end

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
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

local _, _, _, cmdID, _, _, _ = reaper.get_action_context()
local hKey_id = "separated_actions_cmd_h:"
local tKey_id = "separated_actions_cmd_t:"

local header_cmd_id = EK_GetExtState(hKey_id .. cmdID)
local item_cmd_id = EK_GetExtState(tKey_id .. cmdID)

local MainHwnd = reaper.GetMainHwnd()
local ArrangeHwnd = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
local x, y = reaper.GetMousePosition()
local _, ry = reaper.JS_Window_ScreenToClient(ArrangeHwnd, x, y)

local headerHeight = 16
local headerShowingLimit = 40
local item, _ = reaper.GetItemFromPoint(x, y, true)
local isSettingsNeeded = not item and reaper.JS_Window_GetFocus() ~= ArrangeHwnd

if gfx.ext_retina == 1 then
	headerHeight = headerHeight * 2
	headerShowingLimit = 70
end

if (not header_cmd_id and not item_cmd_id) or isSettingsNeeded then
	local isAnyActionSet = false
	local result = EK_AskUser("Enter command ids for media item click", {
		{"CmdID for media item header", header_cmd_id},
		{"CmdID for top of media item", item_cmd_id}
	})

	if result then
		if result[1] and reaper.NamedCommandLookup(result[1]) then
			EK_SetExtState(hKey_id .. cmdID, result[1])
			isAnyActionSet = true
		else
			EK_DeleteExtState(hKey_id .. cmdID)
		end

		if result[2] and reaper.NamedCommandLookup(result[2]) then
			EK_SetExtState(tKey_id .. cmdID, result[2])
			isAnyActionSet = true
		else
			EK_DeleteExtState(tKey_id .. cmdID)
		end

		if isAnyActionSet then
			reaper.MB("Action(s) has set, please use this action in Mouse modifiers on \"Media item\" context. If you want to change settings, execute this script in action list.", "Separated actions for top of item", 0)
		end
	end

	return
end

if not item then return end

local track = reaper.GetMediaItem_Track(item)
local track_y = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") + GetItemHeaderHeight(item)

if ry < track_y then
	-- Clicked on header
	if header_cmd_id then reaper.Main_OnCommand(reaper.NamedCommandLookup(header_cmd_id), 0) end
else
	-- Clicked on media item
	if item_cmd_id then reaper.Main_OnCommand(reaper.NamedCommandLookup(item_cmd_id), 0) end
end

