-- @author Ed Kashinsky
-- @noindex

local ag_grid_type_key = "ag_grid_type"
local ag_grid_type_midi_key = "ag_grid_midi_type"
local ag_grid_scale_key = "ag_grid_scale"
local ag_grid_scale_midi_key = "ag_grid_midi_scale"
local ag_grid_width_ratio_key = "ag_grid_width_scale"
local ag_grid_is_synced_key = "ag_grid_is_synced_key"
local ag_grid_limits = "ag_grid_limits"

local cached_zoom = { arrange = {}, midi = {}}
local defaultGrid = 3 -- Medium
local defaultScale = 1 -- Straight

ag_types_config = {
    { title = 'Widest', ratio = 8, has_scale = false, is_adapt = true },
    { title = 'Wide', ratio = 4, has_scale = false, is_adapt = true  },
    { title = 'Medium', ratio = 2, has_scale = true, is_adapt = true },
    { title = 'Narrow', ratio = 1, has_scale = true, is_adapt = true },
    { title = 'Narrowest', ratio = 0.5, has_scale = true, is_adapt = true },
    { title = '4 bar', ratio = 4, has_scale = false,  is_adapt = false },
    { title = '2 bar', ratio = 2, has_scale = false, is_adapt = false },
    { title = '1 bar', ratio = 1, has_scale = false, is_adapt = false },
    { title = '1/2', ratio = 1/2, has_scale = true, is_adapt = false },
    { title = '1/4', ratio = 1/4, has_scale = true, is_adapt = false },
    { title = '1/8', ratio = 1/8, has_scale = true, is_adapt = false },
    { title = '1/16', ratio = 1/16, has_scale = true, is_adapt = false },
    { title = '1/32', ratio = 1/32, has_scale = true, is_adapt = false },
    { title = '1/64', ratio = 1/64, has_scale = true, is_adapt = false },
}

ag_scale_types_config = {
     { title = 'Straight', value = 1 },
     { title = 'Dotted', value = 3 / 2 },
     { title = 'Triplet', value = 2 / 3 },
     { title = 'Swing' },
}

local function AG_UpdateGrid()
    reaper.SetProjectGrid(proj, AG_GetCurrentGridValue())
    reaper.SetMIDIEditorGrid(proj, AG_GetCurrentGridValue(true))
end

function AG_GetCurrentGrid(for_midi_editor)
    local id = EK_GetExtState(for_midi_editor and ag_grid_type_midi_key or ag_grid_type_key, defaultGrid)
    local type = ag_types_config[id]

    if type == nil then
        return ag_types_config[defaultGrid], defaultGrid
    else
        return type, id
    end
end

function AG_SetCurrentGrid(for_midi_editor, id)
    EK_SetExtState(for_midi_editor and ag_grid_type_midi_key or ag_grid_type_key, id)
    AG_UpdateGrid()
end

function AG_GetGridScale(for_midi_editor)
	local id = EK_GetExtState(for_midi_editor and ag_grid_scale_midi_key or ag_grid_scale_key, defaultScale)
    local type = ag_scale_types_config[id]

    if type == nil then
        return ag_scale_types_config[defaultScale], defaultScale
    else
        return type, id
    end
end

function AG_SetGridScale(for_midi_editor, id, swingamt)
    local _, division, _, _ = reaper.GetSetProjectGrid(proj, false)
    local scale = ag_scale_types_config[id]

	if scale.title == "Swing" then
		reaper.GetSetProjectGrid(proj, true, division, 1, swingamt)
	else
		reaper.GetSetProjectGrid(proj, true, division, 0, 0)
	end

	EK_SetExtState(for_midi_editor and ag_grid_scale_midi_key or ag_grid_scale_key, id)

    -- kostil for not straight
    if for_midi_editor then
        reaper.SetMIDIEditorGrid(proj, 1)
    else
         reaper.SetProjectGrid(proj, 1)
    end

    AG_UpdateGrid()
end

