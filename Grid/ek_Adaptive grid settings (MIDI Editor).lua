-- @author Ed Kashinsky
-- @noindex
-- @about ek_Adaptive grid settings (MIDI Editor)
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

if not CoreLibraryLoad("corebg") then
	reaper.MB('Global startup action is missing. Please install "ek_Global startup action" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Global startup action")
	return
end

local menu = {}
local isSynced = AG_IsSyncedWithMidiEditor()
local current_scale = AG_GetGridScale(true)
local current_grid = AG_GetCurrentGrid(not isSynced)
local option_grid_width_title = "Set grid width ratio"
local option_limits_title = "Set grid limits"
local grid_width = AG_GetWidthRatio()
local _, _, minTitle, maxTitle = AG_GetGridLimits()
local _, _, _, swingamt = reaper.GetSetProjectGrid(proj, false)

for i, row in pairs(ag_scale_types_config) do
	local children = {}
	if row.title == "Swing" then
		for _, s in pairs({ -1, -0.75, -0.5, -0.25, 0.25, 0.5, 0.75, 1}) do
			table.insert(children, {
				title = math.floor(s * 100) .. "%",
				is_selected = current_scale.title == row.title and swingamt == s,
				on_select = function()
					AG_SetGridScale(true, i, s)
					if AG_IsSyncedWithMidiEditor() then AG_SetGridScale(false, i, s) end
				end
			})
		end
	end

	table.insert(menu, {
		title = row.title,
		is_selected = current_scale.title == row.title,
		on_select = function()
			AG_SetGridScale(true, i)
			if AG_IsSyncedWithMidiEditor() then AG_SetGridScale(false, i) end
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
				AG_SetCurrentGrid(true, i)
				if AG_IsSyncedWithMidiEditor() then AG_SetCurrentGrid(false, i) end
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
				AG_SetCurrentGrid(true, i)
				if AG_IsSyncedWithMidiEditor() then AG_SetCurrentGrid(false, i) end
			end
		})
	end
end

table.insert(menu, {is_separator = true})

table.insert(menu, {
	title = "Sync with arrange view",
	is_selected = isSynced,
	on_select = AG_ToggleSyncedWithMidiEditor
})

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