-- @description ek_Global startup action
-- @version 1.0.4
-- @author Ed Kashinsky
-- @about
--   This is startup action brings some ableton-like features in realtime. You can control any option by 'ek_Global startup action settings' script.
--
--   For installation:
--      1. Install this script via **Extensions** -> **ReaPack** -> **Browse Packages**
--      2. Open **Actions** -> **Action List**
--      3. Find "Script: ek_Global startup action" in list and select "Copy selected action command ID" by right mouse click
--      4. Open **Extensions** -> **Startup Actions** -> **Set Global Startup Action...** and paste copied command ID
--      5. Restart Reaper
--      6. Open 'ek_Global startup action settings' for customize options
-- @changelog
--   - Bugs fixes
--   - Added dark mode theme feature
--   - Added settings window
--   - Added customizable options for realtime
-- 	 - Observing of backups works only if you turn up "Timestamp backups" in Preferences
-- @provides
--   ek_Core functions startup.lua

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

CoreFunctionsLoaded("ek_Core functions startup.lua")

local cached_changes = {
	play_state = 0,
	count_items = 0,
	count_selected_tracks = 0,
	count_selected_items = 0,
	first_selected_track = nil,
	first_selected_item = nil,
}

function isChanged(value, param) 
	local cached = cached_changes[param]
	cached_changes[param] = value

	return value ~= cached
end

function observeGlobalAction()
	local something_is_changed = false
	local changes = {
		play_state = isChanged(reaper.GetPlayState(), "play_state"),
		count_items = isChanged(reaper.CountMediaItems(proj), "count_items"),
		count_selected_tracks = isChanged(reaper.CountSelectedTracks(proj), "count_selected_tracks"),
		count_selected_items = isChanged(reaper.CountSelectedMediaItems(proj), "count_selected_items"),
		first_selected_track = isChanged(reaper.GetSelectedTrack(proj, 0), "first_selected_track"),
		first_selected_item = isChanged(reaper.GetSelectedMediaItem(proj, 0), "first_selected_item"),
	}

	for key, is_changed in pairs(changes) do
		if is_changed then
			something_is_changed = true
			goto end_of_changes
		end
	end

	::end_of_changes::

	if something_is_changed then
		Log("Something has changed: \n {param}", ek_log_levels.Notice, changes)

		-- Highlighting of buttons
		if GA_GetSettingValue(ga_settings.highlight_buttons) then
			GA_ObservePreservePitchForSelectedItems(changes, cached_changes)
			GA_ObserveAutomationModeForSelectedTracks(changes, cached_changes)
			GA_ObserveMonitoringFx(changes, cached_changes)
			GA_ObserveOverlapingItemsVertically(changes, cached_changes)
		end

		-- Focus of MIDI Editor
		if GA_GetSettingValue(ga_settings.focus_midi_editor) then
			GA_ObserveMidiEditor(changes, cached_changes)
		end

		-- Project Limit
		if GA_GetSettingValue(ga_settings.project_limit) then
			GA_ObserveProjectLimit(changes, cached_changes)
		end
	end

	-- Auto grid
	if GA_GetSettingValue(ga_settings.auto_grid) then
		GA_ObserveArrangeGrid()
	end

	-- Up Sample Rate
	if GA_GetSettingValue(ga_settings.rec_sample_rate) then
		GA_ObserveArmRec(changes, cached_changes)
	end

	-- Backup files
	if GA_GetSettingValue(ga_settings.backup_files) then
		GA_ObserveAndRemoveOldBackupFiles(changes, cached_changes)
	end

	-- Dark mode
	if GA_GetSettingValue(ga_settings.dark_mode) then
		GA_ObserveDarkMode(changes, cached_changes)
	end

	reaper.defer(observeGlobalAction)
end

observeGlobalAction()

local command = reaper.NamedCommandLookup(GA_GetSettingValue(ga_settings.additional_action))
if command ~= 0 then
	Log("Additional actions has been executed: {param}", ek_log_levels.Notice, command)
	reaper.Main_OnCommand(command, 0)
end

EK_SetIsGlobalActionEnabled()