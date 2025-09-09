-- @description Lock Project to prevent opening same .RPP on different computers
-- @version 1.5
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
    reaper.ShowConsoleMsg("No project open or path is nil.\n")
    return
end

-- normalize slashes
fullPath = fullPath:gsub("\\", "/")

-- split folder and filename
local proj_path, proj_name = fullPath:match("^(.*)/(.-)$")
if not proj_path or not proj_name then return end

-- lock file path
local lockFile = proj_path .. "/" .. proj_name:gsub("%.rpp$", "") .. ".lock"

---------------------------------------
-- Lock logic
---------------------------------------
local function createLock()
    local f = io.open(lockFile, "w")
    if f then
        f:write("LOCKED by " .. (os.getenv("COMPUTERNAME") or "UNKNOWN") .. " at " .. os.date() .. "\n")
        f:close()
    else
        reaper.ShowConsoleMsg("Failed to create lock file: " .. tostring(lockFile) .. "\n")
    end
end

local function removeLock()
    os.remove(lockFile)
end

-- check existing lock
if reaper.file_exists(lockFile) then
    reaper.ShowMessageBox("Someone's already working in this project!\n\nFuck outta here!", "Warning", 0)
    reaper.Main_OnCommand(40004, 0) -- Close project
    return
else
    createLock()
    reaper.atexit(removeLock)
end

---------------------------------------
-- Keep script alive to let REAPER exit handle cleanup
---------------------------------------
local function defer()
    reaper.defer(defer)
end

defer()
