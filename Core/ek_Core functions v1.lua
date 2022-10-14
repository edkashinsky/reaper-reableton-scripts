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
local ext_key_prefix = "ek_stuff"
local delRow = ":"
local delCol = ","
local ext_key_global = "global_action_enabled"
local last_grouped_docker_window_key = "last_grouped_docker_window"
local opened_grouped_docker_window_key = "opened_grouped_docker_window"

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
		if type(msg) == 'boolean' then msg = msg and 'true' or 'false' end
		if type(msg) == 'table' then msg = serializeTable(msg) end
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
	return reaper.HasExtState(ext_key_prefix, key)
end

function EK_GetExtState(key, default)
    local value = reaper.GetExtState(ext_key_prefix, key)

    if value == '' then return default end
	if value == 'true' then value = true end
	if value == 'false' then value = false end

    return value
end

function EK_SetExtState(key, value)
	if not key then return end

	if type(value) == 'boolean' then value = value and 'true' or 'false' end
	if not value then value = "" end

	reaper.SetExtState(ext_key_prefix, key, value, true)
end

function EK_DeleteExtState(key)
	reaper.DeleteExtState(ext_key_prefix, key, true)
end

function EK_IsGlobalActionEnabled()
	return EK_HasExtState(ext_key_global)
end

function EK_SetIsGlobalActionEnabled()
	reaper.SetExtState(ext_key_prefix, ext_key_global, 1, false)
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

function EK_StoreLastGroupedDockerWindow(sectionId, commandId, actionId)
	local id = sectionId .. delRow .. commandId .. delRow .. actionId
	local isFind = false
	local open_windows = EK_GetExtState(opened_grouped_docker_window_key)
	if open_windows == nil then open_windows = "" end
	local open_windows_arr = split(open_windows, delCol)

	for i = 0, #open_windows_arr do
		if open_windows_arr[i] == id then
			isFind = true
			break
		end
	end

	if isFind == false then
		table.insert(open_windows_arr, id);
	end

	local result = table.concat(open_windows_arr, delCol)

	Log("=== Store grouped docker window ===", ek_log_levels.Warning)
	Log("last grouped docker wnd: " .. id, ek_log_levels.Warning)
	Log("opened grouped docker wnd: " .. result, ek_log_levels.Warning)

	EK_SetExtState(opened_grouped_docker_window_key, result)
	EK_SetExtState(last_grouped_docker_window_key, id)
end

function EK_ToggleLastGroupedDockerWindow()
	-- close others tabs --
	local last_window = EK_GetExtState(last_grouped_docker_window_key)
	local open_windows = EK_GetExtState(opened_grouped_docker_window_key)
	local open_windows_arr = split(open_windows, delCol)
	
	for i = 1, #open_windows_arr do
		if open_windows_arr[i] ~= last_window then
			local id = split(open_windows_arr[i], delRow)
				
			local state = reaper.GetToggleCommandStateEx(id[1], id[2])
			if state == 1 then
				reaper.Main_OnCommand(id[3], 0)
				reaper.SetToggleCommandState(id[1], id[2], 0)	
			end
		end
	end
		
	-- toggle current --
	local current_tab_arr = split(last_window, delRow)
	local sectionId = current_tab_arr[1]
	local commandId = current_tab_arr[2]
	local actionId = current_tab_arr[3]
	
	local state = reaper.GetToggleCommandState(commandId)
	local newState
	
	if state == 1 then
		newState = 0
	else
		newState = 1
	end
	
	Log("=== Toggle last docker window ===", ek_log_levels.Warning)
	Log("last grouped docker wnd: " .. last_window, ek_log_levels.Warning)
	Log("opened grouped docker wnd: " .. open_windows, ek_log_levels.Warning)
	Log(sectionId .. " " .. commandId .. " " .. newState, ek_log_levels.Warning)
	
	reaper.Main_OnCommand(actionId, 0)
	reaper.SetToggleCommandState(sectionId, commandId, newState)
	reaper.RefreshToolbar2(sectionId, commandId)
end

function EK_SyncLastGroupedDockerWindows()
	-- close others tabs --
	local open_windows = EK_GetExtState(opened_grouped_docker_window_key)
	local open_windows_arr = split(open_windows, delCol)
	local isAnyWindowOpened = false

	for i = 1, #open_windows_arr do
		local id = split(open_windows_arr[i], delRow)

		local state = reaper.GetToggleCommandStateEx(id[1], id[3])
		if state == 1 then
			reaper.SetToggleCommandState(id[1], id[2], 1)
			reaper.RefreshToolbar2(id[1], id[2])
			isAnyWindowOpened = true
		end
	end


	--if not isAnyWindowOpened then
	--	EK_SetExtState(last_grouped_docker_window_key, "")
	--	EK_SetExtState(opened_grouped_docker_window_key, "")
	--end
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

function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
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

