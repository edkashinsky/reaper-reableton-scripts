-- @description ek_Core functions v1
-- @author Ed Kashinsky
-- @noindex

ek_log_levels = {
	Notice = 1,
	Warning = 2,
	Important = 3,
}

local ek_debug_levels = {
	All = 0,
	Notice = 1,
	Warning = 2,
	Important = 3,
	Off = 4,
}

proj = 0
defProjPitchMode = -1
dir_sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"

local ek_debug_level = ek_debug_levels.Off

local key_ext_prefix = "ek_stuff"
local key_ext_global = "ek_global_action_enabled"
local key_td_windows_stack = "td_windows_stack"
local key_td_last_windows = "td_last_windows"

local _, dpi = reaper.ThemeLayout_GetLayout("tcp", -3)
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
	gfx.ext_retina = dpi >= "512" and 1 or 0
else
	gfx.ext_retina = dpi > "512" and 1 or 0
end

function Log(msg, level, param)
	if not level then level = ek_log_levels.Important end
	if level < ek_debug_level then return end

	if param ~= nil then
		if type(param) == 'boolean' then param = param and 'true' or 'false' end
		if type(param) == 'table' then param = serializeTable(param) end

		msg = string.gsub(msg, "{param}", param)
	else
		if type(msg) == 'table' then msg = serializeTable(msg)
		else msg = tostring(msg) end
	end

	if msg then
		reaper.ShowConsoleMsg(msg)
		reaper.ShowConsoleMsg('\n')
	end
end

function EK_ShowTooltip(fmt)
	local x, y = reaper.GetMousePosition()

	if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
		x = x - 30
		y = y + 50
	end

	reaper.TrackCtl_SetToolTip(fmt, x, y, true)
end

function EK_HasExtState(key)
	return reaper.HasExtState(key_ext_prefix, key)
end

function EK_GetExtState(key, default)
    local value = reaper.GetExtState(key_ext_prefix, key)

    if value == '' then return default end
	if value == 'true' then value = true end
	if value == 'false' then value = false end

    return value
end

function EK_SetExtState(key, value)
	if not key then return end

	if type(value) == 'boolean' then value = value and 'true' or 'false' end
	if not value then value = "" end

	reaper.SetExtState(key_ext_prefix, key, value, true)
end

function EK_DeleteExtState(key)
	reaper.DeleteExtState(key_ext_prefix, key, true)
end

function EK_IsGlobalActionEnabled()
	return reaper.HasExtState(key_ext_global, key_ext_global)
end

function EK_SetIsGlobalActionEnabled()
	reaper.SetExtState(key_ext_global, key_ext_global, 1, false)
end

function EK_GetPitchModesForSelectedItems()
	local selectedPitchModes = {}

	Log("Count selected items: " .. reaper.CountSelectedMediaItems(proj), ek_log_levels.Warning)

	for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
		local item = reaper.GetSelectedMediaItem(proj, i)
		local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

		local itemTake = reaper.GetMediaItemTake(item, takeInd)

		local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "I_PITCHMODE")

		if mode == defProjPitchMode then
			mode = reaper.SNM_GetIntConfigVar("defpitchcfg", defProjPitchMode)
		end

		selectedPitchModes[mode] = true

		Log("Current pitch mode is: " .. mode, ek_log_levels.Warning)
	end

	return selectedPitchModes
end

function EK_GetPitchModes()
	local pitchModes = {}

	local mdx = 0
	local hasMode = true
	local addPitchMode = function (id, title, is_submode)
		local value = {}

		value.id = id
		value.title = title
		value.is_submode = is_submode

		table.insert(pitchModes, value)

		--[[
			if is_submode then
				reaper.ShowConsoleMsg(value.id .. " ")
			else
				Log("\nPITCH MODE: " .. value.id .. " " .. value.title)
			end
		]]--
	end

	while hasMode do
		 local retval, str = reaper.EnumPitchShiftModes(mdx)

		 if retval then
			 -- str may have NULL if a mode is currently unsupported
			 if str ~= nil then
				 addPitchMode(mdx, str, false)

				 local sub_mdx = 0
				 local hasSubMode = true

				 while hasSubMode do
				 	local submode  = reaper.EnumPitchShiftSubModes(mdx, sub_mdx)

					if submode ~= nil then
						addPitchMode(mdx * 2 ^ 16 | sub_mdx, submode, true)
					else
						hasSubMode = false
					end

					sub_mdx = sub_mdx + 1
				 end
			 end

			 mdx = mdx + 1
		 else
			hasMode = false
		 end
	end

	return pitchModes
end

