-- @description ek_Core functions startup
-- @author Ed Kashinsky
-- @noindex

EK_CoreFunctionsLoaded("ek_Adaptive grid functions.lua")

local ga_key_prefix = "ga_"
ga_highlight_buttons = {
    preserve_pitch = "preserve_pitch_btn",
    trim_mode = "trim_mode_btn",
    midi_editor = "midi_editor_btn",
	overlaping_items_vertically = "overlaping_items_vertically",
	mfx_slot_1 = "mfx_slot_1",
	mfx_slot_2 = "mfx_slot_2",
	mfx_slot_3 = "mfx_slot_3",
	mfx_slot_4 = "mfx_slot_4",
	mfx_slot_5 = "mfx_slot_5",
	mfx_slot_custom = "mfx_slot_custom"
}

ga_mfx_slots = {
	mfx_slot_1 = 0,
	mfx_slot_2 = 1,
	mfx_slot_3 = 2,
	mfx_slot_4 = 3,
	mfx_slot_5 = 4
}

local ga_slots_data = {
	{ btn = ga_highlight_buttons.mfx_slot_1, slot = ga_mfx_slots.mfx_slot_1 },
	{ btn = ga_highlight_buttons.mfx_slot_2, slot = ga_mfx_slots.mfx_slot_2 },
	{ btn = ga_highlight_buttons.mfx_slot_3, slot = ga_mfx_slots.mfx_slot_3 },
	{ btn = ga_highlight_buttons.mfx_slot_4, slot = ga_mfx_slots.mfx_slot_4 },
	{ btn = ga_highlight_buttons.mfx_slot_5, slot = ga_mfx_slots.mfx_slot_5 },
}

local ga_auto_switch_preview_me = "auto_switch_preview_enabled"
local ga_me_state_is_playing = "me_is_playing"
local ga_me_current_time = "me_playing_time"

local cachedAdditionalScriptVal = {}

