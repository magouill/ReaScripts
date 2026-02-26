-- @description Link selected tracks FX parameters
-- @author SPK77, X-Raym, casrya; updated by magouill
-- @version 1.1
-- @about
--   Streamlined Links FX parameters of selected tracks if they share the same FX name.
--   Original idea and contributions by SPK77, X-Raym, casrya, Airon.

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------
reaper.set_action_options(1)

local NS = "LinkFXParams"

local _, _, sectionID, cmdID = reaper.get_action_context()
local toggleState = reaper.GetExtState(NS, "Running") == "1"

local function setToggle(state)
    reaper.SetToggleCommandState(sectionID, cmdID, state and 1 or 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    reaper.SetExtState(NS, "Running", state and "1" or "0", true)
end

-- Toggle script ON/OFF
if toggleState then
    -- Script already running, turn it OFF
    setToggle(false)
    return
else
    setToggle(true)
end

--------------------------------------------------
-- FX LINKING STATE
--------------------------------------------------
local last_param_number = -1
local last_val = -10000000

local function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
local function main()
    -- Stop if toggle turned off externally
    if reaper.GetExtState(NS, "Running") ~= "1" then
        setToggle(false)
        return
    end

    local ret, track_number, fx_number, param_number = reaper.GetLastTouchedFX()
    if ret then
        local track = reaper.CSurf_TrackFromID(track_number, false)
        if track and reaper.IsTrackSelected(track) then
            local val = reaper.TrackFX_GetParam(track, fx_number, param_number)
            val = round(val, 7)

            if param_number ~= last_param_number or val ~= last_val then
                last_param_number = param_number
                last_val = val

                local fx_name = select(2, reaper.TrackFX_GetFXName(track, fx_number, ""))

                for i = 0, reaper.CountSelectedTracks(0)-1 do
                    local tr = reaper.GetSelectedTrack(0, i)
                    for fx_i = 0, reaper.TrackFX_GetCount(tr)-1 do
                        local dest_fx_name = select(2, reaper.TrackFX_GetFXName(tr, fx_i, ""))
                        if dest_fx_name == fx_name then
                            reaper.TrackFX_SetParam(tr, fx_i, param_number, val)
                        end
                    end
                end
            end
        end
    end

    reaper.defer(main)
end

--------------------------------------------------
-- CLEANUP ON EXIT
--------------------------------------------------
reaper.atexit(function()
    setToggle(false)
end)

--------------------------------------------------
-- RUN
--------------------------------------------------
main()