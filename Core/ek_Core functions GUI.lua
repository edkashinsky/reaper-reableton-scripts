-- @description ek_Core functions GUI
-- @author Ed Kashinsky
-- @noindex

local ImGui = {}
local ctx
local window_visible = false
local window_opened = false
local window_first_frame_showed = false
local window_width = 0
local window_height = 0
local font_name = 'Helvetica'
local font_size = 13
local default_enter_action = nil
local cached_fonts = nil
local cached_values = {}

gui_font_types = {
	None = 1,
	Italic = 2,
	Bold = 3,
}

gui_colors = {
	White = 0xffffffff,
	Green = 0x6CCA3Cff,
	Red = 0xEB5852ff,
	Blue = 0x1f6fcbff,
	Background = 0x2c2c2cff,
	Text = 0xffffffff,
	TextDisabled = 0xbbbbbbff,
	Input = {
		Background = 0x686868ff,
		Hover = 0x686868bb,
		Text = 0xe9e9e9ff,
		Label = 0xffffffff,
	},
	Button = {

	}
}

gui_buttons_types = {
	Action = 1,
	Cancel = 2,
}

gui_input_types = {
	Label = 1,
	Text = 2,
	Number = 3,
	NumberDrag = 4,
	NumberSlider = 5,
	Checkbox = 6,
	Combo = 7,
	Color = 8,
	ColorView = 9
}

GUI_OnWindowClose = nil
FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float and reaper.ImGui_NumericLimits_Float() or 0, 0

local function GUI_GetWindowFlags()
	return reaper.ImGui_WindowFlags_NoCollapse() |
		reaper.ImGui_WindowFlags_NoResize() |
		reaper.ImGui_WindowFlags_TopMost()
end

local function GUI_GetInputFlags()
	return reaper.ImGui_InputTextFlags_AutoSelectAll() |
		reaper.ImGui_InputTextFlags_AllowTabInput()
end

local function GUI_GetSliderFlags()
	return nil
end

function GUI_GetColorFlags()
	return reaper.ImGui_ColorEditFlags_NoOptions() |
		reaper.ImGui_ColorEditFlags_DisplayHex() |
		reaper.ImGui_ColorEditFlags_NoSidePreview() |
		reaper.ImGui_ColorEditFlags_NoTooltip() |
		reaper.ImGui_ColorEditFlags_NoAlpha() |
		reaper.ImGui_ColorEditFlags_NoBorder()
end

local function GUI_GetFonts()
	if not cached_fonts then
		cached_fonts = {}
		cached_fonts[gui_font_types.None] = ImGui.CreateFont(font_name, font_size, ImGui.FontFlags_None())
		cached_fonts[gui_font_types.Italic] = ImGui.CreateFont(font_name, font_size, ImGui.FontFlags_Italic())
		cached_fonts[gui_font_types.Bold] = ImGui.CreateFont(font_name, font_size, ImGui.FontFlags_Bold())
	end

	return cached_fonts
end

function GUI_GetFont(font_type)
	local fonts = GUI_GetFonts()
	return fonts[font_type]
end

--
-- Show main window
--
local function main()
	ImGui.SetNextWindowSize(ctx, window_width, window_height)

	ImGui.PushFont(ctx, GUI_GetFont(gui_font_types.None))
	ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg(), gui_colors.Background)
	ImGui.PushStyleColor(ctx, ImGui.Col_Separator(), gui_colors.Background)
	ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg(), gui_colors.Input.Background)
	ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered(), gui_colors.Input.Hover)
	ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive(), gui_colors.Input.Hover)
	ImGui.PushStyleColor(ctx, ImGui.Col_Text(), gui_colors.Text)
	ImGui.PushStyleColor(ctx, ImGui.Col_TextDisabled(), gui_colors.TextDisabled)

	window_visible, window_opened = ImGui.Begin(ctx, SCRIPT_NAME, true, GUI_GetWindowFlags())

	if window_visible then
	    frame(ImGui, ctx, not window_first_frame_showed)
		window_first_frame_showed = true
	    ImGui.End(ctx)
	end

	ImGui.PopStyleColor(ctx, 7)
	ImGui.PopFont(ctx)

	if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape()) then
		GUI_CloseMainWindow()
	end

	if window_opened then
	    reaper.defer(main)
	else
		if type(GUI_OnWindowClose) == 'function' then
			GUI_OnWindowClose()
		end

	    ImGui.DestroyContext(ctx)
	end
end

function GUI_ShowMainWindow(w, h)
	if reaper.ImGui_GetVersion == nil or not pcall(function()
		dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua') '0.8.5'
	end) then
		reaper.MB('Please install "ReaImGui: ReaScript binding for Dear ImGui" (minimum v.0.8.5) library via ReaPack', SCRIPT_NAME, 0)
		reaper.ReaPack_BrowsePackages("ReaImGui: ReaScript binding for Dear ImGui")
		return
	end

	for name, func in pairs(reaper) do
		name = name:match('^ImGui_(.+)$')
		if name then ImGui[name] = func end
	end

	window_width = w
	window_height = h

	ctx = ImGui.CreateContext(SCRIPT_NAME)

	for _, font in pairs(GUI_GetFonts()) do
		ImGui.Attach(ctx, font)
	end

	ImGui.SetConfigVar(ctx, ImGui.ConfigVar_ViewportsNoDecoration(), 0)

    reaper.defer(main)
