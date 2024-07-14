-- @description ek_Separated actions for Media item in Mouse modifiers
-- @version 1.1.3
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   This script gives opportunity to attach 2 different actions on Media item context in Mouse modifiers - when we click on header of media item and part between header and middle of it.
--   For installation open "Mouse Modifiers" preferences, find "Media item" context and select this script in any section. Also you can copy this script and use it in different hotkey-sections and actions.
--   Script works in workflows depends on option "Draw labels above the item when media item height is more than":
--		- If option enabled, header label is positioned above the item and "header part" calculates as 1/4 of the upper part of the item
--      - If option disabled, header label is positioned on item and header part calculates as header label height
-- @changelog
--   Script monitors media item label font size and UI scale as well

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

local function GetMediaItemFontData()
    -- GET MEDIA ITEM LABEL FONT FROM COLORTHEME_FILE OR REAPER.INI
    local inipath = reaper.get_ini_file()
    local mi_font
    local _, lasttheme = reaper.BR_Win32_GetPrivateProfileString("reaper", "lastthemefn5", "Error", inipath)
    if lasttheme == "*unsaved*" then
        _, mi_font = reaper.BR_Win32_GetPrivateProfileString("reaper", "mi_font", "Error", inipath)
    else
        local theme = reaper.GetLastColorThemeFile()
        _, mi_font = reaper.BR_Win32_GetPrivateProfileString("reaper", "mi_font", "Error", theme)
        if mi_font == "Error" then
            local ext = theme:find("(.-)%Zip")
            if not ext then
                theme = theme .. "Zip"
            end
            local zip, _ = reaper.JS_Zip_Open(theme, 'r', 6)
            local _, ent_str = reaper.JS_Zip_ListAllEntries(zip)
            local file_name
            for name in ent_str:gmatch("[^\0]+") do
                local file = name:match("(.-)%.ReaperTheme$")
                if file then
                    file_name = name
                    break
                end
            end
            reaper.JS_Zip_Entry_OpenByName(zip, file_name)
            local _, contents = reaper.JS_Zip_Entry_ExtractToMemory(zip)
            mi_font = string.match(tostring(contents), "mi_font=(%x*)")
            reaper.JS_Zip_Entry_Close(zip)
            reaper.JS_Zip_Close(theme)
        end
    end

    mi_font = mi_font:gsub(('[A-F0-9]'):rep(2), function(byte)
        return string.char(tonumber(byte, 16))
    end)

    return ('iiiiibbbbbbbbc32'):unpack(mi_font)
end

local function GetLabelHeight()
    local scale = reaper.SNM_GetDoubleConfigVar("uiscale", 1)
    local font_size, width, escapement, orientation, weight, italic, underline, strike_out,
    charset, out_precision, clip_precision, quality, pitch_and_family, facename = GetMediaItemFontData()

    -- GFX TEXT MEASUREMENT --
    local flags = ''
    if weight > 649 then flags = 'b' end
    if italic == -1 then flags = flags .. 'i' end
    if underline == -1 then flags = flags .. 'u' end

    local function fontflags(str)
        local v = 0
        for a = 1, str:len() do v = v * 256 + string.byte(str, a) end
        return v
    end

    -- Trying to draw debug text and measure how much size it takes
    -- + 1 - it's compensation for padding
    gfx.setfont(1, facename, font_size + 1, fontflags(flags))
    local _, height = gfx.measurestr("QWj_09")

    return height * scale
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
local item, _ = reaper.GetItemFromPoint(x, y, true)
local isSettingsNeeded = not item and reaper.JS_Window_GetFocus() ~= ArrangeHwnd

if (not header_cmd_id and not item_cmd_id) or isSettingsNeeded then
	local isAnyActionSet = false
	EK_AskUser("Enter command ids for media item click", {
		{"CmdID for media item header", header_cmd_id},
		{"CmdID for top of media item", item_cmd_id}
	}, function(result)
		if not result then return end

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
	end)

	return
end

if not item then return end

local track = reaper.GetMediaItem_Track(item)
local track_y = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") + reaper.GetMediaItemInfo_Value(item, "I_LASTY")

if GetItemHeaderHeight(item) == 0 then
	-- "Draw labels above the item when media item height is more than" is disabled
	-- Click on header
    local height_key = "separate_actions_label_height"
    local height = EK_GetExtState(height_key)
    if not height then
        height = GetLabelHeight()
        EK_SetExtState(height_key, height, false, true)
    end

	track_y = track_y + height
else
	-- "Draw labels above the item when media item height is more than" is enabled
	-- Click on 1/4 up part of item
	track_y = track_y + (reaper.GetMediaItemInfo_Value(item, "I_LASTH") / 4)
end

if ry < track_y then
	-- Clicked on header
	if header_cmd_id then reaper.Main_OnCommand(reaper.NamedCommandLookup(header_cmd_id), 0) end
else
	-- Clicked on media item
	if item_cmd_id then reaper.Main_OnCommand(reaper.NamedCommandLookup(item_cmd_id), 0) end
end

