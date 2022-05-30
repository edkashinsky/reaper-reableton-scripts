-- @description ek_Trim silence at the edges of selected items (no prompt)
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/trim_silence_edges_preview.gif)
--
--   It removes silence at the start at the end of item without prompt. Using together with "ek_Trim silence at the edges of selected items"

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) return true else return false end
end

if not CoreFunctionsLoaded("ek_Core functions.lua") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

CoreFunctionsLoaded("ek_Triming silence edges functions.lua")

reaper.Undo_BeginBlock()

local countSelectedItems = reaper.CountSelectedMediaItems(proj)

if countSelectedItems > 0 then
    local leadingThreshold = getTsParamValue(tsParams.leading.threshold)
    local leadingPad = getTsParamValue(tsParams.leading.pad)
    local leadingFade = getTsParamValue(tsParams.leading.fade)
    local trailingThreshold = getTsParamValue(tsParams.trailing.threshold)
    local trailingPad = getTsParamValue(tsParams.trailing.pad)
    local trailingFade = getTsParamValue(tsParams.trailing.fade)

    Debug("== Leading edge ==\n")
    Debug("Threshold: " .. leadingThreshold .. "db\n")
    Debug("Pad: " .. leadingPad .. "s\n")
    Debug("Fade: " .. leadingFade .. "s\n")
    Debug("== Trailing edge ==\n")
    Debug("Threshold: " .. trailingThreshold .. "db\n")
    Debug("Pad: " .. trailingPad .. "s\n")
    Debug("Fade: " .. trailingFade .. "s\n")

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
end

reaper.Undo_EndBlock("Trim silence at the edges of selected items (no prompt)", -1)