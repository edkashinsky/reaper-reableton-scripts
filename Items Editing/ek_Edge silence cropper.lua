-- @description ek_Edge silence cropper
-- @version 1.2.2
-- @author Ed Kashinsky
-- @about
--   This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.
--
--   Also it provides UI for configuration
-- @changelog
--   Updated the minimum version of ReaImGui to version 0.8.5
-- @provides
--   ../Core/ek_Edge silence cropper functions.lua
--   [main=main] ek_Edge silence cropper (no prompt).lua
--   [main=main] ek_Edge silence cropper - apply Preset 1.lua
--   [main=main] ek_Edge silence cropper - apply Preset 2.lua
--   [main=main] ek_Edge silence cropper - apply Preset 3.lua
--   [main=main] ek_Edge silence cropper - apply Preset 4.lua
--   [main=main] ek_Edge silence cropper - apply Preset 5.lua

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

CoreFunctionsLoaded("ek_Edge silence cropper functions.lua")

GUI_ShowMainWindow(330, 0)

local min_step = 0.00001
local using_eel = reaper.APIExists("ImGui_CreateFunctionFromEEL")
local window_open = true
local cachedPositions = { zoom = nil, hor = nil, count_sel_items = 0, values = {}, items_values = {} }
local MainHwnd = reaper.GetMainHwnd()
local ArrangeHwnd = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
local Cropper = EdgeCropper.new()

local bm = {
    leading = { maps = {}, color = ek_colors.Red },
    trailing = { maps = {}, color = ek_colors.Blue },
}

local function _f(value)
    return math.floor(value)
end

local function _drawVerticalLine(bitmap, x, height, color)
    reaper.JS_LICE_Line(bitmap, _f(x), 0, _f(x), _f(height), color, 1, "", true)
end

local function ClearBitmap(map, ind)
    if map.maps[ind] then
        reaper.JS_LICE_DestroyBitmap(map.maps[ind])
    end
end

local function ResetPreview()
    for _, maps in pairs(bm) do
        for i, _ in pairs(maps.maps) do
            ClearBitmap(maps, i)
        end
    end
end

local function UpdateBitmapIfNeeded(map, ind, width, height)
    local needToUpdate = false

    width = _f(width)
    height = _f(height)

    if not map.maps[ind] then
        needToUpdate = true
    else
        local w = reaper.JS_LICE_GetWidth(map.maps[ind])
        local h = reaper.JS_LICE_GetHeight(map.maps[ind])

        needToUpdate = w ~= width or h ~= height
    end

    if needToUpdate then
        ClearBitmap(map, ind)
        map.maps[ind] = reaper.JS_LICE_CreateBitmap(true, width, height)
        -- reaper.JS_LICE_Clear(map.maps[ind], ek_colors.Red)
    end

    return needToUpdate, map.maps[ind]
end

