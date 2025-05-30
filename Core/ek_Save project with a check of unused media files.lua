-- @description ek_Save project with a check of unused media files
-- @version 1.0.8
-- @author Ed Kashinsky
-- @about
--   This helps to keep track of file garbage in your projects. It shows a special warning if you have unused files in the project when saving.
-- @changelog
--   Small fix

function CoreFunctionsLoaded(script)
	local sep = (reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32") and "\\" or "/"
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local script_path = root_path .. ".." .. sep .. "Core" .. sep .. script
	local file = io.open(script_path, 'r')

	if file then file:close() dofile(script_path) else return nil end
	return not not _G["EK_HasExtState"]
end

local loaded = CoreFunctionsLoaded("ek_Core functions.lua")
if not loaded then
	if loaded == nil then
		reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
		reaper.ReaPack_BrowsePackages("ek_Core functions")
	end
	return
end

local i = 0
local file
local files = {}
local cached_found_files = {}
local ignored_files_key = "ignored_media_list"
local ignored_list = EK_GetExtState(ignored_files_key, {}, true)
local root = reaper.GetProjectPath()

local function SaveProject()
	reaper.Main_SaveProject(proj, false)
end

if reaper.IsProjectDirty(proj) == 0 then
	reaper.defer(SaveProject)
	return
end

while file ~= nil or i == 0 do
	file = reaper.EnumerateFiles(root, i)

	if file ~= nil and file:sub(0, 1) ~= "." then
		files[pathJoin(root, file)] = true
	end

	i = i + 1
end

for i = 0, reaper.CountMediaItems(proj) - 1 do
	local item = reaper.GetMediaItem(proj, i)

	for j = 0, reaper.CountTakes(item) - 1 do
		local take = reaper.GetMediaItemTake(item, j)

		if reaper.ValidatePtr(item, "MediaItem_Take*") then
			local source = reaper.GetMediaItemTake_Source(take)
			local take_file = reaper.GetMediaSourceFileName(source)

			if cached_found_files[take_file] == true then
				break
			end

			if files[take_file] == true then
				files[take_file] = nil
				cached_found_files[take_file] = true
				break
			end
		end
	end
end

local hasAnyUnusedFile = false
for path, _ in pairs(files) do
	if not ignored_list[path] then
		hasAnyUnusedFile = true
		break
	end
end

-- for do not disturbing
ignored_list = {}
for path, _ in pairs(files) do
	ignored_list[path] = true
end

EK_SetExtState(ignored_files_key, ignored_list, true)

if hasAnyUnusedFile then
	Log(files, ek_log_levels.Important)

	local res = reaper.MB("There are some unused files in the project. Open \"Project directory cleanup\" before save?\n\n If you press No, you just save project.", "Save project", 3)

	if res == 6 then -- YES
		reaper.Main_OnCommand(reaper.NamedCommandLookup(40098), 0) -- File: Clean current project directory...
		SaveProject()
	elseif res == 7 then -- NO
		reaper.defer(SaveProject)
	end
else
	reaper.defer(SaveProject)
end