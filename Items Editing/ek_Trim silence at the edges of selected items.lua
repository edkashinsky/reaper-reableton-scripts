-- @description ek_Trim silence edges for selected items
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.
--
--   Also it provides UI for configuration
-- @provides
--   ../Core/ek_Triming silence edges functions.lua

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
	if loaded == nil then  reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

CoreFunctionsLoaded("ek_Triming silence edges functions.lua")

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
local original_values = {}

local function preview_result()
    if getTsParamValue(tsParams.preview_result) ~= 1 then return end

    -- Log("show preview\n")
end

local function reset_preview()
    -- Log("reset preview\n")
end

local function detect_original_values()
    for i = 0, countSelectedItems - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)
        local take = reaper.GetActiveTake(item)

        if take ~= nil then
            table.insert(original_values, {
                reaper.GetMediaItemInfo_Value(item, "D_POSITION"),
                reaper.GetMediaItemInfo_Value(item, "D_LENGTH"),
                reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS"),
                reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN"),
                reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
            })
        end
    end
end

local function trimSilenceResult()
    reaper.Undo_BeginBlock()

    local leadingThreshold = getTsParamValue(tsParams.leading.threshold)
    local leadingPad = getTsParamValue(tsParams.leading.pad)
    local leadingFade = getTsParamValue(tsParams.leading.fade)
    local trailingThreshold = getTsParamValue(tsParams.trailing.threshold)
    local trailingPad = getTsParamValue(tsParams.trailing.pad)
    local trailingFade = getTsParamValue(tsParams.trailing.fade)

    Log("== Leading edge ==")
    Log("Threshold: " .. leadingThreshold .. "db")
    Log("Pad: " .. leadingPad .. "s")
    Log("Fade: " .. leadingFade .. "s")
    Log("== Trailing edge ==")
    Log("Threshold: " .. trailingThreshold .. "db")
    Log("Pad: " .. trailingPad .. "s")
    Log("Fade: " .. trailingFade .. "s")

    for i = 0, countSelectedItems - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)

        local take = reaper.GetActiveTake(item)

        if take ~= nil then
            local startTime = getStartPositionLouderThenThreshold(take, leadingThreshold)

            if startTime > 0 then
                trimLeadingPosition(take, startTime)
            end

            local endTime = getEndPositionLouderThenThreshold(take, trailingThreshold)
            if endTime > 0 then
                trimTrailingPosition(take, endTime)
            end
        end
    end

    reaper.UpdateArrange()

  reaper.Undo_EndBlock("Trim silence edges for selected items (no prompt)", -1)
end

function frame()
    local r, curVal, newVal

    --
    -- Leading part
    --
    GUI_DrawText('Leading edge:', GUI_GetFont(gui_font_types.Bold))
    curVal = getTsParamValue(tsParams.leading.threshold)
    r, newVal = reaper.ImGui_SliderDouble(GUI_GetCtx(), 'Threshold In', curVal, -70, 0, '%.1fdb', slider_flags)
    if curVal ~= newVal then
        preview_result()
        setTsParamValue(tsParams.leading.threshold, newVal)
    end

    curVal = getTsParamValue(tsParams.leading.pad)
    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Pad In', curVal, 0.01, 0, nil, '%.2fs')
    if curVal ~= newVal then
        preview_result()
        setTsParamValue(tsParams.leading.pad, newVal)
    end

    curVal = getTsParamValue(tsParams.leading.fade)
    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Fade In', curVal, 0.01, 0, nil, '%.2fs')
    if curVal ~= newVal then
        preview_result()
        setTsParamValue(tsParams.leading.fade, newVal)
    end

    --
    -- Trailing part
    --
    GUI_DrawGap()
    GUI_DrawText('Trailing edge:', GUI_GetFont(gui_font_types.Bold))

    curVal = getTsParamValue(tsParams.trailing.threshold)
    r, newVal = reaper.ImGui_SliderDouble(GUI_GetCtx(), 'Threshold Out', curVal, -70, 0, '%.1fdb', slider_flags)
    if curVal ~= newVal then
        preview_result()
        setTsParamValue(tsParams.trailing.threshold, newVal)
    end

    curVal = getTsParamValue(tsParams.trailing.pad)
    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Pad Out', curVal, 0.01, 0, nil, '%.2fs')
    if curVal ~= newVal then
        preview_result()
        setTsParamValue(tsParams.trailing.pad, newVal)
    end

    curVal = getTsParamValue(tsParams.trailing.fade)
    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Fade Out', curVal, 0.01, 0, nil, '%.2fs')
    if curVal ~= newVal then
        preview_result()
        setTsParamValue(tsParams.trailing.fade, newVal)
    end

    --curVal = getTsParamValue(tsParams.preview_result)
    --r, newVal = reaper.ImGui_Checkbox(GUI_GetCtx(), 'Preview Result', curVal == 1)
    --newVal = newVal and 1 or 0
    --
    --if curVal ~= newVal then
    --    setTsParamValue(tsParams.preview_result, newVal)
    --
    --    if newVal == 1 then
    --        preview_result()
    --    else
    --        reset_preview()
    --    end
    --end

    GUI_DrawGap()
    reaper.ImGui_Indent(GUI_GetCtx(), 60)

    GUI_DrawButton('Trim silence', function()
        trimSilenceResult()
    end)

    reaper.ImGui_SameLine(GUI_GetCtx())

    GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

if countSelectedItems > 0 then
    detect_original_values()
    GUI_ShowMainWindow(330, 300)
    preview_result()
end

function GUI_OnWindowClose()
    if save_changes == false then
        reset_preview()
    end
end

