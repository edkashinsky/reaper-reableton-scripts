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

### Global startup action

<img src="/Assets/images/global_action_settings.png" alt="Global Functions preview" width="450"/>

This function has many useful perks that processed in real-time:

1. **Automatically adjust grid to zoom**. When you change zoom level, grid adjusts to it.
2. **Automatically limit zoom to size of project**. Max zoom level limits by the farthest item in the project.
3. **Automatically focus to MIDI editor when you click on an item**. When you single click on item, you see only one MIDI editor and focus on this particular item.
4. **Automatically highlight buttons**. This option highlights toolbar buttons in real-time.
5. **Monitoring the plugin status on monitoring FX-chain**. If you use spectrum correction plugins (such as Realphones, Sonarworks Reference 4, SoundID Reference and etc.) on Monitoring FX when using headphones, you can always see if the plugin is enabled.
6. **Different sample rate for recording**. This option useful for sound designers, who usually uses 48kHz and forget to increase the sampling rate before recording to get better recording quality.
7. **Dark mode theme**. If you want to turn on special dark theme in night hours, you can use this feature
8. **Automatic limit timestamp backup files**. Useful, if you want to keep only last limited amount of backup files.

For installation:
1. Install 'ek_Global startup action' script via **Extensions** -> **ReaPack** -> **Browse Packages**
2. Open **Actions** -> **Action List**
3. Find this script in list and select "Copy selected action command ID" by right mouse click
4. Open **Extensions** -> **Startup Actions** -> **Set Global Startup Action...** and paste copied command ID
5. Restart Reaper
6. Install and run 'ek_Global startup action settings' and configure the parameters you want to use

![Global Functions preview](/Assets/images/auto_grid_preview.gif)

### Theme

#### Flat Madness Dark Remix

The one of the most [impressive themes](https://forum.cockos.com/showthread.php?t=247086) for Reaper (made by Dmytry Hapochka). I tuned a bit this theme to look it more like Ableton.

![Theme Preview](/Assets/images/theme_preview.png)

For installation:
1. Install [Fonts](/Assets/fonts/theme-fonts.zip?raw=true)
2. Open **Extensions** -> **ReaPack** -> **Browse Packages** and install "Flat Madness Dark Remix"

