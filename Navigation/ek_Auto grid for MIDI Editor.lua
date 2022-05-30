-- @description ek_Auto grid for MIDI Editor
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It changes grid depending on zoom level in MIDI Editor.
--   For installation:
--     1. Create custom action
--     2. Add to it:
--       - View: Zoom horizontally (MIDI relative/mousewheel)
--       - This script (ek_Auto grid for MIDI Editor)
--     3. Add to this custom script MultiZoom shortcut hotkey
--     4. Have fun!
-- @changelog
--    - Small fixes
-- @provides [main=midi_editor] .

local MidiEditor = reaper.MIDIEditor_GetActive()

function GetHZoomLevelForMidiEditor()
	if not MidiEditor then return end
	
	local midiview = reaper.JS_Window_FindChildByID( MidiEditor, 0x3E9 )
  	local _, width = reaper.JS_Window_GetClientSize( midiview )
 	local take =  reaper.MIDIEditor_GetTake( MidiEditor )
  	local guid = reaper.BR_GetMediaItemTakeGUID( take )
  	local item =  reaper.GetMediaItemTake_Item( take )
  	local _, chunk = reaper.GetItemStateChunk( item, "", false )
  	local guidfound, editviewfound = false, false
  	local leftmost_tick, hzoom, timebase
  
  	local function setvalue(a)
    	a = tonumber(a)
    	if not leftmost_tick then leftmost_tick = a
    	elseif not hzoom then hzoom = a
    	else timebase = a
    	end
  	end
  
  	for line in chunk:gmatch("[^\n]+") do
    	if line == "GUID " .. guid then
      	  	guidfound = true
    	end
	
    	if (not editviewfound) and guidfound then
      		if line:find("CFGEDITVIEW ") then
        		--reaper.ShowConsoleMsg(line .. "\n")
        		line:gsub("([%-%d%.]+)", setvalue, 2)
        		editviewfound = true
      	  	end
    	end
	
    	if editviewfound then
      	  	if line:find("CFGEDIT ") then
        		--reaper.ShowConsoleMsg(line .. "\n")
        		line:gsub("([%-%d%.]+)", setvalue, 19)
        		break
      	  	end
    	end
  	end
  
  	local start_time, end_time, HZoom = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick)
  
  	if timebase == 0 or timebase == 4 then
    	end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick + (width-1)/hzoom)
  	else
   		end_time = start_time + (width-1)/hzoom
  	end
  
  	return (width)/(end_time - start_time)
end

local function updateGrid()
	local zoom_level = math.floor(GetHZoomLevelForMidiEditor(MidiEditor))
	local order

	function getNoteDivision(ord)
		if ord < 0 then
			return 2 * math.abs(ord)
		else
			return 1 / (2 ^ ord)
		end
	end

	if zoom_level <= 1 then
		order = -3
	elseif zoom_level < 3 then
		order = -2
	elseif zoom_level < 5 then
		order = -1
	elseif zoom_level < 15 then
		order = 0
	elseif zoom_level < 25 then
		order = 1
	elseif zoom_level < 55 then
		order = 2
	elseif zoom_level < 110 then
		order = 3
	elseif zoom_level < 220 then
		order = 4
	elseif zoom_level < 450 then
		order = 5
	elseif zoom_level < 850 then
		order = 6
	elseif zoom_level < 1600 then
		order = 7
	elseif zoom_level < 3500 then
		order = 8
	elseif zoom_level < 6700 then
		order = 9
	elseif zoom_level < 12000 then
		order = 10
	elseif zoom_level < 30000 then
		order = 11
	elseif zoom_level < 45200 then
		order = 12
	elseif zoom_level < 55100 then
		order = 13
	elseif zoom_level < 80000 then
		order = 14
	elseif zoom_level < 110000 then
		order = 15
	elseif zoom_level < 150000 then
		order = 16
	else
		order = 17
	end

	-- reaper.ShowConsoleMsg(zoom_level .. " " .. order .. " " .. getNoteDivision(order) .. "\n")

	-- reaper.SetProjectGrid(0, getNoteDivision(order))
	reaper.SetMIDIEditorGrid(0, getNoteDivision(order))
end

if MidiEditor then
	updateGrid()
end