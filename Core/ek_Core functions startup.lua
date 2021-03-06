-- @description ek_Core functions startup
-- @author Ed Kashinsky
-- @noindex

local ga_key_prefix = "ga_"
ga_highlight_buttons = {
    monitoring_fx = "monitoring_fx_btn",
    preserve_pitch = "preserve_pitch_btn",
    trim_mode = "trim_mode_btn",
    midi_editor = "midi_editor_btn",
	overlaping_items_vertically = "overlaping_items_vertically"
}

ga_settings = {
	auto_grid = {
		key = "auto_grid",
		title = "Automatically adjust grid to zoom",
		description = "Feature from Ableton: when you change zoom level, grid adjusts to it. By the way, if you want to have this feature in MIDI-editor, install script 'ek_Auto grid for MIDI Editor'.",
		default = true,
		order = 1,
	},
	project_limit = {
		key = "project_limit",
		title = "Automatically limit zoom to content of project",
		description = "Feature from Ableton: max zoom level limits by the farthest item in the project.",
		default = true,
		order = 2,
	},
	focus_midi_editor = {
		key = "focus_midi_editor",
		title = "Automatically focus to MIDI editor when you click on an item",
		description = "Feature from Ableton: when you single click on item, you see only one MIDI editor and focus on this particular item.",
		default = true,
		order = 3,
	},
	highlight_buttons = {
		key = "highlight_buttons",
		title = "Automatically highlight buttons",
		description = "This option highlights toolbar buttons in real-time. This applies to scripts: 'ek_Toggle preserve pitch for selected items', 'ek_Toggle trim mode for selected trackes', 'ek_Toggle monitoring fx plugin'",
		default = true,
		order = 4,
	},
	monitoring_fx_plugin = {
		key = "monitoring_fx_plugin",
		title = "Check plugin status on monitoring FX",
		description = "If you use spectrum correction plugins (such as Realphones, Sonarworks Reference 4, SoundID Reference and etc.) on Monitoring FX when using headphones, you can always see if the plugin is enabled. For using it, add script 'ek_Toggle monitoring fx plugin' to your toolbar and this button will be highlighted automatically when the plugin on monitoring FX is enabled.",
		default = "Realphones",
		order = 5,
	},
	rec_sample_rate = {
		key = "rec_sample_rate",
		title = "Different sample rate for recording",
		description = "This option useful for sound designers, who usually uses 48kHz and forget to increase the sampling rate before recording to get better recording quality.",
		default = false,
		order = 6,
	},
	rec_sample_rate_value = {
		key = "rec_sample_rate_value",
		title = "Sample rate for recording",
		description = "Specify your recording sample rate",
		default = 96000,
		order = 7,
	},
	backup_files = {
		key = "backup_files",
		title = "Automatic limit timestamp backup files",
		description = "If you want to keep only last limited amount of backup files, you can enable this option. Make sure that option 'Timestamp backup' is on in general preferences.",
		default = false,
		order = 8,
	},
	backup_files_limit = {
		key = "backup_files_limit",
		title = "Amount of backup files",
		description = "Specify count of fresh backup files you want to keep.",
		default = 5,
		order = 9,
	},
	dark_mode = {
		key = "dark_mode",
		title = "Use dark mode theme",
		description = "If you want to use special theme for dark mode, turn on this option.",
		default = false,
		order = 10,
	},
	dark_mode_theme = {
		key = "dark_mode_theme",
		title = "Name of theme for dark mode",
		description = "Specify title of theme for dark mode. Note that, this theme should be in the same folder as a regular theme. Name should be with \".ReaperTheme\" extension",
		default = "",
		order = 11,
	},
	dark_mode_time = {
		key = "dark_mode_time",
		title = "Dark mode time interval",
		description = "Specify time interval for dark mode. Format: \"HH:mm-HH:mm\"",
		default = "20:00-09:00",
		order = 12,
	},
	additional_action = {
		key = "additional_action",
		title = "Additional global startup action",
		description = "If you have your own action on startup, you can specified command Id and it will be executed on startup.",
		default = "",
		order = 13,
	},
}

