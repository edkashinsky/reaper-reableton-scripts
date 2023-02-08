-- @description ek_Switch to next grid step
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   Switching to next grid step settings depending on adaptive or not
-- @changelog
--   Small fixes

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

if not CoreFunctionsLoaded("ek_Core functions startup.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

if not EK_IsGlobalActionEnabled() then
	reaper.MB('Please add "ek_Global startup action" as Global startup action (Extenstions -> Startup Actions -> Set global startup action) for realtime highlighting of this button', '', 0)
end

local s_config = ga_settings.arrange_grid_setting
local values = s_config.select_values
local value = EK_GetExtState(s_config.key, s_config.default)
local isAdaptive = in_array(s_config.adaptive_grid_values, value)
local newValue = value + 1
local availableValues = {}

for i = 0, #values - 1 do
	if isAdaptive and in_array(s_config.adaptive_grid_values, i) then
		table.insert(availableValues, i)
	elseif not isAdaptive and not in_array(s_config.adaptive_grid_values, i) then
		table.insert(availableValues, i)
	end
end

Log(availableValues)
Log(value .. " -> " .. newValue)

if in_array(availableValues, newValue) then
	EK_SetExtState(s_config.key, newValue)
	Log("Set grid: " .. newValue)
end