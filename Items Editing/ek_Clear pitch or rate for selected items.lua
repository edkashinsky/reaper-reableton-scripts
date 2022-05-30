-- @description ek_Clear pitch or rate for selected items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script resets any pitch, rate and length info for selected items and makes as default

reaper.Undo_BeginBlock()

proj = 0
semiFactor = 2 ^ (1/12) -- Rate: 2.0 = Pitch * 12

for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

	local itemTake = reaper.GetMediaItemTake(item, takeInd)

	if reaper.TakeIsMIDI(itemTake) then
		-- do nothing
	else
		local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "B_PPITCH")
	
		if mode == 1 then
			-- clear pitch
			reaper.SetMediaItemTakeInfo_Value(itemTake, "D_PITCH", 0)
			reaper.SetMediaItemTakeInfo_Value(itemTake, "D_PLAYRATE", 1)
		else
			-- clear rate
			local rate = reaper.GetMediaItemTakeInfo_Value(itemTake, "D_PLAYRATE")
			
			reaper.SetMediaItemTakeInfo_Value(itemTake, "D_PITCH", 0)
			reaper.SetMediaItemTakeInfo_Value(itemTake, "D_PLAYRATE", 1)
		
			local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
			local semitones = math.log(rate, semiFactor)
			
			if semitones >= 0 then
				length = length * (semiFactor ^ semitones)
			else
				length = length / (semiFactor ^ math.abs(semitones))
			end
			
			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
		end
	end
	
	reaper.UpdateArrange()
end

reaper.Undo_EndBlock("Clear pitch or rate", -1)