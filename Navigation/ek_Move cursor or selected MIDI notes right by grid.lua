-- @description ek_Move cursor or selected MIDI notes right by grid
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   If any note is selected, this script moves it to right by grid size. And move cursor by grid in other case
-- @changelog
--   Bug fix: when item is unselected in arrange view, selected notes in MIDI Editor aren't moved
-- @provides [main=midi_editor] .

reaper.Undo_BeginBlock()

local proj = 0
local editor = reaper.MIDIEditor_GetActive()

local function hasSelectedMidiNote()
	local itemTake = reaper.MIDIEditor_GetTake(editor)
	if not itemTake then
		return false
	end

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
	-- Edit: Move notes right one grid unit
	reaper.MIDIEditor_OnCommand(editor, 40184)
else
	-- Navigate: Move edit cursor right by grid
	reaper.MIDIEditor_OnCommand(editor, 40048)
end

reaper.Undo_EndBlock("Move cursor or selected MIDI notes left by grid", -1)