-- @author Ed Kashinsky
-- @description ek_Select all notes or CC events
-- @version 1.0.0
-- @about
--   Script selects all notes or all CC events depends on focused element. For example, if CC lane is focused, script selects CC events. You can attach this script on "Ctrl+A" hotkey in MIDI Editor.
-- @provides [main=midi_editor] .

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local _, _, noteRow, ccLane, ccLaneVal, ccLaneId = reaper.BR_GetMouseCursorContext_MIDI()
if noteRow == -1 and ccLane ~= -1 then
    -- Select all CC events in last clicked lane
    reaper.MIDIEditor_OnCommand(editor, 40668)
else
    -- Edit: Select all notes
    reaper.MIDIEditor_OnCommand(editor, 40003)
end