-- @description ek_Change pitch mode for selected items
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   ![Preview](/Assets/images/change_pitch_mode_preview.gif)
--
--   This script shows nested menu of all pitch modes for selected items right on the toolbar without "Item properties" window
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

reaper.Undo_BeginBlock()

function showMenu()
	if reaper.CountSelectedMediaItems(proj) > 0 then 
		local menuString = ""
		local selectedPitchModes = EK_GetPitchModesForSelectedItems()
		local pitchModes = EK_GetPitchModes()
	
		for i = 1, #pitchModes do
			local currentLine = pitchModes[i].title

			if selectedPitchModes[pitchModes[i].id] ~= nil and pitchModes[i].is_submode == true then
				currentLine = "!" .. currentLine
			elseif pitchModes[i].is_submode == false then
				for key in pairs(selectedPitchModes) do
				    if math.floor(key / 2 ^ 16) == pitchModes[i].id then
						currentLine = "!" .. currentLine
						break
					end
				end
			end
		
			if pitchModes[i].is_submode == false and pitchModes[i + 1] ~= nil and pitchModes[i + 1].is_submode == true then
				currentLine = ">" .. currentLine
			elseif pitchModes[i].is_submode == true and (pitchModes[i + 1] == nil or pitchModes[i + 1].is_submode == false) then
				currentLine = "<" .. currentLine
			end
		
			if i < #pitchModes then
				currentLine = currentLine .. "|"
			end
			
			menuString = menuString .. currentLine
		end
		
		-- On Windows reaper must create new window
		if reaper.GetOS() == "Win64" then 
			gfx.init("", 0, 0, 0)
      
			gfx.x = gfx.mouse_x
			gfx.y = gfx.mouse_y
		end
	
		-- Debug(menuString)
	
		-- >1|2|3|<4|>5|6|7|<8
	    local retval = gfx.showmenu(menuString)
    
		Log(retval, ek_log_levels.Notice)
	
	    if retval > 0 then
			local j = 1
			for i = 1, #pitchModes do
				if pitchModes[i].is_submode == true then 
					if retval == j then
						EK_SetPitchModeForSelectionItems(pitchModes[i].id)
						break
					end
				
					j = j + 1
				end
			end
	    end
   
		if reaper.GetOS() == "Win64" then 
			gfx.quit()
		end
	end
end

showMenu()

reaper.Undo_EndBlock("Change pitch mode for selected items", -1)