# Reableton - scripts for Reaper

This scripts makes Reaper a bit close to Ableton workflow. Also it brings useful things to save time.

## Installation

1. Install [ReaPack](https://reapack.com)
2. Install [SWS Extension](https://sws-extension.org)
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

1. **Track working time on a project**. You can control how much time you spend on every particular project. It works automatically, when checkbox is enabled
2. **Automatically adjust grid to zoom**. When you change zoom level, grid adjusts to it. Also you can choose grid level like in Ableton (adaptive or fixed). For detailed control recommended to install 'ek_Adaptive grid settings' script
3. **Automatically limit zoom to size of project**. Max zoom level limits by the farthest item in the project.
4. **Automatically focus to MIDI editor when you click on an item**. When you single click on item, you see only one MIDI editor and focus on this particular item.
5. **Automatically highlight buttons**. This option highlights toolbar buttons in real-time. This applies to scripts: 'ek_Toggle preserve pitch for selected items', 'ek_Toggle trim mode for selected trackes', 'ek_Toggle monitoring fx plugin'
6. **Toggle monitoring fx slots in exclusive mode**. If you use spectrum correction plugins (such as Realphones, Sonarworks Reference 4, SoundID Reference and etc.) on Monitoring FX when using headphones, you can always see if the plugin is enabled. For using it, add script 'ek_Toggle monitoring FX on slot 1-5' to your toolbar and this button will be highlighted automatically when the plugin on monitoring FX in particular slot is enabled.
7. **Different sample rate for recording**. This option useful for sound designers, who usually uses 48kHz and forget to increase the sampling rate before recording to get better recording quality.
8. **Automatic limit timestamp backup files**. Useful, if you want to keep only last limited amount of backup files.
9. **Dark mode theme**. If you want to turn on special dark theme in night hours, you can use this feature
10. **Additional global startup action**. If you have your own action on startup, you can specified command Id and it will be executed on startup.

For installation:
1. Install '**ek_Global startup action**' script via Extensions -> ReaPack -> Browse Packages
2. Execute script '**ek_Global startup action settings**' in Action List and enable 'Enable global action' checkbox
3. Restart Reaper
4. Check script '**ek_Global startup action settings**' again and enable features you need

### Adaptive grid

<img src="/Assets/images/auto_grid_preview.gif" alt="Global Functions preview" width="500"/>

Basically, 'Global startup action' controls adaptive grid, but if you want to have advanced control as in Ableton, you can install script 'ek_Adaptive grid settings'. It shows menu with grid settings and some options.

It's package script, here you are available some another scripts:
- **ek_Adaptive grid switch to next grid step, ek_Adaptive grid switch to prev grid step (and version for MIDI Editor)**. It quick solution to switch grid. Works by Option+1/2 in Ableton
- **ek_Adaptive grid settings (MIDI Editor)**. This is version menu for MIDI Editor

Options:
- **Synced with MIDI Editor**. Initially, grid in arrange view and in MIDI Editor is synced. If you change grid, it applies to both. But if you uncheck this option, grid becomes separated.
- **Set grid width ratio**. By this option, you can tweak threshold of changing grid depending on zoom level. Use number from 0 to infinite as scale ratio
- **Set grid limits**. By this option, you can set minimum and maximum grids. Works with adaptive grid

<img src="/Assets/images/adaptive_grid_settings.png" alt="Adaptive grid settings preview" width="270" />

For installation:
1. Install '**ek_Adaptive grid settings**' script via Extensions -> ReaPack -> Browse Packages
2. Attach this script to any toolbar

### Edge silence cropper

This complicated script helps to crop silence on the edges of items by individual thresholds. It is very useful for sounds with loud start and quite long tails. Additionally, you can set offset and fade time. For instant work, there is one more script **ek_Edge silence cropper (no prompt)** - it apply cropping by remembered values.

![Edge silence cropper preview](/Assets/images/edge_silence_cropper_preview.png)

It has preview mode and it is very handy. Every setting has it own color:
- ![#1589F0](https://via.placeholder.com/15/1589F0/1589F0.png) Threshold - Blue - leading threshold is searched in the forward direction from the start of item, and the trailing one in the reverse direction from the end
- ![#f03c15](https://via.placeholder.com/15/f03c15/f03c15.png) Pad - Red - offset from threshold position
- ![#c5f015](https://via.placeholder.com/15/c5f015/c5f015.png) Fade - Green - started from pad position

Script has an adaptive relative mode to get more accurate results with a single preset at different sound volumes:

![Edge silence cropper preview](/Assets/images/edge_silence_cropper/example_2.gif)

Script calculates the maximum peak (in db) in each item and applies a percentage of its volume to leading and trailing thresholds

Installation:
1. Install script **ek_Edge silence cropper** for GUI and preview mode

### Separated actions for Media item in Mouse modifiers

This small script helps to attach 2 independent actions on media item click: on header and zone below of it. 

<img src="/Assets/images/separated_actions_for_media_item_preview.png" alt="Separated_actions_for_media_item_preview" width="400"/>

Installation:
1. Install script **ek_Separated actions for Media item in Mouse modifiers**
2. Execute it from Action list window. You will see small settings window. Choose command ids of actions you want to execute on header and zone below click
3. Open **Preferences** -> **Mouse modifiers**
4. Select **Media item** in Context and **left click**
5. Select this script in **Default action** in main section

If you want to attach different actions on different mouse modifiers (for example, on left click, left drag or double click), please make copy of this script manually and add it with new unique name to Reaper (via Action list window: New action... -> Load ReaScript...) and put new script instance on new action in Mouse modifiers 

### Save project with a check of unused media files

This helps to keep track of file garbage in your projects. It shows a special warning if you have unused files in the project when saving.

<img src="/Assets/images/save_project_check_unused.jpeg" alt="save_project_check_unused" width="281"/>

Installation:
1. Install script **ek_Save project with a check of unused media files**
2. Just attach it on Cmd/Ctrl+S instead of saving by default.

### Smart renaming depending on focus

The script helps to rename an unlimited number of elements of different types with one click. You can also change their color. In addition, script has advanced mode for replacing, additing, changing titles of elements.

<img src="/Assets/images/smart_renaming_depending_on_focus.png" alt="smart_renaming_depending_on_focus" width="400"/>

Installation:
1. Install script **ek_Smart renaming depending on focus**
2. Just attach it on Cmd/Ctrl+R instead of renaming by default.

### Theme

#### Flat Madness Remix

The one of the most [impressive themes](https://forum.cockos.com/showthread.php?t=247086) for Reaper (made by Dmytry Hapochka). I tuned a bit this theme to look it more like Ableton.

![Theme Preview](/Assets/images/theme_preview.png)

For installation:
1. Install [Fonts](/Assets/fonts/theme-fonts.zip?raw=true)
2. Open **Extensions** -> **ReaPack** -> **Browse Packages** and install "Flat Madness Dark Remix" or "Flat Madness Bright Remix"


## List of scripts

#### ek_Add 1 sec gap between selected items

<img src="/Assets/images/add_gap_between_items.gif" alt="add_gap_between_items" width="500"/>

Script adds 1 second gap between selected items. Press CMD/CTRL to add 0.1 seconds gap.

#### ek_Create crossfade on edges of items

This script creates crossfade on edges of tracks. It useful when you don't use overlap on crossfades for better precise but anyway want to create crossfades

Installation for better experience:
1. Open **Preferences** -> **Editing Behavior** -> **Mouse Modifiers**
2. In **Context** field choose **Media item edge** and **double click** in right one
3. Choose this script in field **Default action**
4. Done! It means that when you double click on edge between media items, you create crossfade between them

#### ek_Delete selected items with color of item under mouse position

![Preview](/Assets/images/delete_selected_items_with_color_of_item_under_mouse_position.gif)
This script deletes selected items with the same color of item under mouse position

#### ek_Edge silence cropper

This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.

Also it provides UI for configuration

#### ek_Pin selected items at markers started from

![Preview](/Assets/images/pin_items_to_markers_preview.gif)
This script pins selected items to markers started from specified number. It requires ReaImGui extension.

#### ek_Pin selected items to closest markers

This script pins selected items to closest markers for first selected item. It requires script "ek_Pin selected items at markers started from.lua"

#### ek_Pitch Tool

Pitch tool brings Ableton workflow for pitch manipulations of audio clips.
- Change pitch mode for selected items menu
- Toggle preserve pitch for selected items
- Increase/Decrease pitch or rate for selected items
- Switch to prev/next pitch mode for selected items
- Clear pitch or rate for selected items

#### ek_Remove 1 sec gap between selected items

Script removes 1 second gap between selected items. Press CMD/CTRL to remove 0.1 seconds gap.

#### ek_Select items on track with color of item under mouse position

This script selects items with the same color and on same track of item under mouse position

#### ek_Separated actions for Media item in Mouse modifiers

This script gives opportunity to attach 2 different actions on Media item context in Mouse modifiers - when we click on header of media item and part between header and middle of it.
For installation open "Mouse Modifiers" preferences, find "Media item" context and select this script in any section. Also you can copy this script and use it in different hotkey-sections and actions.

#### ek_Smart split items by mouse cursor

Remake of amazing script by AZ and it works a bit different way. You can split by edit cursor if mouse position on it (or in Tolerance range in pixels).
If you move mouse on transport panel and execute script, you will see settings window

#### ek_Toggle group for selected items

This script makes group disable, if any selected item is grouped and otherwise if not.

#### ek_Toggle overlaping items vertically option

This script toggles option of editing multiple items on one track at the same time

#### ek_Move cursor or items pack

This package has many scripts which are making navigation in arrange view and at the same time are moving some items depends on selection

#### ek_Select items from selected to mouse cursor

This script extends selection of items from selected to mouse cursor. As usual this action attaches in mouse modifiers on media item section

#### ek_Smart horizontal zoom in

This script helps live with Project Limit option is on. It makes zoom available to places behind limits

#### ek_Smart horizontal zoom out

This script helps live with Project Limit option is on. It makes zoom available to places behind limits

#### ek_Toggle time selection by razor or selected items

This script toggle time selection by razor or selected items. Actually it works with loop points, so it supports behaviour when loop points and time selection is unlinked. Also it toggles transport repeat like in Ableton

#### ek_Tracks navigator

This package has 2 scripts "ek_Tracks navigator - go to prev track" and "ek_Tracks navigator - go to next track".
With these scripts you can navigate between non-tiny visible tracks and envelopes. You can attach scripts to arrow keys

#### ek_Toggle Docker

Toggle Docker tool allows you to have just one opened window in one docker. When you open another toggle docker window, current one closes.
Also you can switch last opened window by special scripts like "ek_Toggle Docker - toggle bottom window"

#### ek_Toggle monitoring FX

![Preview](/Assets/images/mfx_slots_preview.gif)

This script monitors a certain fx slot in the monitoring chain and switches the bypass on it. For realtime highlighting install 'Global startup action'

#### ek_Toggle random color for selected items or tracks

It changes color for items or tracks depending on focus

#### ek_Delete selected tracks

If item has several takes and option "Show all takes in lane (when room)" is on, we gonna delete active take. If automation lane in focus, delete it. And in other case it deletes track and select previous available track

#### ek_Duplicate selected tracks or items

If any item is selected, it duplicate item. In other case is duplicate track

#### ek_Insert new track

It just inserts track or inserts it in the end of list depending on situation

#### ek_Nudge volume for selected tracks down

It decrease volume for selected track a bit and shows tooltip with set volume

#### ek_Nudge volume for selected tracks up

It increase volume for selected track a bit and shows tooltip with set volume

#### ek_Set volume for selected tracks

Script shows window with input to set volume

#### ek_Smart renaming depending on focus

Renaming stuff for takes, items, markers, regions and tracks depending on focus

#### ek_Toggle mute and offline FX for selected tracks

This script makes fx offline when selected track is muted

#### ek_Toggle mute for selected tracks

This script toggles mute for selected tracks and makes fx online if it is offine

#### ek_Toggle single solo for selected tracks

Toggles selected track soloed

#### ek_Toggle trim mode for selected trackes

Toggles trim mode for selected tracks and shows current state as button highlight

#### ek_Tracks collapser

This package has 2 scripts "ek_Collapse selected tracks" and "ek_Expand selected tracks". They toggle selected tracks/envelope lanes between 3 states: small, medium, large.
Execute one of these scripts on transport panel and put height values there

## P.S.

If you like scripts, you can support me via [PayPal](https://www.paypal.com/paypalme/kashinsky) or subscribe on my [Soundcloud](https://soundcloud.com/edkashinsky).
