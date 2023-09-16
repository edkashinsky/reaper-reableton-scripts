-- @noindex

local r = reaper
local presets_key = "triming_silence_presets_list"
min_step = 0.00001
using_eel = reaper.APIExists("ImGui_CreateFunctionFromEEL")

local presets = {
    current = nil,
    id = nil,
    is_modified = false,
    list = EK_GetExtState(presets_key, {})
}

function ClearPresetSelectItem()
    EK_SetExtState(p.presets.key, 0)
end

function DeletePreset(name)
    presets.id = nil
    presets.current = nil
    presets.is_modified = false
    presets.list[name] = nil

    EK_SetExtState(presets_key, presets.list)
end

function SavePreset(name)
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

function SetPreset(name)
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

        EK_SetExtState(key, value)
    end
end

function GetPresetSelectValues()
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

function MakePresetModified()
    if presets.id ~= nil then
        presets.is_modified = true
        local val = gui_config[1].select_values[presets.id]
        local label = "modified"

        if not string.find(val, label) then
            gui_config[1].select_values[presets.id] = val .. " [" .. label .. "]"
        end
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
        select_values = { "Absolute thresholds", "Relative thresholds from peaks" },
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
                SetPreset(s.select_values[val + 1])
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
        on_change = function(val)
            p.leading.threshold.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value == 1
        end,
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.leading.threshold_relative.key,
        default = p.leading.threshold_relative.default,
		title = "Threshold In",
		default = 1,
        number_min = 0,
        number_max = 100,
        number_precision = '%.0f%%',
        on_change = function(val)
            p.leading.threshold_relative.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 1
        end,
	},
    {
        type = gui_input_types.NumberDrag,
        key = p.leading.pad.key,
        default = p.leading.pad.default,
		title = "Pad In",
		default = 1,
        number_min = 0,
        number_step = 0.01,
        number_precision = '%.2fs',
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
		default = 1,
        number_min = 0,
        number_step = 0.01,
        number_precision = '%.2fs',
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
        number_precision = '%.1fdb',
        on_change = function(val)
            p.trailing.threshold.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value == 1
        end,
	},
    {
        type = gui_input_types.NumberSlider,
        key = p.trailing.threshold_relative.key,
        default = p.trailing.threshold_relative.default,
		title = "Threshold Out",
		default = 1,
        number_min = 0,
        number_max = 100,
        number_precision = '%.0f%%',
        on_change = function(val)
            p.trailing.threshold_relative.value = val
            MakePresetModified()
        end,
        hidden = function()
            return p.crop_mode.value ~= 1
        end,
	},
    {
        type = gui_input_types.NumberDrag,
        key = p.trailing.pad.key,
        default = p.trailing.pad.default,
		title = "Pad Out",
		default = 1,
        number_step = 0.01,
        number_min = 0,
        number_precision = '%.2fs',
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
		default = 1,
        number_step = 0.01,
        number_min = 0,
        number_precision = '%.2fs',
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

function GetGUID(item)
    if not item then return end

    local _, guid = r.GetSetMediaItemInfo_String(item, "GUID", "", false)
    local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")

    return guid .. ":" .. length
end

function GetThresholdsValues()
    if p.crop_mode.value == 0 then
        return p.leading.threshold.value,
            p.trailing.threshold.value
    else
        return p.leading.threshold_relative.value,
            p.trailing.threshold_relative.value
    end
end

local function SampleToDb(sample)
    -- returns -150 for any 0.0 sample point (since you can't take the log of 0)
    if sample == 0 then
        return -150.0
    else
        return 20 * log10(math.abs(sample))
    end
end

local function GetMaxDbOrThresholdPositionByTakeEEL(take, threshold, isReverse)
    -- making math function local improves their speed
    local max, min, floor = math.max, math.min, math.floor

    -- Function to read the array usinf EEL
    local ReadArrayWithEEL = r.ImGui_CreateFunctionFromEEL([[
        i = reverse == 1 ? block_size : 0;
        maxDb = -150;
        pos_threshold = -1;

        loop(block_size,
            // Loop through each channel separately
            j = reverse == 1 ? n_channels : 1;

            loop(n_channels,
                spl = samplebuffer[i * j];
                db = spl == 0 ? -150 : 20 * log10(abs(spl));

                pos_threshold = (threshold != 1000 && pos_threshold == -1 && db >= threshold) ? (
                    (i * j) / samplerate
                ) : pos_threshold;

                maxDb = max(db, maxDb);

                j = reverse == 1 ? j - 1 : j + 1;
            );

            i = reverse == 1 ? i - 1 : i + 1;
        );
    ]])

    local PCM_source = r.GetMediaItemTake_Source(take)
    local samplerate = r.GetMediaSourceSampleRate(PCM_source)

    if not take or not samplerate then return end

    -- Sort out the selection range
    local item = r.GetMediaItemTake_Item(take)
    local item_start = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
    local sel_start, sel_end = r.GetSet_LoopTimeRange(0, 0, 0, 0, 0)

    if not sel_start or sel_end == sel_start then
        sel_start = item_start
        sel_end = item_start + item_len
    end

    sel_start = max(sel_start, item_start)
    sel_end = min(sel_end, item_start + item_len)

    if sel_end - sel_start <= 0 then return end

    local playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    if playrate ~= 1 then
        r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)
        r.SetMediaItemInfo_Value(item, "D_LENGTH", item_len * playrate)
    end

    -- Define the time range w.r.t the original playrate
    local range_start = (sel_start - item_start) * playrate
    local range_len = (sel_end - sel_start) * playrate
    local range_end = range_start + range_len
    local range_len_spls = floor(range_len * samplerate)

    -- Allow for multichannel audio
    local n_channels = r.GetMediaSourceNumChannels(PCM_source)

    -- Break the range into blocks
    local block_size = 4096
    local n_blocks = floor(range_len_spls / block_size)
    local n_block_size = (block_size * n_channels) / samplerate
    local extra_spls = range_len_spls - block_size * n_blocks

    -- 'samplebuffer' will hold all of the audio data for each block
    local samplebuffer = r.new_array(block_size * n_channels)
    local audio = r.CreateTakeAudioAccessor(take)
    local starttime_sec, startBlock, endBlock, iterBlock

    -- Loop through the audio, one block at a time
    if isReverse then
        starttime_sec = range_end - n_block_size
        if starttime_sec < 0 then starttime_sec = 0 end

        startBlock = n_blocks
        endBlock = 0
        iterBlock = -1
    else
        starttime_sec = range_start
        startBlock = 0
        endBlock = n_blocks
        iterBlock = 1
    end

    local pos = -1
    local maxDb = -150

    for cur_block = startBlock, endBlock, iterBlock do
        local block = cur_block == endBlock and extra_spls or block_size

        samplebuffer.clear()

        -- Loads 'samplebuffer' with the next block
        r.GetAudioAccessorSamples(audio, samplerate, n_channels, starttime_sec, block, samplebuffer)

        -- Use EEL to read from the array
        r.ImGui_Function_SetValue(ReadArrayWithEEL, 'block_size', block)
        r.ImGui_Function_SetValue(ReadArrayWithEEL, 'n_channels', n_channels)
        r.ImGui_Function_SetValue_Array(ReadArrayWithEEL, 'samplebuffer', samplebuffer)
        r.ImGui_Function_SetValue(ReadArrayWithEEL, 'samplerate', samplerate)
        r.ImGui_Function_SetValue(ReadArrayWithEEL, 'reverse', isReverse and 1 or 0)
        r.ImGui_Function_SetValue(ReadArrayWithEEL, 'threshold', threshold and threshold or 1000)
        r.ImGui_Function_Execute(ReadArrayWithEEL)

        pos = r.ImGui_Function_GetValue(ReadArrayWithEEL, 'pos_threshold')
        maxDb = math.max(maxDb, r.ImGui_Function_GetValue(ReadArrayWithEEL, 'maxDb'))

        --Log("[" .. cur_block .. "][" .. n_channels .. "] " .. round(starttime_sec, 2) .. ".." .. round(starttime_sec + ((block * n_channels) / samplerate), 2) .. " => " .. round(maxDb, 2) .. " " .. pos, ek_log_levels.Debug)

        if threshold and pos ~= -1 then
            goto end_looking_eel
        end

        if isReverse then
            starttime_sec = starttime_sec - ((block * n_channels) / samplerate)
            if starttime_sec < 0 then starttime_sec = 0 end
        else
            starttime_sec = starttime_sec + ((block * n_channels) / samplerate)
        end
    end

    ::end_looking_eel::

    --Log("==", ek_log_levels.Debug)

    -- Tell r we're done working with this item, so the memory can be freed
    r.DestroyAudioAccessor(audio)

    -- I told you we'd put everything back
    if playrate ~= 1 then
        r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", playrate)
        r.SetMediaItemInfo_Value(item, "D_LENGTH", item_len)
    end

    if threshold and pos ~= -1 then
        return starttime_sec + pos
    elseif not threshold then
        return maxDb
    else
        return nil
    end
end

local function GetDataForAccessor(take)
    -- Get media source of media item take
    local take_pcm_source = r.GetMediaItemTake_Source(take)
    if take_pcm_source == nil then return end

    -- Create take audio accessor
    local aa = r.CreateTakeAudioAccessor(take)

    if aa == nil then return end

    -- Get the start time of the audio that can be returned from this accessor
    local aa_start = r.GetAudioAccessorStartTime(aa)
    -- Get the end time of the audio that can be returned from this accessor
    local aa_end = r.GetAudioAccessorEndTime(aa)
    local a_length = (aa_end - aa_start) / 25

    if a_length <= 1 then a_length = 1 elseif a_length > 20 then a_length = 20 end

    -- Get the number of channels in the source media.
    local take_source_num_channels =  r.GetMediaSourceNumChannels(take_pcm_source)
    if take_source_num_channels > 2 then take_source_num_channels = 2 end

    -- Get the sample rate. MIDI source media will return zero.
    local take_source_sample_rate = r.GetMediaSourceSampleRate(take_pcm_source)

    -- How many samples are taken from audio accessor and put in the buffer
    local samples_per_channel = take_source_sample_rate / 4

    return aa, a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel
end

local function GetMaxDbOrThresholdPositionByTake(take, threshold, isReverse)
    if take == nil then return end

    local aa, a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel = GetDataForAccessor(take)

    -- Samples are collected to this buffer
    local buffer = r.new_array(samples_per_channel * take_source_num_channels)
    local total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)
    local offs
    local needStopSeeking = false

    if total_samples < 1 then return end

    if isReverse then
        offs = aa_end - samples_per_channel / take_source_sample_rate
    else
        offs = aa_start
    end

    local pos = nil
    local maxDb = 0

    -- Loop through samples
    while not needStopSeeking do
        -- Get a block of samples from the audio accessor.
        -- Samples are extracted immediately pre-FX,
        -- and returned interleaved (first sample of first channel, first sample of second channel...).
        -- Returns 0 if no audio, 1 if audio, -1 on error.
        local aa_ret = r.GetAudioAccessorSamples(
            aa,                       -- AudioAccessor accessor
            take_source_sample_rate,  -- integer samplerate
            take_source_num_channels, -- integer numchannels
            offs,                     -- number starttime_sec
            samples_per_channel,      -- integer numsamplesperchannel
            buffer                    -- r.array samplebuffer
        )

        if aa_ret == 1 then
            local startBuf = 1
            local endBuf = #buffer
            local stepBuf = take_source_num_channels

            if isReverse then
                startBuf = #buffer
                endBuf = 1
                stepBuf = -take_source_num_channels
            end

            for i = startBuf, endBuf, stepBuf do
                for j = 1, take_source_num_channels do
                    local buf_pos = i + j - 1

                    if buf_pos >= 1 and buf_pos <= #buffer then
                        local spl = buffer[buf_pos]

                        if threshold == nil then
                            maxDb = math.max(maxDb, math.abs(spl))
                        elseif SampleToDb(spl) >= threshold then
                            pos = offs + (buf_pos / (take_source_sample_rate * take_source_num_channels))
                            goto end_looking_lua
                        end
                    end
                end
            end
        elseif aa_ret == 0 then -- no audio in current buffer
            -- do nothing
        else
            return
        end

        if isReverse then
            needStopSeeking = offs < aa_start
            offs = offs - samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
        else
            needStopSeeking = offs > aa_end - samples_per_channel / take_source_sample_rate
            offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
        end
    end -- end of while loop

    ::end_looking_lua::

    r.DestroyAudioAccessor(aa)

    if threshold then
        return pos
    else
        return SampleToDb(maxDb)
    end
