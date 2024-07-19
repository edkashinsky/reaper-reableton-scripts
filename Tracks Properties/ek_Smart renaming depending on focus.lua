-- @description ek_Smart renaming depending on focus
-- @version 1.0.13
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   Renaming stuff for takes, items, markers, regions and tracks depending on focus
-- @changelog
--   Small ui fixes
-- @provides
--   ../Core/ek_Smart renaming functions.lua

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

CoreFunctionsLoaded("ek_Smart renaming functions.lua")

local defaultPalette = {
	0xc93b10, 0xc95a10, 0xc9a510, 0xcaca11, 0x80ca0d, 0x51a31a, 0x5bc910, 0x10c92e, 0x13ca5a, 0x12caa5, 0x0ea5ca, 0x2696cf, 0x3682d4, 0x4644d8, 0x4341b0, 0x5e40d5, 0x7738d3, 0x902ed1, 0xa40fc9, 0xca11c9,
}
local wndWidth = 340
local element = GetFocusedElement()
local isColorTreeShowed = false
local isColorTreeShowedChanged = false
local isAdvanced = false
local isTitleSet = false
local isColorSet = false
local lastColorsList = EK_GetExtState(rename_last_colors_list_key, {})
local applyToAllTakes = true
local value, color, newColor
local defaultColorsList

local function GetDefaultColor(id)
	if not defaultColorsList then
		defaultColorsList = EK_GetExtState(rename_default_colors_list_key, defaultPalette)
	end

	return id and defaultColorsList[id] or defaultColorsList
end

local function GetUpdatedDefaultColor(rgb)
	local hue = EK_GetExtState(rename_default_colors_config[1].key, 0)
	local saturation = EK_GetExtState(rename_default_colors_config[2].key, 0)
	local brightness = EK_GetExtState(rename_default_colors_config[3].key, 0)

	local r, g, b, h, s, v

	r, g, b = reaper.ColorFromNative(rgb)

	r = r / 255
	g = g / 255
	b = b / 255

	h, s, v = reaper.ImGui_ColorConvertRGBtoHSV(r, g, b)

	-- Log("RGB: " .. round(r, 2) .. " : " .. round(g, 2) .. " : " .. round(b, 2), ek_log_levels.Debug)
	-- Log("HSV: " .. round(h, 2) .. " : " .. round(s, 2) .. " : " .. round(v, 2), ek_log_levels.Debug)

	h = clamp(h + hue, 0.01, 0.99)
	s = clamp(s + saturation, 0.01, 0.99)
	v = clamp(v + brightness, 0.01, 0.99)

	r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)

	r = round(r * 255)
	g = round(g * 255)
	b = round(b * 255)

	-- Log("NEW RGB: " .. r .. " : " .. g .. " : " .. b, ek_log_levels.Debug)
	-- Log("NEW HSV: " .. round(h, 2) .. " : " .. round(s, 2) .. " : " .. round(v, 2), ek_log_levels.Debug)

	-- Log("=", ek_log_levels.Debug)

	return reaper.ColorToNative(round(r), round(g), round(b))
end

function UpdateDefaultColorsPalette()
	local new_palette = {}

	for i = 1, #defaultPalette do
		local new_color = GetUpdatedDefaultColor(defaultPalette[i])

		table.insert(new_palette, new_color)
	end

	EK_SetExtState(rename_default_colors_list_key, new_palette)
	defaultColorsList = nil
end

local function UpdateLastColorsList(new_color)
	local list = {}
	local limit = 8

	if new_color == 0 then new_color = 1 end

	for i = 1, #GetDefaultColor() do
		if GetDefaultColor(i) == new_color then return false end
	end

	for i = 1, #lastColorsList do
		if lastColorsList[i] == new_color then return false end
	end

	table.insert(list, new_color)

	local i = 1
	while #list < limit and lastColorsList[i] ~= nil do
		local isExists = false

		for _, val in pairs(list) do
			if val == lastColorsList[i] then
				isExists = true
				goto end_looking
			end
		end

		::end_looking::

		if not isExists then table.insert(list, lastColorsList[i]) end

		i = i + 1
	end

	EK_SetExtState(rename_last_colors_list_key, list)

	isColorSet = true
	color = new_color
	lastColorsList = list

	return true
