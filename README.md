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
4. Done! You can find all new scripts in **Extensions** -> **ReaPack** -> **Browse Packages**
5. Install script **ek_Core functions**, because many of scripts require this base script with common functions 
6. From time to time please execute **Extensions** -> **ReaPack** -> **Synchronize Packages** to get new versions of scripts.

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

<img src="/Assets/images/separated_actions_for_media_item_preview.png" alt="Separated_actions_for_media_item_preview" width="500"/>

This small script helps to attach 2 independent actions on media item click: on header and zone below of it. 

Installation:
1. Install script **ek_Separated actions for Media item in Mouse modifiers**
2. Execute it from Action list window. You will see small settings window. Choose command ids of actions you want to execute on header and zone below click
3. Open **Preferences** -> **Mouse modifiers**
4. Select **Media item** in Context and **left click**
5. Select this script in **Default action** in main section

### Theme

#### Flat Madness Remix

The one of the most [impressive themes](https://forum.cockos.com/showthread.php?t=247086) for Reaper (made by Dmytry Hapochka). I tuned a bit this theme to look it more like Ableton.

![Theme Preview](/Assets/images/theme_preview.png)

For installation:
1. Install [Fonts](/Assets/fonts/theme-fonts.zip?raw=true)
2. Open **Extensions** -> **ReaPack** -> **Browse Packages** and install "Flat Madness Dark Remix" or "Flat Madness Bright Remix"


## List of scripts

#### ek_Add 1 sec gap between selected items

Script just adds 1 second gap between selected items without any GUI

#### ek_Change pitch mode for selected items

![Preview](/Assets/images/change_pitch_mode_preview.gif)

This script shows nested menu of all pitch modes for selected items right on the toolbar without "Item properties" window

#### ek_Clear pitch or rate for selected items

This script resets any pitch, rate and length info for selected items and makes as default

#### ek_Create crossfade on edges of items

This script creates crossfade on edges of tracks. It useful when you don't use overlap on crossfades for better precise but anyway want to create crossfades

Installation for better experience:
1. Open **Preferences** -> **Editing Behavior** -> **Mouse Modifiers**
2. In **Context** field choose **Media item edge** and **double click** in right one
3. Choose this script in field **Default action**
4. Done! It means that when you double click on edge between media items, you create crossfade between them

#### ek_Decrease pitch or rate for selected items

This script decreases pitch or rate of selected items depending on "Preserve Pitch" option.

If option is on, script decreases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)

If you hold special keys with mouse click, you get additional opportunities

Hotkeys:
- CMD/CTRL: Adjusting by 0.1 semitone (and 1 semitone without hotkey)
- SHIFT: You can enter absolute value for pitch

#### ek_Edge silence cropper (no prompt)

![Preview](/Assets/images/trim_silence_edges_preview.gif)

It removes silence at the start at the end of item without prompt. Using together with "ek_Trim silence at the edges of selected items"

#### ek_Edge silence cropper

This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.

Also it provides UI for configuration

#### ek_Increase pitch or rate for selected items

This script increases pitch or rate of selected items depending on "Preserve Pitch" option.

If option is on, script increases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)

If you hold special keys with mouse click, you get additional opportunities

Hotkeys:
- CMD/CTRL: Adjusting by 0.1 semitone (and 1 semitone without hotkey)
- SHIFT: You can enter absolute value for pitch

#### ek_Pin selected items at markers started from

![Preview](/Assets/images/pin_items_to_markers_preview.gif)
This script pins selected items to markers started from specified number. It requires ReaImGui extension.

#### ek_Separated actions for Media item in Mouse modifiers

This script gives opportunity to attach 2 different actions on Media item context in Mouse modifiers - when we click on header of media item and part between header and middle of it.
For installation open "Mouse Modifiers" preferences, find "Media item" context and select this script in any section. Also you can copy this script and use it in different hotkey-sections and actions.

#### ek_Switch to next pitch mode for selected items

This script helps to switch between pitch modes quicker just in one click.

Work with script ek_Switch to prev pitch mode for selected items.lua

#### ek_Switch to prev pitch mode for selected items

This script helps to switch between pitch modes quicker just in one click.

Work with script ek_Switch to next pitch mode for selected items.lua

#### ek_Toggle overlaping items vertically option

This script toggles option of editing multiple items on one track at the same time

#### ek_Toggle preserve pitch for selected items

![Preview](/Assets/images/prevent_pitch_preview.gif)

This script just toggle "Preserve Pitch" for selected items but it saves state for button. For example, if you select item and it has preserve option, button starts highlight.

For installation just add this script on toolbar and set "ek_Global Startup Functions" as global startup action via SWS.

#### ek_Auto grid for MIDI Editor

