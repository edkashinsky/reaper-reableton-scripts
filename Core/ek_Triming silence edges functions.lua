-- @noindex

local debug = false

tsParams = {
	leading = {
		threshold = {
			key = 'triming_silence_leading_threshold',
			default = -22.0 -- db
		},
		pad = {
			key = 'triming_silence_leading_pad',
			default = 0.12 -- s
		},
		fade = {
			key = 'triming_silence_leading_fade',
			default = 0.08 -- s
		},
	},
	trailing = {
		threshold = {
			key = 'triming_silence_trailing_threshold',
			default = -55.0 -- db
		},
		pad = {
			key = 'triming_silence_trailing_pad',
			default = 0.22 -- s
		},
		fade = {
			key = 'triming_silence_trailing_fade',
			default = 0.25 -- s
		},
	},
    preview_result = {
        key = 'triming_silence_preview_result',
        default = true
    }
}

local r = reaper
local base_key = "ek_stuff"

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

function round(number, decimals)
  local power = 10 ^ decimals
  return math.floor(number * power) / power
end

function Debug(string)
	if debug then
		reaper.ShowConsoleMsg(string .. "\n")
	end
end
  
function getDataForAccessor(take)
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

function getStartPositionLouderThenThreshold(take, threshold)  
  if take == nil then return end
  
  local aa, a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel = getDataForAccessor(take)
  
  local peak = 0
  local peakTime = 0
  
  -- Samples are collected to this buffer
  local buffer = r.new_array(samples_per_channel * take_source_num_channels)
  local sample_count = 0
  local offs = aa_start
  local total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)

  if total_samples < 1 then return end
  
  -- Loop through samples
  while sample_count < total_samples do
    -- Get a block of samples from the audio accessor.
    -- Samples are extracted immediately pre-FX,
    -- and returned interleaved (first sample of first channel, 
    -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
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
        if sample_count == total_samples then
          audio_end_reached = true
          break
        end
      
        for j = 1, take_source_num_channels do
          local buf_pos = i + j - 1
          local spl = buffer[buf_pos]
          
          if spl > -1 and spl < 1 then
            local db = sample_to_db(spl)
          
            if db >= threshold then
              peak = db
              peakTime = offs + (buf_pos / (take_source_sample_rate * take_source_num_channels))
              
              goto done_start
            end
          end
        end
      
        sample_count = sample_count + 1
      end
    elseif aa_ret == 0 then -- no audio in current buffer
       sample_count = sample_count + samples_per_channel
    else
      return
    end
     
    offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
  end -- end of while loop
   
  ::done_start::
  
  r.DestroyAudioAccessor(aa)
  
  Debug("Start point detected: " .. round(peak, 2) .. "db " .. round(peakTime, 3) .. "s ".. "\n")
  
  return peakTime
end

function getEndPositionLouderThenThreshold(take, threshold)  
  if take == nil then return end
  
  local aa, a_length, aa_start, aa_end, take_source_sample_rate, take_source_num_channels, samples_per_channel = getDataForAccessor(take)
  
  local peak = 0
  local peakTime = 0
  
  -- Samples are collected to this buffer
  local buffer = r.new_array(samples_per_channel * take_source_num_channels)
  local offs = aa_end - samples_per_channel / take_source_sample_rate
  local total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)
  local sample_count = total_samples

  if total_samples < 1 then return end
  
  -- Loop through samples
  while sample_count > 0 do
    -- Get a block of samples from the audio accessor.
    -- Samples are extracted immediately pre-FX,
    -- and returned interleaved (first sample of first channel, 
    -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
    local aa_ret = r.GetAudioAccessorSamples(
      aa,                       -- AudioAccessor accessor
      take_source_sample_rate,  -- integer samplerate
      take_source_num_channels, -- integer numchannels
      offs,                     -- number starttime_sec
      samples_per_channel,      -- integer numsamplesperchannel
      buffer                    -- r.array samplebuffer
    )
    
    if aa_ret == 1 then
      local curPeak = nil
      local curPeakTime = nil
      
      for i = 1, #buffer, take_source_num_channels do
        if sample_count == 0 then
          audio_end_reached = true
          break
        end
      
        for j = 1, take_source_num_channels do
          local buf_pos = i + j - 1
          local spl = buffer[buf_pos]
          
          if spl > -1 and spl < 1 then
            local db = sample_to_db(spl)
          
            if db >= threshold then
              curPeak = db
              curPeakTime = offs + (buf_pos / (take_source_sample_rate * take_source_num_channels))
            end
          end
        end
      
        sample_count = sample_count - 1
      end
      
      if curPeakTime ~= nil then
        peak = curPeak
        peakTime = curPeakTime
        
        goto done_end
      end
      
    elseif aa_ret == 0 then -- no audio in current buffer
       sample_count = sample_count - samples_per_channel
    else
      return
    end
     
    offs = offs - samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
  end -- end of while loop
   
  ::done_end::
  
  r.DestroyAudioAccessor(aa)
  
  Debug("End point detected: " .. round(peak, 2) .. "db " .. round(peakTime, 3) .. "s ".. "\n")
  
  return peakTime
end

function getTsParamValue(param)
  local value = r.GetExtState(base_key, param.key)
  if value ~= '' then return tonumber(value) else return param.default end
end

function setTsParamValue(param, value)
  r.SetExtState(base_key, param.key, value, true)
end

function trimLeadingPosition(take, startOffset)
  startOffset = startOffset - getTsParamValue(tsParams.leading.pad)
  
  if startOffset < 0 then return end
  
  local item = r.GetMediaItemTake_Item(take)
    
  local offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
   
  r.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset + startOffset)
    
  local position = r.GetMediaItemInfo_Value(item, "D_POSITION")
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position + startOffset)
    
  local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length - startOffset)
    
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", getTsParamValue(tsParams.leading.fade))
end

function trimTrailingPosition(take, startOffset)
  startOffset = startOffset + getTsParamValue(tsParams.trailing.pad)
  
  local item = r.GetMediaItemTake_Item(take)
  local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  
  if startOffset > length then return end
  
  endOffset = length - startOffset
    
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length - endOffset)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", getTsParamValue(tsParams.trailing.fade))
end