local function PreviewCropResultInArrangeView()
    if not window_open then return false end

    local zoom = reaper.GetHZoomLevel()
    local _, scrollposh = reaper.JS_Window_GetScrollInfo(ArrangeHwnd, "h")
    local countSelectedItems = reaper.CountSelectedMediaItems(proj)

    local preview = p.preview_result.value

    cachedPositions.zoom = zoom
    cachedPositions.hor = scrollposh

    if cachedPositions.count_sel_items ~= countSelectedItems then
        cachedPositions.count_sel_items = countSelectedItems
        ResetPreview()
    end

    for i = 0, reaper.CountMediaItems(proj) - 1 do
        local item = reaper.GetMediaItem(proj, i)

        if reaper.IsMediaItemSelected(item) and preview then
            Cropper = Cropper.SetItem(item)

            local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
            local track = reaper.GetMediaItem_Track(item)
            local item_height = reaper.GetMediaItemInfo_Value(item, "I_LASTH")
            local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local startTime = Cropper.GetCropPosition()
            local endTime = Cropper.GetCropPosition(true)

            local p_l_pad = Cropper.GetPadValue()
            local p_l_fade = Cropper.GetFadeValue()
            local p_t_pad = Cropper.GetPadValue(true)
            local p_t_fade = Cropper.GetFadeValue(true)

            local item_offset_x = (position * zoom) - scrollposh
            local item_offset_y = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") + GetItemHeaderHeight(item)
            local item_length_px = item_length * zoom

            -- redraw on change item values
            if not cachedPositions.items_values[guid] then
                cachedPositions.items_values[guid] = { D_POSITION = 0, D_FADEINLEN = 0, D_FADEOUTLEN = 0, }
            end

            local isSomethingChanged = false
            for key, value in pairs(cachedPositions.items_values[guid]) do
                local curValue = reaper.GetMediaItemInfo_Value(item, key)
                if curValue ~= value then
                    isSomethingChanged = true
                    cachedPositions.items_values[guid][key] = curValue
                end
            end

            if isSomethingChanged then
                ClearBitmap(bm.leading, i)
                ClearBitmap(bm.trailing, i)
                Cropper.ClearCache(item)
            end

            ------------- LEADING PART --------------

            local l_threshold = startTime * zoom
            local l_pad = l_threshold - (p_l_pad * zoom)
            local l_fade_start = l_pad
            local l_fade_end = l_fade_start + (p_l_fade * zoom)

            if l_threshold < min_step then l_threshold = 0 end
            if l_pad < min_step then l_pad = 0 end
            if l_fade_start < min_step then l_fade_start = 0 end
            if l_fade_end < min_step then l_fade_end = 0 end
            if l_fade_end > item_length_px then l_fade_end = item_length_px end

            local l_bm_width = math.max(l_threshold, l_fade_end)
            local l_bm_height = item_height

            l_bm_width = l_bm_width + 2

            if startTime > min_step and startTime < item_length - min_step then
                local need_update, bitmap = UpdateBitmapIfNeeded(bm.leading, i, l_bm_width, l_bm_height)

                if need_update then
                    -- threshold line
                    _drawVerticalLine(bitmap, l_threshold, item_height, ek_colors.Blue)

                    -- pad line
                    if l_pad > 0 and p_l_pad > 0 then _drawVerticalLine(bitmap, l_pad, item_height, ek_colors.Red) end

                    -- fade line
                    if p_l_fade > 0 and l_fade_start > 0 then
                        reaper.JS_LICE_Line(bitmap, l_fade_start, item_height, l_fade_end, 0, ek_colors.Green, 1, "", true)
                    end

                    reaper.JS_Composite(ArrangeHwnd, _f(item_offset_x), _f(item_offset_y), _f(l_bm_width), _f(l_bm_height), bitmap, 0, 0, _f(l_bm_width), _f(l_bm_height), true)
                end
            else
                ClearBitmap(bm.leading, i)
            end

            ------------- TRAILING PART --------------

            local t_threshold = endTime * zoom
            local t_pad = t_threshold + (p_t_pad * zoom)
            local t_fade_end = t_pad
            local t_fade_start = t_fade_end - (p_t_fade * zoom)


            if t_threshold < min_step then t_threshold = 0 end
            if t_pad < min_step then t_pad = 0 end
            if t_pad > item_length_px then t_pad = item_length_px end
            if t_fade_start < min_step then t_fade_start = 0 end
            if t_fade_end > item_length_px then t_fade_end = item_length_px end

            local t_bm_width = math.max(t_threshold, t_fade_end, t_pad)
            local t_bm_height = item_height

            t_bm_width = t_bm_width + 2

            if endTime > min_step and endTime < item_length - min_step then
                local need_update, bitmap = UpdateBitmapIfNeeded(bm.trailing, i, t_bm_width, t_bm_height)

                if need_update then
                    -- threshold line
                    _drawVerticalLine(bitmap, t_threshold, item_height, ek_colors.Blue)

                    -- pad line
                    if t_pad < item_length_px and p_t_pad > 0 then _drawVerticalLine(bitmap, t_pad, item_height, ek_colors.Red) end

                    -- fade line
                    if p_t_fade > 0 and t_fade_end < item_length_px then
                        reaper.JS_LICE_Line(bitmap, t_fade_start, 0, t_fade_end, item_height, ek_colors.Green, 1, "", true)
                    end

                    reaper.JS_Composite(ArrangeHwnd, _f(item_offset_x), _f(item_offset_y), _f(t_bm_width), _f(t_bm_height), bitmap, 0, 0, _f(t_bm_width), _f(t_bm_height), true)
                end
            else
                ClearBitmap(bm.trailing, i)
            end
        else
            ClearBitmap(bm.leading, i)
            ClearBitmap(bm.trailing, i)
        end
    end

    return true
end

local function CropSilence()
    reaper.Undo_BeginBlock()

    for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)

        Cropper.SetItem(item).Crop()
    end

    reaper.UpdateArrange()

    reaper.Undo_EndBlock("Edge silence cropper", -1)
end

function frame(ImGui, ctx)
    GUI_DrawSettingsTable(gui_config)

    GUI_DrawGap()
    ImGui.Indent(ctx, 72)

    GUI_DrawButton('Trim silence', function()
        CropSilence()
    end)

    ImGui.SameLine(ctx)

    GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

EK_DeferWithCooldown(PreviewCropResultInArrangeView, { last_time = 0, cooldown = using_eel and 0.01 or 0.7, eventTick = function()
    local _, scrollposh = reaper.JS_Window_GetScrollInfo(ArrangeHwnd, "h")

    if not window_open then
        ResetPreview()
        return false
    end

    if cachedPositions.zoom ~= nil and cachedPositions.zoom ~= reaper.GetHZoomLevel() then
        ResetPreview()
    end

    if cachedPositions.hor ~= nil and cachedPositions.hor ~= scrollposh then
        ResetPreview()
    end

    local somethingChanged = false
    for _, config in pairs(p.leading) do
        if cachedPositions.values[config.key] ~= config.value then
            somethingChanged = true
            cachedPositions.values[config.key] = config.value
        end
    end

    for _, config in pairs(p.trailing) do
        if cachedPositions.values[config.key] ~= config.value then
            somethingChanged = true
            cachedPositions.values[config.key] = config.value
        end
    end

    if somethingChanged then
        Cropper.ClearCache()
    end

    return true
end })

function GUI_OnWindowClose()
    ResetPreview()
    window_open = false;
end