function GA_GetOrderedSettings()
	local ordered_settings = {}

	for key, setting in pairs(ga_settings) do
		ordered_settings[setting.order] = setting
	end

	return ordered_settings
end

function GA_GetSettingValue(param)
	return EK_GetExtState(ga_key_prefix .. param.key, param.default)
end

function GA_SetSettingValue(param, value)
	EK_SetExtState(ga_key_prefix .. param.key, value)
end

--
-- Functions for monitoring FX button
--
function EK_GetMonitoringFxIndexOnMasterTrack()
    local masterTrack = reaper.GetMasterTrack(proj)
	local retval, buf
	local start = 0x1000000
    local MonitoringFx = GA_GetSettingValue(ga_settings.monitoring_fx_plugin)

	for i = 0, 20 do
		buf = ""
		retval, buf = reaper.TrackFX_GetFXName(masterTrack, start + i, buf)

		if retval then
			local find = string.find(buf, MonitoringFx)

			if find ~= nil then
				return start + i
			end
		end
	end

	return -1
end

function EK_GetMonitoringFxEnabledOnMasterTrack()
    local masterTrack = reaper.GetMasterTrack(proj)
	local fxInd = EK_GetMonitoringFxIndexOnMasterTrack()

	if fxInd >= 0 then
		return reaper.TrackFX_GetEnabled(masterTrack, fxInd)
	else
		return nil
	end
end

--
-- Update highlighting of buttons
--
function GA_SetButtonForHighlight(buttonKey, sectionID, cmdID)
	EK_SetExtState(ga_key_prefix .. ":" .. buttonKey .. ":section_id", sectionID)
	EK_SetExtState(ga_key_prefix .. ":" .. buttonKey .. ":command_id", cmdID)
end

function GA_UpdateStateForButton(buttonKey, state)
	local sectionID = EK_GetExtState(ga_key_prefix .. ":" .. buttonKey .. ":section_id")
	local cmdID = EK_GetExtState(ga_key_prefix .. ":" .. buttonKey .. ":command_id")
	if cmdID == nil then return end

	local old_state = reaper.GetToggleCommandStateEx(sectionID, cmdID)

	if old_state ~= state then
		Log("Update button state: " .. buttonKey .. "; cmdID = " .. cmdID .. " state = " .. state, ek_log_levels.Notice)

		reaper.SetToggleCommandState(sectionID, cmdID, state)
		reaper.RefreshToolbar2(sectionID, cmdID)
	end
end

--
-- Observe Preserve Pitch Mode
--
function GA_ObservePreservePitchForSelectedItems(changes, values)
	if changes.count_items or changes.count_selected_items or changes.first_selected_item then
		Log("Changed: {param} - preserve pitch", ek_log_levels.Warning, ga_settings.highlight_buttons.key)

		if values.count_selected_items > 0 then
			local count_On = 0
			local count_Off = 0

			for i = 0, values.count_selected_items - 1 do
				local item = reaper.GetSelectedMediaItem(proj, i)
				local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

				local itemTake = reaper.GetMediaItemTake(item, takeInd)

				local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "B_PPITCH")

				if mode == 1 then
					count_On = count_On + 1
				else
					count_Off = count_Off + 1
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
	if changes.count_selected_tracks or changes.first_selected_track then
		Log("Changed: {param} - trim mode", ek_log_levels.Warning, ga_settings.highlight_buttons.key)

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


