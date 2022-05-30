# Reableton - scripts for Reaper

This scripts makes Repear a bit close to Ableton workflow. Also it brings useful things to save time.

## Installation

1. Install [ReaPack](https://reapack.com)
2. Install [SMS Extension](https://sws-extension.org)
3. Restart Reaper
4. Open **Extensions** -> **ReaPack** -> **Browse Packages** and install common API extensions: 
   - js_ReaScriptAPI: API functions for ReaScripts
   - ReaImGui: ReaScript binding for Dear ImGui
5. Open **Extensions** -> **ReaPack** -> **Import Repositories**
6. Add this repository to the form
```
https://raw.githubusercontent.com/edkashinsky/reaper-reableton-scripts/master/index.xml
```
4. Done! You can find all new scripts in **Extensions** -> **ReaPack** -> **Browse Packages**
5. From time to time please execute **Extensions** -> **ReaPack** -> **Synchronize Packages** to get new versions of scripts.

## Main useful scripts

### Ableton Clip Shortcuts

One of the main thing is warping panel:  

<img src="https://cdn.discordapp.com/attachments/275712116315521035/922133416856678510/preview.png" width="450" />

1. **Mode** - ek_Change pitch mode for selected items
2. **Warp** - ek_Toggle preserve pitch for selected items
3. **-1 semi** - ek_Decrease pitch or rate for selected items
4. **+1 semi** - ek_Increase pitch or rate for selected items
5. **Clear** - ek_Clear pitch or rate for selected items

It works similar like in Ableton:

![Ableton Clip Shortcuts](/Assets/images/ableton_clip_shortcuts_demo.gif)

In two words, script changes pitch, if item has **preserve pitch** option and changes rate and length for selected items if items has this option off.

### Global functions

![Global Functions preview](/Assets/images/auto_grid_preview.gif)

This function has many useful perks that processed in real-time:

1. Auto grid update depending on zoom level in arrange view (like in Ableton)
2. Observing that project has only 5 last backup files (it removes older stuff). It only works if you use timestamp backups 
3. Observing of states of buttons (highlight when in needs)
4. Observing of project zoom is limiting by the farthest item (like in Ableton)
5. Observing that if you arm some track, project become 96khz
6. Observing selected midi items and focus it in one MIDI Editor (like in Ableton)

For installation:
1. Install this script via **Extensions** -> **ReaPack** -> **Browse Packages**
2. Open **Actions** -> **Action List**
3. Find "Script: ek_Global Startup Functions.lua" in list and select "Copy selected action command ID" by right mouse click
4. Open **Extensions** -> **Startup Actions** -> **Set Global Startup Action...** and paste copied command ID
5. Restart Reaper

### Theme

#### Flat Madness Dark Remix

The one of the most [impressive themes](https://forum.cockos.com/showthread.php?t=247086) for Reaper. I tuned a bit this theme to look it more like Ableton.

![Theme Preview](/Assets/images/theme_preview.png)

For installation:
1. Install [Fonts](/Assets/fonts/theme-fonts.zip?raw=true)
2. Open **Extensions** -> **ReaPack** -> **Browse Packages** and install "Flat Madness Dark Remix"

