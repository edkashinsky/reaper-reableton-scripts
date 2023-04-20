-- @description ek_Core functions GUI
-- @author Ed Kashinsky
-- @noindex

local ctx
local window_visible = false
local window_opened = false
local window_first_frame_showed = false
local window_width = 0
local window_height = 0
local font_name = 'arial'
local font_size = 15
local default_enter_action = nil
local cached_fonts = nil
local _, imgui_version_num, _ = reaper.ImGui_GetVersion()

gui_font_types = {
	None = 1,
	Italic = 2,
	Bold = 3,
}

gui_colors = {
	White = 0xffffffff,
	Green = 0x6CCA3Cff,
	Red = 0xEB5852ff,
}

gui_buttons_types = {
	Action = 1,
	Cancel = 2,
}

gui_widget_types = {
	Text = 1,
	Number = 2,
	NumberDrag = 3,
	NumberSlider = 4,
	Checkbox = 5,
	Combo = 6,
	Color = 7,
	ColorView = 8
}

GUI_OnWindowClose = nil

local GUI_DefaultColor = reaper.ColorToNative(84, 84, 84)

local function GUI_GetWindowFlags()
	return reaper.ImGui_WindowFlags_NoCollapse() |
		reaper.ImGui_WindowFlags_NoResize() |
		reaper.ImGui_WindowFlags_TopMost()
end

local function GUI_GetInputFlags()
	return reaper.ImGui_InputTextFlags_AutoSelectAll() |
		reaper.ImGui_InputTextFlags_AllowTabInput() |
		reaper.ImGui_InputTextFlags_AlwaysOverwrite()
end

function GUI_GetColorFlags()
	return reaper.ImGui_InputTextFlags_AutoSelectAll() |
		reaper.ImGui_InputTextFlags_AllowTabInput() |
		reaper.ImGui_InputTextFlags_AlwaysOverwrite() |
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
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x1a1b1bff)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x545454ff)

	reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height)

	window_visible, window_opened = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, GUI_GetWindowFlags())

	if window_visible then
	    frame()
		window_first_frame_showed = true
	    reaper.ImGui_End(ctx)
	end

	reaper.ImGui_PopStyleColor(ctx, 2)
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

	local gui_btn_padding = 12
	local gui_btn_height = 27
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
		local newVal
		local s = settingsTable[i]
		local curVal = EK_GetExtState(s.key, s.default)

		reaper.ImGui_PushItemWidth(ctx, 224)
		reaper.ImGui_PushFont(ctx, GUI_GetFont(gui_font_types.Bold))

		newVal = GUI_DrawWidget(s.type, s.title, curVal, s)

		if curVal ~= newVal then EK_SetExtState(s.key, newVal) end

		reaper.ImGui_PopFont(ctx)
		reaper.ImGui_PopItemWidth(ctx)

		if s.description then
			GUI_DrawText(s.description, GUI_GetFont(gui_font_types.Italic))

			if i < #settingsTable then GUI_DrawGap() end
		end
	end
end

function GUI_DrawWidget(type, label, value, settings)
	local newVal
	local input_flags = GUI_GetInputFlags()

	if type == gui_widget_types.Text then
		_, newVal = reaper.ImGui_InputText(ctx, label, value, input_flags)
	elseif type == gui_widget_types.Number then
		if settings.number_precision then
			_, newVal = reaper.ImGui_InputDouble(ctx, label, value, nil, nil, settings.number_precision, input_flags)
		else
			_, newVal = reaper.ImGui_InputInt(ctx, label, value, nil, nil, input_flags)
		end
	elseif type == gui_widget_types.NumberDrag then
		if settings.number_min and not settings.number_max then settings.number_max = 0x7fffffff end

		if settings.number_precision then
			_, newVal = reaper.ImGui_DragDouble(ctx, label, value, nil, settings.number_min, settings.number_max, settings.number_precision, input_flags)
		else
			_, newVal = reaper.ImGui_DragInt(ctx, label, value, nil, settings.number_min, settings.number_max, nil, input_flags)
		end
	elseif type == gui_widget_types.NumberSlider then
		if settings.number_precision then
			_, newVal = reaper.ImGui_SliderDouble(ctx, label, value, settings.number_min, settings.number_max, settings.number_precision, input_flags)
		else
			_, newVal = reaper.ImGui_SliderInt(ctx, label, value, settings.number_min, settings.number_max, nil, input_flags)
		end
	elseif type == gui_widget_types.Checkbox then
		_, newVal = reaper.ImGui_Checkbox(ctx, label, value)
	elseif type == gui_widget_types.Combo then
		_, newVal = reaper.ImGui_Combo(ctx, label, value, join(settings.select_values, "\0") .. "\0")
	elseif type == gui_widget_types.Color then
		if value == 0 then value = nil end

		_, newVal = reaper.ImGui_ColorPicker3(ctx, label, value, GUI_GetColorFlags())
	elseif type == gui_widget_types.ColorView then
		if value == 0 then value = GUI_DefaultColor end

		newVal = reaper.ImGui_ColorButton(ctx, label, value, GUI_GetColorFlags())
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