function EK_SetPitchModeForSelectionItems(newPitchMode)
	if reaper.CountSelectedMediaItems(proj) > 0 then
		for i = 0, reaper.CountSelectedMediaItems(proj) - 1 do
			local item = reaper.GetSelectedMediaItem(proj, i)
			local takeInd = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")

			local itemTake = reaper.GetMediaItemTake(item, takeInd)

			local mode = reaper.GetMediaItemTakeInfo_Value(itemTake, "I_PITCHMODE")

			if mode == defProjPitchMode then
				mode = reaper.SNM_GetIntConfigVar("defpitchcfg", defProjPitchMode)
			end

			reaper.SetMediaItemTakeInfo_Value(itemTake, "I_PITCHMODE", newPitchMode)

			Log("Item had: " .. mode .. " and new mode is: " .. newPitchMode)
		end
	end
end

function EK_GetPitchModeBySubMode(id)
	local mdx = math.floor(id / 2 ^ 16)

	local retval, str = reaper.EnumPitchShiftModes(mdx)

	if retval then
		return str
	else
		return nil
	end
end

local function TD_GetWindowByTitle(title)
	--local main = reaper.GetMainHwnd()
	--local _, list = reaper.JS_Window_ListAllChild(main)
	--
	--for address in list:gmatch('[^,]+') do
	--	local hwnd = reaper.JS_Window_HandleFromAddress(address)
	--	reaper.ShowConsoleMsg(reaper.JS_Window_GetTitle(hwnd) .. '\n')
	--end

	if title == "Edit MIDI" then
		return reaper.MIDIEditor_GetActive()
	else
		return reaper.JS_Window_Find(reaper.JS_Localize(title, 'common'), true)
	end
end

local function TD_IsWindowVisible(title)
	local wnd = TD_GetWindowByTitle(title)

	-- reaper.ShowConsoleMsg("WINDOW: " .. reaper.JS_Window_GetTitle(wnd) .. " (" .. title .. ")\n")

	if title == "Edit MIDI" then
		return reaper.MIDIEditor_GetMode(wnd) ~= -1
	else
		return reaper.JS_Window_IsVisible(wnd)
	end
end

local function TD_StoreWindow(data, title)
	-- debug clear
	--EK_SetExtState(key_td_windows_stack, serializeTable({}))
	--EK_SetExtState(key_td_last_windows, serializeTable({}))

	local wnd = TD_GetWindowByTitle(title)
	local dockerId, _ = reaper.DockIsChildOfDock(wnd)

	-- if wnd == reaper.GetMainHwnd() or string.len(title) == 0 then return end

	local windows = EK_GetExtState(key_td_windows_stack)
	windows = windows ~= nil and unserializeTable(windows) or {}

	if dockerId == -1 then return end

	windows[title] = {
		dockerId,
		data.sectionId,
		data.commandId,
		data.actionId
	}

	windows = serializeTable(windows)

	local last_windows = EK_GetExtState(key_td_last_windows)
	last_windows = last_windows ~= nil and unserializeTable(last_windows) or {}

	last_windows[dockerId] = title
	last_windows = serializeTable(last_windows)

	Log("=== Toggle Docker ===", ek_log_levels.Warning)
	Log("Store window: " .. title, ek_log_levels.Warning)
	Log(data, ek_log_levels.Warning)
	Log("====", ek_log_levels.Warning)
	Log(windows, ek_log_levels.Warning)
	Log("====", ek_log_levels.Warning)

	EK_SetExtState(key_td_windows_stack, windows)
	EK_SetExtState(key_td_last_windows, last_windows)
end

local function TD_HideAllInDockerExcept(title)
	local windows = EK_GetExtState(key_td_windows_stack)
	windows = windows ~= nil and unserializeTable(windows) or {}

	local dockerId = windows[title] and windows[title][1] or -1

	Log("\nClicked: " .. title .. " (" .. dockerId .. ')')

	for wTitle, data in pairs(windows) do
		local wDockedId = data[1]
		local wSectionId = data[2]
		local wCommandId = data[3]
		local wActionId = data[4]

		if dockerId == wDockedId and wTitle ~= title then
			local isVisible = TD_IsWindowVisible(wTitle)
			local state = reaper.GetToggleCommandState(wActionId)

			Log("\t" .. wTitle .. " (" .. wDockedId .. ") -> " .. (isVisible and 1 or 0) .. " " .. state)

			if isVisible then
				reaper.Main_OnCommand(wActionId, 0)
				reaper.SetToggleCommandState(wSectionId, wCommandId, 0)
				reaper.RefreshToolbar2(wSectionId, wCommandId)
			end
		end
	end
end