--
-- Observe Project Limit
--
function GA_ObserveProjectLimit(changes, values)
	Log("Changed: {param}", ek_log_levels.Warning, ga_settings.project_limit.key)

	local use = reaper.SNM_GetIntConfigVar("projmaxlenuse", 1)
	if use == 0 then
		reaper.SNM_SetIntConfigVar("projmaxlenuse", 1)
	end

	if changes.play_state then
		local playingByte = 1
		local limit = reaper.SNM_GetDoubleConfigVar("projmaxlen", 0)
		local cursorPosition = reaper.GetPlayPosition2()

		-- IF PLAYING WITH TURNED ON "Limit project length, stop playback/recording at"
		if values.play_state & playingByte == playingByte and cursorPosition >= limit then
			reaper.SNM_SetIntConfigVar("projmaxlenuse", 0)
		elseif values.play_state & playingByte ~= playingByte then
			reaper.SNM_SetIntConfigVar("projmaxlenuse", 1)
		end
	end

	local maxLen = 0

	for i = 0, values.count_items - 1 do
		local item = reaper.GetMediaItem(proj, i)

		local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

		if (pos + len > maxLen) then
			maxLen = pos + len
		end
	end

	if maxLen < 10 then
		maxLen = 10
	end

	reaper.SNM_SetDoubleConfigVar("projmaxlen", maxLen)
end

