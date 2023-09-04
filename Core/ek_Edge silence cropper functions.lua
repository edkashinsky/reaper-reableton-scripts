-- @noindex

p = {
	leading = {
		threshold = {
			key = 'triming_silence_leading_threshold',
			default = -22.0, -- db
            value = nil,
		},
        threshold_relative = {
			key = 'triming_silence_leading_threshold_relative',
			default = 10, -- %
            value = nil,
		},
		pad = {
			key = 'triming_silence_leading_pad',
			default = 0.12, -- s
            value = nil,
		},
		fade = {
			key = 'triming_silence_leading_fade',
			default = 0.08, -- s
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
			default = 4, -- %
            value = nil,
		},
		pad = {
			key = 'triming_silence_trailing_pad',
			default = 0.22, -- s
            value = nil,
		},
		fade = {
			key = 'triming_silence_trailing_fade',
			default = 0.25, -- s
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
        default = 0,
        value = nil,
    },
}

gui_config = {
    {
        type = gui_input_types.Combo,
		key = p.presets.key,
		title = "Presets",
		select_values = {
			"No preset", "Save preset...",
		},
		default = p.presets.default,
        on_change = function(val)
            if val == 1 then
                EK_AskUser("Save preset", {
                    {"Enter name of preset:", ""}
                }, function(res)
                    if not res or not res[1] then return end

                    Log(res[1], ek_log_levels.Debug)
                end)

                EK_SetExtState(p.presets.key, 0)
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

local r = reaper

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

function GetThresholdsValue()
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
    local db = 20 * log10(math.abs(sample))

    if db > 0 then return 0 else return db end
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
    local samples_per_channel = take_source_sample_rate / 2

    return aa, a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel
end

local function GoThroughTakeBySamples(take, processCallback, isReverse)
    if take == nil then return end

    local aa, a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel = GetDataForAccessor(take)

    -- Samples are collected to this buffer
    local buffer = r.new_array(samples_per_channel * take_source_num_channels)
    local total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)
    local offs, sample_count
    local needStopSeeking = false

    if total_samples < 1 then return end

    if isReverse then
        offs = aa_end - samples_per_channel / take_source_sample_rate
        sample_count = total_samples
    else
        offs = aa_start
        sample_count = 0
    end

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
            for i = 1, #buffer, take_source_num_channels do
                if (isReverse and sample_count == 0) or (not isReverse and sample_count == total_samples) then
                     goto done_start
                end

                for j = 1, take_source_num_channels do
                    local buf_pos = i + j - 1
                    local spl = buffer[buf_pos]
                    local pos_offset = offs + (buf_pos / (take_source_sample_rate * take_source_num_channels))
                    local db = spl > -1 and spl < 1 and SampleToDb(spl) or nil

                    if processCallback(db, pos_offset) then
                        goto done_start
                    end
                end

                if isReverse then
                    sample_count = sample_count - 1
                else
                    sample_count = sample_count + 1
                end
            end
        elseif aa_ret == 0 then -- no audio in current buffer
            if isReverse then
                sample_count = sample_count - samples_per_channel
            else
                sample_count = sample_count + samples_per_channel
            end
        else
            return
        end

        if isReverse then
            offs = offs - samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
            needStopSeeking = sample_count <= 0
        else
            offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
            needStopSeeking = sample_count >= total_samples
        end
    end -- end of while loop

    ::done_start::

    r.DestroyAudioAccessor(aa)

    return a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel
end

local rel_peacks_cache = {}
local function GetRelativeThresholdsByTake(take, rel_threshold)
    if take == nil then return end

    local maxPeak = -100
    local item = reaper.GetMediaItemTake_Item(take)
    local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)

    if rel_peacks_cache[guid] == nil then
        GoThroughTakeBySamples(take, function(db)
            if db > maxPeak then
                maxPeak = db
            end
        end)

        rel_peacks_cache[guid] = maxPeak
    else
        maxPeak = rel_peacks_cache[guid]
    end

    local abs_percent = 10 ^ (maxPeak / 40)

    local rel_db = 40 * log10(abs_percent * (rel_threshold / 100))

    -- Log(maxPeak .. " " .. round(abs_percent * 100) .. " " .. " " .. rel_threshold .. " " .. rel_db, ek_log_levels.Debug)

    return rel_db
end

function GetStartPositionLouderThenThreshold(take, threshold)
    if take == nil then return end

    local peakTime = 0

    if p.crop_mode.value == 1 then -- relative
        threshold = GetRelativeThresholdsByTake(take, threshold)
    end

    GoThroughTakeBySamples(take, function(db, pos_offset)
        if db > threshold then
            peakTime = pos_offset
            return true
        end
    end)

    return peakTime
end

function GetEndPositionLouderThenThreshold(take, threshold)
    if take == nil then return end

    local peakTime

    if p.crop_mode.value == 1 then -- relative
        threshold = GetRelativeThresholdsByTake(take, threshold)
    end

    local _, _, length = GoThroughTakeBySamples(take, function(db, pos_offset)
        if db > threshold then
            peakTime = pos_offset

            return true
        end
    end, true)

    if peakTime == nil then peakTime = length end

    return peakTime
end

local function GetOffsetConsiderPitchByRate(offset, rate)
    local semiFactor = 2 ^ (1 / 12) -- Rate: 2.0 = Pitch * 12
    local semitones = round(math.log(rate, semiFactor), 5)
    local curSemiFactor = 2 ^ ((1 / 12) * math.abs(semitones))

    -- reaper.ShowConsoleMsg(semitones .. "\n")

    return semitones > 0 and (offset * curSemiFactor) or (offset / curSemiFactor)
end

function CropLeadingPosition(take, startOffset)
    startOffset = startOffset - p.leading.pad.value
  
    if startOffset < 0 then return end
  
    local item = r.GetMediaItemTake_Item(take)
    local offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local startOffsetAbs = GetOffsetConsiderPitchByRate(startOffset, rate)

    -- reaper.ShowConsoleMsg(semitones .. " " .. startOffset .. " " ..  startOffsetAbs .. "\n")

    r.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset + startOffsetAbs)
    
    local position = r.GetMediaItemInfo_Value(item, "D_POSITION")
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", position + startOffset)
    
    local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length - startOffset)
    
    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", p.leading.fade.value)
end

function CropTrailingPosition(take, endOffset)
    endOffset = endOffset + p.trailing.pad.value
  
    local item = r.GetMediaItemTake_Item(take)
    local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")

    if endOffset > length then return end
    
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", endOffset)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", p.trailing.fade.value)
end

function GetThresholdsValues()
    local mode = p.leading.mode.value

    if mode == 0 then
        return p.leading.threshold.value, p.trailing.threshold.value
    else
        return p.leading.threshold_relative.value, p.trailing.threshold_relative.value
    end
end