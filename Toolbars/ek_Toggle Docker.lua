--[[
@author Ed Kashinsky
@description ek_Toggle Docker
@version 2.0.4
@about
   The script toggles the visibility of the selected docker window: it hides the window on the first run and shows it again on the next run. 
   The docker can contain any REAPER windows. The script provides four slot versions to support separate shortcuts for different dockers.
@changelog
    * Script monitors last visible window in docker
    * Improved stability and performance
    * Added documentation link
@metapackage
@readme_skip
@provides
    ../Core/data/toggle-docker_*.dat
    [main=main] ek_Toggle Docker (slot 1).lua
    [main=main] ek_Toggle Docker (slot 2).lua
    [main=main] ek_Toggle Docker (slot 3).lua
    [main=main] ek_Toggle Docker (slot 4).lua
]]--