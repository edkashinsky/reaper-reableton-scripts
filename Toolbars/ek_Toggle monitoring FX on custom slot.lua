-- @description ek_Toggle monitoring fx plugin on custom slot
-- @author Ed Kashinsky
-- @noindex
-- @about This script monitors a custom fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'
-- @readme_skip

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

if not CoreLibraryLoad("corebg") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Global startup action")
	return
end

if not EK_IsGlobalActionEnabled() then
	reaper.MB('Please execute script "ek_Global startup action settings" and enable "Enable global action" checkbox in the window', '', 0)
	return
end

reaper.Undo_BeginBlock()

-- ctrl/cmd is pressed (need to show settings window)
local isSettingsNeeded = reaper.JS_Mouse_GetState(4) > 0
local slot_id = EK_GetExtState(ga_highlight_buttons.mfx_slot_custom)
local _, _, sectionID, cmdID = reaper.get_action_context()

if not slot_id or isSettingsNeeded then
	local view_slot_id = slot_id and slot_id + 1 or nil
	EK_AskUser("Enter slot id for action monitoring", {
		{"Custom slot id", view_slot_id}
	}, function(result)
		if not result or not result[1] then return end

		slot_id = tonumber(result[1]) - 1
		EK_SetExtState(ga_highlight_buttons.mfx_slot_custom, slot_id)

		reaper.MB("Slot id has been set. If you want to change it, execute this script with pressed CMD/CTRL key.", "Toggle monitoring fx plugin on custom slot", 0)
	end)

	return
end

GA_ToggleMfxBtnOnSlot(slot_id, ga_highlight_buttons.mfx_slot_custom, sectionID, cmdID)

reaper.Undo_EndBlock("Toggle monitoring fx plugin on custom slot", -1)