end

function GUI_CloseMainWindow()
	window_opened = false
end

function GUI_DrawText(text, font, color)
	if not font then font = GUI_GetFont(gui_font_types.None) end

	if color ~= nil then
		ImGui.PushStyleColor(ctx, ImGui.Col_Text(), color)
	end

	ImGui.PushFont(ctx, font)
	ImGui.TextWrapped(ctx, text)
	ImGui.PopFont(ctx)

	if color ~= nil then
		ImGui.PopStyleColor(ctx)
	end
end

function GUI_DrawLink(text, url)
	text = url or text

	if not reaper.CF_ShellExecute then
		ImGui.Text(ctx, text)
		return
	end

	local color = ImGui.GetStyleColor(ctx, ImGui.Col_CheckMark())
	ImGui.TextColored(ctx, color, text)
	if ImGui.IsItemClicked(ctx) then
		reaper.CF_ShellExecute(url or text)
	elseif ImGui.IsItemHovered(ctx) then
		ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand())
	end
end

function GUI_DrawHint(text, title)
	if not title then title = "[?]" end

	ImGui.TextDisabled(ctx, title)
	if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayShort()) and ImGui.BeginTooltip(ctx) then
		ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
		ImGui.Text(ctx, text)
		ImGui.PopTextWrapPos(ctx)
		ImGui.EndTooltip(ctx)
	end
end

function GUI_SetCursorCenter(text)
	local avail_w = ImGui.GetContentRegionAvail(ctx)
	local text_w  = ImGui.CalcTextSize(ctx, text)

	ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + math.max(0, (avail_w - text_w) // 2))
end

-- works only when ConfigVar_ViewportsNoDecoration() is disabled
--function GUI_AllowOnlyHorizontalResize()
--	ImGui.SetNextWindowSizeConstraints(ctx, 0, -1, FLT_MAX, -1)
--end
--
--function GUI_AllowOnlyVerticalResize()
--	ImGui.SetNextWindowSizeConstraints(ctx, -1, 0, -1, FLT_MAX)
--end

function GUI_DrawButton(label, action, btn_type, prevent_close_wnd, keyboard_key_action)
	if not btn_type then btn_type = gui_buttons_types.Action end

	local gui_btn_padding = 10
	local gui_btn_height = 25
	local width = ImGui.CalcTextSize(ctx, label)
	width = width + (gui_btn_padding * 2)

	if btn_type == gui_buttons_types.Action then

	elseif btn_type == gui_buttons_types.Cancel then
		ImGui.PushStyleColor(ctx, ImGui.Col_Button(), 0x545454ff)
		ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), 0x666666ff)
		ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), 0x777777ff)
	end

	if not default_enter_action and btn_type == gui_buttons_types.Action and type(action) == 'function' then
		default_enter_action = action
	end

	local button_action = function()
		if type(action) == 'function' then
			action()
		end

		if not prevent_close_wnd then
			GUI_CloseMainWindow()
		end
	end

	if ImGui.Button(ctx, label, width, gui_btn_height) then
		button_action()
    end

	if keyboard_key_action and ImGui.IsKeyPressed(ctx, keyboard_key_action) then
		button_action()
	end

	if btn_type == gui_buttons_types.Action then

	elseif btn_type == gui_buttons_types.Cancel then
		ImGui.PopStyleColor(ctx, 3)
	end
end

function GUI_DrawGap(height)
	if not height then height = 5 end

	ImGui.Dummy(ctx, 0, height)
end

function GUI_ClearValuesCache()
	for key, _ in pairs(cached_values) do
		cached_values[key] = nil
	end
end

function GUI_DrawSettingsTable(settingsTable)
	for i = 1, #settingsTable do
		local newVal, curVal
		local s = settingsTable[i]
		local hidden = s.hidden == true or (type(s.hidden) == "function" and s.hidden())

		if not hidden then
			local disabled = s.disabled == true or (type(s.disabled) == "function" and s.disabled())

			if s.type == gui_input_types.Label then
				ImGui.TextWrapped(ctx, s.title)
			else
				if type(s.value) == "function" then curVal = s.value()
				elseif s.value then curVal = s.value
				elseif cached_values[s.key] ~= nil then curVal = cached_values[s.key]
				else
					curVal = EK_GetExtState(s.key, s.default)
					cached_values[s.key] = curVal
				end

				if disabled then ImGui.BeginDisabled(ctx, true) end

				newVal = GUI_DrawInput(s.type, s.title, curVal, s)

				if curVal ~= newVal then
					EK_SetExtState(s.key, newVal)

					if type(s.on_change) == "function" then
						s.on_change(newVal, s)
					end

					cached_values[s.key] = nil
				end
			end

			if s.description then
				local descr

				if type(s.description) == "function" then
					descr = s.description(newVal)
				else
					descr = s.description
				end

				if descr ~= nil then
					GUI_DrawText(descr, GUI_GetFont(gui_font_types.Italic))

					if i < #settingsTable then GUI_DrawGap() end
				end
			end

			if disabled then ImGui.EndDisabled(ctx) end
		end
	end
