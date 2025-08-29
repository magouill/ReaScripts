-- @description Lock Project to prevent opening same .RPP on different computers
-- @version 1.4
-- @author magouill
-- @about
--   Creates a .lock file in the project folder when opened.
--   If another REAPER instance (or computer via synced storage) tries to open,
--   it will refuse and show a warning.
--   Lock file is automatically removed when project/REAPER closes.

---------------------------------------
-- Project info
---------------------------------------

local _, fullPath = reaper.EnumProjects(-1, "")
if not fullPath or fullPath == "" then return end -- no project loaded

-- Extract folder and project name
local proj_path = fullPath:match("^(.*)\\") .. "\\"
local proj_name = fullPath:match("\\([^\\]+)$")
local lockFile  = proj_path .. proj_name .. ".lock"

---------------------------------------
-- Lock logic
---------------------------------------

local function createLock()
  local f, err = io.open(lockFile, "w")
  if f then
    f:write("LOCKED by " .. (os.getenv("COMPUTERNAME") or "UNKNOWN") .. " at " .. os.date() .. "\n")
    f:close()
  else
    reaper.ShowConsoleMsg("Failed to create lock file: " .. tostring(err) .. "\n")
  end
end

local function removeLock()
  os.remove(lockFile)
end

-- Check if already locked
if reaper.file_exists(lockFile) then
  reaper.ShowMessageBox("Someone's already working in this project!\n\n" .. lockFile, "Warning", 0)
  reaper.Main_OnCommand(40004, 0) -- Close project
else
  createLock()
  reaper.atexit(removeLock)
end
