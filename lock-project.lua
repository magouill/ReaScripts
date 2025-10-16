-- @description Lock Project to prevent opening same .RPP on different computers
-- @version 1.6
-- @author magouill
-- @about
--   Creates a .lock file in the project folder when opened.
--   If another REAPER instance tries to open, it will refuse.
--   Lock file is removed when project/REAPER closes.

---------------------------------------
-- Get current project pointer and path
---------------------------------------
local proj, fullPath = reaper.EnumProjects(-1, "")
if not fullPath or fullPath == "" then
    reaper.ShowConsoleMsg("No project open.\n")
    return
end

fullPath = fullPath:gsub("\\", "/")
local proj_path, proj_name = fullPath:match("^(.*)/(.-)$")
if not proj_path or not proj_name then return end

local lockFile = proj_path .. "/" .. proj_name:gsub("%.rpp$", "") .. ".lock"
local proj_ptr_str = tostring(proj)
local computer = os.getenv("COMPUTERNAME") or "UNKNOWN"

---------------------------------------
-- Lock helpers
---------------------------------------
local function createLock()
    local f = io.open(lockFile, "w")
    if f then
        f:write("LOCKED by " .. computer .. " (" .. proj_ptr_str .. ") at " .. os.date() .. "\n")
        f:close()
    else
        reaper.ShowConsoleMsg("[Lock] Failed to create lock file: " .. lockFile .. "\n")
    end
end

local function removeLock()
    local f = io.open(lockFile, "r")
    if f then
        local contents = f:read("*a") or ""
        f:close()
        if contents:find(proj_ptr_str, 1, true) then
            os.remove(lockFile)
        end
    end
end

---------------------------------------
-- Check existing lock
---------------------------------------
if reaper.file_exists(lockFile) then
    local f = io.open(lockFile, "r")
    local contents = f and f:read("*a") or ""
    if f then f:close() end

    if not contents:find(proj_ptr_str, 1, true) then
    reaper.ShowMessageBox("Someone's already working in this project!\n\nFuck outta here!", "Project Locked", 0)
        reaper.Main_OnCommand(40860, 0) -- Close current tab/project only
        return
    end
end

---------------------------------------
-- Create lock and monitor project
---------------------------------------
createLock()
local function loop()
    -- Check if this project still exists
    local stillOpen = false
    local i = 0
    while true do
        local p, path = reaper.EnumProjects(i, "")
        if not p then break end
        if p == proj then
            stillOpen = true
            break
        end
        i = i + 1
    end

    -- If project closed -> remove lock and stop
    if not stillOpen then
        removeLock()
        return -- stop loop
    end

    reaper.defer(loop)
end

loop()
