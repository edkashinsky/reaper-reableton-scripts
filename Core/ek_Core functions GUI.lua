-- @description ek_Core functions GUI
-- @author Ed Kashinsky
-- @noindex

local ImGui = {}
local ctx
local GUI_THEME_DARK = "Dark"
local GUI_THEME_LIGHT = "Light"
local key_gui_theme = "gui_theme"
local key_gui_font_size = "gui_font_size"
local window_visible = false
local window_opened = false
local window_first_frame_showed = false
local window_width = 0
local window_height = 0
local font_name = 'Arial'
local font_size = EK_GetExtState(key_gui_font_size, 14)
local default_enter_action = nil
local cached_fonts = nil
local cached_values = {}

local gui_themes = { GUI_THEME_DARK, GUI_THEME_LIGHT }
local theme = EK_GetExtState(key_gui_theme, GUI_THEME_DARK)
local version = EK_GetScriptVersion()
local coreVersion = EK_GetScriptVersion(debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. dir_sep .. ")") .. "ek_Core functions.lua")
local _, _, imGuiVersion = reaper.ImGui_GetVersion()

gui_fonts = {
	None = 1,
	Italic = 2,
	Bold = 3,
}

gui_cols = {
	White = 0xffffffff,
	Green = 0x6CCA3Cff,
	Red = 0xEB5852ff,
	Background = {
		Dark = 0x202022ff,
		Light = 0xccccccff,
	},
	ScrollGrab = {
		Dark = 0x686868ff,
		Light = 0xaaaaaaff,
	},
	Text = {
		Dark = 0xffffffff,
		Light = 0x202022ff,
		Disabled = {
			Dark = 0xbbbbbbff,
			Light = 0xeeeeeeff,
		},
		Link = {
			Dark = 0x4296FAFF,
			Light = 0x1f6fcbff
		}
	},
	Header = {
		Background = 0x5865f2ff,
		Text = 0xffffffff,
	},
	Menu = {
		Background = {
			Dark = 0x37373bff,
			Light = 0xc4c4c4ff,
		},
		Hovered = {
			Dark = 0x67676eff,
			Light = 0xaaaaaaff,
		},
		Active = {
			Dark = 0x67676eff,
			Light = 0xaaaaaaff,
		},
	},
	Input = {
		Background = {
			Dark = 0x686868ff,
			Light = 0xaaaaaaff,
		},
		Hover = 0x686868bb,
		Text = 0xe9e9e9ff,
		Label = {
			Dark = 0xffffffff,
			Light = 0x202022ff,
		},
		CheckMark = 0x7ffffffff,
		Grab = 0x707affff,
		Combo = {
			Background = {
				Dark = 0x686868ff,
				Light = 0xaaaaaaff,
			},
			Hovered = 0x999999ff
		}
	},
	Button = {
		Basic = {
			Background = 0x5865f2ff,
			Hovered = 0x4751c4ff,
			Active = 0x4751c4ff,
			Text = 0xffffffff,
		},
		Cancel = {
			Background = {
				Dark = 0x686868ff,
				Light = 0xaaaaaaff,
			},
			Hovered = 0x4f4f4fff,
			Active = 0x4f4f4fff,
			Text = 0xffffffff,
		}

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
GUI_DrawMenu = nil
FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float and reaper.ImGui_NumericLimits_Float() or 0, 0


local function GUI_GetWindowFlags()
	return reaper.ImGui_WindowFlags_NoCollapse() |
		reaper.ImGui_WindowFlags_NoResize() |
		reaper.ImGui_WindowFlags_TopMost() |
		reaper.ImGui_WindowFlags_MenuBar()
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
		cached_fonts[gui_fonts.None] = ImGui.CreateFont(font_name, font_size, ImGui.FontFlags_None())
		cached_fonts[gui_fonts.Italic] = ImGui.CreateFont(font_name, font_size, ImGui.FontFlags_Italic())
		cached_fonts[gui_fonts.Bold] = ImGui.CreateFont(font_name, font_size, ImGui.FontFlags_Bold())
	end

	return cached_fonts
end

function GUI_GetFont(font_type)
	local fonts = GUI_GetFonts()
	return fonts[font_type]
end

function GUI_GetColor(color)
	if not color then return nil end

	if type(color) == 'table' and color.Dark and color.Light then
		return theme == GUI_THEME_DARK and color.Dark or color.Light
	end

	return color
end

function GUI_PushColor(reaimgui_col, col)
	if type(reaimgui_col) == 'table' then
		for key, val in pairs(reaimgui_col) do
			ImGui.PushStyleColor(ctx, key, GUI_GetColor(val))
		end
	else
		ImGui.PushStyleColor(ctx, reaimgui_col, GUI_GetColor(col))
	end
end

function GUI_DrawModalPopup(title, content)
	local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
	ImGui.SetNextWindowSize(ctx, 480, 0)
    ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Always(), 0.5, 0.5)

	GUI_PushColor(ImGui.Col_Text(), gui_cols.Header.Text)
	if ImGui.BeginPopupModal(ctx, title, nil, ImGui.WindowFlags_NoResize()) then
		ImGui.PopStyleColor(ctx)

		content(ImGui, ctx)

		ImGui.EndPopup(ctx)
	else
		ImGui.PopStyleColor(ctx)
	end
end

local function DrawAboutPopup()
	GUI_DrawModalPopup('About', function()
		GUI_DrawText("Hello, brave Reaper user! My name is ")
		ImGui.SameLine(ctx, 0, 0);
		GUI_DrawLink("Ed Kashinsky", "https://soundcloud.com/edkashinsky")
		GUI_DrawText("and I'm glad you're using my scripts!")

		GUI_DrawGap(10)

		GUI_DrawText("If you have any ideas for improving scripts or bug reports,")
		GUI_DrawText("please create an issue on ")
		ImGui.SameLine(ctx, 0, 0);
		GUI_DrawLink("Github", "https://github.com/edkashinsky/reaper-reableton-scripts/issues/new")
		ImGui.SameLine(ctx, 0, 0);
		ImGui.Text(ctx, " or just text me on ")
		ImGui.SameLine(ctx, 0, 0);
		GUI_DrawLink("Facebook", "https://www.facebook.com/edkashinsky.music/")

		GUI_DrawGap(10)

		GUI_DrawText("You can support my work via:")
		ImGui.Bullet(ctx)
		ImGui.SameLine(ctx, 0, 5);
		GUI_DrawLink("PayPal", "https://www.paypal.com/paypalme/kashinsky")

		ImGui.Bullet(ctx)
		ImGui.SameLine(ctx, 0, 5);
		GUI_DrawLink("BuyMeCoffee", "https://buymeacoffee.com/edkashinsky")

		ImGui.Bullet(ctx)
		ImGui.SameLine(ctx, 0, 5);
		GUI_DrawLink("Ko-fi", "https://ko-fi.com/edkashinsky")

		ImGui.Bullet(ctx)
		ImGui.SameLine(ctx, 0, 5);
		GUI_DrawLink("Boosty", "https://boosty.to/edkashinsky/donate")
		GUI_DrawGap(10)

		GUI_DrawText("GUI Global Settings", gui_fonts.Bold)

		local newVal
		local key = 0
		for i = 1, #gui_themes do
			if gui_themes[i] == theme then key = i - 1 end
		end

		ImGui.PushItemWidth(ctx, 160)
		newVal = GUI_DrawInput(gui_input_types.Combo, "Theme", key, { select_values = gui_themes })
		if newVal ~= key then
			theme = gui_themes[newVal + 1]
			EK_SetExtState(key_gui_theme, theme)
		end

		newVal = GUI_DrawInput(gui_input_types.NumberSlider, "Font size (need to reopen script)", font_size, { number_min = 9, number_max = 20})
		if newVal ~= font_size then
			font_size = newVal
			EK_SetExtState(key_gui_font_size, font_size)
		end

		GUI_DrawGap(10)

		if version then
			GUI_DrawText("Script version: " .. version)
		end

		if coreVersion then
			GUI_DrawText("Core functions version: " .. coreVersion)
		end

		GUI_DrawText("ReaImGui version: " .. imGuiVersion)

		GUI_DrawGap(10)

		if version then
			GUI_SetCursorCenter('     Close   About script    ')

			GUI_DrawButton('About script', function()
				local owner = reaper.ReaPack_GetOwner(({reaper.get_action_context()})[2])
				if owner then
					reaper.ReaPack_AboutInstalledPackage(owner)
					reaper.ReaPack_FreeEntry(owner)
				end
			end, gui_buttons_types.Action, true)

			ImGui.SameLine(ctx)
		else
			GUI_SetCursorCenter('   Close   ')
		end

		GUI_DrawButton('Close', function()
			ImGui.CloseCurrentPopup(ctx)
		end, gui_buttons_types.Cancel, true)
	end)
end

--
-- Show main window
--
local function main()
	ImGui.SetNextWindowSize(ctx, window_width, window_height)

	GUI_PushColor({
		[ImGui.Col_WindowBg()] = gui_cols.Background,
		[ImGui.Col_Separator()] = gui_cols.Background,
		[ImGui.Col_PopupBg()] = gui_cols.Background,
		[ImGui.Col_ScrollbarBg()] = gui_cols.Background,
		[ImGui.Col_ScrollbarGrab()] = gui_cols.ScrollGrab,
		[ImGui.Col_Text()] = gui_cols.Text,
		[ImGui.Col_TextDisabled()] = gui_cols.Text.Disabled,
		[ImGui.Col_MenuBarBg()] = gui_cols.Menu.Background,
		[ImGui.Col_FrameBg()] = gui_cols.Input.Background,
		[ImGui.Col_FrameBgHovered()] = gui_cols.Input.Hover,
		[ImGui.Col_FrameBgActive()] = gui_cols.Input.Hover,
		[ImGui.Col_Header()] = gui_cols.Header.Background,
		[ImGui.Col_HeaderHovered()] = gui_cols.Menu.Hovered,
		[ImGui.Col_HeaderActive()] = gui_cols.Menu.Active,
		[ImGui.Col_Button()] = gui_cols.Button.Basic.Background,
		[ImGui.Col_ButtonHovered()] = gui_cols.Button.Basic.Hovered,
		[ImGui.Col_ButtonActive()] = gui_cols.Button.Basic.Active,
		[ImGui.Col_TitleBg()] = gui_cols.Header.Background,
		[ImGui.Col_TitleBgActive()] = gui_cols.Header.Background,
		[ImGui.Col_TitleBgCollapsed()] = gui_cols.Header.Background,
		[ImGui.Col_CheckMark()] = gui_cols.Input.CheckMark,
		[ImGui.Col_SliderGrab()] = gui_cols.Input.Grab,
	})

	ImGui.PushFont(ctx, GUI_GetFont(gui_fonts.None))
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding(), 2)
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding(), 12, 12)
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize(), 1)

	window_visible, window_opened = ImGui.Begin(ctx, SCRIPT_NAME, true, GUI_GetWindowFlags())

	if window_visible then
		local open_about_popup
		local menu_action

		if ImGui.BeginMenuBar(ctx) then
			if type(GUI_DrawMenu) == 'function' then
				menu_action = GUI_DrawMenu(ImGui, ctx)
			end

			if ImGui.MenuItem(ctx, 'About') then open_about_popup = true end
			ImGui.EndMenuBar(ctx)
		end

		if open_about_popup then ImGui.OpenPopup(ctx, 'About') end
		if type(menu_action) == 'function' then menu_action() end

		DrawAboutPopup()
	    frame(ImGui, ctx, not window_first_frame_showed)
		window_first_frame_showed = true
	    ImGui.End(ctx)
	end

	ImGui.PopStyleVar(ctx, 3)

	ImGui.PopStyleColor(ctx, 22)
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
	w = w or 0
	h = h or 0

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
	if not font then font = gui_fonts.None end

	if color ~= nil then
		GUI_PushColor(ImGui.Col_Text(), color)
	end

	ImGui.PushFont(ctx, GUI_GetFont(font))
	ImGui.TextWrapped(ctx, text)
	ImGui.PopFont(ctx)

	if color ~= nil then
		ImGui.PopStyleColor(ctx)
	end
