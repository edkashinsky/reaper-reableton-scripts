-- @description ek_Global startup action
-- @version 1.1.7
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
--   Library dependency check added – The application now verifies that all required libraries are present before running.
-- @provides
--   data/core-bg_*.dat
--   [main=main] ek_Global startup action - settings.lua

local CONTEXT = ({reaper.get_action_context()})
local SCRIPT_NAME = CONTEXT[2]:match("([^/\\]+)%.lua$"):gsub("ek_", "")
local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not reaper.APIExists("SNM_SetIntConfigVar") then
    reaper.MB('Please install SWS extension via https://sws-extension.org', SCRIPT_NAME, 0)
	return
end

if not reaper.APIExists("JS_Mouse_GetState") then
    reaper.MB('Please install "js_ReaScriptAPI: API functions for ReaScripts" via ReaPack', SCRIPT_NAME, 0)
    reaper.ReaPack_BrowsePackages("js_ReaScriptAPI: API functions for ReaScripts")
	return
end

if not reaper.APIExists("ImGui_GetVersion") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', SCRIPT_NAME, 0)
    reaper.ReaPack_BrowsePackages("ReaImGui: ReaScript binding for Dear ImGui")
	return
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("core-bg") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages). \nLua version is: ' .. _VERSION, SCRIPT_NAME, 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

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

local ga_debug = false
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
			break
		end
	end

	local auto_switch_track_on_preview = GA_GetSettingValue(ga_settings.auto_switch_track_on_preview)
	local stop_media_explorer_on_playback = GA_GetSettingValue(ga_settings.stop_media_explorer_on_playback)

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

		-- Auto-Switch playback via selected track in Media Explorer
		if auto_switch_track_on_preview then
			GA_ObserveAutoSwitchTrackInMediaExplorer(changes, cached_changes)
		end

		-- Stop preview in Media Explorer when playback started
		if stop_media_explorer_on_playback then
			GA_StopPreviewMediaExplorerOnPlayback(changes, cached_changes)
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

	-- Follow to playing state in Media Explorer
	-- (for "Auto-Switch playback via selected track in Media Explorer" or "Stop preview in Media Explorer when playback started")
	if auto_switch_track_on_preview or stop_media_explorer_on_playback then
		GA_ObservePlayStateInMediaExplorer()
	end

	if ga_debug then
		local exec_time = round((reaper.time_precise() - time_precise) * 1000, 3)
		local desc = ""
		if exec_time > 10 then desc = "[DANGER]"
		elseif exec_time > 1 then desc = "[WARNING]" end

		Log(exec_time .. "ms. " .. desc, ek_log_levels.Important)
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