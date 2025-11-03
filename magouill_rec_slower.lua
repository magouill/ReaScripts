-- @description Half-Speed Playback with Optional Recording (robust toggle)
-- @version 1.2
-- @author magouill
-- @about
--   Slows playback to CUSTOM_RATE while recording when SWS toggle is ON; 
--   restores normal rate for normal playback; inactive when toggle is OFF.

local CUSTOM_RATE = 0.65
local TOGGLE_CMD = "_S&M_CYCLACTION_1"
local toggle_id = reaper.NamedCommandLookup(TOGGLE_CMD)

local prev_recording = false
local prev_playing = false

function main()
    local toggle_on = reaper.GetToggleCommandStateEx(0, toggle_id) == 1
    local ps = reaper.GetPlayState()
    local recording = ps & 4 == 4
    local playing = ps & 1 == 1

    if toggle_on then
        if recording then
            -- Slow down only during active recording
            reaper.CSurf_OnPlayRateChange(CUSTOM_RATE)
        elseif playing and not recording and not prev_recording then
            -- Playback started normally (not recording) reset rate
            reaper.CSurf_OnPlayRateChange(1.0)
        end
    else
        -- Toggle OFF do nothing
    end

    prev_recording = recording
    prev_playing = playing
    reaper.defer(main)
end

main()