end

local function drawClearButton(ImGui, ctx)
	local draw_list = ImGui.GetWindowDrawList(ctx)

	local p = { ImGui.GetCursorScreenPos(ctx) }
	local x = p[1]
	local y = p[2]
	local sz = 19
	local offset = 3

	ImGui.DrawList_AddRectFilled(draw_list, x, y, x + sz, y + sz, gui_colors.Background, 0.0);
	ImGui.DrawList_AddLine(draw_list, x + offset, y + offset, x + sz - 1 - offset, y + sz - 1 - offset, gui_colors.Red, 1)
	ImGui.DrawList_AddLine(draw_list, x + offset, y + sz - 1 - offset, x + sz - 1 - offset, y + offset, gui_colors.Red, 1)

	if color == 0 then
		ImGui.DrawList_AddRect(draw_list, x, y, x + sz, y + sz, gui_colors.White, 0.0);
	end
	if ImGui.InvisibleButton(ctx, '##Clear color', sz, sz) then
		color = 0
		isColorSet = true
	end
end

local function drawAddColorButton(ImGui, ctx)
	local draw_list = ImGui.GetWindowDrawList(ctx)

	local p = { ImGui.GetCursorScreenPos(ctx) }
	local x = p[1]
	local y = p[2]
	local sz = 18
	local cx = x + (sz / 2)
	local cy = y + (sz / 2)
	local offset = 3

	ImGui.DrawList_AddRectFilled(draw_list, x, y, x + sz, y + sz, gui_colors.Background, 0.0);
	ImGui.DrawList_AddLine(draw_list, cx, y + offset, cx, y + sz - offset, gui_colors.White, 1)
	ImGui.DrawList_AddLine(draw_list, x + offset, cy, x + sz - offset, cy, gui_colors.White, 1)

	if ImGui.InvisibleButton(ctx, '##Add color', sz, sz) then
		newColor = nil
		ImGui.OpenPopup(ctx, 'mypicker')
	end

	if ImGui.BeginPopup(ctx, 'mypicker') then
		local newVal = GUI_DrawInput(gui_input_types.Color, "Add new color", newColor)
		if newVal ~= newColor then
			newColor = newVal
		end

		GUI_DrawInput(gui_input_types.ColorView, "Add new color", newColor)

		ImGui.SameLine(ctx)

		GUI_DrawButton('Add color', function()
			UpdateLastColorsList(newColor)
			ImGui.CloseCurrentPopup(ctx)
		end, gui_buttons_types.Action, true)

		ImGui.SameLine(ctx)

		GUI_DrawButton('Cancel', function()
			ImGui.CloseCurrentPopup(ctx)
		end, gui_buttons_types.Cancel, true)

		GUI_DrawText()
		GUI_DrawText( 'Default color palette settings', GUI_GetFont(gui_font_types.Bold))
		ImGui.Separator(ctx)

		GUI_DrawSettingsTable(rename_default_colors_config)

		ImGui.EndPopup(ctx)
	end
end

local function frameForColorSection(ImGui, ctx)
	ImGui.Separator(ctx)

	drawClearButton(ImGui, ctx)

	ImGui.SameLine(ctx, nil, 4)

	for i = 1, #lastColorsList do
		if GUI_DrawInput(gui_input_types.ColorView, "Last Color #" .. i, lastColorsList[i], { selected = color == lastColorsList[i] }) then
			color = lastColorsList[i]
			isColorSet = true
		end

		ImGui.SameLine(ctx, nil, 4)
	end

	drawAddColorButton(ImGui, ctx)

	for i = 1, #GetDefaultColor() do
		local clr = tonumber(GetDefaultColor(i))
		if GUI_DrawInput(gui_input_types.ColorView, "Default Color #" .. i, clr, { selected = color == clr }) then
			color = clr
			isColorSet = true
		end

		if i ~= #GetDefaultColor() and i % 10 ~= 0 then ImGui.SameLine(ctx, nil, 4) end
	end

	ImGui.Separator(ctx)
end

