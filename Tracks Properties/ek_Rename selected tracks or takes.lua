-- @description ek_Rename selected tracks or takes
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Renaming stuff for takes, items and tracks depending on focus

reaper.Undo_BeginBlock()

local proj = 0

local countSelectedItems = reaper.CountSelectedMediaItems(proj)
		
if countSelectedItems == 1 then
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