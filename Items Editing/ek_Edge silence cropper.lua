-- @description ek_Edge silence cropper
-- @version 1.1.12
-- @author Ed Kashinsky
-- @about
--   This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.
--
--   Also it provides UI for configuration
-- @changelog
--   • Bug fix for cropping midi-items for no-prompt version
-- @provides
--   ../Core/ek_Edge silence cropper functions.lua
--   [main=main] ek_Edge silence cropper (no prompt).lua

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

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

CoreFunctionsLoaded("ek_Edge silence cropper functions.lua")

local window_open = true
local cachedPositions = { leading = {}, trailing = {}, zoom = nil, hor = nil, count_sel_items = 0 }
local MainHwnd = reaper.GetMainHwnd()
local ArrangeHwnd = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)

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

    if not map.maps[ind] then
        needToUpdate = true
    else
        local w = reaper.JS_LICE_GetWidth(map.maps[ind])
        local h = reaper.JS_LICE_GetHeight(map.maps[ind])

        needToUpdate = w ~= width or h ~= height
    end

    if needToUpdate then
        ClearBitmap(map, ind)
        map.maps[ind] = reaper.JS_LICE_CreateBitmap(true, math.floor(width), math.floor(height))
        -- reaper.JS_LICE_Clear(map.maps[ind], ek_colors.Red)
    end

    return needToUpdate, map.maps[ind]
end

local function GetEdgePositionsByItem(item)
    if not item then return end

    local startTime, endTime
    local take = reaper.GetActiveTake(item)
    local guid = GetGUID(item)
    local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    if not take or not guid then return end

    local l_cache = cachedPositions.leading[guid]
    local r_cache = cachedPositions.trailing[guid]

    if reaper.TakeIsMIDI(take) then
        local _, chunk = reaper.GetItemStateChunk(item, "", false)

        if l_cache and l_cache.midi_chunk == chunk then startTime = l_cache.position
        else
            startTime = GetStartPositionOfMidiNote(take)
            cachedPositions.leading[guid] = { midi_chunk = chunk, position = startTime }
        end

        if r_cache and r_cache.midi_chunk == chunk then endTime = r_cache.position
        else
            endTime = GetEndPositionOfMidiNote(take)
            cachedPositions.trailing[guid] = { midi_chunk = chunk, position = endTime }
        end
    else
        local p_l_threshold, p_t_threshold = GetThresholdsValues()

        if l_cache and l_cache.threshold == p_l_threshold and l_cache.rate == rate then
            startTime = l_cache.position
        else
            startTime = GetStartPositionLouderThenThreshold(take, p_l_threshold)
            cachedPositions.leading[guid] = { threshold = p_l_threshold, position = startTime, rate = rate }
        end

        if r_cache and r_cache.threshold == p_t_threshold and r_cache.rate == rate then
            endTime = r_cache.position
        else
            endTime = GetEndPositionLouderThenThreshold(take, p_t_threshold)
            cachedPositions.trailing[guid] = { threshold = p_t_threshold, position = endTime, rate = rate }
        end
    end

    return startTime, endTime
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
            local track = reaper.GetMediaItem_Track(item)
            local item_height = reaper.GetMediaItemInfo_Value(item, "I_LASTH")
            local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local startTime, endTime = GetEdgePositionsByItem(item)
            local p_l_pad, p_l_fade = GetLeadingPadAndOffset(startTime)
            local p_t_pad, p_t_fade = GetTrailingPadAndOffset(endTime, item_length)

            local item_offset_x = (position * zoom) - scrollposh
            local item_offset_y = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") + GetItemHeaderHeight(item)
            local item_length_px = item_length * zoom

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

            if startTime > min_step and startTime < item_length then
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

            if endTime > min_step and endTime < item_length then
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

            local guid = GetGUID(item)
            cachedPositions.leading[guid] = nil
            cachedPositions.trailing[guid] = nil
        end
    end

    return true
end

local function CropSilence()
    reaper.Undo_BeginBlock()

    local l_threshold, t_threshold = GetThresholdsValues()

    Log("== Leading edge ==")
    Log("Threshold: " .. l_threshold .. "db/%")
    Log("Pad: " .. p.leading.pad.value .. "s")
    Log("Fade: " .. p.leading.fade.value .. "s")
    Log("== Trailing edge ==")
    Log("Threshold: " .. t_threshold .. "db/%")
    Log("Pad: " .. p.trailing.pad.value .. "s")
    Log("Fade: " .. p.trailing.fade.value .. "s")

    for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)
        local take = reaper.GetActiveTake(item)

        local startTime, endTime = GetEdgePositionsByItem(item)

        if endTime and endTime > 0 then CropTrailingPosition(take, endTime) end
        if startTime and startTime > 0 then CropLeadingPosition(take, startTime) end
    end

    reaper.UpdateArrange()

    reaper.Undo_EndBlock("Edge silence cropper", -1)
end

function frame()
    GUI_DrawSettingsTable(gui_config)

    GUI_DrawGap()
    reaper.ImGui_Indent(GUI_GetCtx(), 72)

    GUI_DrawButton('Trim silence', function()
        CropSilence()
    end)

    reaper.ImGui_SameLine(GUI_GetCtx())

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

    return true
end })

GUI_ShowMainWindow(330, 0)

function GUI_OnWindowClose()
    ResetPreview()
    window_open = false;
end