local function GA_GetThemesList()
	local result = {}
	local themeName
	local i = 0
	local curThemeNamePath = reaper.GetLastColorThemeFile()
	local curThemeNamePathPart = split(curThemeNamePath, dir_sep)

	local curThemeName = curThemeNamePathPart[#curThemeNamePathPart]
	if not curThemeName then curThemeName = "" end
	local themePath = curThemeNamePath:match("(.*" .. dir_sep .. ")")

	while themeName ~= nil or i == 0 do
		themeName = reaper.EnumerateFiles(themePath, i)

		if themeName ~= nil and string.match(themeName, "[%g]+[.][Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee]") then
			local name = ""
			local nameParts = split(themeName, "[.]")

			for j = 1, #nameParts - 1 do
				name = name .. nameParts[j]
				if j < #nameParts - 1 then name = name .. "." end
			end

			if not in_array(result, name) then
				table.insert(result, name)
			end
		end

		i = i + 1
	end

	table.sort(result)

	table.insert(result, 1, "[Not specified]")

	return result
end

local _, ga_grid_id = AG_GetCurrentGrid()
local _, ga_grid_midi_id = AG_GetCurrentGrid(true)
local ga_grid_titles = {}
for _, row in pairs(ag_types_config) do
	table.insert(ga_grid_titles, row.title)
end

local ga_enabled = EK_IsGlobalActionEnabled()
ga_startup_exists = reaper.file_exists(EK_ConcatPath(reaper.GetResourcePath(), 'Scripts', '__startup.lua'))
local ga_dark_theme_list = GA_GetThemesList()
local ga_dark_theme_key = "ga_dark_theme"

local function GA_GetDarkTheme()
	return EK_GetExtState(ga_dark_theme_key)
end

ga_settings = {
	enabled =  {
		key = "ga_enabled",
		type = gui_input_types.Checkbox,
		title = "Enable global action",
		description = "Turn on the core functionality so that the options below start working.",
		value = function()
			if EK_IsGlobalActionEnabled() and not EK_IsGlobalActionEnabledViaStartup() then
				return true
			end

			local val = GA_GetSettingValue(ga_settings.enabled)
			if val and not ga_startup_exists then
				return false
			end

			return val
		end,
		on_change = function(val)
			if EK_IsGlobalActionEnabled() and not EK_IsGlobalActionEnabledViaStartup() then
				return
			end

			if val then GA_EnableStartupHook()
			else GA_DisableStartupHook() end

			ga_startup_exists = reaper.file_exists(EK_ConcatPath(reaper.GetResourcePath(), 'Scripts', '__startup.lua'))
		end,
		default = false,
		disabled = ga_enabled and not EK_IsGlobalActionEnabledViaStartup(),
		order = 1,
	},
	track_time = {
		key = "track_time",
		type = gui_input_types.Checkbox,
		title = "Track working time on a project",
		description = function(val)
			if not val then return nil end

			local createdDate, trackingTime = GA_GetProjectWorkingInfo()
			local projectName = reaper.GetProjectName(proj)
			local str = ""

			if string.len(projectName) > 0 then
				str = str .. "The project \"" .. projectName .. "\" was started on " .. (createdDate and createdDate or "N/A") .. "\n"
				str = str .. "Total time spent on it " .. (trackingTime and trackingTime or "N/A")
			else
				str = "Project not found"
			end

			return str
		end,
		default = true,
		disabled = not ga_enabled,
		order = 2,
	},
	auto_grid = {
		key = "ga_auto_grid",
		type = gui_input_types.Checkbox,
		title = "Automatically adjust grid to zoom",
		description = "Feature from Ableton: when you change zoom level, grid adjusts to it. By the way, if you want to have this feature in MIDI-editor, install script 'ek_Auto grid for MIDI Editor' and set it on zoom shortcut.",
		default = true,
		disabled = not ga_enabled,
		order = 3,
	},
	arrange_grid_setting = {
		key = "ga_arrange_grid_setting",
		type = gui_input_types.Combo,
		title = "Grid setting for Arrange view",
		--description = "Select which grid you want to have in Arrange view",
		default = ga_grid_id - 1,
		value = function()
			local _, id = AG_GetCurrentGrid()
			return id - 1
		end,
		select_values = ga_grid_titles,
		on_change = function(val)
			AG_SetCurrentGrid(false, val + 1)
			if AG_IsSyncedWithMidiEditor() then
				local _, id = AG_GetCurrentGrid()
				AG_SetCurrentGrid(true, id)
			end
		end,
		disabled = not ga_enabled,
		order = 4,
	},
	midi_grid_setting = {
		key = "ga_midi_grid_setting",
		type = gui_input_types.Combo,
		title = "Grid setting for MIDI Editor",
		description = "Select which grid you want to have. Use script 'ek_Adaptive grid' for more fine tuning",
		default = ga_grid_midi_id - 1,
		value = function()
			local _, id = AG_GetCurrentGrid(true)
			return id - 1
		end,
		select_values = ga_grid_titles,
		on_change = function(val)
			AG_SetCurrentGrid(true, val + 1)

			-- make not synced
			if AG_IsSyncedWithMidiEditor() then AG_ToggleSyncedWithMidiEditor() end
		end,
		disabled = not ga_enabled,
		order = 5,
	},
	project_limit = {
		key = "ga_project_limit",
		type = gui_input_types.Checkbox,
		title = "Automatically limit zoom to content of project",
		default = true,
		on_change = function(val)
			GA_UpdateProjectLimitSetting(val)
		end,
		disabled = not ga_enabled,
		order = 6,
	},
	project_limit_offset = {
		key = "ga_project_limit_offset",
		type = gui_input_types.NumberDrag,
		title = "Offset from the edge item",
		description = "Feature from Ableton: max zoom level limits by the farthest item in the project.",
		default = 0,
		number_precision = "%.0f%%",
		number_min = 0,
		disabled = not ga_enabled,
		order = 7,
	},
	focus_midi_editor = {
		key = "ga_focus_midi_editor",
		type = gui_input_types.Checkbox,
		title = "Automatically focus to MIDI editor when you click on an item",
		description = "Feature from Ableton: when you single click on item, you see only one MIDI editor and focus on this particular item.",
		default = true,
		disabled = not ga_enabled,
		order = 8,
	},
	auto_switch_track_on_preview = {
		key = "auto_switch_track_on_preview",
		type = gui_input_types.Checkbox,
		title = "Auto-Switch playback via selected track in Media Explorer",
		description = "If you use previewing in the \"Play through the first selected track\" mode in Media Explorer and want playback to follow the currently selected track.",
		default = false,
		disabled = not ga_enabled,
		order = 9,
	},
	highlight_buttons = {
		key = "ga_highlight_buttons",
		type = gui_input_types.Checkbox,
		title = "Automatically highlight buttons",
		description = "This option highlights toolbar buttons in real-time. This applies to scripts: 'ek_Toggle preserve pitch for selected items', 'ek_Toggle trim mode for selected trackes', 'ek_Toggle monitoring fx plugin'",
		default = true,
		disabled = not ga_enabled,
		order = 10,
	},
	mfx_slots_exclusive = {
		key = "ga_mfx_slots_exclusive",
		type = gui_input_types.Checkbox,
		title = "Toggle monitoring fx slots in exclusive mode",
		description = "If you use script 'ek_Toggle monitoring FX on slot 1-5' and want to toggle plugins between slots in monitoring chain exclusively (when you turn on some plugin, others are turning off)",
		default = false,
		disabled = not ga_enabled,
		order = 11,
	},
	rec_sample_rate = {
		key = "ga_rec_sample_rate",
		type = gui_input_types.Checkbox,
		title = "Different sample rate for recording",
		description = "This option useful for sound designers, who usually uses 48kHz and forget to increase the sampling rate before recording to get better recording quality.",
		default = false,
		disabled = not ga_enabled,
		order = 12,
	},
	rec_sample_rate_value = {
		key = "ga_rec_sample_rate_value",
		type = gui_input_types.Combo,
		title = "Sample rate for recording",
		description = "Specify your recording sample rate",
		select_values = {
			48000, 96000, 176400, 192000,
		},
		default = 1,
		disabled = not ga_enabled,
		order = 13,
	},
	dark_mode = {
		key = "ga_dark_mode",
		type = gui_input_types.Checkbox,
		title = "Use dark mode theme",
		description = "If you want to use special theme for dark mode, turn on this option.",
		default = false,
		disabled = not ga_enabled,
		order = 14,
	},
	dark_mode_theme = {
		key = "ga_dark_mode_theme_combo",
		type = gui_input_types.Combo,
		title = "Name of theme for dark mode",
		description = "Specify title of theme for dark mode. Note that, this theme should be in the same folder as a regular theme. Name should be with \".ReaperTheme\" extension",
		default = 0,
		select_values = ga_dark_theme_list,
		on_change = function(val)
			if ga_dark_theme_list[val + 1] then
				EK_SetExtState(ga_dark_theme_key, ga_dark_theme_list[val + 1])
			else
				EK_DeleteExtState(ga_dark_theme_key)
			end
		end,
		value = function()
			local val = GA_GetSettingValue(ga_settings.dark_mode_theme)
			local theme = GA_GetDarkTheme()

			if theme and ga_dark_theme_list[val + 1] == theme then
				return val
			else
				local isSet = false
				for key, row in pairs(ga_dark_theme_list) do
					if row == theme then
						val = key - 1
						EK_SetExtState(ga_settings.dark_mode_theme.key, val)
						isSet = true
					end
				end

				if not isSet and val ~= 0 then
					val = 0
					EK_SetExtState(ga_settings.dark_mode_theme.key, val)
				end

				return val
			end
		end,
		disabled = not ga_enabled,
		order = 15,
	},
	dark_mode_time = {
		key = "ga_dark_mode_time",
		type = gui_input_types.Text,
		title = "Dark mode time interval",
		description = "Specify time interval for dark mode. Format: \"HH:mm-HH:mm\"",
		default = "20:00-09:00",
		disabled = not ga_enabled,
		order = 16,
	},
	additional_action = {
		key = "ga_additional_action",
		type = gui_input_types.Text,
		title = "Additional global startup action",
		description = function(val)
			local description = ""

			if val ~= cachedAdditionalScriptVal.value then
				cachedAdditionalScriptVal.value = val
				cachedAdditionalScriptVal.title = reaper.kbd_getTextFromCmd(reaper.NamedCommandLookup(val), nil)
			end

			if (string.len(val) > 0 and string.len(cachedAdditionalScriptVal.title) == 0) then
				cachedAdditionalScriptVal.title = "(Incorrect command id)"
			end

			if string.len(cachedAdditionalScriptVal.title) > 0 then
				description = cachedAdditionalScriptVal.title .. "\n\n"
			end

			description = description .. "If you have your own action on startup, you can specified command Id and it will be executed on startup."

			return description
		end,
		default = "",
		disabled = not ga_enabled,
		order = 17,
	},
}

local _, dpi = reaper.ThemeLayout_GetLayout("tcp", -3)
if IS_WINDOWS then
	gfx.ext_retina = tonumber(dpi) >= 512 and 1 or 0
else
	gfx.ext_retina = tonumber(dpi) > 512 and 1 or 0
end

function GA_GetSettingValue(param)
	return EK_GetExtState(param.key, param.default)
end

--
-- Functions for monitoring FX button
--
function GA_GetEnabledMfxOnSlot(slot)
	local id = 0x1000000 + slot
	local masterTrack = reaper.GetMasterTrack(proj)

	return reaper.TrackFX_GetEnabled(masterTrack, id)
end

function GA_SetEnabledMfxOnSlot(slot, enabled)
	local id = 0x1000000 + slot
	local masterTrack = reaper.GetMasterTrack(proj)

	reaper.TrackFX_SetEnabled(masterTrack, id, enabled)
end

function GA_ToggleMfxBtnOnSlot(slot, btn, sectionID, cmdID)
	if GA_GetSettingValue(ga_settings.mfx_slots_exclusive) then
		local isAnySlotsEnabled = false
		for _, row in pairs(ga_slots_data) do
			if slot ~= row.slot then
				if not isAnySlotsEnabled and GA_GetEnabledMfxOnSlot(row.slot) then
					isAnySlotsEnabled = true
				end

				GA_SetEnabledMfxOnSlot(row.slot, false)
				GA_UpdateStateForButton(row.btn, 0)
			end
		end

		if isAnySlotsEnabled then
			GA_SetEnabledMfxOnSlot(slot, true)
		else
			GA_SetEnabledMfxOnSlot(slot, not GA_GetEnabledMfxOnSlot(slot))
		end
	else
		GA_SetEnabledMfxOnSlot(slot, not GA_GetEnabledMfxOnSlot(slot))
	end

	reaper.SetToggleCommandState(sectionID, cmdID, GA_GetEnabledMfxOnSlot(slot) and 1 or 0)
	reaper.RefreshToolbar2(sectionID, cmdID)
	GA_SetButtonForHighlight(btn, sectionID, cmdID)

	-- update audio connection just in case
	reaper.Audio_Quit()
	reaper.Audio_Init()
end

--
-- Update highlighting of buttons
--
function GA_SetButtonForHighlight(buttonKey, sectionID, cmdID)
	-- drop existed key
	for _, value in pairs(ga_highlight_buttons) do
		if buttonKey ~= value then
			local sid = tonumber(EK_GetExtState(ga_key_prefix .. ":" .. value .. ":section_id"))
			local cid = tonumber(EK_GetExtState(ga_key_prefix .. ":" .. value .. ":command_id"))

			if sid == sectionID and cid == cmdID then
				EK_DeleteExtState(ga_key_prefix .. ":" .. value .. ":section_id")
				EK_DeleteExtState(ga_key_prefix .. ":" .. value .. ":command_id")

				Log("[HIGHLIGHT] Button {param} uses actual ids, so it was deleted", ek_log_levels.Notice, value)
			end
		end
	end

	EK_SetExtState(ga_key_prefix .. ":" .. buttonKey .. ":section_id", sectionID)
	EK_SetExtState(ga_key_prefix .. ":" .. buttonKey .. ":command_id", cmdID)
end

function GA_UpdateStateForButton(buttonKey, state)
	local sectionID = EK_GetExtState(ga_key_prefix .. ":" .. buttonKey .. ":section_id")
	local cmdID = EK_GetExtState(ga_key_prefix .. ":" .. buttonKey .. ":command_id")
	if cmdID == nil then return end

	local old_state = reaper.GetToggleCommandStateEx(sectionID, cmdID)

	if old_state ~= state then
		Log("[HIGHLIGHT] Update button state: {param}; cmdID = " .. cmdID .. " state = " .. state, ek_log_levels.Notice, buttonKey)

		reaper.SetToggleCommandState(sectionID, cmdID, state)
		reaper.RefreshToolbar2(sectionID, cmdID)
	end
end

--
-- Observe Preserve Pitch Mode
--
function GA_ObservePreservePitchForSelectedItems(changes, values)
	if changes.project_path or changes.count_items or changes.count_selected_items or changes.first_selected_item then
		Log("[HIGHLIGHT] {param} - preserve pitch observing..", ek_log_levels.Notice, ga_settings.highlight_buttons.key)

		if values.count_selected_items > 0 then
			local count_On = 0
			local count_Off = 0

			for i = 0, values.count_selected_items - 1 do
				local item = reaper.GetSelectedMediaItem(proj, i)
				local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

				local itemTake = reaper.GetMediaItemTake(item, takeInd)

				if itemTake then
					local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "B_PPITCH")

					if mode == 1 then
						count_On = count_On + 1
					else
						count_Off = count_Off + 1
					end
				end
			end

			-- if all selected items has preserve pitch than highlight
			if values.count_selected_items == count_On then
				GA_UpdateStateForButton(ga_highlight_buttons.preserve_pitch, 1)
			else
				GA_UpdateStateForButton(ga_highlight_buttons.preserve_pitch, 0)
			end
		else
			GA_UpdateStateForButton(ga_highlight_buttons.preserve_pitch, 0)
		end
	end
