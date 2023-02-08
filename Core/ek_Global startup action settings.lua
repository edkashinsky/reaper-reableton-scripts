-- @description ek_Global startup action settings
-- @version 1.0.5
-- @author Ed Kashinsky
-- @about
--   Here you can set features for global startup actions
-- @changelog
--   improves GUI and added new functions

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
	if loaded == nil then reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

if not CoreFunctionsLoaded("ek_Core functions startup.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

local ordered_settings = EK_SortTableByKey(ga_settings)

function frame()
	GUI_DrawText("Settings for 'ek_Global startup action'", GUI_GetFont(gui_font_types.Bold))

	reaper.ImGui_TextWrapped(GUI_GetCtx(), "Status:")
	reaper.ImGui_SameLine(GUI_GetCtx())

	if EK_IsGlobalActionEnabled() then
		reaper.ImGui_TextColored(GUI_GetCtx(), gui_colors.Green, "Enabled")
	else
		reaper.ImGui_TextColored(GUI_GetCtx(), gui_colors.Red, "Disabled")
		GUI_DrawGap()
		GUI_DrawText("Open 'Extensions' => 'Startup actions' => 'Set global startup action' and paste command id of 'ek_Global startup action' and re-open Reaper", GUI_GetFont(gui_font_types.Bold), gui_colors.Red)
	end

	GUI_DrawGap()

	GUI_DrawSettingsTable(ordered_settings)
end

GUI_ShowMainWindow(490, 670)