end

local rel_peacks_cache = {}
local function GetRelativeThresholdsByTake(take, rel_threshold)
    if take == nil then return end

    local maxPeak = -100
    local item = r.GetMediaItemTake_Item(take)
    local guid = GetGUID(item)
    
    if rel_peacks_cache[guid] == nil then
        maxPeak = using_eel and GetMaxDbOrThresholdPositionByTakeEEL(take) or
            GetMaxDbOrThresholdPositionByTake(take)

        rel_peacks_cache[guid] = maxPeak
    else
        maxPeak = rel_peacks_cache[guid]
    end

    local abs_percent = 10 ^ (maxPeak / 40)

    local rel_db = 40 * log10(abs_percent * (rel_threshold / 100))

    --Log(r.GetTakeName(take) .. ": VAL=" .. rel_db .. " MAX=" .. maxPeak, ek_log_levels.Debug)

    return rel_db
end

function GetStartPositionLouderThenThreshold(take, threshold)
    if take == nil then return end

    local peakTime = 0

    if p.crop_mode.value == 1 then -- relative
        local orig = threshold
        threshold = GetRelativeThresholdsByTake(take, orig)

        if orig == 100 then threshold = threshold - min_step end -- for good comparing floats
    end

    peakTime = using_eel and GetMaxDbOrThresholdPositionByTakeEEL(take, threshold) or
        GetMaxDbOrThresholdPositionByTake(take, threshold)

    if peakTime == nil then peakTime = 0 end

    return peakTime
