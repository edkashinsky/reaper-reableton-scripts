-- @description ek_Switch to prev pitch mode for selected items
-- @version 1.0.1
-- @author Ed Kashinsky
-- @about
--   This script helps to switch between pitch modes quicker just in one click.
--
--   Work with script ek_Switch to next pitch mode for selected items.lua
-- @changelog
--   - Added core functions

function CoreFunctionsLoaded()
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. "ek_Core functions.lua"
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded()
if not loaded then
	if loaded == nil then  reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0) end
	return
end

reaper.Undo_BeginBlock()

local function getPrevPitchMode(ind)
	local pitchModes = EK_GetPitchModes()

	for i = 1, #pitchModes do
		if pitchModes[i].is_submode == true and pitchModes[i].id == ind then
			local j = i
			
			while pitchModes[j] ~= nil do
				j = j - 1
				
				if pitchModes[j] ~= nil and pitchModes[j].is_submode == true then
					return pitchModes[j]
				end
			end
			
			return pitchModes[i]
		end 
	end
	
	return pitchModes[0]
end

local item = reaper.GetSelectedMediaItem(proj, 0)
if item ~= nil then
	local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
	local itemTake = reaper.GetMediaItemTake(item, takeInd)
	local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "I_PITCHMODE")

	if mode == defProjPitchMode then
		mode = reaper.SNM_GetIntConfigVar("defpitchcfg", defProjPitchMode)
	end
	
	local newMode = getPrevPitchMode(mode)
	local base_mode = EK_GetPitchModeBySubMode(newMode.id)

	EK_SetPitchModeForSelectionItems(newMode.id)
	EK_ShowTooltip(base_mode .. " (" .. newMode.title .. ")")
end

reaper.Undo_EndBlock("Switch to prev pitch mode for selected items", -1)