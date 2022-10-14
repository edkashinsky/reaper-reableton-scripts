-- @description ek_Auto grid for MIDI Editor
-- @version 1.0.1
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
--    - Added grid modes like in Ableton
-- @provides [main=midi_editor] .

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

if not CoreFunctionsLoaded("ek_Core functions startup.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

local MidiEditor = reaper.MIDIEditor_GetActive()

function GetHZoomLevelForMidiEditor()
	if not MidiEditor then return end
	
	local midiview = reaper.JS_Window_FindChildByID(MidiEditor, 0x3E9)
  	local _, width = reaper.JS_Window_GetClientSize(midiview)
 	local take =  reaper.MIDIEditor_GetTake(MidiEditor)
  	local guid = reaper.BR_GetMediaItemTakeGUID(take)
  	local item =  reaper.GetMediaItemTake_Item(take)
  	local _, chunk = reaper.GetItemStateChunk(item, "", false)
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
	local id = tonumber(GA_GetSettingValue(ga_settings.midi_grid_setting))
	local settings = GA_GetGridSettings(id)
	local grid

	if settings.is_adapt then
		grid = GA_GetAdaptiveGridValue(zoom_level)
		grid = grid * settings.ratio
	else
		grid = settings.ratio
	end

	-- reaper.ShowConsoleMsg(zoom_level .. " " .. order .. " " .. getNoteDivision(order) .. "\n")

	reaper.SetMIDIEditorGrid(0, grid)
end

if MidiEditor then
	updateGrid()
end