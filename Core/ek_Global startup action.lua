-- @description ek_Global startup action
-- @version 1.0.45
-- @author Ed Kashinsky
-- @about
--   This is startup action brings some ableton-like features in realtime. You can control any option by 'ek_Global startup action settings' script.
--
--   For installation:
--      1. Install 'ek_Core functions.lua'
--		2. Install this script via **Extensions** -> **ReaPack** -> **Browse Packages**
--	    3. Open script 'ek_Global startup action settings' and turn on "Enable global action"
--      4. Restart Reaper
--      5. Open 'ek_Global startup action settings' again for customize options
--      6. If you want to use auto-grid for MIDI Editor, install script **ek_Auto grid for MIDI Editor** and set it on zoom shortcut.
-- @changelog
--   Fixed bug when theme for dark mode is being cleared
-- @provides
--   ek_Core functions startup.lua
--   ek_Adaptive grid functions.lua
--   [main=main] ek_Global startup action - settings.lua

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
	if loaded == nil then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
	end
	return
end

CoreFunctionsLoaded("ek_Core functions startup.lua")

local cached_changes = {
	project_path = nil,
	play_state = 0,
	cursor_position = 0,
	count_items = 0,
	count_selected_tracks = 0,
	count_selected_items = 0,
	first_selected_track = nil,
	first_selected_item = nil,
}

local ga_cooldown = 0.2
local ga_last_time = reaper.time_precise()

local dfi_time = reaper.time_precise()
local dfi_time_delay = 0.2
local dfi_item = nil
local dfi_is_executed = false
local function updateDfiItem()
	-- delayed mode
	if reaper.time_precise() < dfi_time + dfi_time_delay then
		reaper.defer(updateDfiItem)
		return
	end

	setDfiItem(dfi_item)
	dfi_is_executed = false
end

local function isChanged(value, param)
	local cached = cached_changes[param]
	cached_changes[param] = value

	if param == "first_selected_item" and dfi_item ~= value then
		dfi_item = value

		if not dfi_is_executed then
			dfi_is_executed = true
			dfi_time = reaper.time_precise()
			updateDfiItem()
		end
	end

	return value ~= cached
end

local function observeGlobalAction()
	local time_precise = reaper.time_precise()
	if time_precise < ga_last_time + ga_cooldown then
		reaper.defer(observeGlobalAction)
		return
	end

	ga_last_time = time_precise

	local something_is_changed = false
	local changes = {
		project_path = isChanged(reaper.GetProjectPath(), "project_path"),
		play_state = isChanged(reaper.GetPlayState(), "play_state"),
		cursor_position = isChanged(reaper.GetCursorPosition(), "cursor_position"),
		count_items = isChanged(reaper.CountMediaItems(proj), "count_items"),
		count_selected_tracks = isChanged(reaper.CountSelectedTracks(proj), "count_selected_tracks"),
		count_selected_items = isChanged(reaper.CountSelectedMediaItems(proj), "count_selected_items"),
		first_selected_track = isChanged(reaper.GetSelectedTrack(proj, 0), "first_selected_track"),
		first_selected_item = isChanged(reaper.GetSelectedMediaItem(proj, 0), "first_selected_item"),
	}

	for _, is_changed in pairs(changes) do
		if is_changed then
			something_is_changed = true
			goto end_of_changes
		end
	end

	::end_of_changes::

	if something_is_changed then
		Log("[GLOBAL] Something has changed: \n {param}", ek_log_levels.Notice, changes)

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

		-- Toggle docker
		if changes.project_path or changes.play_state then
			TD_SyncOpenedWindows()
		end
	end

	-- Auto grid
	if GA_GetSettingValue(ga_settings.auto_grid) then
		GA_ObserveGrid()
	end

	-- Up Sample Rate
	if GA_GetSettingValue(ga_settings.rec_sample_rate) then
		GA_ObserveArmRec(changes, cached_changes)
	end

	-- Dark mode
	if GA_GetSettingValue(ga_settings.dark_mode) then
		GA_ObserveDarkMode(changes, cached_changes)
	end

	-- Track working time
	if GA_GetSettingValue(ga_settings.track_time) then
		GA_ObserveProjectWorkingTime(something_is_changed, cached_changes)
	end

	reaper.defer(observeGlobalAction)
end

observeGlobalAction()

local command = reaper.NamedCommandLookup(GA_GetSettingValue(ga_settings.additional_action))
if command ~= 0 then
	Log("[GLOBAL] Additional actions has been executed: {param}", ek_log_levels.Notice, command)
	reaper.Main_OnCommand(command, 0)
end

TD_SyncOpenedWindows()
EK_SetIsGlobalActionEnabled()