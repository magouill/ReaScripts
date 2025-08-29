-- @description Simple toggle input FX on all tracks
-- @version 1.6.1
-- @author magouill
-- @provides
--    [main] . > Toggle Input FX on all tracks

local UNDO_STATE_FX = 2 -- track/master fx
local FX_SLOT = 0x1000000 -- first input FX (slot 0)

reaper.Undo_BeginBlock()

local trackCount = reaper.CountTracks(0)

-- loop over all tracks
for ti = 0, trackCount - 1 do
  local track = reaper.GetTrack(0, ti)
  if track then
    local enabled = reaper.TrackFX_GetEnabled(track, FX_SLOT)
    if enabled ~= nil then
      -- inverted toggle: if enabled, disable; if disabled, enable
      reaper.TrackFX_SetEnabled(track, FX_SLOT, enabled)
      reaper.TrackFX_SetEnabled(track, FX_SLOT, not enabled)
    end
  end
end

reaper.Undo_EndBlock("Toggle Input FX on all tracks", UNDO_STATE_FX)
