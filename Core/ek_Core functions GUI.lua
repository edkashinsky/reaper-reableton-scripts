-- @description ek_Core functions GUI
-- @author Ed Kashinsky
-- @noindex

local ctx
local window_visible = false
local window_opened = false
local window_first_frame_showed = false
local window_width = 0
local window_height = 0
local font_name = 'Helvetica'
local font_size = 12
local default_enter_action = nil
local cached_fonts = nil
local _, imgui_version_num, _ = reaper.ImGui_GetVersion()
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

local function GUI_GetWindowFlags()
	return reaper.ImGui_WindowFlags_NoCollapse() |
		reaper.ImGui_WindowFlags_NoResize() |
		reaper.ImGui_WindowFlags_TopMost()
end

local function GUI_GetInputFlags()
	return reaper.ImGui_InputTextFlags_AutoSelectAll() |
		reaper.ImGui_InputTextFlags_AllowTabInput()
end

function GUI_GetColorFlags()
	return reaper.ImGui_InputTextFlags_AutoSelectAll() |
		reaper.ImGui_InputTextFlags_AllowTabInput() |
		reaper.ImGui_ColorEditFlags_NoOptions() |
		reaper.ImGui_ColorEditFlags_DisplayHex() |
		reaper.ImGui_ColorEditFlags_NoSidePreview() |
		reaper.ImGui_ColorEditFlags_NoTooltip() |
		reaper.ImGui_ColorEditFlags_NoAlpha()
end

local function GUI_GetFonts()
	if not cached_fonts then
		cached_fonts = {}
		cached_fonts[gui_font_types.None] = reaper.ImGui_CreateFont(font_name, font_size, reaper.ImGui_FontFlags_None())
		cached_fonts[gui_font_types.Italic] = reaper.ImGui_CreateFont(font_name, font_size, reaper.ImGui_FontFlags_Italic())
		cached_fonts[gui_font_types.Bold] = reaper.ImGui_CreateFont(font_name, font_size, reaper.ImGui_FontFlags_Bold())
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
	local attachFonts = function(func_name)
		for _, font in pairs(GUI_GetFonts()) do func_name(ctx, font) end
	end

	-- ImGui_AttachFont renamed to ImGui_Attach
	if imgui_version_num >= 18910 then
		if not window_opened then attachFonts(reaper.ImGui_Attach) end
	else
		attachFonts(reaper.ImGui_AttachFont)
	end

	reaper.ImGui_PushFont(ctx, GUI_GetFont(gui_font_types.None))
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), gui_colors.Background)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), gui_colors.Background)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), gui_colors.Input.Background)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), gui_colors.Input.Hover)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), gui_colors.Input.Hover)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Text)

	reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height)

	window_visible, window_opened = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, GUI_GetWindowFlags())

	if window_visible then
	    frame()
		window_first_frame_showed = true
	    reaper.ImGui_End(ctx)
	end

	reaper.ImGui_PopStyleColor(ctx, 6)
	reaper.ImGui_PopFont(ctx)

	if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
		GUI_CloseMainWindow()
	end

	if window_opened then
	    reaper.defer(main)
	else
		if type(GUI_OnWindowClose) == 'function' then
			GUI_OnWindowClose()
		end

	    reaper.ImGui_DestroyContext(ctx)
	end
end

function GUI_ShowMainWindow(w, h)
	window_width = w
	window_height = h

	ctx = reaper.ImGui_CreateContext(SCRIPT_NAME)

	reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)

    reaper.defer(main)
end

function GUI_CloseMainWindow()
	window_opened = false
end

function GUI_DrawText(text, font, color)
	if not font then font = GUI_GetFont(gui_font_types.None) end

	if color ~= nil then
		reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), color)
	end

	reaper.ImGui_PushFont(ctx, font)
	reaper.ImGui_TextWrapped(ctx, text)
	reaper.ImGui_PopFont(ctx)

	if color ~= nil then
		reaper.ImGui_PopStyleColor(ctx)
	end
end

function GUI_DrawButton(label, action, btn_type, prevent_close_wnd, keyboard_key_action)
	if not btn_type then btn_type = gui_buttons_types.Action end

	local gui_btn_padding = 10
	local gui_btn_height = 25
	local width = reaper.ImGui_CalcTextSize(ctx, label)
	width = width + (gui_btn_padding * 2)

	if btn_type == gui_buttons_types.Action then

	elseif btn_type == gui_buttons_types.Cancel then
		reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x545454ff)
		reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x666666ff)
		reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x777777ff)
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

	if reaper.ImGui_Button(ctx, label, width, gui_btn_height) then
		button_action()
    end

	if keyboard_key_action and reaper.ImGui_IsKeyPressed(ctx, keyboard_key_action) then
		button_action()
	end

	if btn_type == gui_buttons_types.Action then

	elseif btn_type == gui_buttons_types.Cancel then
		reaper.ImGui_PopStyleColor(ctx, 3)
	end
end

function GUI_DrawGap()
	reaper.ImGui_Text(ctx, '')
end

function GUI_GetCtx()
	return ctx
end

