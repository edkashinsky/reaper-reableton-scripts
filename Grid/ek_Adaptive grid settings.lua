-- @description ek_Adaptive grid settings
-- @version 1.0.2
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   Switching to next grid step settings depending on adaptive or not
-- @changelog
--    Now tracking for MIDI Editor is working automatically. No need need to attach additional tracking scripts to zoom actions in MIDI Editor.
--    Please restart Reaper for taking effect
-- @provides
--   [main=main] ek_Adaptive grid switch to next grid step.lua
--   [main=main] ek_Adaptive grid switch to prev grid step.lua
--   [main=midi_editor] ek_Adaptive grid switch to next grid step (MIDI Editor).lua
--   [main=midi_editor] ek_Adaptive grid switch to prev grid step (MIDI Editor).lua
--   [main=midi_editor] ek_Adaptive grid settings (MIDI Editor).lua

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

if not CoreFunctionsLoaded("ek_Core functions.lua") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

if not CoreFunctionsLoaded("ek_Adaptive grid functions.lua") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	return
end

if not EK_IsGlobalActionEnabled() then
	reaper.MB('Please execute script "ek_Global startup action settings" and enable "Enable global action" checkbox in the window', '', 0)
	return
end

local menu = {}
local midiMenu = {}
local current_scale = AG_GetGridScale()
local current_grid = AG_GetCurrentGrid()
local current_midi_grid = AG_GetCurrentGrid(true)
local _, _, _, swingamt = reaper.GetSetProjectGrid(proj, false)
local option_grid_width_title = "Set grid width ratio"
local option_limits_title = "Set grid limits"
local grid_width = AG_GetWidthRatio()
local isSynced = AG_IsSyncedWithMidiEditor()
local _, _, minTitle, maxTitle = AG_GetGridLimits()

for i, row in pairs(ag_scale_types_config) do
	local children = {}
	if row.title == "Swing" then
		for _, s in pairs({ -1, -0.75, -0.5, -0.25, 0.25, 0.5, 0.75, 1}) do
			table.insert(children, {
				title = math.floor(s * 100) .. "%",
				is_selected = current_scale.title == row.title and swingamt == s,
				on_select = function()
					AG_SetGridScale(false, i, s)
					if AG_IsSyncedWithMidiEditor() then AG_SetGridScale(true, i, s) end
				end
			})
		end
	end

	table.insert(menu, {
		title = row.title,
		is_selected = current_scale.title == row.title,
		on_select = function()
			AG_SetGridScale(false, i)
			if AG_IsSyncedWithMidiEditor() then AG_SetGridScale(true, i) end
		end,
		children = children
	})
end

table.insert(menu, {is_separator = true})

for i, row in pairs(ag_types_config) do
	if row.is_adapt then
		table.insert(menu, {
			title = row.title,
			is_selected = current_grid.title == row.title,
			on_select = function()
				AG_SetCurrentGrid(false, i)

				if AG_IsSyncedWithMidiEditor() then AG_SetCurrentGrid(true, i) end
			end
		})
	end
end

table.insert(menu, {is_separator = true})

for i, row in pairs(ag_types_config) do
	if not row.is_adapt then
		table.insert(menu, {
			title = row.title,
			is_selected = current_grid.title == row.title,
			on_select = function()
				AG_SetCurrentGrid(false, i)
				if AG_IsSyncedWithMidiEditor() then AG_SetCurrentGrid(true, i) end
			end
		})
	end
end

table.insert(menu, {is_separator = true})

if not isSynced then
	for i, row in pairs(ag_types_config) do
		if row.is_adapt then
			table.insert(midiMenu, {
				title = row.title,
				is_selected = current_midi_grid.title == row.title,
				on_select = function() AG_SetCurrentGrid(true, i) end
			})
		end
	end

	table.insert(midiMenu, {is_separator = true})

	for i, row in pairs(ag_types_config) do
		if not row.is_adapt then
			table.insert(midiMenu, {
				title = row.title,
				is_selected = current_midi_grid.title == row.title,
				on_select = function() AG_SetCurrentGrid(true, i) end
			})
		end
	end

	table.insert(midiMenu, {is_separator = true})

	table.insert(midiMenu, {
		title = "Sync with arrange view",
		is_selected = isSynced,
		on_select = AG_ToggleSyncedWithMidiEditor
	})

	table.insert(menu, {title = "MIDI Editor", children = midiMenu })
end

if grid_width then option_grid_width_title = option_grid_width_title .. " [" .. grid_width .. "]" end
if minTitle or maxTitle then
	option_limits_title = option_limits_title .. " [" .. (minTitle and minTitle or "n/a") .. "..." .. (maxTitle and maxTitle or "n/a") .. "]"
end

table.insert(menu, {title = "Options", children = {
	{title = "Synced with MIDI Editor", is_selected = isSynced, on_select = AG_ToggleSyncedWithMidiEditor },
	{title = option_grid_width_title, on_select = function()
		EK_AskUser("Set grid width ratio", {
			{"Width ratio: (e.g 0.5)", AG_GetWidthRatio() }
		}, function(result)
			if not result or not result[1] then return end

			local ratio = tonumber(result[1])
			if ratio == nil or ratio <= 0 then
				reaper.MB('Ratio must be positive fractional number', 'Error', 0)
			else
				AG_SetWidthRatio(ratio)
			end
		end)
	end },
	{title = option_limits_title, on_select = function()
		local _, _, minTitle, maxTitle = AG_GetGridLimits()

		EK_AskUser("Set grid limits", {
			{"Min grid size (e.g 1/64)", minTitle },
			{"Max grid size (e.g 1)", maxTitle }
		}, function(result)
			if not result then return end

			AG_SetGridLimits(result[1], result[2])

			_, _, minTitle, maxTitle = AG_GetGridLimits()

			reaper.MB('Limits have been set to ' .. (minTitle and minTitle or "n/a") .. ", " .. (maxTitle and maxTitle or "n/a"), "Set grid limits", 0)
		end)
	end },
}})

EK_ShowMenu(menu)