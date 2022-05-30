-- @description ek_Core functions
-- @author Ed Kashinsky
-- @about Base functions used by ek-scripts.
-- @version 1.0.0
-- @provides
--   ek_Core functions v1.lua
--   ek_Core functions GUI.lua
-- @changelog
--    - added core loader

function CoreLoadFunctions()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])

  dofile(script_path .. "ek_Core functions v1.lua")
  dofile(script_path .. "ek_Core functions GUI.lua")
end

CoreLoadFunctions()