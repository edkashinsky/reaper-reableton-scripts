-- @description ek_Move cursor or selected MIDI notes left by grid
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   If any note is selected, this script moves it to left by grid size. And move cursor by grid in other case
-- @changelog
--   - Small fixes
-- @provides [main=midi_editor] .

reaper.Undo_BeginBlock()

local proj = 0

local function hasSelectedMidiNote()
	local item = reaper.GetSelectedMediaItem(proj, 0)
	
	if item == nil then
		return false
	end
	
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

	local itemTake = reaper.GetMediaItemTake(item, takeInd)
	
	local retval, notes = reaper.MIDI_CountEvts(itemTake)
	
	if not retval then
		return false
	end
	
	for i = 0, notes - 1 do
		local retval, sel = reaper.MIDI_GetNote(itemTake, i)
		
		if sel == true then
	  		return true
		end
	end
	
	return false
end

if hasSelectedMidiNote() then
	-- Edit: Move notes left one grid unit
	reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40183)
else
	-- Navigate: Move edit cursor left by grid
	reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40047)
end

reaper.Undo_EndBlock("Move cursor or selected MIDI notes left by grid", -1)