end

--
-- Observe Automation Mode
--
function GA_ObserveAutomationModeForSelectedTracks(changes, values)
	if changes.project_path or changes.count_selected_tracks or changes.first_selected_track then
		Log("[HIGHLIGHT] {param} observing...", ek_log_levels.Notice, ga_settings.highlight_buttons.key)

		if values.count_selected_tracks > 0 then
			local count_On = 0
			local count_Off = 0

			for i = 0, values.count_selected_tracks - 1 do
				local track = reaper.GetSelectedTrack(proj, i)
				local mode = reaper.GetTrackAutomationMode(track)

				if mode == 2 then
					count_On = count_On + 1
				else
					count_Off = count_Off + 1
				end
			end

			-- if all selected items has preserve pitch than highlight
			if values.count_selected_tracks == count_On then
				GA_UpdateStateForButton(ga_highlight_buttons.trim_mode, 2)
			else
				GA_UpdateStateForButton(ga_highlight_buttons.trim_mode, 0)
			end
		else
			GA_UpdateStateForButton(ga_highlight_buttons.trim_mode, 0)
		end
	end
end

function GA_UpdateProjectLimitSetting(isSet)
	local value = isSet and 1 or 0

	local use = reaper.SNM_GetIntConfigVar("projmaxlenuse", 0)
	if use ~= value then
		reaper.SNM_SetIntConfigVar("projmaxlenuse", value)
	end