function GUI_DrawSettingsTable(settingsTable)
	for i = 1, #settingsTable do
		local newVal, curVal
		local s = settingsTable[i]
		local hidden = s.hidden == true or (type(s.hidden) == "function" and s.hidden())

		if not hidden then
			local disabled = s.disabled == true or (type(s.disabled) == "function" and s.disabled())

			if s.type == gui_input_types.Label then
				reaper.ImGui_TextWrapped(ctx, s.title)
			else
				if type(s.value) == "function" then curVal = s.value()
				elseif s.value then curVal = s.value
				elseif cached_values[s.key] ~= nil then curVal = cached_values[s.key]
				else
					curVal = EK_GetExtState(s.key, s.default)
					cached_values[s.key] = curVal
				end

				if disabled then reaper.ImGui_BeginDisabled(ctx, true) end

				newVal = GUI_DrawInput(s.type, s.title, curVal, s)

				if curVal ~= newVal then
					if type(s.value) ~= "function" then
						cached_values[s.key] = newVal
						EK_SetExtState(s.key, newVal)
					end

					if type(s.on_change) == "function" then
						s.on_change(newVal)
					end
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

			if disabled then reaper.ImGui_EndDisabled(ctx) end
		end
	end
end

function GUI_DrawInput(i_type, i_label, i_value, i_settings)
	if not i_settings then i_settings = {} end

	local newVal
	local input_flags = i_settings.flags and i_settings.flags or GUI_GetInputFlags()
	local needLabel = true
	local inner_spacing_x = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing())

	reaper.ImGui_PushFont(ctx, GUI_GetFont(gui_font_types.Bold))
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Input.Text)

	if i_type == gui_input_types.Text then
		_, newVal = reaper.ImGui_InputText(ctx, '##' .. i_label, i_value, input_flags)
	elseif i_type == gui_input_types.Number then
		if i_settings.number_precision then
			_, newVal = reaper.ImGui_InputDouble(ctx, '##' .. i_label, i_value, nil, nil, i_settings.number_precision, input_flags)
		else
			_, newVal = reaper.ImGui_InputInt(ctx, '##' .. i_label, i_value, nil, nil, input_flags)
		end
	elseif i_type == gui_input_types.NumberDrag then
		if i_settings.number_min and not i_settings.number_max then i_settings.number_max = 0x7fffffff end

		if i_settings.number_precision then
			_, newVal = reaper.ImGui_DragDouble(ctx, '##' .. i_label, i_value, i_settings.number_step, i_settings.number_min, i_settings.number_max, i_settings.number_precision, input_flags)
		else
			_, newVal = reaper.ImGui_DragInt(ctx, '##' .. i_label, i_value, i_settings.number_step, i_settings.number_min, i_settings.number_max, nil, input_flags)
		end
	elseif i_type == gui_input_types.NumberSlider then
		if i_settings.number_precision then
			_, newVal = reaper.ImGui_SliderDouble(ctx, '##' .. i_label, i_value, i_settings.number_min, i_settings.number_max, i_settings.number_precision, input_flags)
		else
			_, newVal = reaper.ImGui_SliderInt(ctx, '##' .. i_label, i_value, i_settings.number_min, i_settings.number_max, nil, input_flags)
		end
	elseif i_type == gui_input_types.Checkbox then
		_, newVal = reaper.ImGui_Checkbox(ctx, '##' .. i_label, i_value)
	elseif i_type == gui_input_types.Combo then
		local select_values

		if type(i_settings.select_values) == "function" then
			select_values = i_settings.select_values()
		else
			select_values = i_settings.select_values
		end

		_, newVal = reaper.ImGui_Combo(ctx, '##' .. i_label, i_value, join(i_settings.select_values, "\0") .. "\0")
	elseif i_type == gui_input_types.Color then
		if i_value == 0 then i_value = nil end

		_, newVal = reaper.ImGui_ColorPicker3(ctx, '##' .. i_label, i_value, GUI_GetColorFlags())
	elseif i_type == gui_input_types.ColorView then
		if i_value == 0 then i_value = tonumber(gui_colors.Input.Background >> 8) end

		local flags = i_settings.flags and i_settings.flags or GUI_GetColorFlags()

		reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), gui_colors.White)
		if i_settings.selected then
			newVal = reaper.ImGui_ColorButton(ctx, '##' .. i_label, i_value, flags & ~reaper.ImGui_InputTextFlags_AllowTabInput())
		else
			newVal = reaper.ImGui_ColorButton(ctx, '##' .. i_label, i_value, flags)
		end
		reaper.ImGui_PopStyleColor(ctx)

		needLabel = false
	end

	reaper.ImGui_PopStyleColor(ctx)
	reaper.ImGui_PopFont(ctx)

	--
	-- LABEL
	--
	if needLabel then
		reaper.ImGui_SameLine(ctx, nil, inner_spacing_x)
		reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),  gui_colors.Input.Label)
		if i_settings.label_not_bold ~= true then reaper.ImGui_PushFont(ctx, GUI_GetFont(gui_font_types.Bold)) end

		reaper.ImGui_Text(ctx, i_label)

		if i_settings.label_not_bold ~= true then reaper.ImGui_PopFont(ctx) end
		reaper.ImGui_PopStyleColor(ctx)
	end

	return newVal
end

function GUI_SetWindowSize(width, height)
	window_width = width
	window_height = height
end

function GUI_SetFocusOnWidget()
	if window_first_frame_showed == false then
		reaper.ImGui_SetKeyboardFocusHere(ctx)
	end
end