--
-- Observe Monitoring Fx
--
function GA_ObserveMonitoringFx(changes, values)
	if changes.play_state then
		local isEnabled = EK_GetMonitoringFxEnabledOnMasterTrack()

		Log("Changed: {param} - monitoring fx", ek_log_levels.Warning, ga_settings.highlight_buttons.key)
		GA_UpdateStateForButton(ga_highlight_buttons.monitoring_fx, isEnabled == true and 1 or 0)
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
			Log("Changed: {param} - midi editor", ek_log_levels.Warning, ga_settings.highlight_buttons.key)

			reaper.Main_OnCommand(reaper.NamedCommandLookup(40153), 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
		end

		GA_UpdateStateForButton(ga_highlight_buttons.midi_editor, state ~= -1 and 1 or 0)
	end
end

--
-- Observe overlaping items vertically option
--
function GA_ObserveOverlapingItemsVertically(changes, values)
	if changes.play_state then
		local state = reaper.GetToggleCommandState(40507) -- Options: Offset overlapping media items vertically

		Log("Changed: {param} - overlaping items vertically " .. state, ek_log_levels.Warning, ga_settings.highlight_buttons.key)
		GA_UpdateStateForButton(ga_highlight_buttons.overlaping_items_vertically, state == 1 and 1 or 0)
	end
end

--
-- Observe Grid in Arrange View
--
local cached_zoom_level

function GA_ObserveArrangeGrid()
    local getOrderByZoomLevel = function(level)
	    local order

        if level <= 1 then
            order = -3
        elseif level < 3 then
            order = -2
        elseif level < 5 then
            order = -1
        elseif level < 15 then
            order = 0
        elseif level < 25 then
            order = 1
        elseif level < 55 then
            order = 2
        elseif level < 110 then
            order = 3
        elseif level < 220 then
            order = 4
        elseif level < 450 then
            order = 5
        elseif level < 850 then
            order = 6
        elseif level < 1600 then
            order = 7
        elseif level < 3500 then
            order = 8
        elseif level < 6700 then
            order = 9
        elseif level < 12000 then
            order = 10
        elseif level < 30000 then
            order = 11
        elseif level < 45200 then
            order = 12
        elseif level < 55100 then
            order = 13
        elseif level < 80000 then
            order = 14
        elseif level < 110000 then
            order = 15
        elseif level < 150000 then
            order = 16
        else
            order = 17
        end
        return order
    end
    local getNoteDivision = function(order)
        if order < 0 then
            return 2 * math.abs(order)
        else
            return 1 / (2 ^ order)
        end
    end
	local zoom_level = math.floor(reaper.GetHZoomLevel())

	if zoom_level ~= cached_zoom_level then
		Log("Changed: {param}", ek_log_levels.Warning, ga_settings.auto_grid.key)

		local order = getOrderByZoomLevel(zoom_level)

		reaper.SetProjectGrid(proj, getNoteDivision(order))
		cached_zoom_level = zoom_level
	end
end

--
-- Observe arm rec
--
local cached_first_selected_track_sample_rate_marked = nil

function GA_ObserveArmRec(changes, values)
	if values.first_selected_track ~= nil and values.first_selected_track ~= cached_first_selected_track_sample_rate_marked then
		local isArmed = reaper.GetMediaTrackInfo_Value(values.first_selected_track, "I_RECARM")
		local retval, desc = reaper.GetAudioDeviceInfo("SRATE")
		local setting = GA_GetSettingValue(ga_settings.rec_sample_rate_value)
		local hasMidiProgram = reaper.HasTrackMIDIProgramsEx(proj, values.first_selected_track)

		if isArmed == 1 and desc ~= setting and hasMidiProgram == nil then
			Log("Changed: {param}", ek_log_levels.Warning, ga_settings.rec_sample_rate.key)

			reaper.SNM_SetIntConfigVar("projsrate", setting)
			reaper.SNM_SetIntConfigVar("projsrateuse", 1)
			EK_ShowTooltip("Sample Rate has been changed to " .. setting .. " Hz")

			reaper.Audio_Quit()
			reaper.Audio_Init()

			cached_first_selected_track_sample_rate_marked = values.first_selected_track
		end
	end
end


--
-- Backup projects
--
local opts = reaper.SNM_GetIntConfigVar("saveopts", 0)
local enabledBackups = opts & 16 > 0
local cached_backup_last_time = 0
local backup_timer_limit = (reaper.SNM_GetIntConfigVar("autosaveint", 1) * 60) + 5

function GA_ObserveAndRemoveOldBackupFiles(changes, values)
	if not enabledBackups then return end

	local time = reaper.time_precise()
	if time > cached_backup_last_time + backup_timer_limit then
		Log("Changed: {param}", ek_log_levels.Warning, ga_settings.backup_files.key)

		cached_backup_last_time = time + backup_timer_limit

		local i = 0
		local file
		local backup_files = {}

		local root = reaper.GetProjectPath() .. "/../"
		local project = string.gsub(reaper.GetProjectName(proj), ".[rR][pP][pP]", "")
		local pattern = project .. "[0-9_-]+[.]rpp[-]bak"

		if string.len(project) == 0 then
			return
		end

		while file ~= nil or i == 0 do
			file = reaper.EnumerateFiles(root, i)

			if file ~= nil and string.match(file, pattern) then
				table.insert(backup_files, file)
			end

			i = i + 1
		end

		local max_limit = tonumber(GA_GetSettingValue(ga_settings.backup_files_limit))
		if #backup_files > max_limit then
			table.sort(backup_files)

			for j = 1, #backup_files - max_limit do
				Log("To delete " .. backup_files[j], ek_log_levels.Notice)

				os.remove(root .. backup_files[j])
			end
		end
	end
end

local function inTimeInterval(stParam, edParam)
	local time = math.floor(reaper.time_precise())
	local date = os.date("*t", time)

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

function GA_ObserveDarkMode(changes, values)
	local timeInterval = GA_GetSettingValue(ga_settings.dark_mode_time)
	local themeName = GA_GetSettingValue(ga_settings.dark_mode_theme)

	if not timeInterval or not themeName then return end

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

	local theme_key = ga_key_prefix .. "cached_dark_mode_theme"
	local curThemeNamePath = reaper.GetLastColorThemeFile()
	local curThemeNamePathPart = split(curThemeNamePath, dir_sep)
	local curThemeName = curThemeNamePathPart[#curThemeNamePathPart]
	if not curThemeName then curThemeName = "" end
	local inInterval = inTimeInterval(startParam, endParam)
	local themePath = string.gsub(curThemeNamePath, curThemeName, "")

	-- Log((inInterval and 1 or 0) .. " " .. themeName .. " " .. curThemeName .. " " .. EK_GetExtState(theme_key), ek_log_levels.Notice)

	if inInterval and curThemeName ~= themeName then
		EK_SetExtState(theme_key, curThemeName)
		reaper.OpenColorThemeFile(themePath .. "/" .. themeName)
		Log("Turn on dark mode to " .. themeName)
	elseif not inInterval and curThemeName == themeName then
		local curThemeNameCached = EK_GetExtState(theme_key)

		if curThemeNameCached ~= nil and curThemeNameCached ~= curThemeName then
			reaper.OpenColorThemeFile(themePath .. "/" .. curThemeNameCached)
			Log("Turn on light mode to " .. curThemeNameCached)
		end
	end
end