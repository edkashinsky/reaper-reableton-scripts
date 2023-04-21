# Reableton - scripts for Reaper

This scripts makes Reaper a bit close to Ableton workflow. Also it brings useful things to save time.

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
7. Done! You can find all new scripts in **Extensions** -> **ReaPack** -> **Browse Packages**
8. Install script **ek_Core functions**, because many of scripts require this base script with common functions 
9. From time to time please execute **Extensions** -> **ReaPack** -> **Synchronize Packages** to get new versions of scripts.

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

<img src="/Assets/images/global_action_settings.png" alt="Global Functions preview" width="500"/>

This function has many useful perks that processed in real-time:

1. **Automatically adjust grid to zoom**. When you change zoom level, grid adjusts to it. Also you can choose grid level like in Ableton (adaptive or fixed)
2. **Automatically limit zoom to size of project**. Max zoom level limits by the farthest item in the project.
3. **Automatically focus to MIDI editor when you click on an item**. When you single click on item, you see only one MIDI editor and focus on this particular item.
4. **Automatically highlight buttons**. This option highlights toolbar buttons in real-time. This applies to scripts: 'ek_Toggle preserve pitch for selected items', 'ek_Toggle trim mode for selected trackes', 'ek_Toggle monitoring fx plugin'
5. **Toggle monitoring fx slots in exclusive mode**. If you use spectrum correction plugins (such as Realphones, Sonarworks Reference 4, SoundID Reference and etc.) on Monitoring FX when using headphones, you can always see if the plugin is enabled. For using it, add script 'ek_Toggle monitoring FX on slot 1-5' to your toolbar and this button will be highlighted automatically when the plugin on monitoring FX in particular slot is enabled.
6. **Different sample rate for recording**. This option useful for sound designers, who usually uses 48kHz and forget to increase the sampling rate before recording to get better recording quality.
7. **Automatic limit timestamp backup files**. Useful, if you want to keep only last limited amount of backup files.
8. **Dark mode theme**. If you want to turn on special dark theme in night hours, you can use this feature
9. **Additional global startup action**. If you have your own action on startup, you can specified command Id and it will be executed on startup.

For installation:
1. Install 'ek_Global startup action' script via **Extensions** -> **ReaPack** -> **Browse Packages**
2. Open **Actions** -> **Action List**
3. Find this script in list and select "Copy selected action command ID" by right mouse click
4. Open **Extensions** -> **Startup Actions** -> **Set Global Startup Action...** and paste copied command ID
5. Restart Reaper
6. Install and run 'ek_Global startup action settings' and configure the parameters you want to use

<img src="/Assets/images/auto_grid_preview.gif" alt="Global Functions preview" width="500"/>

### Edge silence cropper

This complicated script helps to crop silence on the edges of items by individual thresholds. It is very useful for sounds with loud start and quite long tails. Additionally, you can set offset and fade time. For instant work, there is one more script **ek_Edge silence cropper (no prompt)** - it apply cropping by remembered values.

![Edge silence cropper preview](/Assets/images/edge_silence_cropper_preview.png)

It has preview mode and it is very handy. Every setting has it own color:
- ![#1589F0](https://via.placeholder.com/15/1589F0/1589F0.png) Threshold - Blue 
- ![#f03c15](https://via.placeholder.com/15/f03c15/f03c15.png) Pad - Red 
- ![#c5f015](https://via.placeholder.com/15/c5f015/c5f015.png) Fade - Green

Installation:
1. Install script **ek_Edge silence cropper** for GUI and preview mode
2. [Additionally] install script **ek_Edge silence cropper (no prompt)** to applying crop without any GUI

### Separated actions for Media item in Mouse modifiers

This small script helps to attach 2 independent actions on media item click: on header and zone below of it. 

<img src="/Assets/images/separated_actions_for_media_item_preview.png" alt="Separated_actions_for_media_item_preview" width="400"/>

Installation:
1. Install script **ek_Separated actions for Media item in Mouse modifiers**
2. Execute it from Action list window. You will see small settings window. Choose command ids of actions you want to execute on header and zone below click
3. Open **Preferences** -> **Mouse modifiers**
4. Select **Media item** in Context and **left click**
5. Select this script in **Default action** in main section

### Save project with a check of unused media files

This helps to keep track of file garbage in your projects. It shows a special warning if you have unused files in the project when saving.

<img src="/Assets/images/save_project_check_unused.jpeg" alt="save_project_check_unused" width="281"/>

Installation:
1. Install script **ek_Save project with a check of unused media files**
2. Just attach it on Cmd/Ctrl+S instead of saving by default.

### Smart renaming depending on focus

The script helps to rename an unlimited number of elements of different types with one click. You can also change their color. In addition, script has advanced mode for replacing, additing, changing titles of elements.

<img src="/Assets/images/smart_renaming_depending_on_focus.jpeg" alt="save_project_check_unused" width="281"/>

InstallationL
1. Install script **ek_Smart renaming depending on focus**
2. Just attach it on Cmd/Ctrl+R instead of renaming by default.

### Theme

#### Flat Madness Remix

The one of the most [impressive themes](https://forum.cockos.com/showthread.php?t=247086) for Reaper (made by Dmytry Hapochka). I tuned a bit this theme to look it more like Ableton.

![Theme Preview](/Assets/images/theme_preview.png)

For installation:
1. Install [Fonts](/Assets/fonts/theme-fonts.zip?raw=true)
2. Open **Extensions** -> **ReaPack** -> **Browse Packages** and install "Flat Madness Dark Remix" or "Flat Madness Bright Remix"

