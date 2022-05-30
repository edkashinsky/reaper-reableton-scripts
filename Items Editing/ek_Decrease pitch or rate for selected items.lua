-- @description ek_Decrease pitch or rate for selected items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script decreases pitch or rate of selected items depending on "Preserve Pitch" option.
--
--   If option is on, script decreases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)
--
--   This script normally subtracts 1 semitone, but if you hold ctrl/cmd it subtracts 0.1 semitone
--
--   Works with 'ek_Increase pitch or rate for selected items'
-- @changelog
--   - Added core functions

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) return true else return false end
end

if not CoreFunctionsLoaded() then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

reaper.Undo_BeginBlock()

local proj = 0
local adding = 1

-- ctrl/cmd is pressed (smoother changes)
if reaper.JS_Mouse_GetState(4) > 0 then
  adding = 0.1
end

local semiFactor = 2 ^ (1 / 12) -- Rate: 2.0 = Pitch * 12
local curSemiFactor = 2 ^ ((1 / 12) * adding)

for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

	local itemTake = reaper.GetMediaItemTake(item, takeInd)
	
	if reaper.TakeIsMIDI(itemTake) then
		local retval, notes = reaper.MIDI_CountEvts(itemTake)
		
		-- decrease pitch for every note
		if retval then
			for j = 0, notes - 1 do
				local retval, sel, muted, startppqpos, endppqpos, chan, pitch = reaper.MIDI_GetNote(itemTake, j)
		
				pitch = pitch - 1
				reaper.MIDI_SetNote(itemTake, j, sel, muted, startppqpos, endppqpos, chan, pitch)

				ShowPitchTooltip(pitch)
			end
		end
	else
		local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "B_PPITCH")
		
		if mode == 1 then
			-- decrease pitch
			local pitch = reaper.GetMediaItemTakeInfo_Value(itemTake, "D_PITCH")
			pitch = pitch - adding
			
			reaper.SetMediaItemTakeInfo_Value(itemTake, "D_PITCH", pitch)
			
			if i == 0 then
				ShowPitchTooltip(pitch)
			end
		else
			-- decrease rate
			local rate = reaper.GetMediaItemTakeInfo_Value(itemTake, "D_PLAYRATE")
			rate = rate / curSemiFactor
			
			reaper.SetMediaItemTakeInfo_Value(itemTake, "D_PLAYRATE", rate)
			
			local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length * curSemiFactor)
			
			if i == 0 then
				local semitones = round(math.log(rate, semiFactor), 1)
				ShowPitchTooltip(semitones)
			end
		end
	end
	
	reaper.UpdateArrange()
end

reaper.Undo_EndBlock("Decrease Pitch or Rate", -1)