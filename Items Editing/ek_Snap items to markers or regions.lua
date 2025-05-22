-- @description ek_Snap items to markers or regions
-- @version 1.1.6
-- @author Ed Kashinsky
-- @about
--   This script snaps selected items to markers or regions started from specified number. It requires ReaImGui extension.
--   It has 3 behaviours: simple, stems, consider overlapped items. You can see how it works shematically on pictograms in GUI
--   You can set custom offset depends on your need: just begin of item, snap offset, first cue marker, peak of item
--   Script gives posibility to limit markers/regions snapping. For example only 2 markers after specified.
-- @readme_skip
-- @changelog
--    UI updates
-- @provides
--   ../Core/data/snap-items_*.dat
--   ../Core/images/snap-items/*
--   [main=main] ek_Snap items to closest markers.lua
--   [main=main] ek_Snap items to closest regions.lua

local function CoreLibraryLoad(lib)
	local sep = package.config:sub(1,1)
	local root_path = debug.getinfo(1, 'S').source:sub(2, -5):match("(.*" .. sep .. ")")
	local version = string.match(_VERSION, "%d+%.?%d*")
	local dat_path = root_path .. ".." .. sep .. "Core" .. sep .. "data" .. sep .. lib .. "_" .. version .. ".dat"
	local file = io.open(dat_path, 'r')

	if file then file:close() dofile(dat_path) return true else return false end
end

if not CoreLibraryLoad("core") or not CoreLibraryLoad("snap-items") then
	reaper.MB('Core functions is missing. Please install "ek_Core functions" it via ReaPack (Action: Browse packages)', '', 0)
	reaper.ReaPack_BrowsePackages("ek_Core functions")
	return
end

SI_ShowGui()