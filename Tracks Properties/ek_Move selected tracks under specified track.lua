-- @description ek_Move selected tracks under specified track
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   Script moves selected tracks to new track as childs

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

local extNameKey = "move_tracks_to_track_name"
local extAsChildKey = "move_tracks_to_track_as_child"
local newTrackName = EK_GetExtState(extNameKey)
local moveAsChild = EK_GetExtState(extAsChildKey, true)

local window, _, _ = reaper.BR_GetMouseCursorContext()
if window == "transport" or not newTrackName then
	local settings = {
		{
			key = extNameKey,
			type = gui_input_types.Text,
			title = "Track name",
			description = "Enter a name for the track that the selected tracks will move to",
		},
		{
			key = extAsChildKey,
			type = gui_input_types.Checkbox,
			title = "Move as child tracks",
			description = "If this option is not enabled, the selected tracks are moved under the track with the name specified above",
			default = true,
		},
		{
			type = gui_input_types.Label,
			font = gui_fonts.Bold,
			title = "\nNote!",
		},
		{
			type = gui_input_types.Label,
			font = gui_fonts.Italic,
			title = "You can change this name anytime you want if you hover your mouse over the transport panel and run this script",
		},
	}

	function frame(ImGui, ctx)
		ImGui.PushItemWidth(ctx, 224)
		GUI_DrawSettingsTable(settings)
		ImGui.PopItemWidth(ctx)
	end

	GUI_ShowMainWindow()
	return
end

local function GetNewParentTrack()
	for i = 0, reaper.CountTracks(proj) - 1 do
		local track = reaper.GetTrack(proj, i)
		local _, name = reaper.GetTrackName(track)

		if newTrackName and name == newTrackName then
			return track
		end
	end

	return nil
end

reaper.Undo_BeginBlock()

local newParent = GetNewParentTrack()

if not newParent then
	EK_ShowTooltip("There is no any track with title \"" .. newTrackName .. "\" in the project.")
	return
end

if reaper.CountSelectedTracks(proj) == 0 then
	EK_ShowTooltip("There is no any selected tracks.")
	return
end

local ind = reaper.GetMediaTrackInfo_Value(newParent, "IP_TRACKNUMBER")
reaper.ReorderSelectedTracks(ind, moveAsChild and 1 or 0)

reaper.Undo_EndBlock("Move selected tracks under specified track", -1)