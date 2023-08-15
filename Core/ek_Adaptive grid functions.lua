-- @author Ed Kashinsky
-- @noindex

local ag_grid_type_key = "ag_grid_type"
local ag_grid_type_midi_key = "ag_grid_midi_type"
local ag_grid_scale_key = "ag_grid_scale"
local ag_grid_scale_midi_key = "ag_grid_midi_scale"
local ag_grid_width_ratio_key = "ag_grid_width_scale"
local ag_grid_is_synced_key = "ag_grid_is_synced_key"
local ag_grid_limits = "ag_grid_limits"

local cached_zoom_level
local cached_config_id
local cached_zoom_level_scale
local cached_width_ratio
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

    AG_UpdateGrid()
end

function AG_GetWidthRatio()
    return EK_GetExtState(ag_grid_width_ratio_key, 1)
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
    EK_SetExtState(ag_grid_is_synced_key, not AG_IsSyncedWithMidiEditor())

    if AG_IsSyncedWithMidiEditor() then
        local _, id = AG_GetCurrentGrid()
        AG_SetCurrentGrid(true, id)

        _, id = AG_GetGridScale()
        AG_SetGridScale(true, id)
    end

    AG_UpdateGrid()
end

function AG_IsSyncedWithMidiEditor()
    return EK_GetExtState(ag_grid_is_synced_key, true)
end

local function AG_GetAdaptiveGridDivision(zoom_level, for_midi_editor)
    local value
    local ratio = AG_GetWidthRatio()
    local min, max = AG_GetGridLimits()

	local getRetinaLevel = function(lvl)
        if gfx.ext_retina ~= 0 then lvl = lvl * 2 end
		return lvl * ratio
	end

    local getOrderByZoomLevel = function(level)
	    local order

        if level <= getRetinaLevel(1) then
            order = -3
        elseif level < getRetinaLevel(3) then
            order = -2
        elseif level < getRetinaLevel(5) then
            order = -1
        elseif level < getRetinaLevel(15) then
            order = 0
        elseif level < getRetinaLevel(25) then
            order = 1
        elseif level < getRetinaLevel(55) then
            order = 2
        elseif level < getRetinaLevel(110) then
            order = 3
        elseif level < getRetinaLevel(220) then
            order = 4
        elseif level < getRetinaLevel(450) then
            order = 5
        elseif level < getRetinaLevel(850) then
            order = 6
        elseif level < getRetinaLevel(1600) then
            order = 7
        elseif level < getRetinaLevel(3500) then
            order = 8
        elseif level < getRetinaLevel(6700) then
            order = 9
        elseif level < getRetinaLevel(12000) then
            order = 10
        elseif level < getRetinaLevel(30000) then
            order = 11
        elseif level < getRetinaLevel(45200) then
            order = 12
        elseif level < getRetinaLevel(55100) then
            order = 13
        elseif level < getRetinaLevel(80000) then
            order = 14
        elseif level < getRetinaLevel(110000) then
            order = 15
        elseif level < getRetinaLevel(150000) then
            order = 16
        else
            order = 17
        end
        return order
    end

	local order = getOrderByZoomLevel(zoom_level)

    if order < 0 then value = (2 * math.abs(order))
    else value = (1 / (2 ^ order)) end

    if min ~= nil and value <= min then value = min
    elseif max ~= nil and value >= max then value = max end

	return value
end

local function AG_GetHZoomLevelForMidiEditor()
	local MidiEditor = reaper.MIDIEditor_GetActive()

	if not MidiEditor then return end

	local midiview = reaper.JS_Window_FindChildByID(MidiEditor, 0x3E9)
  	local _, width = reaper.JS_Window_GetClientSize(midiview)
 	local take = reaper.MIDIEditor_GetTake(MidiEditor)

	if not reaper.ValidatePtr(take, "MediaTake*") then return end

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

  	local start_time, end_time, _ = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick)

  	if timebase == 0 or timebase == 4 then
    	end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick + (width-1)/hzoom)
  	else
   		end_time = start_time + (width-1)/hzoom
  	end

  	return (width) / (end_time - start_time)
end

local function AG_GetZoomLevel(for_midi_editor)
    local zoom_level = for_midi_editor and AG_GetHZoomLevelForMidiEditor() or reaper.GetHZoomLevel()

    if type(zoom_level) == "string" then
        return tonumber(zoom_level)
    elseif type(zoom_level) == "number" then
        return math.floor(zoom_level)
    else
        return nil
    end
end

function AG_GetCurrentGridValue(for_midi_editor)
    local settings = AG_GetCurrentGrid(for_midi_editor)
    local zoom_level = AG_GetZoomLevel(for_midi_editor)
    local grid
    local log
    if zoom_level == nil then return nil end

    if settings.is_adapt then
        grid = AG_GetAdaptiveGridDivision(zoom_level, for_midi_editor)
        grid = grid * settings.ratio

        log = "ADAPT " .. grid .. " " .. settings.ratio
    else
        grid = settings.ratio
        log = "NOT ADAPT " .. settings.ratio
    end

    if settings.has_scale then
        local scale = AG_GetGridScale(for_midi_editor)
        if scale.value then
            grid = grid * scale.value
            log = log .. " + " .. scale.value
        end
    end

    Log(log, ek_log_levels.Notice)
    return grid
end

function AG_GridIsChanged(for_midi_editor)
    local zoom_level = AG_GetZoomLevel(for_midi_editor)
	local _, id = AG_GetCurrentGrid(for_midi_editor)
	local scale = AG_GetGridScale(for_midi_editor)
    local ratio = AG_GetWidthRatio()

    if zoom_level ~= cached_zoom_level or id ~= cached_config_id or scale ~= cached_zoom_level_scale or ratio ~= cached_width_ratio then
        cached_zoom_level = zoom_level
        cached_config_id = id
        cached_zoom_level_scale = scale
        cached_width_ratio = ratio

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