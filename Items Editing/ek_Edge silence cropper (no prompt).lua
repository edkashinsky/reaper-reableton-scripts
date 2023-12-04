-- @description ek_Edge silence cropper (no prompt)
-- @author Ed Kashinsky
-- @noindex
-- @readme_skip

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
    local leadingThreshold, trailingThreshold = GetThresholdsValues()
    local leadingPad = p.leading.pad.value
    local leadingFade = p.leading.fade.value
    local trailingPad = p.trailing.pad.value
    local trailingFade = p.trailing.fade.value

    Log("== Leading edge ==")
    Log("Threshold: " .. leadingThreshold .. "db/%")
    Log("Pad: " .. leadingPad .. "s")
    Log("Fade: " .. leadingFade .. "s")
    Log("== Trailing edge ==")
    Log("Threshold: " .. trailingThreshold .. "db/%")
    Log("Pad: " .. trailingPad .. "s")
    Log("Fade: " .. trailingFade .. "s")

    for i = 0, countSelectedItems - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)

        local take = reaper.GetActiveTake(item)
        local startTime, endTime

        if reaper.TakeIsMIDI(take) then
            startTime = GetStartPositionOfMidiNote(take)
            endTime = GetEndPositionOfMidiNote(take)
        else
            startTime = GetStartPositionLouderThenThreshold(take, leadingThreshold)
            endTime = GetEndPositionLouderThenThreshold(take, trailingThreshold)
        end

        if endTime > 0 then CropTrailingPosition(take, endTime) end
        if startTime > 0 then CropLeadingPosition(take, startTime) end
    end

    reaper.UpdateArrange()
end

reaper.Undo_EndBlock("Edge silence cropper (no prompt)", -1)