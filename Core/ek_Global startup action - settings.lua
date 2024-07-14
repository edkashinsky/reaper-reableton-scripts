-- @description ek_Global startup action settings
-- @author Ed Kashinsky
-- @noindex

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

GUI_ShowMainWindow(490, 670)

local ordered_settings = EK_SortTableByKey(ga_settings)

function frame(ImGui, ctx)
	local isSet = GA_GetSettingValue(ga_settings.enabled)
	local isEnabled = EK_IsGlobalActionEnabled()
	local isStartupSet = EK_IsGlobalActionEnabledViaStartup()

	if (isSet and not isStartupSet and not isEnabled and ga_startup_exists) or (not isSet and isStartupSet and isEnabled) then
		GUI_DrawText( "Please restart REAPER for changes to take effect...", GUI_GetFont(gui_font_types.Bold), gui_colors.Red)
	end

	if not isStartupSet and isEnabled then
		GUI_DrawText( "It's enabled by manual setting via SWS Startup actions...", GUI_GetFont(gui_font_types.Bold), gui_colors.Green)
	end

	ImGui.PushItemWidth(ctx, 224)
	GUI_DrawSettingsTable(ordered_settings)
	ImGui.PopItemWidth(ctx)
end