end
--
-- Observe Project Limit
--
function GA_ObserveProjectLimit(changes, values)
	Log("[PROJECT LIMIT] {param} observing...", ek_log_levels.Notice, ga_settings.project_limit.key)

	local maxLen = 0

	-- ITEMS --
	for i = 0, values.count_items - 1 do
		local item = reaper.GetMediaItem(proj, i)

		local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

		if (pos + len > maxLen) then maxLen = pos + len end
	end

	-- MARKERS/REGIONS --
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	for i = 0, num_markers + num_regions - 1 do
		local _, isrgn, pos, rgnend = reaper.EnumProjectMarkers(i)
		local r_pos = isrgn == true and rgnend or pos

		if (r_pos > maxLen) then maxLen = r_pos end
	end

	local offset = GA_GetSettingValue(ga_settings.project_limit_offset)
	if offset ~= 0 then
		offset = maxLen * (offset / 100)

		maxLen = maxLen + offset
	end

	if maxLen < 10 then maxLen = 10 end

	reaper.SNM_SetDoubleConfigVar("projmaxlen", maxLen)

	-- local isPlaying = values.play_state & 1 == 1
	-- local isRecording = values.play_state & 4 == 4

	if values.cursor_position >= maxLen or values.play_state & 1 == 1 or values.play_state & 4 == 4 then
		GA_UpdateProjectLimitSetting(false)
	else
		GA_UpdateProjectLimitSetting(maxLen > 0)
	end