function AG_GetWidthRatio()
    return EK_GetExtState(ag_grid_width_ratio_key, 2)
end

function AG_SetWidthRatio(value)
    EK_SetExtState(ag_grid_width_ratio_key, value)
    AG_UpdateGrid()
end

local function AG_GetFractionByNote(note)
    local fraction
    local nom, denom, tripletOrDotted = note:match('(%d+)/(%d+)([TtDd]?)')

    if nom then
        local factor = 1
        if tripletOrDotted == 't' or tripletOrDotted == 'T' then
            factor = ag_scale_types_config[3].value
        elseif tripletOrDotted == 'd' or tripletOrDotted == 'D' then
            factor = ag_scale_types_config[2].value
        end

        fraction = nom / denom * factor
    else
        fraction = tonumber(note)
    end

    if (not fraction or fraction < 0) and note ~= '' then
        return nil
    else
        return fraction or 0
    end
end

function AG_GetGridLimits()
    local limits = EK_GetExtState(ag_grid_limits)

    if type(limits) == 'table' then
        return limits[1], limits[2], limits[3], limits[4]
    else
        return nil
    end
end

function AG_SetGridLimits(min, max)
    local minValue, maxValue
    local data = { nil, nil, nil, nil }

    if min then minValue = AG_GetFractionByNote(min) end
    if max then maxValue = AG_GetFractionByNote(max) end

    if minValue and maxValue and minValue > maxValue then return end -- max should be greater then max

    if minValue then
        data[1] = minValue
        data[3] = min
    end

    if maxValue then
        data[2] = maxValue
        data[4] = max
    end

    EK_SetExtState(ag_grid_limits, data)
    AG_UpdateGrid()
end

function AG_ToggleSyncedWithMidiEditor()
     -- Grid: Use the same grid division in arrange view and MIDI editor
    reaper.Main_OnCommand(reaper.NamedCommandLookup(42010), 0)
    AG_UpdateGrid()
end

function AG_IsSyncedWithMidiEditor()
    -- Grid: Use the same grid division in arrange view and MIDI editor
    local isSynced = reaper.GetToggleCommandState(42010)

    return tonumber(isSynced) == 1
end

local function AG_GetAdaptiveGridDivision(zoom_level, for_midi_editor)
    local spacing = 15
    local min, max = AG_GetGridLimits()
    local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local _, _, _, start_beat = reaper.TimeMap2_timeToBeats(0, start_time)
    local _, _, _, end_beat = reaper.TimeMap2_timeToBeats(0, end_time)

    -- Current view width in pixels
    local arrange_pixels = (end_time - start_time) * zoom_level
    -- Number of measures that fit into current view
    local arrange_measures = (end_beat - start_beat) / 4

    local measure_length_in_pixels = arrange_pixels / arrange_measures

    -- The maximum grid (divisions) that would be allowed with spacing
    local max_grid = measure_length_in_pixels / spacing

     -- Get current grid
    local _, grid_div, _, _ = reaper.GetSetProjectGrid(0, false)
    local grid = 1 / grid_div

    local factor = AG_GetWidthRatio()
    factor = tonumber(factor) or 2

    -- How often can current grid fit into max_grid?
    local exp = math.log(max_grid / grid, factor)
    local new_grid = grid * factor ^ math.floor(exp)

    local value = 1 / new_grid

    if min ~= nil and value <= min then value = min
    elseif max ~= nil and value >= max then value = max end

	return value
end

local function AG_GetHZoomLevelForMidiEditor()
	local MidiEditor = reaper.MIDIEditor_GetActive()
	if not MidiEditor then return end

 	local take = reaper.MIDIEditor_GetTake(MidiEditor)
	if not take or not reaper.ValidatePtr(take, "MediaItem_Take*") then return end

    local midiview = reaper.JS_Window_FindChildByID(MidiEditor, 0x3E9)
  	local _, width = reaper.JS_Window_GetClientSize(midiview)
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

  	local start_time, end_time, _ = reaper.MIDI_GetProjTimeFromPPQPos(take, leftmost_tick)

  	if timebase == 0 or timebase == 4 then
    	end_time = reaper.MIDI_GetProjTimeFromPPQPos(take, leftmost_tick + (width - 1) / hzoom)
  	else
   		end_time = start_time + (width - 1) / hzoom
  	end

  	return (width) / (end_time - start_time)
