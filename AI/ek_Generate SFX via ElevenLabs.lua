-- @description ek_Generate SFX via ElevenLabs
-- @version 1.1.7
-- @author Ed Kashinsky
-- @readme_skip
-- @about
--   Script uses ElevenLabs API to generate sound effects and inserts them into the project.
-- @changelog
--   UI updates

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
	if loaded == nil then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
	end
	return
end

GUI_ShowMainWindow()

local input_callback
local settings_key = 'ai_elevenlabs_settings'
local settings = EK_GetExtState(settings_key, {
	amount = 1,
	auto_duration = true,
	duration = 10,
	influence = 0.4,
	api_key = "",
	enable_console = false,
	console_collapsed = false,
	save_history = true,
	history = {},
})
local data = {
	prompt = "",
	history_pos = 0, -- 0: new line, 1..#history: browsing history
	is_waiting = false,
	req_left = 0,
	logs = {},
	is_console_collapsed = settings.console_collapsed
}

local function ConsoleLog(message, is_important)
	if is_important and not settings.enable_console then
		reaper.MB(tostring(message), "Error from ElevenLabs API", 0)
	end

	table.insert(data.logs, "[" .. os.date("%H:%M:%S") .. "] " .. tostring(message))
end

local function GetFilename(prompt)
	prompt = prompt:gsub("[^%a%d]", "_"):sub(0, 32)
	if not settings.auto_duration then prompt = prompt .. "_" .. settings.duration end

	return "EL_" .. prompt .. "_" .. EK_GenerateRandomHexSeq(4) .. ".mp3"
end

local function GenerateSfx()
	local project_path = reaper.GetProjectPath()
	local filename = GetFilename(data.prompt)
	local post_data = {
		["text"] = data.prompt,
		["prompt_influence"] = settings.influence,
	}

	if not settings.auto_duration then
		post_data["duration_seconds"] = settings.duration
	end

	local code = tonumber(EK_CurlRequest(CURL_POST, "https://api.elevenlabs.io/v1/sound-generation", {
		["Content-Type"] = "application/json",
		["xi-api-key"] = settings.api_key
	}, post_data, {
		'-s -w "%{http_code}"',
		'-o "' .. project_path .. dir_sep .. filename .. '"'
	}))

	data.req_left = data.req_left - 1

	if code == 200 and reaper.file_exists(project_path .. dir_sep .. filename) then
		reaper.InsertMedia(project_path .. dir_sep .. filename, 0)
		ConsoleLog("File \"" .. project_path .. dir_sep .. filename .. "\" has been imported")

		if data.req_left > 0 then
			ConsoleLog("Next variation is requested... Left " .. data.req_left)
			reaper.defer(GenerateSfx)
		else
			reaper.defer(function() data.is_waiting = false end)
		end
	elseif code ~= 200 and reaper.file_exists(project_path .. dir_sep .. filename) then
		local file = io.open(project_path .. dir_sep .. filename, "rb")
		ConsoleLog("Response: " .. tostring(file:read "*a"), true)
		file:close()

		os.remove(project_path .. dir_sep .. filename)
		data.req_left = 0
		reaper.defer(function() data.is_waiting = false end)
	else
		local err = "Response code: " .. tostring(code)
		if code == 200 or code == 0 then
			err = err .. "\nPlease make sure that there are no non-Latin characters in the project path (" .. project_path .. ")"
		end

		ConsoleLog(err, true)
		data.req_left = 0
		reaper.defer(function() data.is_waiting = false end)
	end
end

