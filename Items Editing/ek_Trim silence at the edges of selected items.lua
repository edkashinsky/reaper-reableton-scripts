-- @description ek_Trim silence edges for selected items
-- @version 1.1.1
-- @author Ed Kashinsky
-- @about
--   This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.
--
--   Also it provides UI for configuration
-- @changelog
--   - Small fixes
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

local p_l_threshold = getTsParamValue(tsParams.leading.threshold)
local p_l_pad = getTsParamValue(tsParams.leading.pad)
local p_l_fade = getTsParamValue(tsParams.leading.fade)
local p_t_threshold = getTsParamValue(tsParams.trailing.threshold)
local p_t_pad = getTsParamValue(tsParams.trailing.pad)
local p_t_fade = getTsParamValue(tsParams.trailing.fade)
local p_preview = getTsParamValue(tsParams.preview_result)

local cachedPositions = {
    leading = {},
    trailing = {},
}

local function getEdgePositionsByItem(item)
    if not item then return end

    local take = reaper.GetActiveTake(item)
    local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)

    if not take or not guid then return end

    local startTime, endTime

    if cachedPositions.leading[guid] and cachedPositions.leading[guid].threshold == p_l_threshold then
        startTime = cachedPositions.leading[guid].position
    else
        startTime = getStartPositionLouderThenThreshold(take, p_l_threshold)
        cachedPositions.leading[guid] = { threshold = p_l_threshold, position = startTime }
    end

    if cachedPositions.trailing[guid] and cachedPositions.trailing[guid].threshold == p_t_threshold then
        endTime = cachedPositions.trailing[guid].position
    else
        endTime = getEndPositionLouderThenThreshold(take, p_t_threshold)
        cachedPositions.trailing[guid] = { threshold = p_t_threshold, position = endTime }
    end

    return startTime, endTime
end

local function _f(value)
    return math.floor(value)
end

local function _drawVerticalLine(bitmap, x, height, color)
    reaper.JS_LICE_Line(bitmap, _f(x), 0, _f(x), _f(height), color, 1, "", true)
end

local bm = {
    leading = { maps = {}, color = ek_colors.Red },
    trailing = { maps = {}, color = ek_colors.Blue },
}

local function clearBitmap(map, ind)
    if map.maps[ind] then
        reaper.JS_LICE_DestroyBitmap(map.maps[ind])
    end
end

local function reset_preview()
    for _, maps in pairs(bm) do
        for i, map in pairs(maps.maps) do
            clearBitmap(maps, i)
        end
    end
end

local function updateBitmapIfNeeded(map, ind, width, height)
    local needToUpdate = false

    if not map.maps[ind] then
        needToUpdate = true
    else
        local w = reaper.JS_LICE_GetWidth(map.maps[ind])
        local h = reaper.JS_LICE_GetHeight(map.maps[ind])

        needToUpdate = w ~= width or h ~= height
    end

    if needToUpdate then
        clearBitmap(map, ind)
        map.maps[ind] = reaper.JS_LICE_CreateBitmap(true, math.floor(width), math.floor(height))
        -- reaper.JS_LICE_Clear(map.maps[ind], ek_colors.Red)
    end

    return map.maps[ind]
end

local MainHwnd = reaper.GetMainHwnd()
local ArrangeHwnd = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)

local headerHeight = 16
if gfx.ext_retina == 1 then headerHeight = headerHeight * 2 end
local min_start = 0.0001

local function preview_result()
    local zoom = reaper.GetHZoomLevel()
    local _, scrollposh = reaper.JS_Window_GetScrollInfo(ArrangeHwnd, "h")

    for i = 0, reaper.CountMediaItems(proj) - 1 do
        local item = reaper.GetMediaItem(proj, i)

        if reaper.IsMediaItemSelected(item) then
            local track = reaper.GetMediaItem_Track(item)
            local item_height = reaper.GetMediaItemInfo_Value(item, "I_LASTH")
            local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local startTime, endTime = getEdgePositionsByItem(item)

            local item_offset_x = (position * zoom) - scrollposh
            local item_offset_y = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") + headerHeight
            local item_length_px = item_length * zoom

            ------------- LEADING PART --------------

            local l_threshold = startTime * zoom
            local l_pad = l_threshold - (p_l_pad * zoom)
            local l_fade_start = l_pad
            local l_fade_end = l_fade_start + (p_l_fade * zoom)

            if l_threshold < min_start then l_threshold = 0 end
            if l_pad < min_start then l_pad = 0 end
            if l_fade_start < min_start then l_fade_start = 0 end
            if l_fade_end < min_start then l_fade_end = 0 end
            if l_fade_end > item_length_px then l_fade_end = item_length_px end

            local l_bm_width = math.max(l_threshold, l_fade_end)
            local l_bm_height = item_height

            l_bm_width = l_bm_width + 2

            if p_preview == 1 and startTime > min_start and startTime < item_length then
                local bitmap = updateBitmapIfNeeded(bm.leading, i, l_bm_width, l_bm_height)

                -- reaper.ShowConsoleMsg(l_pad .. " " .. l_bm_width .. " " .. l_bm_height .. "\n")

                -- threshold line
                _drawVerticalLine(bitmap, l_threshold, item_height, ek_colors.Blue)

                -- pad line
                if l_pad > 0 and p_l_pad > 0 then _drawVerticalLine(bitmap, l_pad, item_height, ek_colors.Red) end

                -- fade line
                if p_l_fade > 0 and l_fade_start > 0 then
                    reaper.JS_LICE_Line(bitmap, l_fade_start, item_height, l_fade_end, 0, ek_colors.Green, 1, "", true)
                end

                reaper.JS_Composite(ArrangeHwnd, _f(item_offset_x), _f(item_offset_y), _f(l_bm_width), _f(l_bm_height), bitmap, 0, 0, _f(l_bm_width), _f(l_bm_height), true)
            else
                clearBitmap(bm.leading, i)
            end

            ------------- TRAILING PART --------------

            local t_threshold = endTime * zoom
            local t_pad = t_threshold + (p_t_pad * zoom)
            local t_fade_end = t_pad
            local t_fade_start = t_fade_end - (p_t_fade * zoom)


            if t_threshold < min_start then t_threshold = 0 end
            if t_pad < min_start then t_pad = 0 end
            if t_pad > item_length_px then t_pad = item_length_px end
            if t_fade_start < min_start then t_fade_start = 0 end
            if t_fade_end > item_length_px then t_fade_end = item_length_px end

            local t_bm_width = math.max(t_threshold, t_fade_end, t_pad)
            local t_bm_height = item_height

            t_bm_width = t_bm_width + 2

            if p_preview == 1 and endTime > min_start and endTime < item_length then
                local bitmap = updateBitmapIfNeeded(bm.trailing, i, t_bm_width, t_bm_height)

                -- threshold line
                _drawVerticalLine(bitmap, t_threshold, item_height, ek_colors.Blue)

                -- pad line
                if t_pad < item_length_px and p_t_pad > 0 then _drawVerticalLine(bitmap, t_pad, item_height, ek_colors.Red) end

                -- fade line
                if p_t_fade > 0 and t_fade_end < item_length_px then
                    reaper.JS_LICE_Line(bitmap, t_fade_start, 0, t_fade_end, item_height, ek_colors.Green, 1, "", true)
                end

                reaper.JS_Composite(ArrangeHwnd, _f(item_offset_x), _f(item_offset_y), _f(t_bm_width), _f(t_bm_height), bitmap, 0, 0, _f(t_bm_width), _f(t_bm_height), true)
            else
                clearBitmap(bm.trailing, i)
            end
        else
            clearBitmap(bm.leading, i)
            clearBitmap(bm.trailing, i)
        end
    end
