-- @description ek_Rename selected tracks or takes
-- @version 1.0.3
-- @author Ed Kashinsky
-- @about
--   Renaming stuff for takes, items, markers, regions and tracks depending on focus
-- @changelog
--   Added support of renaming markers and regions:
--    - If position of marker or starting position of region is equal with edit cursor, you can rename name of marker
--	  - As usual, you can click on marker or region in header of arrange and cursor position become equal with marker/region

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

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

reaper.Undo_BeginBlock()

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
local cursorPosition = reaper.GetCursorPosition()
local s_isrgn, s_pos, s_rgnend, s_name, s_markrgnindexnumber
local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)

local function renameProjectMarker(markrgnindexnumber, isrgn, pos, rgnend, name)
	EK_AskUser((isrgn and "Rename region" or "Rename marker") .. " #" .. markrgnindexnumber, {
		{"Enter title", name }
	}, function(result)
		if not result then return end

		local new_name = " "

		if result[1] then new_name = result[1] end

		reaper.SetProjectMarker(markrgnindexnumber, isrgn, pos, rgnend, new_name)
	end)
end

for i = 0, num_markers + num_regions - 1 do
	local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)

	if pos == cursorPosition then
		s_markrgnindexnumber = markrgnindexnumber
		s_isrgn = isrgn
		s_pos = pos
		s_rgnend = rgnend
		s_name = name
	end
end

if s_markrgnindexnumber ~= nil then
	-- rename marker title
	renameProjectMarker(s_markrgnindexnumber, s_isrgn, s_pos, s_rgnend, s_name)
elseif countSelectedItems == 1 then
	-- Xenakios/SWS: Rename takes...
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RENMTAKE"), 0)
elseif countSelectedItems > 1 then
	-- Xenakios/SWS: Rename takes with same name...	
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RENMTAKEALL"), 0)
else
	-- Xenakios/SWS: Rename selected tracks...
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RENAMETRAXDLG"), 0)
end

reaper.Undo_EndBlock("Rename selected tracks or takes", -1)