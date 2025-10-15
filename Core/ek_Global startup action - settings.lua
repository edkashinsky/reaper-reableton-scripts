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

xpcall(function()
	if not CoreLibraryLoad("core") or not CoreLibraryLoad("core-bg") then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
		return
	end

	GUI_SetAboutLinks({
		{'Documentation', 'https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Global-Startup-Action'},
		{'Forum thread', 'https://forum.cockos.com/showthread.php?t=298431'}
	})

	GA_ShowGui()
end, function(err)
	local _, _, imGuiVersion = reaper.ImGui_GetVersion()

	reaper.ShowConsoleMsg("\nERROR: " .. err .. "\n\n")
	reaper.ShowConsoleMsg("Stack traceback:\n")
	reaper.ShowConsoleMsg("\t" .. debug.traceback() .. "\n\n")
	reaper.ShowConsoleMsg("Reaper: " .. reaper.GetAppVersion() .. "\n")
	reaper.ShowConsoleMsg("Platform: " .. reaper.GetOS() .. "\n")
	reaper.ShowConsoleMsg("Lua: " .. _VERSION .. "\n")
	reaper.ShowConsoleMsg("ReaImGui: " .. imGuiVersion .. "\n")

	if EK_GetScriptVersion ~= nil then
		reaper.ShowConsoleMsg("Version: " .. tostring(EK_GetScriptVersion()) .. "\n")
		reaper.ShowConsoleMsg("Core: " .. tostring(EK_GetScriptVersion(pathJoin(CORE_PATH, "ek_Core functions.lua"))) .. "\n")
	end
end)

