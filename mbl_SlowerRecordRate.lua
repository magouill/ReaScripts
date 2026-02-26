-- @description Slower Record Rate (forces normal rate when not recording)
-- @version 1.4
-- @author magouill
-- @about
--   Uses CUSTOM_RATE while recording.
--   Forces 1.0 master playrate when not recording.
--   Keeps Preserve Pitch enabled.

------------------------------------------------------------
-- USER SETTINGS
------------------------------------------------------------
local NS = "SlowerRecordRate"
local KEY = "CUSTOM_RATE"
local DEFAULT_RATE = 0.90

------------------------------------------------------------
-- INITIALIZE
------------------------------------------------------------
reaper.set_action_options(1)

local PRESERVE_CMD = reaper.NamedCommandLookup("40671")
local _, _, sectionID, cmdID = reaper.get_action_context()

CUSTOM_RATE = tonumber(reaper.GetExtState(NS, KEY)) or DEFAULT_RATE

-- Enable toolbar toggle
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

------------------------------------------------------------
-- CLEAN EXIT
------------------------------------------------------------
local function exit()
    reaper.CSurf_OnPlayRateChange(1.0)
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

reaper.atexit(exit)

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------
local prev_mode = "stopped"

local function main()
    local ps = reaper.GetPlayState()
    local recording = (ps & 4) == 4
    local playing   = (ps & 1) == 1
    local stopped   = ps == 0
    local current_rate = reaper.Master_GetPlayRate()

    if recording then
        reaper.CSurf_OnPlayRateChange(CUSTOM_RATE)
        prev_mode = "recording"
    elseif prev_mode == "recording" then
        if current_rate ~= 1.0 then
            CUSTOM_RATE = current_rate
            reaper.SetExtState("SlowerRecordRate", "CUSTOM_RATE", tostring(CUSTOM_RATE), true)
        end
    end
    if playing and not recording then
        reaper.CSurf_OnPlayRateChange(1.0)
    end

    reaper.defer(main)
end

main()
