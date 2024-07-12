-- @noindex

local r = reaper
local presets_key = "triming_silence_presets_list"

local presets = {
    current = nil,
    id = nil,
    is_modified = false,
    list = EK_GetExtState(presets_key, {})
}

local function ClearPresetSelectItem()
    EK_SetExtState(p.presets.key, 0)
end

local function DeletePreset(name)
    presets.id = nil
    presets.current = nil
    presets.is_modified = false
    presets.list[name] = nil

    EK_SetExtState(presets_key, presets.list)
end

local function SavePreset(name)
    local data = {}

    for _, block in pairs(p) do
        if block.value ~= nil then
            data[block.key] = block.value
        else
            for _, info in pairs(block) do
                data[info.key] = info.value
            end
        end
    end

    presets.current = name
    presets.is_modified = false
    presets.list[name] = data

    EK_SetExtState(presets_key, presets.list)
end

local function SetPreset(name, is_persist)
    presets.current = name
    presets.is_modified = false

    local data = presets.list[name]

    if not data then return end

    for key, value in pairs(data) do
        for k, block in pairs(p) do
            if block.key ~= nil then
                if block.key == key then p[k].value = value end
            else
                for kp, info in pairs(block) do
                    if info.key == key then p[k][kp].value = value end
                end
            end
        end

        if is_persist then
            EK_SetExtState(key, value)
        end
    end
end

local function GetPresetSelectValues()
    local label
    local presets_list = {}

    table.insert(presets_list, "No preset")
    table.insert(presets_list, "Save preset...")

    local presets_names = {}

    for name, _ in pairs(presets.list) do
        label = name

        if presets.current == name and presets.is_modified == true then name = name .. " [modified]" end
        table.insert(presets_names, label)
    end

    table.sort(presets_names)

    for _, name in pairs(presets_names) do
        table.insert(presets_list, name)
    end

    if presets.current then
        for key, value in pairs(presets_list) do
            if value == presets.current then presets.id = key end
        end
    end

    if presets.id then
        presets_list[1] = "Delete preset..."
        EK_SetExtState(p.presets.key, presets.id - 1)
    end

    GUI_ClearValuesCache()

    return presets_list
end

local function MakePresetModified()
    if presets.id ~= nil then
        presets.is_modified = true
        local val = gui_config[1].select_values[presets.id]
        local label = "modified"

        if not string.find(val, label) then
            gui_config[1].select_values[presets.id] = val .. " [" .. label .. "]"
        end
    end
end

function ApplyQuickPreset(num)
    num = num + 2

    local p = GetPresetSelectValues()

    if p[num] == nil then
        reaper.MB('Preset ' .. (num - 2)  .. ' does not found. Please execute "ek_Edge silence cropper" script to create preset for applying', 'Edge silence cropper', 0)
        return
    else
        SetPreset(p[num])
    end

    local countSelectedItems = reaper.CountSelectedMediaItems(proj)

    if countSelectedItems > 0 then
        local Cropper = EdgeCropper.new()

        for i = 0, countSelectedItems - 1 do
            local item = reaper.GetSelectedMediaItem(proj, i)
            Cropper.SetItem(item).Crop()
        end

        reaper.UpdateArrange()
    end
end

p = {
	leading = {
		threshold = {
			key = 'triming_silence_leading_threshold',
			default = -22.0, -- db
            value = nil,
		},
        threshold_relative = {
			key = 'triming_silence_leading_threshold_relative',
			default = 45, -- %
            value = nil,
		},
        rms_threshold = {
            key = 'triming_silence_leading_rms_threshold',
			default = -22.0, -- db
            value = nil,
        },
        rms_threshold_relative = {
            key = 'triming_silence_leading_rms_threshold_relative',
			default = 45, -- %
            value = nil,
        },
		pad = {
			key = 'triming_silence_leading_pad',
			default = 0.05, -- s
            value = nil,
		},
		fade = {
			key = 'triming_silence_leading_fade',
			default = 0.05, -- s
            value = nil,
		},
        rms_bin_size = {
            key = 'triming_silence_leading_rms_bin_size',
            default = 0.3, -- s
            value = nil,
        },
	},
	trailing = {
		threshold = {
			key = 'triming_silence_trailing_threshold',
			default = -55.0, -- db
            value = nil,
		},
         threshold_relative = {
			key = 'triming_silence_trailing_threshold_relative',
			default = 10, -- %
            value = nil,
		},
        rms_threshold = {
            key = 'triming_silence_trailing_rms_threshold',
			default = -22.0, -- db
            value = nil,
        },
        rms_threshold_relative = {
            key = 'triming_silence_trailing_rms_threshold_relative',
			default = 45, -- %
            value = nil,
        },
		pad = {
			key = 'triming_silence_trailing_pad',
			default = 0.20, -- s
            value = nil,
		},
		fade = {
			key = 'triming_silence_trailing_fade',
			default = 0.22, -- s
            value = nil,
		},
	},
    crop_mode = {
        key = 'triming_silence_crop_mode',
        select_values = {
            "Absolute peak (in db)",
            "Relative peak from max (in %)",
            "Absolute RMS (in db)",
            "Relative RMS from max (in %)"
        },
        default = 1,
        value = nil,
    },
    preview_result = {
        key = 'triming_silence_preview_result',
        default = true,
        value = nil,
    },
    presets = {
        key = 'triming_silence_presets',
        select_values = GetPresetSelectValues(),
        default = 0,
        value = nil,
    },
}