end

local function trimSilenceResult()
    reaper.Undo_BeginBlock()

    Log("== Leading edge ==")
    Log("Threshold: " .. p_l_threshold .. "db")
    Log("Pad: " .. p_l_pad .. "s")
    Log("Fade: " .. p_l_fade .. "s")
    Log("== Trailing edge ==")
    Log("Threshold: " .. p_t_threshold .. "db")
    Log("Pad: " .. p_t_pad .. "s")
    Log("Fade: " .. p_t_fade .. "s")

    for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)
        local take = reaper.GetActiveTake(item)

        local startTime, endTime = getEdgePositionsByItem(item)

        if startTime and startTime > 0 then trimLeadingPosition(take, startTime) end
        if endTime and endTime > 0 then trimTrailingPosition(take, endTime - startTime) end
    end

    reaper.UpdateArrange()

    reaper.Undo_EndBlock("Trim silence edges for selected items (no prompt)", -1)
end

function frame()
    local r, newVal

    --
    -- Leading part
    --
    GUI_DrawText('Leading edge:', GUI_GetFont(gui_font_types.Bold))
    r, newVal = reaper.ImGui_SliderDouble(GUI_GetCtx(), 'Threshold In', p_l_threshold, -70, 0, '%.1fdb', slider_flags)
    if p_l_threshold ~= newVal then
        setTsParamValue(tsParams.leading.threshold, newVal)
        p_l_threshold = newVal
    end

    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Pad In', p_l_pad, 0.01, 0, nil, '%.2fs')
    if p_l_pad ~= newVal then
        setTsParamValue(tsParams.leading.pad, newVal)
        p_l_pad = newVal
    end

    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Fade In', p_l_fade, 0.01, 0, nil, '%.2fs')
    if p_l_fade ~= newVal then
        setTsParamValue(tsParams.leading.fade, newVal)
        p_l_fade = newVal
    end

    --
    -- Trailing part
    --
    GUI_DrawGap()
    GUI_DrawText('Trailing edge:', GUI_GetFont(gui_font_types.Bold))

    r, newVal = reaper.ImGui_SliderDouble(GUI_GetCtx(), 'Threshold Out', p_t_threshold, -70, 0, '%.1fdb', slider_flags)
    if p_t_threshold ~= newVal then
        setTsParamValue(tsParams.trailing.threshold, newVal)
        p_t_threshold = newVal
    end

    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Pad Out', p_t_pad, 0.01, 0, nil, '%.2fs')
    if p_t_pad ~= newVal then
        setTsParamValue(tsParams.trailing.pad, newVal)
        p_t_pad = newVal
    end

    r, newVal = reaper.ImGui_DragDouble(GUI_GetCtx(), 'Fade Out', p_t_fade, 0.01, 0, nil, '%.2fs')
    if p_t_fade ~= newVal then
        setTsParamValue(tsParams.trailing.fade, newVal)
        p_t_fade = newVal
    end

    r, newVal = reaper.ImGui_Checkbox(GUI_GetCtx(), 'Preview Result', p_preview == 1)
    newVal = newVal and 1 or 0

    if p_preview ~= newVal then
        setTsParamValue(tsParams.preview_result, newVal)
        p_preview = newVal
    end

    GUI_DrawGap()
    reaper.ImGui_Indent(GUI_GetCtx(), 60)

    GUI_DrawButton('Trim silence', function()
        trimSilenceResult()
    end)

    reaper.ImGui_SameLine(GUI_GetCtx())

    GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)

     preview_result()
end

GUI_ShowMainWindow(330, 320)

function GUI_OnWindowClose()
    reset_preview()
end

