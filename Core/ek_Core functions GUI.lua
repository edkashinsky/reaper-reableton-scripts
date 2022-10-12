-- @description ek_Core functions GUI
-- @author Ed Kashinsky
-- @noindex

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

local ctx
local window_visible = false
local window_opened = false
local window_width = 0
local window_height = 0
local font_name = 'arial'
local font_size = 15
local default_enter_action = nil
local cached_fonts = nil

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

GUI_OnWindowClose = nil


local function GetWindowFlags()
	return reaper.ImGui_WindowFlags_NoCollapse() |
		reaper.ImGui_WindowFlags_NoResize() |
		reaper.ImGui_WindowFlags_TopMost()
end

function GUI_GetInputFlags()
	return reaper.ImGui_InputTextFlags_AutoSelectAll() |
		reaper.ImGui_InputTextFlags_AllowTabInput() |
		reaper.ImGui_InputTextFlags_AlwaysOverwrite()
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
	for flag, font in pairs(GUI_GetFonts()) do
		reaper.ImGui_AttachFont(ctx, font)
	end

	reaper.ImGui_PushFont(ctx, GUI_GetFont(gui_font_types.None))
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x1a1b1bff)
	reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x545454ff)

	reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height)

	window_visible, window_opened = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, GetWindowFlags())

	if window_visible then
	    frame()
	    reaper.ImGui_End(ctx)
	end

	reaper.ImGui_PopStyleColor(ctx, 2)
	reaper.ImGui_PopFont(ctx)

	if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
		GUI_CloseMainWindow()
	end

	--if default_enter_action and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) then
	--	default_enter_action()
	--end

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

function GUI_DrawButton(label, action, btn_type, prevent_close_wnd)
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

	if reaper.ImGui_Button(ctx, label, width, gui_btn_height) then
		if type(action) == 'function' then
			action()
		end

		if not prevent_close_wnd then
			GUI_CloseMainWindow()
		end
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
