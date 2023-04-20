-- @description ek_Smart renaming depending on focus
-- @version 1.0.2
-- @author Ed Kashinsky
-- @about
--   Renaming stuff for takes, items, markers, regions and tracks depending on focus
-- @changelog
--   - Fixed: When you change only color, title won't be changed
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

if not reaper.APIExists("ImGui_WindowFlags_NoCollapse") then
    reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" via ReaPack', '', 0)
	return
end

CoreFunctionsLoaded("ek_Smart renaming functions.lua")

local wndWidth = 347
local element = GetFocusedElement()
local isColorTreeShowed = false
local isColorTreeShowedChanged = false
local isAdvanced = false
local isTitleSet = false
local isColorSet = false
local lastColorsList = EK_GetExtState(rename_last_colors_list_key, {})
local applyToAllTakes = true
local value, color

local function UpdateLastColorsList(newColor)
	local list = {}
	local i = 1
	local limit = 8

	table.insert(list, newColor)

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
end

local function frameForAdvancedForm()
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

	reaper.ImGui_PushItemWidth(GUI_GetCtx(), 224)
	reaper.ImGui_PushFont(GUI_GetCtx(), GUI_GetFont(gui_font_types.Bold))

	local newVal = GUI_DrawWidget(gui_widget_types.Combo, "Type", a_key, settings)
	if newVal ~= a_key then
		EK_SetExtState(rename_advanced_types_key, rename_advanced_config[newVal + 1].id)
	end

	reaper.ImGui_PopFont(GUI_GetCtx())
	reaper.ImGui_PopItemWidth(GUI_GetCtx())
	GUI_DrawSettingsTable(a_fields)

	reaper.ImGui_Text(GUI_GetCtx(), "Example:")
	reaper.ImGui_SameLine(GUI_GetCtx())
	reaper.ImGui_PushFont(GUI_GetCtx(), GUI_GetFont(gui_font_types.Bold))
	reaper.ImGui_Text(GUI_GetCtx(), GetProcessedTitleByAdvanced(element.value, 1))
	reaper.ImGui_PopFont(GUI_GetCtx())

end

function frame()
	if not EK_IsWindowFocusedByTitle(ek_js_wnd.titles.ScriptSmartRenaming) then
		element = GetFocusedElement()
	end

	local newVal

	-- if newElement.type == element.type then element = newElement end
	if not isTitleSet then value = element.value end
	if not isColorSet then color = element.color end

	--
	-- HEADER
	--
	reaper.ImGui_Text(GUI_GetCtx(), element.typeTitle .. ":")

	reaper.ImGui_SameLine(GUI_GetCtx())
	reaper.ImGui_PushFont(GUI_GetCtx(), GUI_GetFont(gui_font_types.Bold))
	reaper.ImGui_Text(GUI_GetCtx(), element.title)
	reaper.ImGui_PopFont(GUI_GetCtx())

	reaper.ImGui_BeginDisabled(GUI_GetCtx(), element.type == rename_types.Nothing)

	--
	-- NEW TITLE
	--

	if GUI_DrawWidget(gui_widget_types.ColorView, "Color view", color) then
		isColorTreeShowed = not isColorTreeShowed
		isColorTreeShowedChanged = true
	end

	reaper.ImGui_SameLine(GUI_GetCtx())

	GUI_SetFocusOnWidget()

	reaper.ImGui_BeginDisabled(GUI_GetCtx(), isAdvanced == true)

	reaper.ImGui_PushItemWidth(GUI_GetCtx(), 195)
	reaper.ImGui_PushFont(GUI_GetCtx(), GUI_GetFont(gui_font_types.Bold))

	newVal = GUI_DrawWidget(gui_widget_types.Text, "New Title", value)
	if newVal ~= value then
		value = newVal
		isTitleSet = true
	end

	reaper.ImGui_PopFont(GUI_GetCtx())
	reaper.ImGui_PopItemWidth(GUI_GetCtx())

	reaper.ImGui_EndDisabled(GUI_GetCtx())

	--
	-- COLOR
	--
	if isColorTreeShowed then
		reaper.ImGui_PushItemWidth(GUI_GetCtx(), 224)
		newVal = GUI_DrawWidget(gui_widget_types.Color, "Color", color)
		if newVal ~= color then
			color = newVal
			isColorSet = true
		end
		reaper.ImGui_PopItemWidth(GUI_GetCtx())

		for i = 1, #lastColorsList do
			if GUI_DrawWidget(gui_widget_types.ColorView, "Last Color #" .. i, lastColorsList[i]) then
				color = lastColorsList[i]
				isColorSet = true
			end

			if i < #lastColorsList then reaper.ImGui_SameLine(GUI_GetCtx()) end
		end
	end

	if isColorTreeShowedChanged then
		GUI_SetWindowSize(wndWidth, 0)
		isColorTreeShowedChanged = false
	end

	if element.type == rename_types.Item then
		newVal = GUI_DrawWidget(gui_widget_types.Checkbox, "Apply to all takes", applyToAllTakes)
		if newVal ~= applyToAllTakes then
			applyToAllTakes = newVal
		end
	end

	--
	-- ADVANCED
	--
	newVal = GUI_DrawWidget(gui_widget_types.Checkbox, "Advanced", isAdvanced)
	if newVal ~= isAdvanced then
		isAdvanced = newVal
		GUI_SetWindowSize(wndWidth, 0)
	end

	if isAdvanced then
		frameForAdvancedForm()
	end

	reaper.ImGui_Indent(GUI_GetCtx(), 75)

	GUI_DrawButton('Rename', function()
		reaper.Undo_BeginBlock()

		element.value = value
		element.color = color

		if element.type == rename_types.Item then
			element.applyToAllTakes = applyToAllTakes
		end

		if isColorSet then
			UpdateLastColorsList(color)
		end

		SaveData(element, isTitleSet, isColorSet, isAdvanced)

		reaper.Undo_EndBlock(SCRIPT_NAME, -1)
	end, gui_buttons_types.Action, false, reaper.ImGui_Key_Enter())

	reaper.ImGui_EndDisabled(GUI_GetCtx())

	reaper.ImGui_SameLine(GUI_GetCtx())

	GUI_DrawButton('Cancel', nil, gui_buttons_types.Cancel)
end

if element.type ~= rename_types.Nothing then
	GUI_ShowMainWindow(wndWidth, 0)
end