function TD_ToggleWindow(title, actionId)
	local _, _, sectionID, cmdID = reaper.get_action_context()
	local isVisible = TD_IsWindowVisible(title)

	TD_HideAllInDockerExcept(title)

	reaper.Main_OnCommand(actionId, 0)
	reaper.SetToggleCommandState(sectionID, cmdID, isVisible and 0 or 1)
	reaper.RefreshToolbar2(sectionID, cmdID)

	if not isVisible then
		TD_StoreWindow({
			sectionId = sectionID,
			commandId = cmdID,
			actionId = actionId
		}, title)
	end
end

function TD_ToggleLastWindow(dockerId)
	local windows = EK_GetExtState(key_td_windows_stack)
	windows = windows ~= nil and unserializeTable(windows) or {}

	local dockers = EK_GetExtState(key_td_last_windows)
	dockers = dockers ~= nil and unserializeTable(dockers) or {}

	local title = dockers[dockerId]
	if not title then return end

	Log("Toggling " .. title)

	TD_HideAllInDockerExcept(title)

	local isVisible = TD_IsWindowVisible(title)
	local data = windows[title]
	if not data then return end

	local sectionId = data[2]
	local commandId = data[3]
	local actionId = data[4]

	reaper.Main_OnCommand(actionId, 0)
	reaper.SetToggleCommandState(sectionId, commandId, isVisible and 0 or 1)
	reaper.RefreshToolbar2(sectionId, commandId)
end

function TD_SyncOpenedWindows()
	local windows = EK_GetExtState(key_td_windows_stack)
	windows = windows ~= nil and unserializeTable(windows) or {}

	for wTitle, data in pairs(windows) do
		local wSectionId = data[2]
		local wCommandId = data[3]
		local isVisible = TD_IsWindowVisible(wTitle)
		local isActive = reaper.GetToggleCommandStateEx(wSectionId, wCommandId) == 1

		-- reaper.ShowConsoleMsg(wTitle .. " " .. (isVisible and 1 or 0) .. " " .. (isActive and 1 or 0) .. "\n")

		if isVisible ~= isActive then
			reaper.SetToggleCommandState(wSectionId, wCommandId, isVisible and 1 or 0)
			reaper.RefreshToolbar2(wSectionId, wCommandId)
		end
	end
end

function split(str, pat)
	if not str then return {} end

	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   	local fpat = "(.-)" .. pat
   	local last_end = 1
   	local s, e, cap = str:find(fpat, 1)

	while s do
      	if s ~= 1 or cap ~= "" then
         	table.insert(t, cap)
      	end
      	last_end = e+1
      	s, e, cap = str:find(fpat, last_end)
   	end

	if last_end <= #str then
      	cap = str:sub(last_end)
      	table.insert(t, cap)
   	end

   	return t
end

function join(list, delimiter)
	if type(list) ~= 'table' or #list == 0 then return "" end

	local string = list[1]

	for i = 2, #list do
		string = string .. delimiter .. list[i]
	end

	return string
end

function round(number, decimals)
    local power = 10 ^ decimals
    return math.ceil(number * power) / power
end

function ShowPitchTooltip(semi)
	semi = round(semi, 1)

	local message = (semi > 0 and "+" .. semi or semi) .. " " .. (math.abs(semi) == 1 and "semitone" or "semitones")
	EK_ShowTooltip(message)
end

function log10(x)
  	return math.log(x, 10)
end

function sample_to_db(sample)
  --returns -150 for any 0.0 sample point (since you can't take the log of 0)
  if sample == 0 then
    return -150.0
  else
    local db = 20 * log10(math.abs(sample))

    if db > 0 then return 0 else return db end
  end
end

function modifyTime(dt, mdParams)
	if not mdParams then mdParams = {} end

	return os.time({
		year = mdParams.year ~= nil and mdParams.year or dt.year,
		month = mdParams.month ~= nil and mdParams.month or dt.month,
		day = mdParams.day ~= nil and mdParams.day or dt.day,
		hour = mdParams.hour ~= nil and mdParams.hour or dt.hour,
		min = mdParams.min ~= nil and mdParams.min or dt.min,
		sec = 0
	})
end

function clearPitchForTake(take)
	if not take then return end

	local semiFactor = 2 ^ (1/12) -- Rate: 2.0 = Pitch * 12

	if reaper.TakeIsMIDI(take) then
		-- do nothing
	else
		local mode = reaper.GetMediaItemTakeInfo_Value(take, "B_PPITCH")

		if mode == 1 then
			-- clear pitch
			reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", 0)
			reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)
		else
			-- clear rate
			local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

			reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", 0)
			reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)

			local item = reaper.GetMediaItemTakeInfo_Value(take, "P_ITEM")
			local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
			local semitones = math.log(rate, semiFactor)

			if semitones >= 0 then
				length = length * (semiFactor ^ semitones)
			else
				length = length / (semiFactor ^ math.abs(semitones))
			end

			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
		end
	end

	reaper.UpdateArrange()
end

