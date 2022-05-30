-- @description ek_Toggle Media Browser window
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It remember Media Browser button for toggling docker window
--
--   For correct work please install ek_Toggle last under docker window
-- @changelog
--   - Added core functions
-- @provides [main=main,mediaexplorer] .

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) return true else return false end
end

if not CoreFunctionsLoaded() then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

-- Media explorer: Show/hide media explorer
local actionId = 50124
local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

EK_StoreLastGroupedDockerWindow(sectionID, cmdID, actionId)
EK_ToggleLastGroupedDockerWindow()