-- @description ek_Toggle mute for selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script toggles mute for selected tracks and makes fx online if it is offine
  
reaper.Undo_BeginBlock()

local proj = 0

local function toggleMuteOnTrack(track, is_disable)
  local isFxOffline = reaper.GetMediaTrackInfo_Value(track, "I_FXEN") == 0

  reaper.SetMediaTrackInfo_Value(track, "B_MUTE", is_disable and 1 or 0)

  if isFxOffline then
    reaper.SetMediaTrackInfo_Value(track, "I_FXEN", 1)

    for j = 0, reaper.TrackFX_GetCount(track) - 1 do
      reaper.TrackFX_SetOffline(track, j, 0)
    end
  end
end

for i = 0, reaper.CountSelectedTracks(proj) - 1 do
  local track = reaper.GetSelectedTrack(proj, i)
  local isMuted = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1

  toggleMuteOnTrack(track, not isMuted)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Toggle mute for selected tracks", 0)