function changePitchForTake(take, value, preservePitch, isDelta)
	if not take then return end

	local semiFactor = 2 ^ (1 / 12) -- Rate: 2.0 = Pitch * 12
	local curSemiFactor = 2 ^ ((1 / 12) * math.abs(value))

	if reaper.TakeIsMIDI(take) then
		local retval, notes = reaper.MIDI_CountEvts(take)

		-- increase pitch for every note
		if retval then
			for j = 0, notes - 1 do
				local _, sel, muted, startppqpos, endppqpos, chan, pitch = reaper.MIDI_GetNote(take, j)

				if isDelta then
					pitch = value > 0 and pitch + 1 or pitch - 1
				else
					pitch = value
				end

				reaper.MIDI_SetNote(take, j, sel, muted, startppqpos, endppqpos, chan, pitch)
				ShowPitchTooltip(pitch)
			end
		end
	else
		if preservePitch then
			-- increase pitch
			local pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")

			if isDelta then
				pitch = pitch + value
			else
				pitch = value
			end

			reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch)

			ShowPitchTooltip(pitch)
		else
			if not isDelta then
				clearPitchForTake(take)
			end

			-- increase rate
			local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

			rate = value > 0 and rate * curSemiFactor or rate / curSemiFactor

			reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", rate)

			local item = reaper.GetMediaItemTakeInfo_Value(take, "P_ITEM")
			local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

			length = value > 0 and length / curSemiFactor or length * curSemiFactor

			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

			local semitones = round(math.log(rate, semiFactor), 1)
			ShowPitchTooltip(semitones)
		end
	end

	reaper.UpdateArrange()
end

function EK_AskUser(title, fields)
	local labels = ""
	local values = ""

	for i = 1, #fields do
		if fields[i][1] then labels = labels .. fields[i][1] end
		if fields[i][2] then values = values .. fields[i][2] end

		if i < #fields then
			if fields[i][1] then labels = labels .. "," end
			if fields[i][2] then values = values .. "," end
		end
	end

	local is_done, result = reaper.GetUserInputs(title, #fields, labels, values)

	if is_done then
		return split(result, ",")
	else
		return
	end
end

local function getColor(color)
	return (color[3] & 0xFF) | ((color[2] & 0xFF) << 8) | ((color[1] & 0xFF) << 16) | (0xFF << 24)
end

ek_colors = {
	Red = getColor({ 255, 0, 0 }),
	Green = getColor({ 0, 255, 0 }),
	Blue = getColor({ 0, 0, 255 }),
	White = getColor({ 255, 255, 255 }),
}

local Pickle = {
	clone = function(t)
		local nt = {}

	  	for i, v in pairs(t) do
			nt[i] = v
	  	end

	  	return nt
  	end
}

function Pickle:pickle_(root)
	if type(root) ~= "table" then error("can only pickle tables, not ".. type(root).."s") end

	self._tableToRef = {}
	self._refToTable = {}
	local savecount = 0
	self:ref_(root)
	local s = ""

	while #self._refToTable > savecount do
		savecount = savecount + 1
		local t = self._refToTable[savecount]
		s = s.."{"

		for i, v in pairs(t) do
			s = string.format("%s[%s]=%s,", s, self:value_(i), self:value_(v))
		end
		s = s.."},"
	end

	return string.format("{%s}", s)
end

function Pickle:value_(v)
	local vtype = type(v)

	if vtype == "string" then return string.format("%q", v)
	elseif vtype == "number" then return v
	elseif vtype == "boolean" then return tostring(v)
	elseif vtype == "table" then return "{"..self:ref_(v).."}"
	else error("pickle a "..type(v).." is not supported") end
end

function Pickle:ref_(t)
	local ref = self._tableToRef[t]

	if not ref then
		if t == self then error("can't pickle the pickle class") end

		table.insert(self._refToTable, t)
		ref = #self._refToTable
		self._tableToRef[t] = ref
	end

	return ref
end

function serializeTable(t)
	return Pickle:clone():pickle_(t)
end

function unserializeTable(s)
	if s == nil or s == '' then return end
	if type(s) ~= "string" then error("can't unpickle a "..type(s)..", only strings") end

	local gentables = load("return " .. s)
	if gentables then
		local tables = gentables()

		if tables then
			for tnum = 1, #tables do
				local t = tables[tnum]
				local tcopy = {}

				for i, v in
					pairs(t) do tcopy[i] = v
				end

				for i, v in pairs(tcopy) do
					local ni, nv
					if type(i) == "table" then ni = tables[i[1]] else ni = i end
					if type(v) == "table" then nv = tables[v[1]] else nv = v end
					t[i] = nil
					t[ni] = nv
				end
			end

			return tables[1]
		end
	else
		--error
	end
end