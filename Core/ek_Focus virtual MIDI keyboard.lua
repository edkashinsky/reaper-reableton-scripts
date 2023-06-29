-- @description ek_Focus virtual MIDI keyboard
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   Focus virtual MIDI keyboard

local commandId = 40377
local state = reaper.GetToggleCommandState(commandId)
local start_time = reaper.time_precise()
local delay = 0.2

local function execDefer()
    local current_time = reaper.time_precise()

    if current_time < start_time + delay then
        reaper.defer(execDefer)
        return
    end

    reaper.Main_OnCommand(commandId, 0)
end

if state == 1 then
    reaper.Main_OnCommand(commandId, 0)
    reaper.defer(execDefer)
else
    reaper.Main_OnCommand(commandId, 0)
end
