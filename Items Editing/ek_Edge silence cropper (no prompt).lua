-- @description ek_Edge silence cropper (no prompt)
-- @version 1.0.2
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/trim_silence_edges_preview.gif)
--
--   It removes silence at the start at the end of item without prompt. Using together with "ek_Trim silence at the edges of selected items"
-- @changelog
--   - Fixed bug with MIDI items

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

CoreFunctionsLoaded("ek_Edge silence cropper functions.lua")

reaper.Undo_BeginBlock()

local countSelectedItems = reaper.CountSelectedMediaItems(proj)

if countSelectedItems > 0 then
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

        if take ~= nil and not reaper.TakeIsMIDI(take) then
            local startTime = getStartPositionLouderThenThreshold(take, leadingThreshold)
            if startTime > 0 then trimLeadingPosition(take, startTime) end

            local endTime = getEndPositionLouderThenThreshold(take, trailingThreshold)
            if endTime > 0 then trimTrailingPosition(take, endTime) end
        end
    end

    reaper.UpdateArrange()
end

reaper.Undo_EndBlock("Edge silence cropper (no prompt)", -1)