-- @description ek_Toggle mute and offline FX for selected tracks
-- @version 1.0.0
-- @author Ed Kashinsky
-- @about
--   This script makes fx offline when selected track is muted
  
reaper.Undo_BeginBlock()

local proj = 0

local function toggleFxOfflineOnTrack(track, is_disable)
  reaper.SetMediaTrackInfo_Value(track, "I_FXEN", is_disable and 0 or 1)
  reaper.SetMediaTrackInfo_Value(track, "B_MUTE", is_disable and 1 or 0)

  for j = 0, reaper.TrackFX_GetCount(track) - 1 do
    reaper.TrackFX_SetOffline(track, j, is_disable)
  end
end

for i = 0, reaper.CountSelectedTracks(proj) - 1 do
  local track = reaper.GetSelectedTrack(proj, i)
  local isFxDisabled = reaper.GetMediaTrackInfo_Value(track, "I_FXEN") == 0

  toggleFxOfflineOnTrack(track, not isFxDisabled)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Toggle mute and offline FX for selected tracks", 0)
