-- @description Global Project Lock Watcher (multi-project fix)
-- @version 2.2
-- @author magouill
-- @about
--   Works globally on REAPER startup.
--   Creates .lock file for every open project.
--   Supports multiple projects simultaneously.

local computer = os.getenv("COMPUTERNAME") or "UNKNOWN"

-- Track locks by project pointer
local activeLocks = {}

-- Helper to get lock file from project path
local function getLockFile(projPath)
    local proj_path, proj_name = projPath:match("^(.*)/(.-)$")
    if not proj_path or not proj_name then return nil end
    return proj_path .. "/" .. proj_name:gsub("%.rpp$", "") .. ".lock"
end

-- Create lock for a project
local function createLock(proj, projPath)
    local lockFile = getLockFile(projPath)
    if not lockFile then return end

    if reaper.file_exists(lockFile) then
        local f = io.open(lockFile, "r")
        local contents = f and f:read("*a") or ""
        if f then f:close() end

         -- Extract PC name from the lock file
        local otherPC = contents:match("LOCKED by ([^%s]+)")
        if otherPC and otherPC ~= computer then
            reaper.ShowMessageBox(
                "This project is already being worked on by: " .. otherPC .. 
                "\n\nFuck outta here!", 
                "Project Locked", 
                0
            )
            reaper.Main_OnCommand(40860, 0) -- Close current tab/project only
            return
        end
    end

    local f = io.open(lockFile, "w")
    if f then
        f:write("LOCKED by " .. computer .. " at " .. os.date() .. "\n")
        f:close()
        activeLocks[proj] = lockFile
    else
        reaper.ShowConsoleMsg("[Lock] Failed to create lock file: " .. lockFile .. "\n")
    end
end

-- Remove a lock
local function removeLock(proj)
    local lockFile = activeLocks[proj]
    if lockFile and reaper.file_exists(lockFile) then
        local f = io.open(lockFile, "r")
        if f then
            local contents = f:read("*a") or ""
            f:close()
            if contents:find(computer, 1, true) then
                os.remove(lockFile)
            end
        end
    end
    activeLocks[proj] = nil
end

-- Cleanup all locks on exit
reaper.atexit(function()
    for proj, _ in pairs(activeLocks) do
        removeLock(proj)
    end
end)

-- Main watcher loop
local knownProjects = {}

local function watchProjects()
    local newKnown = {}

    -- Enumerate all open projects
    local i = 0
    while true do
        local proj, path = reaper.EnumProjects(i, "")
        if not proj then break end
        if path and path ~= "" then
            path = path:gsub("\\", "/")
            newKnown[proj] = path
            -- New project not seen before
            if not knownProjects[proj] then
                createLock(proj, path)
            end
        end
        i = i + 1
    end

    -- Detect closed projects
    for proj, _ in pairs(knownProjects) do
        if not newKnown[proj] then
            removeLock(proj)
        end
    end

    knownProjects = newKnown
    reaper.defer(watchProjects)
end

watchProjects()