gui_config = {
    {
        type = gui_input_types.Combo,
		key = p.presets.key,
		title = "Presets",
		select_values =  p.presets.select_values,
		default = p.presets.default,
        on_change = function(val, s)
            if s.select_values[val + 1] == "Save preset..." then
                local name

                if presets.current ~= nil then
                    name = presets.current
                else
                    local i = 1
                    for _, _ in pairs(presets.list) do i = i + 1 end

                    name = "Preset " .. i
                    while presets.list[name] ~= nil or presets.list[name .. " [modified]"] ~= nil do
                        i = i + 1
                        name = "Preset " .. i
                    end
                end

                EK_AskUser("Save preset", {
                    {"Enter name of preset:", name }
                }, function(res)
                    if not res or not res[1] then
                        r.MB("Please set name for saving preset...", "Save preset", 0)
                        ClearPresetSelectItem()
                    else
                        SavePreset(res[1])
                    end

                    s.select_values = GetPresetSelectValues()
                end)
            elseif s.select_values[val + 1] == "Delete preset..." then
                if presets.current and r.MB('Are you sure to delete this preset "' .. presets.current .. '"?', "Delete preset...", 4) == 6 then
                    DeletePreset(presets.current)
                end

                ClearPresetSelectItem()
                s.select_values = GetPresetSelectValues()
            elseif val ~= 0 then
                SetPreset(s.select_values[val + 1], true)
                s.select_values = GetPresetSelectValues()
            end
        end
	},
	{
        type = gui_input_types.Combo,
		key = p.crop_mode.key,
		title = "Crop mode",
		select_values = p.crop_mode.select_values,
		default = p.crop_mode.default,
        on_change = function(val)
            p.crop_mode.value = val
            MakePresetModified()
        end
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.leading.rms_bin_size.key,
        default = p.leading.rms_bin_size.default,
		title = "RMS window",
        number_min = 0.01,
        number_max = 1,
        number_precision = '%.2fs',
        on_change = function(val)
            p.leading.rms_bin_size.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 2 and p.crop_mode.value ~= 3
        end,
	},
    {
		type = gui_input_types.Label,
		title = "\nLeading edge: ",
	},
    {
        type = gui_input_types.NumberSlider,
		key = p.leading.threshold.key,
		default = p.leading.threshold.default,
		title = "Threshold In",
        number_min = -90,
        number_max = 0,
        number_precision = '%.1fdb',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.leading.threshold.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 0
        end,
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.leading.threshold_relative.key,
        default = p.leading.threshold_relative.default,
		title = "Threshold In",
        number_min = 0,
        number_max = 100,
        number_precision = '%.0f%%',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.leading.threshold_relative.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 1
        end,
	},
    {
        type = gui_input_types.NumberSlider,
		key = p.leading.rms_threshold.key,
		default = p.leading.rms_threshold.default,
		title = "Threshold In",
        number_min = -90,
        number_max = 0,
        number_precision = '%.1fdb',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.leading.rms_threshold.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 2
        end,
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.leading.rms_threshold_relative.key,
        default = p.leading.rms_threshold_relative.default,
		title = "Threshold In",
        number_min = 0,
        number_max = 100,
        number_precision = '%.0f%%',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.leading.rms_threshold_relative.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 3
        end,
	},
    {
        type = gui_input_types.NumberDrag,
        key = p.leading.pad.key,
        default = p.leading.pad.default,
		title = "Pad In",
        number_min = 0,
        number_step = 0.001,
        number_precision = '%.3fs',
        on_change = function(val)
            p.leading.pad.value = val
            MakePresetModified()
        end
	},
    {
        type = gui_input_types.NumberDrag,
        key = p.leading.fade.key,
        default = p.leading.fade.default,
		title = "Fade In",
        number_min = 0,
        number_step = 0.001,
        number_precision = '%.3fs',
        on_change = function(val)
            p.leading.fade.value = val
            MakePresetModified()
        end
	},
    {
		type = gui_input_types.Label,
		title = "\nTrailing edge: ",
	},
    {
        type = gui_input_types.NumberSlider,
		key = p.trailing.threshold.key,
		default = p.trailing.threshold.default,
		title = "Threshold Out",
        number_min = -90,
        number_max = 0,
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        number_precision = '%.1fdb',
        on_change = function(val)
            p.trailing.threshold.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 0
        end,
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.trailing.threshold_relative.key,
        default = p.trailing.threshold_relative.default,
		title = "Threshold Out",
        number_min = 0,
        number_max = 100,
        number_precision = '%.0f%%',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.trailing.threshold_relative.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 1
        end,
	},
    {
        type = gui_input_types.NumberSlider,
		key = p.trailing.rms_threshold.key,
		default = p.trailing.rms_threshold.default,
		title = "Threshold Out",
        number_min = -90,
        number_max = 0,
        number_precision = '%.1fdb',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.trailing.rms_threshold.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 2
        end,
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.trailing.rms_threshold_relative.key,
        default = p.trailing.rms_threshold_relative.default,
		title = "Threshold Out",
        number_min = 0,
        number_max = 100,
        number_precision = '%.0f%%',
        flags = reaper.ImGui_SliderFlags_Logarithmic and reaper.ImGui_SliderFlags_Logarithmic() or nil,
        on_change = function(val)
            p.trailing.rms_threshold_relative.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 3
        end,
	},
    {
        type = gui_input_types.NumberDrag,
        key = p.trailing.pad.key,
        default = p.trailing.pad.default,
		title = "Pad Out",
        number_step = 0.001,
        number_min = 0,
        number_precision = '%.3fs',
        on_change = function(val)
            p.trailing.pad.value = val
            MakePresetModified()
        end
	},
    {
        type = gui_input_types.NumberDrag,
        key = p.trailing.fade.key,
        default = p.trailing.fade.default,
		title = "Fade Out",
        number_step = 0.001,
        number_min = 0,
        number_precision = '%.3fs',
        on_change = function(val)
            p.trailing.fade.value = val
            MakePresetModified()
        end
	},
    {
        type = gui_input_types.Checkbox,
		key = p.preview_result.key,
		default = p.preview_result.default,
		title = "Preview result",
        on_change = function(val)
            p.preview_result.value = val
        end
	},
}

