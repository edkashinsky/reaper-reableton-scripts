-- @description ek_Toggle preserve pitch for selected items
-- @author Ed Kashinsky
-- @about
--    ![Preview](/Assets/images/prevent_pitch_preview.gif)
--
--    This script just toggle "Preserve Pitch" for selected items but it saves state for button. For example, if you select item and it has preserve option, button starts highlight.
--
--    For installation just add this script on toolbar and set "ek_Global Startup Functions" as global startup action via SWS.
-- @noindex
-- @readme_skip

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

if not CoreLibraryLoad("core-bg") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Global startup action")
	return
end

if not EK_IsGlobalActionEnabled() then
	reaper.MB('Please execute script "ek_Global startup action settings" and enable "Enable global action" checkbox in the window', '', 0)
	return
end

reaper.Undo_BeginBlock()

local s_new_value, filename, sectionID, cmdID = reaper.get_action_context()

function togglePreservePitch()
	local countSelectedItems = reaper.CountSelectedMediaItems(proj)
	
	if countSelectedItems > 0 then
		local state = reaper.GetToggleCommandStateEx(sectionID, cmdID);
		
		for i = 0, countSelectedItems - 1 do
			local item = reaper.GetSelectedMediaItem(proj, i)
			local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
	
			local itemTake = reaper.GetMediaItemTake(item, takeInd)
			local newValue = state == 1 and 0 or 1
			
			reaper.SetMediaItemTakeInfo_Value(itemTake, "B_PPITCH", newValue)
			reaper.SetToggleCommandState(sectionID, cmdID, newValue)
			reaper.RefreshToolbar2(sectionID, cmdID)
		end
	end
end

togglePreservePitch()
GA_SetButtonForHighlight(ga_highlight_buttons.preserve_pitch, sectionID, cmdID)

reaper.Undo_EndBlock("Toggle preserve pitch for selected items", -1)