end

function GetEndPositionLouderThenThreshold(take, threshold)
    if take == nil then return end

    local peakTime

    if p.crop_mode.value == 1 then -- relative
        local orig = threshold
        threshold = GetRelativeThresholdsByTake(take, orig)

        if orig == 100 then threshold = threshold - min_step end -- for good comparing floats
    end

    peakTime = using_eel and GetMaxDbOrThresholdPositionByTakeEEL(take, threshold, true) or
        GetMaxDbOrThresholdPositionByTake(take, threshold, true)

    if peakTime == nil then
        local item = r.GetMediaItemTake_Item(take)
        peakTime = r.GetMediaItemInfo_Value(item, "D_LENGTH")
    end

    return peakTime
end

local function GetOffsetConsiderPitchByRate(offset, rate)
    local semiFactor = 2 ^ (1 / 12) -- Rate: 2.0 = Pitch * 12
    local semitones = round(math.log(rate, semiFactor), 5)
    local curSemiFactor = 2 ^ ((1 / 12) * math.abs(semitones))

    -- r.ShowConsoleMsg(semitones .. "\n")

    return semitones > 0 and (offset * curSemiFactor) or (offset / curSemiFactor)
end

function CropLeadingPosition(take, startOffset)
    local pad, fade = GetLeadingPadAndOffset(startOffset)

    startOffset = startOffset - pad
  
    if startOffset < 0 then return end
  
    local item = r.GetMediaItemTake_Item(take)
    local offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local startOffsetAbs = GetOffsetConsiderPitchByRate(startOffset, rate)

    -- r.ShowConsoleMsg(semitones .. " " .. startOffset .. " " ..  startOffsetAbs .. "\n")

    r.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset + startOffsetAbs)
    
    local position = r.GetMediaItemInfo_Value(item, "D_POSITION")
    r.SetMediaItemInfo_Value(item, "D_POSITION", position + startOffset)
    
    local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
    r.SetMediaItemInfo_Value(item, "D_LENGTH", length - startOffset)
    
    r.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade)