ClearPresetSelectItem()

-- initing values --
for i, block in pairs(p) do
    if block.key ~= nil then
        p[i].value = EK_GetExtState(block.key, block.default)
    else
        for j, info in pairs(block) do
            p[i][j].value = EK_GetExtState(info.key, info.default)
        end
    end
end

EdgeCropper = {}
EdgeCropper.__index = EdgeCropper

function EdgeCropper.new()
    local self = setmetatable({}, EdgeCropper)

    local min_db_step = 0.2
    local min_step = 0.000001
    local using_eel = reaper.APIExists("ImGui_CreateFunctionFromEEL")
    local cache = {}
    local curItem, curTake, curItemLength, curItemPosition

    local SampleToDb = function(sample)
        -- returns -150 for any 0.0 sample point (since you can't take the log of 0)
        if sample == 0 then
            return -150.0
        else
            return 20 * log10(math.abs(sample))
        end
    end

    local GetCache = function(prefix)
        local _, guid = r.GetSetMediaItemInfo_String(curItem, "GUID", "", false)

        if prefix then
            if cache[guid] == nil then cache[guid] = {} end

            return cache[guid][prefix]
        else
            return cache[guid]
        end
    end

    local SetCache = function(value, prefix)
        local _, guid = r.GetSetMediaItemInfo_String(curItem, "GUID", "", false)

        if prefix then cache[guid][prefix] = value
        else cache[guid] = value end
    end

    self.ClearCache = function(item)
        Log("CLEAR CACHE", ek_log_levels.Warning)
        if curItem then
            curItemLength = r.GetMediaItemInfo_Value(curItem, "D_LENGTH")
            curItemPosition = r.GetMediaItemInfo_Value(curItem, "D_POSITION")
        end

        if item ~= nil then
            local _, guid = r.GetSetMediaItemInfo_String(item, "GUID", "", false)
            cache[guid] = nil
        else
            cache = {}
        end
    end

    self.SetItem = function(item)
        curItem = item
        curTake = r.GetActiveTake(item)
        curItemLength = r.GetMediaItemInfo_Value(curItem, "D_LENGTH")
        curItemPosition = r.GetMediaItemInfo_Value(curItem, "D_POSITION")

        return self
    end

    local BuildSamplesBuffer = function(isReverse, isPortioned, Callback)
        if not curTake then return end

        local starttime_sec, startBlock, endBlock, iterBlock
        local PCM_source = r.GetMediaItemTake_Source(curTake)
        local samplerate = r.GetMediaSourceSampleRate(PCM_source)
        local audio = r.CreateTakeAudioAccessor(curTake)
        local n_channels = r.GetMediaSourceNumChannels(PCM_source)
        local item_len_spls = math.floor(curItemLength * samplerate)

        local max_block_size = 4194303

        local block_size = isPortioned and samplerate or math.floor(item_len_spls)

        if block_size > max_block_size / n_channels then
            block_size = math.floor(max_block_size / n_channels)
        elseif block_size > item_len_spls then
            block_size = item_len_spls
        end

        local n_blocks = math.floor(item_len_spls / block_size)

        if n_blocks < 1 then n_blocks = 1 end

        local extra_spls = item_len_spls - block_size * n_blocks

        -- 'samplebuffer' will hold all of the audio data for each block
        local samplebuffer = r.new_array(block_size * n_channels)

        -- Loop through the audio, one block at a time
        if isReverse then
            starttime_sec = curItemLength - (block_size / samplerate)
            if starttime_sec < 0 then starttime_sec = 0 end

            startBlock = n_blocks
            endBlock = 0
            iterBlock = -1
        else
            starttime_sec = 0
            startBlock = 0
            endBlock = n_blocks
            iterBlock = 1
        end

        Log("=== SEARCH " .. startBlock .. " -> " .. endBlock .. " by " .. iterBlock .. " [" .. item_len_spls .. "spl.][" .. round(curItemLength, 3) .. "s.][" .. samplerate .. "Hz] ===", ek_log_levels.Warning)

        for cur_block = startBlock, endBlock, iterBlock do
            local block = cur_block == endBlock and extra_spls or block_size

            if block == 0 then goto end_looking end

            samplebuffer.clear()

            -- Loads 'samplebuffer' with the next block
            r.GetAudioAccessorSamples(audio, samplerate, n_channels, starttime_sec, block, samplebuffer)

            Log("\t" .. cur_block .. " block: [" .. n_channels .. "ch.][" .. block .. "spl.][" .. round((starttime_sec + (block / samplerate)) - starttime_sec, 3) .. "s.] " .. round(starttime_sec, 3) .. " - " .. round(starttime_sec + (block / samplerate), 3) .. "s.", ek_log_levels.Warning)

            if Callback(samplebuffer, block, samplerate, n_channels, starttime_sec) then
                goto end_looking
            end

            if isReverse then
                starttime_sec = starttime_sec - (block / samplerate)
                if starttime_sec < 0 then starttime_sec = 0 end
            else
                starttime_sec = starttime_sec + (block / samplerate)
            end
        end

        ::end_looking::

        -- Tell r we're done working with this item, so the memory can be freed
        r.DestroyAudioAccessor(audio)
    end

    local GoThroughMidiTakeByNotes = function(isReverse, Callback)
        if curTake == nil or not r.TakeIsMIDI(curTake) then return end

        local note

        if isReverse then
            local _, notecnt, _, _ = r.MIDI_CountEvts(curTake)
            note = notecnt - 1
        else
            note = 0
        end

        local needStopSeeking = false

        while not needStopSeeking do
            local ret, _, muted, startppq, endppq, _, _, _ = r.MIDI_GetNote(curTake, note)

            if ret then
                local startTime = r.MIDI_GetProjTimeFromPPQPos(curTake, startppq)
                local endTime = r.MIDI_GetProjTimeFromPPQPos(curTake, endppq)

                if Callback(muted, startTime, endTime) then
                    needStopSeeking = true
                end
            end

            if isReverse then note = note - 1
            else note = note + 1 end

            if not ret then needStopSeeking = true end
        end
    end

    local GetOffsetConsiderPitchByRate = function(offset, rate)
        local semiFactor = 2 ^ (1 / 12) -- Rate: 2.0 = Pitch * 12
        local semitones = round(math.log(rate, semiFactor), 5)
        local curSemiFactor = 2 ^ ((1 / 12) * math.abs(semitones))

        -- r.ShowConsoleMsg(semitones .. "\n")

        return semitones > 0 and (offset * curSemiFactor) or (offset / curSemiFactor)
    end

    local EelEngine = {
        GetMaxPeakPosition = function()
            local CallbackEEL = r.ImGui_CreateFunctionFromEEL([[
                i = 0;
                maxDb = -150;
                maxAmpl = 0;
                position = -1;

                while (i < block_size) (
                    while (i < block_size) (
                        // Loop through each channel separately
                        j = 1;

                        loop(n_channels,
                            spl = samplebuffer[(i * n_channels) + j];
                            ampl = abs(spl);

                            maxAmpl = max(maxAmpl, ampl);
                            maxDb = ampl != 0 && ampl == maxAmpl ? 20 * log10(ampl) : maxDb;
                            position = ampl != 0 && ampl == maxAmpl ? i / samplerate : position;

                            j += 1;
                        );

                        i += 1;
                    );
                );
            ]])

            local maxDb = -150
            local position = -1

            BuildSamplesBuffer( false, false, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                -- Use EEL to read from the array
                r.ImGui_Function_SetValue(CallbackEEL, 'block_size', block_size)
                r.ImGui_Function_SetValue(CallbackEEL, 'n_channels', n_channels)
                r.ImGui_Function_SetValue_Array(CallbackEEL, 'samplebuffer', samplebuffer)
                r.ImGui_Function_SetValue(CallbackEEL, 'samplerate', samplerate)
                r.ImGui_Function_Execute(CallbackEEL)

                local curMaxDb = r.ImGui_Function_GetValue(CallbackEEL, 'maxDb')
                local curPosition = r.ImGui_Function_GetValue(CallbackEEL, 'position')

                maxDb = math.max(maxDb, curMaxDb)
                if maxDb == curMaxDb then
                    position = starttime_sec + curPosition
                end
            end)

            return maxDb, position
        end,
        GetPeakThresholdPosition = function(threshold, isReverse)
            local CallbackEEL = r.ImGui_CreateFunctionFromEEL([[
                i = (reverse == 1) ? block_size : 0;
                maxDb = -150;
                position = -1;

                while ((reverse == 1 && i > 0) || (reverse != 1 && i < block_size)) (
                    // Loop through each channel separately
                    j = 1;

                    loop(n_channels,
                        spl = samplebuffer[(i * n_channels) + j];
                        db = maxDb != -150 || spl == 0 ? -150 : 20 * log10(abs(spl));

                        maxDb = maxDb == -150 && db >= threshold ? db : maxDb;
                        position = position == -1 && db >= threshold ? i / samplerate : position;

                        j += 1;
                    );

                    i = (reverse == 1) ? i - 1 : i + 1;
                );
            ]])

            local maxDb = -150
            local pos = -1

            BuildSamplesBuffer(isReverse, true, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                -- Use EEL to read from the array
                r.ImGui_Function_SetValue(CallbackEEL, 'block_size', block_size)
                r.ImGui_Function_SetValue(CallbackEEL, 'n_channels', n_channels)
                r.ImGui_Function_SetValue_Array(CallbackEEL, 'samplebuffer', samplebuffer)
                r.ImGui_Function_SetValue(CallbackEEL, 'samplerate', samplerate)
                r.ImGui_Function_SetValue(CallbackEEL, 'reverse', isReverse and 1 or 0)
                r.ImGui_Function_SetValue(CallbackEEL, 'threshold', threshold)
                r.ImGui_Function_Execute(CallbackEEL)

                local curMaxDb = r.ImGui_Function_GetValue(CallbackEEL, 'maxDb')
                local curPos = r.ImGui_Function_GetValue(CallbackEEL, 'position')

                if curPos ~= -1 then
                    maxDb = curMaxDb
                    pos = starttime_sec + curPos

                    return true
                end
            end)

            if pos >= 0 then
                return maxDb, pos
            else
                return nil
            end
        end,
        GetMaxRmsPosition = function()
            local CallbackEEL = r.ImGui_CreateFunctionFromEEL([[
                i = 0;
                maxDb = -150;
                maxAmpl = 0;
                position = -1;

                while (i < bins) (
                    j = 1;
                    sqsum = 0;
                    count = 0;

                    loop(bin_samples,
                        spl = samplebuffer[j + (i * bin_samples)];
                        sqsum = sqsum + (spl * spl);
                        count = count + 1;

                        j += 1;
                    );

                    rms = sqrt(sqsum / count);
                    maxAmpl = max(maxAmpl, rms);

                    maxDb = rms != 0 && rms == maxAmpl ? 20 * log10(rms) : maxDb;
                    position = rms != 0 && rms == maxAmpl ? i * bin_size : position;

                    i += 1;
                );
            ]])

            local maxDb = -150
            local position = -1

            BuildSamplesBuffer(false, false, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                local bin_samples = math.floor(p.leading.rms_bin_size.value * samplerate * n_channels)
                if bin_samples > #samplebuffer then bin_samples = #samplebuffer end

                local bins = math.floor(#samplebuffer / bin_samples)

                if bins == 0 then bins = 1 end

                -- Use EEL to read from the array
                r.ImGui_Function_SetValue(CallbackEEL, 'block_size', block_size)
                r.ImGui_Function_SetValue(CallbackEEL, 'n_channels', n_channels)
                r.ImGui_Function_SetValue_Array(CallbackEEL, 'samplebuffer', samplebuffer)
                r.ImGui_Function_SetValue(CallbackEEL, 'samplerate', samplerate)

                r.ImGui_Function_SetValue(CallbackEEL, 'bins', bins)
                r.ImGui_Function_SetValue(CallbackEEL, 'bin_size', p.leading.rms_bin_size.value)
                r.ImGui_Function_SetValue(CallbackEEL, 'bin_samples', bin_samples)

                r.ImGui_Function_Execute(CallbackEEL)

                local curMaxDb = r.ImGui_Function_GetValue(CallbackEEL, 'maxDb')
                local curPosition = r.ImGui_Function_GetValue(CallbackEEL, 'position')

                maxDb = math.max(maxDb, curMaxDb)
                if maxDb == curMaxDb then
                    position = starttime_sec + curPosition
                end
            end)

            return maxDb, position
        end,
        GetRmsThresholdPosition = function(threshold, isReverse)
            local CallbackEEL = r.ImGui_CreateFunctionFromEEL([[
                i = (reverse == 1) ? bins : 0;
                maxDb = -150;
                position = -1;

                while ((reverse == 1 && i >= 0) || (reverse != 1 && i < bins)) (
                    j = 1;
                    sqsum = 0;
                    count = 0;

                    loop(bin_samples,
                        spl = samplebuffer[j + (i * bin_samples)];
                        sqsum = sqsum + (spl * spl);
                        count = count + 1;

                        j += 1;
                    );

                    rms = maxDb == -150 ? sqrt(sqsum / count) : 0;
                    db = maxDb != -150 || rms == 0 ? -150 : 20 * log10(rms);

                    maxDb = maxDb == -150 && db >= threshold ? db : maxDb;
                    position = position == -1 && db >= threshold ? i * bin_size : position;

                    i = (reverse == 1) ? i - 1 : i + 1;
                );
            ]])

            local maxDb = -150
            local position = -1

            BuildSamplesBuffer(isReverse, true, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                local bin_samples = math.floor(p.leading.rms_bin_size.value * samplerate * n_channels)
                if bin_samples > #samplebuffer then bin_samples = #samplebuffer end

                local bins = math.floor(#samplebuffer / bin_samples)

                if bins == 0 then bins = 1 end

                -- Use EEL to read from the array
                r.ImGui_Function_SetValue(CallbackEEL, 'block_size', block_size)
                r.ImGui_Function_SetValue(CallbackEEL, 'n_channels', n_channels)
                r.ImGui_Function_SetValue_Array(CallbackEEL, 'samplebuffer', samplebuffer)
                r.ImGui_Function_SetValue(CallbackEEL, 'samplerate', samplerate)
                r.ImGui_Function_SetValue(CallbackEEL, 'reverse', isReverse and 1 or 0)
                r.ImGui_Function_SetValue(CallbackEEL, 'threshold', threshold)

                r.ImGui_Function_SetValue(CallbackEEL, 'bins', bins)
                r.ImGui_Function_SetValue(CallbackEEL, 'bin_size', p.leading.rms_bin_size.value)
                r.ImGui_Function_SetValue(CallbackEEL, 'bin_samples', bin_samples)

                r.ImGui_Function_Execute(CallbackEEL)

                local curMaxDb = r.ImGui_Function_GetValue(CallbackEEL, 'maxDb')
                local curPosition = r.ImGui_Function_GetValue(CallbackEEL, 'position')

                if curPosition >= 0 then
                    maxDb = curMaxDb
                    position = starttime_sec + curPosition

                    return true
                end
            end)

            if position >= 0 then
                return maxDb, position
            else
                return nil
            end
        end
    }
    local LuaEngine = {
        GetMaxPeakPosition = function()
            local position = -1
            local maxDb = 0

            BuildSamplesBuffer(false, false, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                 local i = 0

                 while (i < block_size) do
                     for j = 1, n_channels do
                         local ind = (i * n_channels) + j

                         if ind < #samplebuffer then
                             local spl = samplebuffer[ind];
                             local curSpl = math.abs(spl)

                             maxDb = math.max(maxDb, curSpl)
                             if maxDb == curSpl then
                                 position = starttime_sec + (i / samplerate)
                             end
                         end
                     end

                     i = i + 1
                 end
            end)

            return SampleToDb(maxDb), position
        end,
        GetPeakThresholdPosition = function(threshold, isReverse)
            local position = -1
            local maxDb = -150

            BuildSamplesBuffer(isReverse, true, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                 local i = isReverse and block_size or 0

                 while ((isReverse and i > 0) or (not isReverse and i < block_size)) do
                     for j = 1, n_channels do
                         local ind = (i * n_channels) + j

                         if ind < #samplebuffer then
                             local spl = samplebuffer[ind]
                             local db = SampleToDb(spl)

                             if db >= threshold then
                                 maxDb = db
                                 position = starttime_sec + (i / samplerate)

                                 return true
                             end
                         end
                     end

                     i = isReverse and i - 1 or i + 1
                 end
            end)

            if position >= 0 then
                return maxDb, position
            else
                return nil
            end
        end,
        GetMaxRmsPosition = function()
            local maxRms = 0
            local position = -1

            BuildSamplesBuffer(false, false, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                local i = 0
                local bin_samples = math.floor(p.leading.rms_bin_size.value * samplerate * n_channels)
                local bins = math.floor(#samplebuffer / bin_samples)

                if bins == 0 then bins = 1 end

                while (i < bins) do
                    local sqsum = 0
                    local count = 0

                    for j = 1, bin_samples do
                        local iter = j + (i * bin_samples)

                        if iter < #samplebuffer then
                            local spl = samplebuffer[iter]
                            sqsum = sqsum + (spl * spl)
                            count = count + 1
                        end
                    end

                    local rms = math.sqrt(sqsum / count)

                    maxRms = math.max(maxRms, rms)

                    --local pos = starttime_sec + (i * p.leading.rms_bin_size.value)
                    --Log("[" .. bin_samples .. "][" .. round(pos, 3) .. " - " .. round(pos + count / (samplerate * n_channels), 3) .."] => " .. round(SampleToDb(rms), 3), ek_log_levels.Debug)

                    if rms == maxRms then
                        position = starttime_sec + (i * p.leading.rms_bin_size.value)
                    end

                    i = i + 1
                end
            end)

            return SampleToDb(maxRms), position
        end,
        GetRmsThresholdPosition = function(threshold, isReverse)
            local maxRms = 0
            local position = -1

            BuildSamplesBuffer(isReverse, true, function(samplebuffer, block_size, samplerate, n_channels, starttime_sec)
                local bin_samples = math.floor(p.leading.rms_bin_size.value * samplerate * n_channels)

                if bin_samples > #samplebuffer then bin_samples = #samplebuffer end

                local bins = math.floor(#samplebuffer / bin_samples)

                if bins == 0 then bins = 1 end

                local i = isReverse and bins or 0

                while ((isReverse and i >= 0) or (not isReverse and i < bins)) do
                    local sqsum = 0
                    local count = 0

                    for j = 1, bin_samples do
                        local iter = j + (i * bin_samples)

                        if iter < #samplebuffer then
                            local spl = samplebuffer[iter]
                            sqsum = sqsum + (spl * spl)
                            count = count + 1
                        end
                    end

                    local rms = math.sqrt(sqsum / count)

                    if SampleToDb(rms) >= threshold then
                        maxRms = rms
                        position = starttime_sec + (i * p.leading.rms_bin_size.value)
                        return true
                    end

                    --if not isReverse then
                    --    local pos = starttime_sec + (i * p.leading.rms_bin_size.value)
                    --    Log("[" .. bin_samples .. "][" .. round(pos, 3) .. " - " .. round(pos + count / (samplerate * n_channels), 3) .."] => " .. round(SampleToDb(rms), 3), ek_log_levels.Debug)
                    --
                    --end

                    i = isReverse and i - 1 or i + 1
                end
            end)

            if position >= 0 then
                return SampleToDb(maxRms), position
            else
                return nil
            end
        end
    }

    local GetPositionOfMidiNote = function(isReverse)
        if curTake == nil or not r.TakeIsMIDI(curTake) then return end

        local pos

        GoThroughMidiTakeByNotes(isReverse, function(muted, start_time, end_time)
            if not muted then
                local time

                if isReverse then
                    time = end_time - curItemPosition

                    if time > curItemLength and start_time - curItemPosition <= curItemLength then
                        pos = curItemLength
                        return true
                    elseif time <= curItemLength then
                        pos = time
                        return true
                    end
                else
                    time = start_time - curItemPosition

                    if time < 0 and end_time - curItemPosition >= 0 then
                        pos = 0
                        return true
                    elseif time >= 0 then
                        pos = time
                        return true
                    end
                end
            end
        end)

        if not pos then pos = curItemLength
        end

        return pos
    end

    local engine = using_eel and EelEngine or LuaEngine

    self.GetThresholdsValues = function()
        if p.crop_mode.value == 0 then -- Absolute thresholds
            return p.leading.threshold.value, p.trailing.threshold.value
        elseif p.crop_mode.value == 1 then -- Relative thresholds from max peak
            return p.leading.threshold_relative.value, p.trailing.threshold_relative.value
        elseif p.crop_mode.value == 2 then -- Absolute RMS
            return p.leading.rms_threshold.value, p.trailing.rms_threshold.value
        elseif p.crop_mode.value == 3 then -- Relative RMS from max peak
            return p.leading.rms_threshold_relative.value, p.trailing.rms_threshold_relative.value
        end
    end

    self.GetPadValue = function(isReverse)
        if curItem == nil then return end

        local pad = 0
        local prefix = p.crop_mode.value .. ":pad:" .. (isReverse and "rev" or "")
        local cache_val = GetCache(prefix)

        if cache_val == nil then
            local pos = self.GetCropPosition(isReverse)

            if isReverse then
                pad = p.trailing.pad.value + pos > curItemLength and curItemLength - pos - min_step or p.trailing.pad.value
            else
                pad = p.leading.pad.value > pos and pos - min_step or p.leading.pad.value
            end

            SetCache(pad, prefix)
        else
            pad = cache_val
        end

        return pad
    end

    self.GetFadeValue = function(isReverse)
        if curItem == nil then return end

        local fade = 0
        local prefix = p.crop_mode.value .. ":fade:" .. (isReverse and "rev" or "")
        local cache_val = GetCache(prefix)

        if cache_val == nil then
            local pos = self.GetCropPosition(isReverse)
            local padPos = pos + self.GetPadValue(isReverse)
            local curItemFade = r.GetMediaItemInfo_Value(curItem, isReverse and "D_FADEOUTLEN" or "D_FADEINLEN")
            local fadeValue = isReverse and p.trailing.fade.value or p.leading.fade.value

            if fadeValue > curItemFade then curItemFade = fadeValue end

            if isReverse then
                if padPos >= curItemLength then
                    fade = 0
                else
                    local leadingPos = self.GetCropPosition()
                    local leadingPadPos = leadingPos - self.GetPadValue()
                    local leadingFade = self.GetFadeValue()

                    fade = padPos - curItemFade < leadingPadPos + leadingFade and
                        padPos - (leadingPadPos + leadingFade) - min_step or curItemFade
                end
            else
                if padPos <= 0 then
                    fade = 0
                else
                    fade = curItemFade + padPos > curItemLength and
                        curItemLength - padPos - min_step or curItemFade
                end
            end

            SetCache(fade, prefix)
        else
            fade = cache_val
        end

        return fade
    end

    local GetMaxDbPosition = function()
        if curTake == nil then return end

        local db = -150
        local prefix = p.crop_mode.value .. ":max"
        local cache_val = GetCache(prefix)

        if cache_val == nil then
            if p.crop_mode.value == 1 then -- Relative thresholds from max peak
                db, _ = engine.GetMaxPeakPosition()
            elseif p.crop_mode.value == 3 then -- Relative RMS from max peak
                db, _ = engine.GetMaxRmsPosition()
            end

            SetCache(db, prefix)
        else
            db = cache_val
        end

        return db
    end

    local GetRelativeThreshold = function(isReverse)
        local db = GetMaxDbPosition()
        local lt, tt = self.GetThresholdsValues()
        local threshold = isReverse and tt or lt

        if threshold == 0 then return -150 end

        local abs_percent = 10 ^ (db / 40)
        local rel_db = 40 * log10(abs_percent * (threshold / 100))

        return rel_db - min_db_step -- for good comparing floats
    end

    self.GetCropPosition = function(isReverse)
        if curTake == nil then return end

        local lt, tt
        local pos = 0

        local prefix = p.crop_mode.value .. ":pos:" .. (isReverse and "rev" or "")
        local cache_val = GetCache(prefix)

        if cache_val == nil then
            if reaper.TakeIsMIDI(curTake) then
                pos = GetPositionOfMidiNote(isReverse)
            elseif p.crop_mode.value == 0 then -- Absolute thresholds
                lt, tt = self.GetThresholdsValues()
                _, pos = engine.GetPeakThresholdPosition(isReverse and tt or lt, isReverse)
            elseif p.crop_mode.value == 1 then -- Relative thresholds from max peak
                local rel_t = GetRelativeThreshold(isReverse)
                 _, pos = engine.GetPeakThresholdPosition(rel_t, isReverse)
            elseif p.crop_mode.value == 2 then -- Absolute RMS
                lt, tt = self.GetThresholdsValues()
                _, pos = engine.GetRmsThresholdPosition(isReverse and tt or lt, isReverse)
            elseif p.crop_mode.value == 3 then -- Relative RMS from max peak
                local rel_t = GetRelativeThreshold(isReverse)
                 _, pos = engine.GetRmsThresholdPosition(rel_t, isReverse)
            end

            if pos == nil then
                pos = isReverse and curItemLength or 0
            end

            SetCache(pos, prefix)
        else
            pos = cache_val
        end

        return pos
    end

    self.Crop = function()
        ----------------------
        -- LEADING POSITION --
        ----------------------
        local l_pad = self.GetPadValue()
        local l_fade = self.GetFadeValue()
        local l_position = self.GetCropPosition()

        -----------------------
        -- TRAILING POSITION --
        -----------------------
        local t_pad = self.GetPadValue(true)
        local t_fade = self.GetFadeValue(true)
        local t_position = self.GetCropPosition(true)

        if l_position then
            l_position = l_position - l_pad

            local offset = r.GetMediaItemTakeInfo_Value(curTake, "D_STARTOFFS")
            local rate = r.GetMediaItemTakeInfo_Value(curTake, "D_PLAYRATE")
            local startOffsetAbs = GetOffsetConsiderPitchByRate(l_position, rate)

            -- r.ShowConsoleMsg(semitones .. " " .. startOffset .. " " ..  startOffsetAbs .. "\n")

            r.SetMediaItemTakeInfo_Value(curTake, "D_STARTOFFS", offset + startOffsetAbs)
            r.SetMediaItemInfo_Value(curItem, "D_POSITION", curItemPosition + l_position)
            r.SetMediaItemInfo_Value(curItem, "D_LENGTH", curItemLength - l_position)
            r.SetMediaItemInfo_Value(curItem, "D_FADEINLEN", l_fade)
        end

        if t_position then
            t_position = t_position + t_pad - l_position

            if t_position < curItemLength then
                r.SetMediaItemInfo_Value(curItem, "D_LENGTH", t_position)
                r.SetMediaItemInfo_Value(curItem, "D_FADEOUTLEN", t_fade)
            end
        end
    end

    return self
end