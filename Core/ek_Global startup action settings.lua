-- @description ek_Global startup action settings
-- @version 1.0.7
-- @author Ed Kashinsky
-- @about
--   Here you can set features for global startup actions
-- @changelog
--   - Easier set up for new users. Now you need just turn option "Enable global action" via "ek_Global startup action settings". No more work with SWS Startup actions
--   - Tracking of working time on a project. Check it out in "ek_Global startup action settings"
--   - Showing script name of "Additional global startup action" in "ek_Global startup action settings"
--   - Global refactoring of adaptive grid. Now there are collected in new script "ek_Adaptive grid" with even context menu. Check it out in ReaPack scripts
--   - Improved work with Dark Mode
--   - Many small bug fixes
--   - GUI refactoring

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
	local isSet = GA_GetSettingValue(ga_settings.enabled)
	local isEnabled = EK_IsGlobalActionEnabled()
	local isStartupSet = EK_IsGlobalActionEnabledViaStartup()

	if (isSet and not isStartupSet and not isEnabled and ga_startup_exists) or (not isSet and isStartupSet and isEnabled) then
		GUI_DrawText( "Please restart REAPER for changes to take effect...", GUI_GetFont(gui_font_types.Bold), gui_colors.Red)
	end

	if not isStartupSet and isEnabled then
		GUI_DrawText( "It's enabled by manual setting via SWS Startup actions...", GUI_GetFont(gui_font_types.Bold), gui_colors.Green)
	end

	reaper.ImGui_PushItemWidth(GUI_GetCtx(), 224)
	GUI_DrawSettingsTable(ordered_settings)
	reaper.ImGui_PopItemWidth(GUI_GetCtx())
end

GUI_ShowMainWindow(490, 670)