local function frameForAdvancedForm(ImGui, ctx)
	local a_key = 0
	local a_type = EK_GetExtState(rename_advanced_types_key, rename_advanced_types.Replace)
	local a_fields

	local settings = { select_values = {} }
	for i = 1, #rename_advanced_config do
		table.insert(settings.select_values, rename_advanced_config[i].text)
		if a_type == rename_advanced_config[i].id then
			a_key = i - 1
			a_fields = rename_advanced_config[i].fields
		end
	end

	ImGui.PushItemWidth(ctx, 216)

	local newVal = GUI_DrawInput(gui_input_types.Combo, "Type", a_key, settings)
	if newVal ~= a_key then
		EK_SetExtState(rename_advanced_types_key, rename_advanced_config[newVal + 1].id)
	end

	GUI_DrawSettingsTable(a_fields)

	ImGui.PopItemWidth(ctx)

	ImGui.Separator(ctx)

	GUI_DrawText('Example:')
	ImGui.SameLine(ctx)
	ImGui.PushFont(ctx, GUI_GetFont(gui_font_types.Bold))
	GUI_DrawText(GetProcessedTitleByAdvanced(element.value, 1))

	ImGui.PopFont(ctx)
end

local start_time = reaper.time_precise()
local cooldown = 0.5
local function NeedToUpdateFocusedElement()
	local time = reaper.time_precise()
	if time > start_time + cooldown then
		start_time = time
		return true
	else
		return false
	end
end

function frame(ImGui, ctx)
	if NeedToUpdateFocusedElement() then
		element = GetFocusedElement()
	end

	local newVal

	-- if newElement.type == element.type then element = newElement end
	if not isTitleSet then value = element.value end
	if not isColorSet then color = element.color end

	--
	-- HEADER
	--
	GUI_DrawText(element.typeTitle .. ":")
	ImGui.SameLine(ctx)
	ImGui.PushFont(ctx, GUI_GetFont(gui_font_types.Bold))
	GUI_DrawText(element.title)
	ImGui.PopFont(ctx)

	ImGui.BeginDisabled(ctx, element.type == rename_types.Nothing)

	--
	-- NEW TITLE
	--

	if GUI_DrawInput(gui_input_types.ColorView, "Color view", color) then
		isColorTreeShowed = not isColorTreeShowed
		isColorTreeShowedChanged = true
	end

	ImGui.SameLine(ctx, nil, 4)

	ImGui.BeginDisabled(ctx, isAdvanced == true)

	ImGui.PushItemWidth(ctx, 194)

	GUI_SetFocusOnWidget()

	newVal = GUI_DrawInput(gui_input_types.Text, "New Title", value)
	if newVal ~= value then
		value = newVal
		isTitleSet = true
	end

	ImGui.PopItemWidth(ctx)

	ImGui.EndDisabled(ctx)

	--
	-- COLOR
	--
	if isColorTreeShowed then
		frameForColorSection(ImGui, ctx)
	end

	if isColorTreeShowedChanged then
		GUI_SetWindowSize(wndWidth, 0)
		isColorTreeShowedChanged = false
	end

	if element.type == rename_types.Item then
		newVal = GUI_DrawInput(gui_input_types.Checkbox, "Apply to all takes", applyToAllTakes)
		if newVal ~= applyToAllTakes then
			applyToAllTakes = newVal
		end
	end

	--
	-- ADVANCED
	--
	newVal = GUI_DrawInput(gui_input_types.Checkbox, "Advanced", isAdvanced, { label_not_bold = true })
	if newVal ~= isAdvanced then
		isAdvanced = newVal
		GUI_SetWindowSize(wndWidth, 0)
	end

	if isAdvanced then
		frameForAdvancedForm(ImGui, ctx)
	end

	ImGui.Separator(ctx)

	ImGui.Indent(ctx, 85)

	GUI_DrawButton('Rename', function()
		reaper.Undo_BeginBlock()

		element.value = value
		element.color = color

		if element.type == rename_types.Item then
			element.applyToAllTakes = applyToAllTakes
		end

		if isAdvanced then isTitleSet = true end

		SaveData(element, isTitleSet, isColorSet, isAdvanced)
		reaper.UpdateArrange()

		reaper.Undo_EndBlock(SCRIPT_NAME, -1)
	end, gui_buttons_types.Action, false, reaper.ImGui_Key_Enter())

	ImGui.EndDisabled(ctx)

	ImGui.SameLine(ctx)

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

GUI_ShowMainWindow(wndWidth, 0)
