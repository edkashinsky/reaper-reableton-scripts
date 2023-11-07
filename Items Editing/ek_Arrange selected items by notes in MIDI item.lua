-- @description ek_Arrange selected items by notes in MIDI item
-- @author Ed Kashinsky
-- @version 1.0.2
-- @changelog
--   Small bug fix
-- @about
--    This script arranges selected items by notes in first selected MIDI item
--

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

if not CoreFunctionsLoaded("ek_Core functions.lua") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

reaper.Undo_BeginBlock()

local function GetSelectedMidiItem()
	for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
		local item = reaper.GetSelectedMediaItem(proj, i)
		local take = reaper.GetActiveTake(item)

		if reaper.TakeIsMIDI(take) then return item end
	end

	return nil
end

local midi_item = GetSelectedMidiItem()

if not midi_item then
	EK_ShowTooltip("Select one MIDI-item")
	return
end

local midi_take = reaper.GetActiveTake(midi_item)
local midi_pos = reaper.GetMediaItemInfo_Value(midi_item, "D_POSITION")
local _, notecnt, _, _ = reaper.MIDI_CountEvts(midi_take)

local _, midi_guid = reaper.GetSetMediaItemInfo_String(midi_item, "GUID", "", false)
local stems = EK_GetSelectedItemsAsGroupedStems({ midi_guid })
local noteInd = 1

for i = 0, notecnt - 1 do
	local _, _, _, startppq, _, _, _, _ = reaper.MIDI_GetNote(midi_take, i)
	local startTime = reaper.MIDI_GetProjTimeFromPPQPos(midi_take, startppq)

	if startTime >= midi_pos then
		Log("MIDI Note ON " .. startTime, ek_log_levels.Important)

		if stems[noteInd] then
			local pos_first_item

			for j = 1, #stems[noteInd] do
				local item = EK_GetMediaItemByGUID(stems[noteInd][j].item_id)

				if item ~= nil then
					if j == 1 then
						pos_first_item = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
					end

					local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

					reaper.SetMediaItemInfo_Value(item, "D_POSITION", startTime + (pos - pos_first_item))
					Log("\tSet item FROM " .. pos .. " TO " .. (startTime + (pos - pos_first_item)), ek_log_levels.Important)
				end
			end
		end

		noteInd = noteInd + 1
	end
end

reaper.Undo_EndBlock("Move items to MIDI notes", -1)