end

function CropTrailingPosition(take, endOffset)
    local item = r.GetMediaItemTake_Item(take)
    local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
    local pad, fade = GetTrailingPadAndOffset(endOffset, length)

    endOffset = endOffset + pad

    if endOffset > length then return end
    
    r.SetMediaItemInfo_Value(item, "D_LENGTH", endOffset)
    r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fade)
end

local function GoThroughMidiTakeByNotes(take, processCallback, isReverse)
    if take == nil or not r.TakeIsMIDI(take) then return end

    local note

    if isReverse then
        local _, notecnt, _, _ = r.MIDI_CountEvts(take)
        note = notecnt - 1
    else
        note = 0
    end

    local needStopSeeking = false

    while not needStopSeeking do
        local ret, _, muted, startppq, endppq, _, _, _ = r.MIDI_GetNote(take, note)

        if ret then
            local startTime = r.MIDI_GetProjTimeFromPPQPos(take, startppq)
            local endTime = r.MIDI_GetProjTimeFromPPQPos(take, endppq)

            if processCallback(muted, startTime, endTime) then
                needStopSeeking = true
            end
        end

        if isReverse then
            note = note - 1
        else
            note = note + 1
        end

        if not ret then
            needStopSeeking = true
        end
    end
end

function GetStartPositionOfMidiNote(take)
    if take == nil or not r.TakeIsMIDI(take) then return end

    local item = r.GetMediaItemTake_Item(take)
    local position =  r.GetMediaItemInfo_Value(item, "D_POSITION")

    local pos = 0

    GoThroughMidiTakeByNotes(take, function(muted, start_time, end_time)
        if not muted then
            local time = start_time - position

            if time < 0 and end_time - position >= 0 then
                pos = 0
                return true
            elseif time >= 0 then
                pos = time
                return true
            end
        end
    end)

    return pos
end

function GetEndPositionOfMidiNote(take)
    if take == nil or not r.TakeIsMIDI(take) then return end

    local item = r.GetMediaItemTake_Item(take)
    local position =  r.GetMediaItemInfo_Value(item, "D_POSITION")
    local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")

    local pos

    GoThroughMidiTakeByNotes(take, function(muted, start_time, end_time)
        if not muted then
            local time = end_time - position

            if time > length and start_time - position <= length then
                pos = length
                return true
            elseif time <= length then
                pos = time
                return true
            end
        end
    end, true)

    if not pos then pos = length end

    return pos
end

function GetLeadingPadAndOffset(startTime)
    if p.leading.pad.value > startTime then
        local corrected_pad = startTime - min_step
        return corrected_pad, p.leading.fade.value - (p.leading.pad.value - corrected_pad)
    else
        return p.leading.pad.value, p.leading.fade.value
    end
end

function GetTrailingPadAndOffset(endTime, itemLength)
    if p.trailing.pad.value + endTime > itemLength then
        local corrected_pad = itemLength - endTime - min_step
        return corrected_pad, p.trailing.fade.value - (p.trailing.pad.value - corrected_pad)
    else
        return p.trailing.pad.value, p.trailing.fade.value
    end
end