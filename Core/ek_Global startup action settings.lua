-- @description ek_Global startup action settings
-- @version 1.0.4
-- @author Ed Kashinsky
-- @about
--   Here you can set features for global startup actions
-- @changelog
--   - Added grid modes like in Ableton

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

local ordered_settings = GA_GetOrderedSettings()

function frame()
	local is_enabled = EK_IsGlobalActionEnabled()
	local input_flags = GUI_GetInputFlags()

	GUI_DrawText("Settings for 'ek_Global startup action'", GUI_GetFont(gui_font_types.Bold))

	reaper.ImGui_TextWrapped(GUI_GetCtx(), "Status:")
	reaper.ImGui_SameLine(GUI_GetCtx())

	if is_enabled then
		reaper.ImGui_TextColored(GUI_GetCtx(), gui_colors.Green, "Enabled")
	else
		reaper.ImGui_TextColored(GUI_GetCtx(), gui_colors.Red, "Disabled")
		GUI_DrawGap()
		GUI_DrawText("Open 'Extensions' => 'Startup actions' => 'Set global startup action' and paste command id of 'ek_Global startup action' and re-open Reaper", GUI_GetFont(gui_font_types.Bold), gui_colors.Red)

		input_flags = input_flags | reaper.ImGui_InputTextFlags_ReadOnly()
	end

	GUI_DrawGap()

	for i = 1, #ordered_settings do
		local r, newVal
		local setting = ordered_settings[i]
		local curVal = GA_GetSettingValue(setting)

		reaper.ImGui_PushItemWidth(GUI_GetCtx(), 200)

		reaper.ImGui_PushFont(GUI_GetCtx(), GUI_GetFont(gui_font_types.Bold))

		if setting.select_values then
			r, newVal = reaper.ImGui_Combo(GUI_GetCtx(), setting.title, curVal, join(setting.select_values, "\0") .. "\0")
		elseif type(curVal) == 'boolean' then
			r, newVal = reaper.ImGui_Checkbox(GUI_GetCtx(), setting.title, curVal)
		elseif type(curVal) == 'number' then
			r, newVal = reaper.ImGui_InputInt(GUI_GetCtx(), setting.title, curVal, nil, nil, input_flags)
		else
			r, newVal = reaper.ImGui_InputText(GUI_GetCtx(), setting.title, curVal, input_flags)
		end

		if curVal ~= newVal then
			GA_SetSettingValue(setting, newVal)
		end

		reaper.ImGui_PopFont(GUI_GetCtx())
		reaper.ImGui_PopItemWidth(GUI_GetCtx())

		if setting.description then
			GUI_DrawText(setting.description, GUI_GetFont(gui_font_types.Italic))
			GUI_DrawGap()
		end
	end
end

GUI_ShowMainWindow(490, 670)