It changes grid depending on zoom level in MIDI Editor.
For installation:
1. Create custom action
2. Add to it:
- View: Zoom horizontally (MIDI relative/mousewheel)
- This script (ek_Auto grid for MIDI Editor)
3. Add to this custom script MultiZoom shortcut hotkey
4. Have fun!

#### ek_Move cursor or selected MIDI notes left by grid

If any note is selected, this script moves it to left by grid size. And move cursor by grid in other case

#### ek_Move cursor or selected MIDI notes right by grid

If any note is selected, this script moves it to right by grid size. And move cursor by grid in other case

#### ek_Move cursor or selected items left by grid

If any item is selected, this script moves it to left by grid size. And moves cursor by grid in other case

#### ek_Move cursor or selected items left by pixel

If any item is selected, this script moves to left it by pixel. And moves cursor by pixel in other case

#### ek_Move cursor or selected items right by grid

If any item is selected, this script moves it to right by grid size. And moves cursor by grid in other case

#### ek_Move cursor or selected items right by pixel

If any item is selected, this script moves it to right by pixel. And moves cursor by pixel in other case

#### ek_Move cursor to start of item under mouse

It just moves edit cursor to start of selected item

#### ek_Select items from selected to mouse cursor

This script extends selection of items from selected to mouse cursor. As usual this action attaches in mouse modifiers on media item section

#### ek_Select next non-tiny track

This script helps to navigate by tracks and shown envelopes by hotkeys.

I usually attach this script to down arrow and it goes down throw project and select next track/envelope lane if it visible

#### ek_Select prev non-tiny track

This script helps to navigate by tracks and shown envelopes by hotkeys.

I usually attach this script to up arrow and it goes up throw project and select previous track/envelope lane if it visible

#### ek_Smart horizontal zoom in

This script helps live with Project Limit option is on. It makes zoom available to places behind limits

#### ek_Smart horizontal zoom out

This script helps live with Project Limit option is on. It makes zoom available to places behind limits

#### ek_Toggle MIDI Editor window in arrange

It remember MIDI Editor button for toggling docker window in arrange view

For correct work please install ek_Toggle last under docker window

#### ek_Toggle MIDI Editor window

It remember MIDI Editor button for toggling docker window in MIDI Editor section

For correct work please install ek_Toggle last under docker window

#### ek_Toggle Media Browser window

It remember Media Browser button for toggling docker window

For correct work please install ek_Toggle last under docker window

#### ek_Toggle last under docker window

This script helps to join several windows (on one docker region as usual) to one shortcut for toggling view. It remembers last opened window and toggle it.

#### ek_Toggle monitoring fx plugin on slot 1

![Preview](/Assets/images/mfx_slots_preview.gif)

This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'

#### ek_Toggle monitoring fx plugin on slot 2

This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'

#### ek_Toggle monitoring fx plugin on slot 3

This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'

#### ek_Toggle monitoring fx plugin on slot 4

This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'

#### ek_Toggle monitoring fx plugin on slot 5

This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'

#### ek_Toggle random color for selected items or tracks

It changes color for items or tracks depending on focus

#### ek_Toggle render matrix window

It remember Render Matrix button for toggling docker window

For work please install ek_Toggle last under docker window

#### ek_Collapse selected tracks

It collapses selected tracks/envelope lanes between 3 states: small, large. Put height values you like to 'Extensions' -> 'Command parameters' -> 'Track Height A' (for small size) and 'Track Height B' (for large size)

#### ek_Delete selected tracks

If item has several takes and option "Show all takes in lane (when room)" is on, we gonna delete active take. If automation lane in focus, delete it. And in other case it deletes track and select previous available track

#### ek_Duplicate selected tracks or items

If any item is selected, it duplicate item. In other case is duplicate track

#### ek_Expand selected tracks

It expands selected tracks/envelope lanes between 2 states: small, large. Put height values you like to 'Extensions' -> 'Command parameters' -> 'Track Height A' (for small size) and 'Track Height B' (for large size)

#### ek_Insert new track

It just inserts track or inserts it in the end of list depending on situation

#### ek_Nudge volume for selected tracks down

It decrease volume for selected track a bit and shows tooltip with set volume

#### ek_Nudge volume for selected tracks up

It increase volume for selected track a bit and shows tooltip with set volume

#### ek_Rename selected tracks or takes

Renaming stuff for takes, items and tracks depending on focus

#### ek_Toggle mute and offline FX for selected tracks

This script makes fx offline when selected track is muted

#### ek_Toggle mute for selected tracks

This script toggles mute for selected tracks and makes fx online if it is offine

#### ek_Toggle single solo for selected tracks

Toggles selected track soloed

#### ek_Toggle trim mode for selected trackes

Toggles trim mode for selected tracks and shows current state as button highlight

