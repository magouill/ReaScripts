-- @description Creates a .lock for every open project preventing multiple users from editing the same project.
-- @version 2.3
-- @author magouill
-- @about
--   Global lock system with:
--   - Multi-project support
--   - Crash-safe stale lock detection
--   - Cross-platform path normalization
--   - Immediate cleanup on REAPER exit

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local CHECK_INTERVAL = 60    -- seconds between scans
local STALE_TIMEOUT  = 21600 -- 6 hours (in seconds)

--------------------------------------------------
-- SCRIPT TOGGLE STATE (Action List ON indicator)
--------------------------------------------------
local _, _, sectionID, cmdID = reaper.get_action_context()

local function setToggle(state)
    reaper.SetToggleCommandState(sectionID, cmdID, state)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

setToggle(1) -- Show as ON

reaper.atexit(function()
    setToggle(0) -- Reset to OFF when script exits
end)

--------------------------------------------------
-- SYSTEM INFO
--------------------------------------------------
local computer =
    os.getenv("COMPUTERNAME") or
    os.getenv("HOSTNAME") or
    "UNKNOWN"

--------------------------------------------------
-- STATE
--------------------------------------------------
local activeLocks = {}
local lastCheck = 0

--------------------------------------------------
-- PATH NORMALIZATION
--------------------------------------------------
local function normalizePath(path)
    if not path or path == "" then return path end

    path = path:gsub("\\", "/") -- Convert backslashes
    path = path:gsub("/+", "/") -- Remove duplicate slashes
    
    if #path > 3 then
        path = path:gsub("/$", "") -- Remove trailing slash
    end

    return path
end

local function getLockFile(projPath)
    projPath = normalizePath(projPath)

    local proj_path, proj_name = projPath:match("^(.*)/(.-)$")
    if not proj_path or not proj_name then return nil end

    proj_name = proj_name:gsub("%.rpp$", "")
    return proj_path .. "/" .. proj_name .. ".lock"
end

--------------------------------------------------
-- LOCK HELPERS
--------------------------------------------------
local function parseLock(contents)
    local owner  = contents:match("LOCKED by ([^%s]+)")
    local stamp  = contents:match("TIME (%d+)")
    stamp = tonumber(stamp)
    return owner, stamp
end

local function isStale(timestamp)
    if not timestamp then return true end
    return (os.time() - timestamp) > STALE_TIMEOUT
end

--------------------------------------------------
-- CREATE LOCK
--------------------------------------------------
local function createLock(proj, projPath)
    local lockFile = getLockFile(projPath)
    if not lockFile then return end

    if reaper.file_exists(lockFile) then
        local f = io.open(lockFile, "r")
        local contents = f and f:read("*a") or ""
        if f then f:close() end

        local owner, stamp = parseLock(contents)

        if owner and owner ~= computer then
            if not isStale(stamp) then
                reaper.ShowMessageBox(
                    "Project is currently locked by:\n\n" .. owner ..
                    "\n\nPlease try again later.",
                    "Project Locked",
                    0
                )
                reaper.Main_OnCommand(40860, 0)
                return
            end
            -- If stale -> silently overwrite
        end
    end

    local f = io.open(lockFile, "w")
    if f then
        f:write("LOCKED by " .. computer .. "\n")
        f:write("TIME " .. os.time() .. "\n")
        f:close()
        activeLocks[proj] = lockFile
    else
        reaper.ShowConsoleMsg("[Lock] Failed to create: " .. lockFile .. "\n")
    end
end

--------------------------------------------------
-- REMOVE LOCK
--------------------------------------------------
local function removeLock(proj)
    local lockFile = activeLocks[proj]
    if not lockFile then return end

    if reaper.file_exists(lockFile) then
        local f = io.open(lockFile, "r")
        local contents = f and f:read("*a") or ""
        if f then f:close() end

        local owner = contents:match("LOCKED by ([^%s]+)")

        if owner == computer then
            os.remove(lockFile)
        end
    end

    activeLocks[proj] = nil
end

--------------------------------------------------
-- CLEANUP ON EXIT
--------------------------------------------------
reaper.atexit(function()
    for proj, _ in pairs(activeLocks) do
        removeLock(proj)
    end
end)

--------------------------------------------------
-- WATCH LOOP
--------------------------------------------------
local nextCheck = 0

local function watchProjects()
    local now = reaper.time_precise()

    if now >= nextCheck then
        nextCheck = now + CHECK_INTERVAL

        local newActive = {}

        local i = 0
        while true do
            local proj, path = reaper.EnumProjects(i, "")
            if not proj then break end

            if path and path ~= "" then
                path = normalizePath(path)
                newActive[proj] = path

                if not activeLocks[proj] then
                    createLock(proj, path)
                end
            end

            i = i + 1
        end

        -- Remove locks from closed projects
        for proj, _ in pairs(activeLocks) do
            if not newActive[proj] then
                removeLock(proj)
            end
        end
    end

    reaper.defer(watchProjects)
end

--------------------------------------------------
-- START
--------------------------------------------------
watchProjects()
