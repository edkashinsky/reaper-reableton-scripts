-- @description ek_Global startup action settings
-- @author Ed Kashinsky
-- @noindex

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("core-bg") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

GUI_ShowMainWindow(0, 670)

local ordered_settings = EK_SortTableByKey(ga_settings)

function frame(ImGui, ctx)
	local isSet = GA_GetSettingValue(ga_settings.enabled)
	local isEnabled = EK_IsGlobalActionEnabled()
	local isStartupSet = EK_IsGlobalActionEnabledViaStartup()

	if (isSet and not isStartupSet and not isEnabled and ga_startup_exists) or (not isSet and isStartupSet and isEnabled) then
		GUI_DrawText( "Please restart REAPER for changes to take effect...", gui_fonts.Bold, gui_cols.Red)
	end

	if not isStartupSet and isEnabled then
		GUI_DrawText( "It's enabled by manual setting via SWS Startup actions...", gui_fonts.Bold, gui_cols.Green)
	end

	ImGui.PushItemWidth(ctx, 224)
	GUI_DrawSettingsTable(ordered_settings)
	ImGui.PopItemWidth(ctx)
end