end

function GUI_DrawLink(text, url)
	url = url or text

	if not reaper.CF_ShellExecute then
		ImGui.Text(ctx, text)
		return
	end

	ImGui.TextColored(ctx, GUI_GetColor(gui_cols.Text.Link), text)
	if ImGui.IsItemClicked(ctx) then
		reaper.CF_ShellExecute(url or text)
	elseif ImGui.IsItemHovered(ctx) then
		ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand())
	end
end

function GUI_DrawHint(text, title)
	if not title then title = "[?]" end

	GUI_PushColor(ImGui.Col_Text(), gui_cols.Button.Basic.Background)
	ImGui.PushFont(ctx, GUI_GetFont(gui_fonts.Bold))
	ImGui.Text(ctx, title)
	ImGui.PopFont(ctx)
	ImGui.PopStyleColor(ctx)

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
		GUI_PushColor(ImGui.Col_Text(), gui_cols.Button.Basic.Text)
	elseif btn_type == gui_buttons_types.Cancel then
		GUI_PushColor({
			[ImGui.Col_Button()] = gui_cols.Button.Cancel.Background,
			[ImGui.Col_ButtonHovered()] = gui_cols.Button.Cancel.Hovered,
			[ImGui.Col_ButtonActive()] = gui_cols.Button.Cancel.Active,
			[ImGui.Col_Text()] = gui_cols.Button.Cancel.Text,
		})
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
		ImGui.PopStyleColor(ctx, 1)
	elseif btn_type == gui_buttons_types.Cancel then
		ImGui.PopStyleColor(ctx, 4)
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
					GUI_DrawText(descr, gui_fonts.Italic)

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

	ImGui.PushFont(ctx, GUI_GetFont(gui_fonts.Bold))
	GUI_PushColor(ImGui.Col_Text(), gui_cols.Input.Text)

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
		GUI_PushColor({
			[ImGui.Col_PopupBg()] = gui_cols.Input.Combo.Background,
			[ImGui.Col_ScrollbarBg()] = gui_cols.Input.Combo.Background,
			[ImGui.Col_HeaderHovered()] = gui_cols.Input.Combo.Hovered,
		})
		local select_values

		if type(i_settings.select_values) == "function" then
			select_values = i_settings.select_values()
		else
			select_values = i_settings.select_values
		end

		_, newVal = ImGui.Combo(ctx, '##' .. i_label, i_value, join(i_settings.select_values, "\0") .. "\0")

		ImGui.PopStyleColor(ctx, 3)
	elseif i_type == gui_input_types.Color then
		if i_value == 0 then i_value = nil end

		_, newVal = ImGui.ColorPicker3(ctx, '##' .. i_label, i_value, GUI_GetColorFlags())
	elseif i_type == gui_input_types.ColorView then
		if i_value == 0 then i_value = tonumber(GUI_GetColor(gui_cols.Input.Background) >> 8) end

		local flags = i_settings.flags and i_settings.flags or GUI_GetColorFlags()

		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg(), GUI_GetColor(gui_cols.White))
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
		GUI_PushColor(ImGui.Col_Text(), gui_cols.Input.Label)

		if i_settings.label_not_bold ~= true then ImGui.PushFont(ctx, GUI_GetFont(gui_fonts.Bold)) end

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
