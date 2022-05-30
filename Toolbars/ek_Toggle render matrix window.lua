-- @description ek_Toggle render matrix window
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   It remember Render Matrix button for toggling docker window
--
--   For work please install ek_Toggle last under docker window
-- @changelog
--   - Added core functions

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

-- View: Show region render matrix window
local actionId = 41888
local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

EK_StoreLastGroupedDockerWindow(sectionID, cmdID, actionId)
EK_ToggleLastGroupedDockerWindow()