local function SaveHistory()
	data.history_pos = 0
	for i = #settings.history, 1, -1 do
		if stricmp(settings.history[i], data.prompt) then
			table.remove(settings.history, i)
			break
		end
	end

	settings.history[#settings.history + 1] = data.prompt
end

function GUI_DrawMenu(ImGui, ctx)
	if ImGui.MenuItem(ctx, 'Settings') then
		return function()
			ImGui.OpenPopup(ctx, 'Settings')
		end
	end
end

function frame(ImGui, ctx, is_first_frame)
	local newVal
	local is_changed = false

	if string.len(settings.api_key) == 0 then
		ImGui.OpenPopup(ctx, 'Settings')
	end

	GUI_DrawModalPopup('Settings', function()
		GUI_DrawText("Script uses ElevenLabs API to generate sound effects and inserts them into the project.", gui_fonts.Bold)
		GUI_DrawLink("https://elevenlabs.io/")
		GUI_DrawGap(10)
		GUI_DrawText("Please enter your API-key to start working with the script. Authorize on website and go to Profile + API section")

		newVal = GUI_DrawInput(gui_input_types.Text, "API-key", settings.api_key)
		if newVal ~= settings.api_key then
			settings.api_key = newVal
			is_changed = true
		end

		newVal = GUI_DrawInput(gui_input_types.Checkbox, "Save prompts history (use arrow keys)", settings.save_history)
		if newVal ~= settings.save_history then
			settings.save_history = newVal
			is_changed = true
		end

		ImGui.SameLine(ctx)

		GUI_DrawHint("Use Up and Down keys when you are in focus of prompt field to go through the history of requests.")

		newVal = GUI_DrawInput(gui_input_types.Checkbox, "Enable console log", settings.enable_console)
		if newVal ~= settings.enable_console then
			settings.enable_console = newVal
			is_changed = true
		end

		GUI_DrawButton('Test request', function()
			ConsoleLog(EK_CurlRequest(CURL_POST, "https://api.elevenlabs.io/v1/sound-generation", {
				["Content-Type"] = "application/json",
				["xi-api-key"] = "123"
			}, nil, {
				"-I"
			}))
			ImGui.CloseCurrentPopup(ctx)
			settings.enable_console = true
		end, gui_buttons_types.Action, true)

		GUI_DrawGap(10)
		GUI_DrawText("Thanks to Tyoma Makeev in development of Python part and Konstantin Knerik for the script idea and support.", gui_fonts.Italic)
		GUI_DrawGap(10)

		ImGui.BeginDisabled(ctx, string.len(settings.api_key) == 0)

		GUI_SetCursorCenter('   Close   ')
		GUI_DrawButton('Close', function()
			ImGui.CloseCurrentPopup(ctx)
		end, gui_buttons_types.Cancel, true)

		ImGui.EndDisabled(ctx)
	end)

	ImGui.BeginDisabled(ctx, data.is_waiting or string.len(settings.api_key) == 0)

	if not ImGui.ValidatePtr(input_callback, 'ImGui_Function*') then
        input_callback = ImGui.CreateFunctionFromEEL([[
			prev_history_pos = HistoryPos;
			history_line = #;
			EventKey == Key_UpArrow ? (
				HistoryPos == 0 ? HistoryPos = HistorySize : HistoryPos > 1 ? HistoryPos -= 1;
				strcpy(history_line, #HistoryPrev);
			);
			EventKey == Key_DownArrow ? (
				HistoryPos != 0 ? (
					HistoryPos += 1;
					HistoryPos > HistorySize ? HistoryPos = 0;
				);
				strcpy(history_line, #HistoryNext);
			);

			// A better implementation would preserve the data on the current input line along with cursor position.
			prev_history_pos != HistoryPos ? (
				InputTextCallback_DeleteChars(0, strlen(#Buf));
				InputTextCallback_InsertChars(0, history_line);
			);
		]])

		ImGui.Function_SetValue(input_callback, 'Key_UpArrow', ImGui.Key_UpArrow())
		ImGui.Function_SetValue(input_callback, 'Key_DownArrow', ImGui.Key_DownArrow())
	end

	if settings.save_history then
		ImGui.Function_SetValue(input_callback, 'HistoryPos',  data.history_pos)
		ImGui.Function_SetValue(input_callback, 'HistorySize', #settings.history)
		ImGui.Function_SetValue_String(input_callback, '#HistoryPrev',
		settings.history[data.history_pos == 0 and #settings.history or data.history_pos - 1])
		ImGui.Function_SetValue_String(input_callback, '#HistoryNext', settings.history[data.history_pos + 1])
	end

	GUI_SetFocusOnWidget()
	ImGui.SetNextItemWidth(ctx, -FLT_MIN)

	_, newVal = ImGui.InputTextWithHint(ctx, "###Prompt", "Describe your sound effect and then click generate...", data.prompt, ImGui.InputTextFlags_CallbackHistory(), input_callback)
	if newVal ~= data.prompt then
		data.prompt = newVal
	end

	data.history_pos = ImGui.Function_GetValue(input_callback, 'HistoryPos')

	newVal = GUI_DrawInput(gui_input_types.NumberSlider, "Amount of variations", settings.amount, { number_min = 1, number_max = 10})
	if newVal ~= settings.amount then
		settings.amount = newVal
		is_changed = true
	end

	ImGui.SameLine(ctx)
	GUI_DrawHint("Amount of files, each file will be created as new request.")

	newVal = GUI_DrawInput(gui_input_types.NumberSlider, "Prompt influence", settings.influence, { number_min = 0, number_max = 1, number_precision = "%.1f"})
	if newVal ~= settings.influence then
		settings.influence = newVal
		is_changed = true
	end

	ImGui.SameLine(ctx)
	GUI_DrawHint("Slide the scale to make your generation perfectly adhere to your prompt or allow for a little creativity")

	if not settings.auto_duration then
		newVal = GUI_DrawInput(gui_input_types.Number, "Duration (sec.)", settings.duration, { number_min = 0})
		if newVal ~= settings.duration then
			settings.duration = newVal
			is_changed = true
		end

		ImGui.SameLine(ctx)
		GUI_DrawHint("Determine how long your generations should be")
	end

	newVal = GUI_DrawInput(gui_input_types.Checkbox, "Automatic duration", settings.auto_duration, { label_not_bold = true })
	if newVal ~= settings.auto_duration then
		settings.auto_duration = newVal
		is_changed = true
	end

	GUI_DrawGap(5)

	GUI_DrawButton("Generate and import", function()
		if string.len(data.prompt) == 0 then
			ConsoleLog("[ERR] Please type some text for prompt.")
			return
		end

		if data.is_waiting then return end

		if settings.save_history then
			SaveHistory()
			is_changed = true
		end

		ConsoleLog("Prompt \"" .. data.prompt .. "\" (" .. settings.amount .. ") is requested. Waiting for response...")
		data.req_left = settings.amount
		data.is_waiting = true
		reaper.defer(GenerateSfx)
	end, gui_buttons_types.Action, true, ImGui.Key_Enter())

	ImGui.EndDisabled(ctx)

	if settings.enable_console then
		GUI_DrawGap(20)

		if is_first_frame and not settings.console_collapsed then
			ImGui.SetNextItemOpen(ctx, true)
		end

		local y = ImGui.GetCursorPosY(ctx)
		local _, h = ImGui.Viewport_GetSize(ImGui.GetWindowViewport(ctx))
		local is_collapsed = true

		GUI_PushColor(ImGui.Col_Text(), gui_cols.Header.Text)

		if ImGui.CollapsingHeader(ctx, "Console log") then
			ImGui.PopStyleColor(ctx)
			GUI_PushColor(ImGui.Col_ChildBg(), gui_cols.Input.Background)

			if ImGui.BeginChild(ctx, "Console log", 0, h - y > 140 and 0 or 140) then
				local logMsgs = ""
				for _, val in pairs(data.logs) do
					logMsgs = logMsgs .. val .. "\n";
				end

				ImGui.InputTextMultiline(ctx, "###Logs", logMsgs, -FLT_MIN, -FLT_MIN, ImGui.InputTextFlags_ReadOnly())
				ImGui.EndChild(ctx)
			end
			ImGui.PopStyleColor(ctx)

			is_collapsed = false
		else
			ImGui.PopStyleColor(ctx)
		end

		if settings.console_collapsed ~= is_collapsed then
			is_changed = true
			settings.console_collapsed = is_collapsed
		end
	end

	if is_changed then
		is_changed = false
		EK_SetExtState(settings_key, settings)
	end
end