end

--
-- Observe Monitoring Fx
--
function GA_ObserveMonitoringFx(changes, values)
	if changes.project_path or changes.play_state then
		for _, row in pairs(ga_slots_data) do
            local isEnabled = GA_GetEnabledMfxOnSlot(row.slot)
			GA_UpdateStateForButton(row.btn, isEnabled == true and 1 or 0)
        end

		local slot_id = EK_GetExtState(ga_highlight_buttons.mfx_slot_custom)
		if slot_id then
			local isEnabled = GA_GetEnabledMfxOnSlot(slot_id)
			GA_UpdateStateForButton(ga_highlight_buttons.mfx_slot_custom, isEnabled == true and 1 or 0)
		end

		Log("[HIGHLIGHT] {param} monitoring fx observing...", ek_log_levels.Notice, ga_settings.highlight_buttons.key)
	end
end

--
-- Observe MIDI Editor
--
function GA_ObserveMidiEditor(changes, values)
	if changes.first_selected_item or changes.count_selected_items then
		local midiEditor = reaper.MIDIEditor_GetActive()
		local state = reaper.MIDIEditor_GetMode(midiEditor)

		if state ~= -1 then
			Log("[MIDI EDITOR] {param} midi editor observing...", ek_log_levels.Warning, ga_settings.highlight_buttons.key)

			reaper.Main_OnCommand(reaper.NamedCommandLookup(40153), 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
		end

		GA_UpdateStateForButton(ga_highlight_buttons.midi_editor, state ~= -1 and 1 or 0)
	end
end

--
-- Observe overlaping items vertically option
--
function GA_ObserveOverlapingItemsVertically(changes, values)
	if changes.project_path or changes.play_state then
		local state = reaper.GetToggleCommandState(40507) -- Options: Offset overlapping media items vertically

		Log("[HIGHLIGHT] {param} - overlaping items vertically observing...", ek_log_levels.Notice, ga_settings.highlight_buttons.key)
		GA_UpdateStateForButton(ga_highlight_buttons.overlaping_items_vertically, state == 1 and 1 or 0)
	end
end

--
-- Observe Grid
--
function GA_ObserveGrid()
	local is_synced = AG_IsSyncedWithMidiEditor()
	local is_arrange_changed = AG_GridIsChanged()
	local is_midi_changed = AG_GridIsChanged(true)

	if is_arrange_changed or (is_synced and is_midi_changed) then
		local showGrid = reaper.SNM_GetIntConfigVar("projshowgrid", 0) & 1 > 0
		if showGrid then
			local grid = AG_GetCurrentGridValue()
			reaper.SetProjectGrid(proj, grid)

			Log("[GRID] Observing arrange grid... grid = {param} ", ek_log_levels.Notice, grid)
		end
	end

	if is_midi_changed or (is_synced and is_arrange_changed) then
		local MidiEditor = reaper.MIDIEditor_GetActive()
		if MidiEditor then
			local grid = AG_GetCurrentGridValue(true)
			if grid ~= nil then
				reaper.SetMIDIEditorGrid(0, grid)
				Log("[GRID] Observing midi grid... grid = {param} ", ek_log_levels.Notice, grid)
			end
		end
	end
end

--
-- Observe arm rec
--
local cached_first_selected_track_sample_rate_marked = nil

function GA_ObserveArmRec(changes, values)
	if values.first_selected_track ~= nil and values.first_selected_track ~= cached_first_selected_track_sample_rate_marked then
		local isArmed = reaper.GetMediaTrackInfo_Value(values.first_selected_track, "I_RECARM")
		local _, desc = reaper.GetAudioDeviceInfo("SRATE")
		local s_config = ga_settings.rec_sample_rate_value
		local setting = GA_GetSettingValue(s_config)
		local hasMidiProgram = reaper.HasTrackMIDIProgramsEx(proj, values.first_selected_track)

		setting = s_config.select_values[setting + 1]
		if not setting then setting = s_config.select_values[s_config.default + 1] end

		if isArmed == 1 and desc ~= setting and hasMidiProgram == nil then
			Log("[RECORD] {param} observing...", ek_log_levels.Warning, s_config.key)

			reaper.SNM_SetIntConfigVar("projsrate", setting)
			reaper.SNM_SetIntConfigVar("projsrateuse", 1)
			EK_ShowTooltip("Sample Rate has been changed to " .. setting .. " Hz")

			reaper.Audio_Quit()
			reaper.Audio_Init()

			cached_first_selected_track_sample_rate_marked = values.first_selected_track
		end
	end
end

local function inTimeInterval(stParam, edParam)
	local time = os.time()
	local date = os.date("*t")

	local startTime = modifyTime(date, {
		hour = stParam.hour,
		min = stParam.min,
	})

	local endTime = modifyTime(date, {
		hour = edParam.hour,
		min = edParam.min,
	})

	if startTime == endTime then
		return false
	elseif endTime <= startTime then -- 20:00 / 09:00
		if date.hour >= os.date("*t", startTime).hour then
			endTime = modifyTime(date, {
				day = date.day + 1,
				hour = edParam.hour,
				min = edParam.min,
			})
		else
			startTime = modifyTime(date, {
				day = date.day - 1,
				hour = stParam.hour,
				min = stParam.min,
			})
		end
	end

	return time >= startTime and time <= endTime
end

local observe_dark_mode_last_time = 0
local observe_dark_mode_cooldown = 60

--
-- Dark theme
--
function GA_ObserveDarkMode(changes, values)
	local time = reaper.time_precise()
	if time < observe_dark_mode_last_time + observe_dark_mode_cooldown then
		return
	end

	observe_dark_mode_last_time = time

	local timeInterval = GA_GetSettingValue(ga_settings.dark_mode_time)
	if not timeInterval then return end

	local hours = split(timeInterval, "-")
	if not hours[1] or not hours[2] then return end

	local startHours = split(hours[1], ":")
	if not startHours[1] or not startHours[2] then return end

	local endHours = split(hours[2], ":")
	if not endHours[1] or not endHours[2] then return end

	local startParam = {
		hour = tonumber(startHours[1]),
		min = tonumber(startHours[2]),
	}

	local endParam = {
		hour = tonumber(endHours[1]),
		min = tonumber(endHours[2])
	}

	local inInterval = inTimeInterval(startParam, endParam)
	local themeName = GA_GetDarkTheme()

	if themeName == nil then themeName = "" end

	local theme_key = ga_key_prefix .. "cached_dark_mode_theme"
	local is_executed_key = ga_key_prefix .. "is_executed_dark_switch"
	local curThemeNamePath = reaper.GetLastColorThemeFile()
	local curThemeNamePathPart = split(curThemeNamePath, dir_sep)
	local curThemeName = curThemeNamePathPart[#curThemeNamePathPart]
	if not curThemeName then curThemeName = "" end
	local themePath = curThemeNamePath:match("(.*" .. dir_sep .. ")")
	local isExecutedToday = EK_GetExtState(is_executed_key)

	Log("[DARK THEME] Observing...", ek_log_levels.Notice)
	Log({ inInterval and 1 or 0, themeName, curThemeName, EK_GetExtState(theme_key) }, ek_log_levels.Notice)

	if reaper.file_exists(themePath .. themeName .. ".ReaperTheme") then
		themeName = themeName .. ".ReaperTheme"
	elseif reaper.file_exists(themePath .. themeName .. ".ReaperThemeZip") then
		themeName = themeName .. ".ReaperThemeZip"
	else
		Log("[DARK THEME] Theme \"{param}\" does not exists", ek_log_levels.Important, themePath .. themeName)
		EK_DeleteExtState(ga_dark_theme_key)
		return
	end

	if inInterval and curThemeName ~= themeName then
		EK_SetExtState(theme_key, curThemeName)
		reaper.OpenColorThemeFile(themePath .. themeName)
		Log("[DARK THEME] Turn on dark mode to \"{param}\"", ek_log_levels.Important, themeName)
		EK_DeleteExtState(is_executed_key, false)
	elseif not inInterval and not isExecutedToday and curThemeName == themeName then
		local curThemeNameCached = EK_GetExtState(theme_key)

		if curThemeNameCached ~= nil and curThemeNameCached ~= curThemeName then
			reaper.OpenColorThemeFile(themePath .. curThemeNameCached)
			Log("[DARK THEME] Turn on light mode to \"{param}\"", ek_log_levels.Important, curThemeNameCached)
			EK_SetExtState(is_executed_key, true, false, true)
		end
	end
end

--
-- Tracking time
--
local pwt_key = "pwt_working_time"
local pwt_project_created
local pwt_accrue_time = 0
local pwt_accrue_time_text = ""
local pwt_downtime_time = 0
local pwt_accrue_cooldown = 60 -- 1 min
local pwt_downtime_cooldown = 240 -- 4 min
local pwt_play_state = 0

local function GA_GetProjectWorkingTime(accrueBy)
	local currentTime = EK_GetExtState(pwt_key, 0, true)

	if accrueBy ~= nil then
		currentTime = currentTime + accrueBy

		if currentTime < 0 then currentTime = 0 end
		EK_SetExtState(pwt_key, currentTime, true)
	end

	return currentTime
end

function GA_GetProjectWorkingInfo()
	local isEnabled = EK_IsGlobalActionEnabled() and GA_GetSettingValue(ga_settings.track_time)

	if not isEnabled then return end

	if pwt_project_created == nil then
		local path = reaper.GetProjectPath()

		if string.len(path) > 0 then
			pwt_project_created = EK_GetFileDate(path, true)
		else
			pwt_project_created = false
		end
	end

	if pwt_project_created ~= false then
		local time = GA_GetProjectWorkingTime()
		if time ~= pwt_accrue_time then
			pwt_accrue_time = time
			local days, hours, minutes, _ = EK_GetTime(pwt_accrue_time)

			if pwt_accrue_time < 60 then
				pwt_accrue_time_text = "Less than 1m."
			elseif days == 0 then
				pwt_accrue_time_text = string.format("%02d:%02d", hours, minutes)
			else
				pwt_accrue_time_text = string.format("%dd. %02d:%02d", days, hours, minutes)
			end
		end
	end

	return pwt_project_created, pwt_accrue_time_text
end

function GA_ObserveProjectWorkingTime(something_is_changed, values)
	local time = reaper.time_precise()

	-- accrue timer
	if time	> pwt_accrue_time + pwt_accrue_cooldown and (time < pwt_downtime_time or pwt_play_state & 1 == 1) then
		pwt_accrue_time = time
		local currentTime = GA_GetProjectWorkingTime(pwt_accrue_cooldown)
		local _, projfn = reaper.EnumProjects(-1)

		Log("[TRACK TIME] Accruing " .. pwt_accrue_cooldown .. "s., New time: " .. currentTime .. "s., Project: \"" .. projfn .. "\"", ek_log_levels.Notice)
	end

	-- check downtime
	if something_is_changed then
		pwt_downtime_time = time + pwt_downtime_cooldown
		pwt_play_state = values.play_state
	end
end

function GA_ObservePlayStateInMediaExplorer()
	local isPlaying = EK_GetExtState(ga_me_state_is_playing)

	if not EK_GetExtState(ga_auto_switch_preview_me) then
		if isPlaying then EK_SetExtState(ga_me_state_is_playing, false) end
		return
	end

	local media_explorer = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer", 'common'), true)
	if not media_explorer and isPlaying then
		if isPlaying then EK_SetExtState(ga_me_state_is_playing, false) end
		return
	end

	local mx_timer_view = reaper.JS_Window_FindChildByID(media_explorer, 1016)
	if not mx_timer_view then
		if isPlaying then EK_SetExtState(ga_me_state_is_playing, false) end
		return
	end

	local current, length = string.match(reaper.JS_Window_GetTitle(mx_timer_view), "(.-)/(.*)")
	if not length then
		if isPlaying then EK_SetExtState(ga_me_state_is_playing, false) end
		return
	end

	local total_seconds = 0
	local last_time = EK_GetExtState(ga_me_current_time, 0)
	if string.match(current, "^%d+:%d%d%.%d%d%d$") ~= nil then
		-- 0:02.924 (Seconds)
		local minutes, seconds, milliseconds = string.match(current, "(%d+):(%d+)%.(%d+)")
		total_seconds = tonumber(minutes) * 60 + tonumber(seconds) + tonumber(milliseconds) / 1000
	else
		-- 1.324 (Beats)
		total_seconds = tonumber(current)
	end

	if total_seconds ~= last_time and not isPlaying then
		EK_SetExtState(ga_me_state_is_playing, true)
	elseif total_seconds == last_time and isPlaying then
		EK_SetExtState(ga_me_state_is_playing, false)
	end

	if last_time ~= total_seconds then
		EK_SetExtState(ga_me_current_time, total_seconds)
	end
end

function GA_ObserveAutoSwitchTrackInMediaExplorer(something_is_changed, values)
	local output = GetReaperIniValue(IS_WINDOWS and "reaper_explorer" or "reaper_sexplorer", "outputidx")
	local isEnabled = EK_GetExtState(ga_auto_switch_preview_me)

	if output == -1 and not isEnabled then
		EK_SetExtState(ga_auto_switch_preview_me, true)
	elseif output ~= -1 and isEnabled then
		EK_DeleteExtState(ga_auto_switch_preview_me)
	end

	local isPlaying = EK_GetExtState(ga_me_state_is_playing)
	if isPlaying then
		local media_explorer = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer", 'common'), true)
		if media_explorer then
			-- Preview: Display position in whole seconds or beats (must be disabled)
			if reaper.GetToggleCommandStateEx(32063, 40032) == 1 then
				reaper.JS_Window_OnCommand(media_explorer, 40032)
			end

			reaper.JS_Window_OnCommand(media_explorer, 1010) -- Preview: Pause
			reaper.JS_Window_OnCommand(media_explorer, 1008) -- Preview: Play
		end
	end

	Log("Media Explorer playing state: " .. tostring(isPlaying), ek_log_levels.Warning)
end

function getDfiItem()
	local guid = EK_GetExtState("delayed_first_selected_item")

	if guid then
		for i = 0, reaper.CountMediaItems(proj) - 1 do
			local item = reaper.GetMediaItem(proj, i)

			if reaper.ValidatePtr(item, "MediaItem*") then
				local _, id = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
				if guid == id then
					return item
				end
			end
		end
	else
		return nil
	end
end

function setDfiItem(item)
	local guid = ""

	if reaper.ValidatePtr(item, "MediaItem*") then
		_, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
	end

	EK_SetExtState("delayed_first_selected_item", guid)
end

--
-- Setting global action via __startup.lua
--
local function GA_ToggleCommentLineInContent(line, content, is_comment)
	local s_start, s_end

	if is_comment then s_start, s_end = content:find(line)
	else s_start, s_end = content:find("-- " .. line) end

	if not s_start or not s_end then return content end

	line = line:gsub("%%", "")

	return is_comment and
		content:sub(1, s_start - 1) .. "-- " .. line .. content:sub(s_end + 1) or
		content:sub(1, s_start - 1) .. line .. content:sub(s_end + 1)
end

function GA_EnableStartupHook()
    local res_path = reaper.GetResourcePath()
	local script_name = "Custom: ek_Global startup action.lua"
    local startup_path = EK_ConcatPath(res_path, 'Scripts', '__startup.lua')
    local cmd_name = EK_LookupCommandIdByName(script_name)
	local content

	local startup_file = io.open(startup_path, 'r')
	if startup_file then
		content = startup_file:read('*a')
		startup_file:close()
	end

	if content and content:match(script_name) then
		local new_content = content
		new_content = GA_ToggleCommentLineInContent('reaper.SetExtState%("ek_stuff", "ek_startup_enabled", 1, false%)', new_content)
		new_content = GA_ToggleCommentLineInContent('reaper.Main_OnCommand%(reaper.NamedCommandLookup%("_' .. cmd_name ..'"%), 0%)', new_content)

		if new_content ~= content then
			startup_file = io.open(startup_path, 'w')
			startup_file:write(new_content)
			startup_file:close()

			return true
		end
	else
		-- not exists
		local hook = '-- %s\n'
		hook = hook .. 'reaper.SetExtState("ek_stuff", "ek_startup_enabled", 1, false)\n'
		hook = hook .. 'reaper.Main_OnCommand(reaper.NamedCommandLookup("_%s"), 0)'
		hook = hook:format(script_name, cmd_name)

		startup_file = io.open(startup_path, 'w')
		startup_file:write(content and content .. '\n\n' .. hook or hook)
		startup_file:close()

		return true
	end

	return false
end

function GA_DisableStartupHook()
	local res_path = reaper.GetResourcePath()
	local script_name = "Custom: ek_Global startup action.lua"
    local startup_path = EK_ConcatPath(res_path, 'Scripts', '__startup.lua')
    local cmd_name = EK_LookupCommandIdByName(script_name)
	local content

	local startup_file = io.open(startup_path, 'r')
	if not startup_file then return false end

	content = startup_file:read('*a')
	startup_file:close()

	if not content or not content:match(script_name) then return false end

	local new_content = content
	new_content = GA_ToggleCommentLineInContent('reaper.SetExtState%("ek_stuff", "ek_startup_enabled", 1, false%)', new_content, true)
	new_content = GA_ToggleCommentLineInContent('reaper.Main_OnCommand%(reaper.NamedCommandLookup%("_' .. cmd_name ..'"%), 0%)', new_content, true)

	if new_content ~= content then
		startup_file = io.open(startup_path, 'w')
		startup_file:write(new_content)
		startup_file:close()

		return true
	else
		return false
	end
end