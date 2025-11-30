-- @description Custom-Speed Playback with Optional Recording (robust toggle)
-- @version 1.3
-- @author magouill
-- @about
--   Slows playback to CUSTOM_RATE while recording when SWS toggle is ON; 
--   restores normal rate for normal playback; inactive when toggle is OFF.

local CUSTOM_RATE = 0.75  -- initial default
local TOGGLE_CMD = "_S&M_CYCLACTION_1"
local toggle_id = reaper.NamedCommandLookup(TOGGLE_CMD)

local prev_recording = false
local prev_playing = false
local prev_toggle = false

function main()
    local toggle_on = reaper.GetToggleCommandStateEx(0, toggle_id) == 1
    local ps = reaper.GetPlayState()
    local recording = ps & 4 == 4
    local playing = ps & 1 == 1
    local current_rate = reaper.Master_GetPlayRate()

    -- If toggle is turned OF, reset playback rate to 1.0 once
    if (not toggle_on) and prev_toggle then
        reaper.CSurf_OnPlayRateChange(1.0)
    end

    if toggle_on then
        if recording and not prev_recording then
            -- Hit RECORD to update slow rate only if current_rate != 1.0
            if current_rate ~= 1.0 then
                CUSTOM_RATE = current_rate
            end
            reaper.CSurf_OnPlayRateChange(CUSTOM_RATE)
        elseif recording then
            -- Enforcing the saved slow rate during recording
            reaper.CSurf_OnPlayRateChange(CUSTOM_RATE)
        elseif playing and not recording and not prev_recording then
            -- Playback not recording then reset rate
            reaper.CSurf_OnPlayRateChange(1.0)
        end
    end

    prev_recording = recording
    prev_playing = playing
    prev_toggle = toggle_on

    reaper.defer(main)
end

main()
