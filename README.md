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


## List of scripts

#### ek_Increase pitch or rate for selected items

This script increases pitch or rate of selected items depending on "Preserve Pitch" option.

If option is on, script increases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)

This script normally adds 1 semitone, but if you hold ctrl/cmd it adds 0.1 semitone

#### ek_Trim silence at the edges of selected items (no prompt)

![Preview](/Assets/images/trim_silence_edges_preview.gif)

It removes silence at the start at the end of item without prompt. Using together with "ek_Trim silence at the edges of selected items"

#### ek_Toggle preserve pitch for selected items

![Preview](/Assets/images/prevent_pitch_preview.gif)

This script just toggle "Preserve Pitch" for selected items but it saves state for button. For example, if you select item and it has preserve option, button starts highlight.

For installation just add this script on toolbar and set "ek_Global Startup Functions" as global startup action via SWS.

#### ek_Switch to prev pitch mode for selected items

This script helps to switch between pitch modes quicker just in one click.

Work with script ek_Switch to next pitch mode for selected items.lua

#### ek_Add 1 sec gap between selected items

Script just adds 1 second gap between selected items without any GUI

#### ek_Pin selected items at markers started from

![Preview](/Assets/images/pin_items_to_markers_preview.gif)
This script pins selected items to markers started from specified number. It requires [Lokasenna_GUI](https://github.com/jalovatt/Lokasenna_GUI)

#### ek_Decrease pitch or rate for selected items

This script decreases pitch or rate of selected items depending on "Preserve Pitch" option.

If option is on, script decreases pitch and change rate in other case. Also when rate is changing, length is changing too (like in Ableton)

This script normally subtracts 1 semitone, but if you hold ctrl/cmd it subtracts 0.1 semitone

Works with 'ek_Increase pitch or rate for selected items'

#### ek_Switch to next pitch mode for selected items

This script helps to switch between pitch modes quicker just in one click.

Work with script ek_Switch to prev pitch mode for selected items.lua

#### ek_Clear pitch or rate for selected items

This script resets any pitch, rate and length info for selected items and makes as default

#### ek_Toggle overlaping items vertically option

This script toggles option of editing multiple items on one track at the same time

#### ek_Create crossfade on edges of items

This script creates crossfade on edges of tracks. It useful when you don't use overlap on crossfades for better precise but anyway want to create crossfades

Installation for better experience:
1. Open **Preferences** -> **Editing Behavior** -> **Mouse Modifiers**
2. In **Context** field choose **Media item edge** and **double click** in right one
3. Choose this script in field **Default action**
4. Done! It means that when you double click on edge between media items, you create crossfade between them

#### ek_Trim silence edges for selected items

This script helps to remove silence at the start and at the end of selected items by individual thresholds, pads and fades.

Also it provides UI for configuration

#### ek_Change pitch mode for selected items

![Preview](/Assets/images/change_pitch_mode_preview.gif)

This script shows nested menu of all pitch modes for selected items right on the toolbar without "Item properties" window

#### ek_Move cursor or selected MIDI notes left by grid

If any note is selected, this script moves it to left by grid size. And move cursor by grid in other case

#### ek_Smart horizontal zoom in

This script helps live with Project Limit option is on. It makes zoom available to places behind limits

#### ek_Select next non-tiny track

This script helps to navigate by tracks and shown envelopes by hotkeys.

I usually attach this script to down arrow and it goes down throw project and select next track/envelope lane if it visible

#### ek_Smart horizontal zoom out

This script helps live with Project Limit option is on. It makes zoom available to places behind limits

#### ek_Move cursor or selected items right by pixel

If any item is selected, this script moves it to right by pixel. And moves cursor by pixel in other case

#### ek_Move cursor or selected items left by pixel

If any item is selected, this script moves to left it by pixel. And moves cursor by pixel in other case

#### ek_Move cursor or selected items right by grid

If any item is selected, this script moves it to right by grid size. And moves cursor by grid in other case

#### ek_Move cursor or selected MIDI notes right by grid

If any note is selected, this script moves it to right by grid size. And move cursor by grid in other case

#### ek_Select prev non-tiny track

This script helps to navigate by tracks and shown envelopes by hotkeys.

I usually attach this script to up arrow and it goes up throw project and select previous track/envelope lane if it visible

#### ek_Auto grid for MIDI Editor

It changes grid depending on zoom level in MIDI Editor.
For installation:
1. Create custom action
2. Add to it:
- View: Zoom horizontally (MIDI relative/mousewheel)
- This script (ek_Auto grid for MIDI Editor)
3. Add to this custom script MultiZoom shortcut hotkey
4. Have fun!

#### ek_Move cursor or selected items left by grid

If any item is selected, this script moves it to left by grid size. And moves cursor by grid in other case

#### ek_Toggle monitoring fx plugin

This script helps to watching for monitoring plugins (Realphones, Reference 4 and etc). You can see state of enabling plugin by state of button on your toolbar.

For installation just add this script on toolbar and set "ek_Global Startup Functions" as global startup action via SWS.

If you want to change Realphones for another plugin, please put in "ek_Headphones monitoring functions"

#### ek_Toggle random color for selected items or tracks

It changes color for items or tracks depending on focus

#### ek_Toggle last under docker window

This script helps to join several windows (on one docker region as usual) to one shortcut for toggling view. It remembers last opened window and toggle it.

#### ek_Toggle MIDI Editor window

It remember MIDI Editor button for toggling docker window in MIDI Editor section

For correct work please install ek_Toggle last under docker window

#### ek_Toggle MIDI Editor window in arrange

It remember MIDI Editor button for toggling docker window in arrange view

For correct work please install ek_Toggle last under docker window

#### ek_Toggle Media Browser window

It remember Media Browser button for toggling docker window

For correct work please install ek_Toggle last under docker window

#### ek_Toggle render matrix window

It remember Render Matrix button for toggling docker window

For work please install ek_Toggle last under docker window

#### ek_Collapse selected tracks

It collapses selected tracks/envelope lanes between 3 states: small, medium, large

#### ek_Toggle single solo for selected tracks

Toggles selected track soloed

#### ek_Expand selected tracks

It expands selected tracks/envelope lanes between 3 states: small, medium, large

#### ek_Toggle trim mode for selected trackes

Toggles trim mode for selected tracks and shows current state as button highlight

#### ek_Nudge volume for selected tracks up

It increase volume for selected track a bit and shows tooltip with set volume

#### ek_Rename selected tracks or takes

Renaming stuff for takes, items and tracks depending on focus

#### ek_Insert new track

It just inserts track or inserts it in the end of list depending on situation

#### ek_Delete selected tracks

If item has several takes and option "Show all takes in lane (when room)" is on, we gonna delete active take. And in other case it deletes track and select previous available track

#### ek_Duplicate selected tracks or items

If any item is selected, it duplicate item. In other case is duplicate track

#### ek_Nudge volume for selected tracks down

It decrease volume for selected track a bit and shows tooltip with set volume