end

local function AG_GetZoomLevel(for_midi_editor)
    local zoom_level = for_midi_editor and AG_GetHZoomLevelForMidiEditor() or reaper.GetHZoomLevel()

    if type(zoom_level) == "string" then
        return tonumber(zoom_level)
    elseif type(zoom_level) == "number" then
        return zoom_level
    else
        return nil
    end
end

function AG_GetCurrentGridValue(for_midi_editor)
    local settings = AG_GetCurrentGrid(for_midi_editor)
    local zoom_level = AG_GetZoomLevel(for_midi_editor)
    local grid

    if zoom_level == nil then return nil end

    if settings.is_adapt then
        grid = AG_GetAdaptiveGridDivision(zoom_level, for_midi_editor)
        grid = grid * settings.ratio
    else
        grid = settings.ratio
    end

    if settings.has_scale then
        local scale = AG_GetGridScale(for_midi_editor)
        if scale.value then
            grid = grid * scale.value
        end
    end

    return grid
end

local function AG_IsMidiEditorZoomLevelChanged()
    local MidiEditor = reaper.MIDIEditor_GetActive()
    if not MidiEditor then return false end

    local take = reaper.MIDIEditor_GetTake(MidiEditor)
    if not take or not reaper.ValidatePtr(take, "MediaItem_Take*") then return false end

    local item = reaper.GetMediaItemTake_Item(take)
    local _, chunk = reaper.GetItemStateChunk(item, "", false)

    if chunk ~= cached_zoom.midi.chunk then
        cached_zoom.midi.chunk = chunk
        return true
    else
        return false
    end
end

function AG_GridIsChanged(for_midi_editor)
    local cached = for_midi_editor and cached_zoom.midi or cached_zoom.arrange
    local is_zoom_changed = false

    if for_midi_editor then
        is_zoom_changed = AG_IsMidiEditorZoomLevelChanged()
    else
        local zoom_level = AG_GetZoomLevel(for_midi_editor)
        is_zoom_changed = zoom_level ~= cached.zoom_level

        cached_zoom.arrange.zoom_level = zoom_level
    end

    if is_zoom_changed then
        return true
    end

	local _, id = AG_GetCurrentGrid(for_midi_editor)
	local scale = AG_GetGridScale(for_midi_editor)
    local ratio = AG_GetWidthRatio()

    if id ~= cached.config_id or scale ~= cached.zoom_level_scale or ratio ~= cached.width_ratio then
        if for_midi_editor then
            cached_zoom.midi.config_id = id
            cached_zoom.midi.zoom_level_scale = scale
            cached_zoom.midi.width_ratio = ratio
        else
            cached_zoom.arrange.config_id = id
            cached_zoom.arrange.zoom_level_scale = scale
            cached_zoom.arrange.width_ratio = ratio
        end

        return true
    else
        return false
    end
end

function AG_QuickToggleGrid(is_next, for_midi_editor)
    local grid, id = AG_GetCurrentGrid(for_midi_editor)
    local newValue = is_next and id + 1 or id - 1
    local availableValues = {}

    for i, row in pairs(ag_types_config) do
        if grid.is_adapt and row.is_adapt then
            table.insert(availableValues, i)
        elseif not grid.is_adapt and not row.is_adapt then
            table.insert(availableValues, i)
        end
    end

    Log(availableValues)
    Log(grid)
    Log(id .. " -> " .. newValue)

    if in_array(availableValues, newValue) then
        AG_SetCurrentGrid(for_midi_editor, newValue)
        Log("Set grid: " .. newValue)
    end
end