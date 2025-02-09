-- @description ek_Play preview in Media Editor
-- @author Ed Kashinsky
-- @noindex
-- @about This action starts preview playback in the Media Explorer if it is available
-- @readme_skip

local media_explorer = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer", 'common'), true)
if media_explorer then
    reaper.JS_Window_OnCommand(media_explorer, 1010) -- Preview: Pause
    reaper.JS_Window_OnCommand(media_explorer, 1008) -- Preview: Play
end