end

function GUI_DrawInput(i_type, i_label, i_value, i_settings)
	if not i_settings then i_settings = {} end

	local newVal
	local input_flags = i_settings.flags and i_settings.flags or GUI_GetInputFlags()
	local needLabel = true
	local inner_spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing())

	ImGui.PushFont(ctx, GUI_GetFont(gui_font_types.Bold))
	ImGui.PushStyleColor(ctx, ImGui.Col_Text(), gui_colors.Input.Text)

	if i_type == gui_input_types.Text then
		_, newVal = ImGui.InputText(ctx, '##' .. i_label, i_value, input_flags)
	elseif i_type == gui_input_types.Number then
		if i_settings.number_precision then
			_, newVal = ImGui.InputDouble(ctx, '##' .. i_label, i_value, nil, nil, i_settings.number_precision, input_flags)
		else
			_, newVal = ImGui.InputInt(ctx, '##' .. i_label, i_value, nil, nil, input_flags)
		end
	elseif i_type == gui_input_types.NumberDrag then
		input_flags = i_settings.flags and i_settings.flags or GUI_GetSliderFlags()

		if i_settings.number_min and not i_settings.number_max then i_settings.number_max = 0x7fffffff end

		if i_settings.number_precision then
			_, newVal = ImGui.DragDouble(ctx, '##' .. i_label, i_value, i_settings.number_step, i_settings.number_min, i_settings.number_max, i_settings.number_precision, input_flags)
		else
			_, newVal = ImGui.DragInt(ctx, '##' .. i_label, i_value, i_settings.number_step, i_settings.number_min, i_settings.number_max, nil, input_flags)
		end
	elseif i_type == gui_input_types.NumberSlider then
		input_flags = i_settings.flags and i_settings.flags or GUI_GetSliderFlags()

		if i_settings.number_precision then
			_, newVal = ImGui.SliderDouble(ctx, '##' .. i_label, i_value, i_settings.number_min, i_settings.number_max, i_settings.number_precision, input_flags)
		else
			_, newVal = ImGui.SliderInt(ctx, '##' .. i_label, i_value, i_settings.number_min, i_settings.number_max, nil, input_flags)
		end
	elseif i_type == gui_input_types.Checkbox then
		_, newVal = ImGui.Checkbox(ctx, '##' .. i_label, i_value)
	elseif i_type == gui_input_types.Combo then
		local select_values

		if type(i_settings.select_values) == "function" then
			select_values = i_settings.select_values()
		else
			select_values = i_settings.select_values
		end

		_, newVal = ImGui.Combo(ctx, '##' .. i_label, i_value, join(i_settings.select_values, "\0") .. "\0")
	elseif i_type == gui_input_types.Color then
		if i_value == 0 then i_value = nil end

		_, newVal = ImGui.ColorPicker3(ctx, '##' .. i_label, i_value, GUI_GetColorFlags())
	elseif i_type == gui_input_types.ColorView then
		if i_value == 0 then i_value = tonumber(gui_colors.Input.Background >> 8) end

		local flags = i_settings.flags and i_settings.flags or GUI_GetColorFlags()

		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg(), gui_colors.White)
		if i_settings.selected then
			newVal = ImGui.ColorButton(ctx, '##' .. i_label, i_value, flags & ~ImGui.ColorEditFlags_NoBorder())
		else
			newVal = ImGui.ColorButton(ctx, '##' .. i_label, i_value, flags)
		end
		ImGui.PopStyleColor(ctx)

		needLabel = false
	end

	ImGui.PopStyleColor(ctx)
	ImGui.PopFont(ctx)

	--
	-- LABEL
	--
	if needLabel then
		ImGui.SameLine(ctx, nil, inner_spacing_x)
		ImGui.PushStyleColor(ctx, ImGui.Col_Text(),  gui_colors.Input.Label)
		if i_settings.label_not_bold ~= true then ImGui.PushFont(ctx, GUI_GetFont(gui_font_types.Bold)) end

		ImGui.Text(ctx, i_label)

		if i_settings.label_not_bold ~= true then ImGui.PopFont(ctx) end
		ImGui.PopStyleColor(ctx)
	end

	return newVal
end

function GUI_SetWindowSize(width, height)
	window_width = width
	window_height = height
end

function GUI_SetFocusOnWidget()
	if window_first_frame_showed == false then
		ImGui.SetKeyboardFocusHere(ctx)
	end
end
