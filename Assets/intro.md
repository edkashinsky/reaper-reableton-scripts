<p align="center">
   <img src="/Assets/images/logo.png" alt="Logo" width="300" />
</p>

This scripts makes Reaper a bit close to Ableton workflow. Also it brings useful things to save time.

# Installation

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

# Main useful scripts

### Pitch Tool

Pitch Tool is a script that allows you to adjust pitch quickly and flexibly. It inherits the convenient pitch workflow features from Ableton while also introducing its own unique enhancements for an even smoother experience.

<img src="/Assets/images/pitch_tool.png" alt="Global Functions preview" width="300"/>

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Pitch-Tool)


### Smart Renamer

This script allows for convenient context-aware renaming of objects in REAPER. It also offers advanced features for batch renaming using simple rules. As a bonus, it lets you change the color of selected elements.

<img src="/Assets/images/smart_renamer.png" alt="Global Functions preview" width="400"/>

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Smart-Renamer)


### Edge Silence Cropper

This script allows you to trim silence from the edges of items using individual thresholds. It significantly speeds up work with voiceovers, impacts, and other sounds that often have silent tails or heads — especially when dealing with large batches. It can be used alongside Reaper's built-in Dynamic Split for more precise timing adjustments without silence.

<img src="/Assets/images/edge_silence_cropper.png" alt="Global Functions preview" width="350"/>

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Edge-Silence-Cropper)


### Region Render Matrix Filler

Region Render Matrix Filler significantly speeds up the process of filling the Render Matrix in REAPER, especially in projects with a large number of regions. It’s particularly useful for tasks like layer-based sound rendering, gameplay VO synced to video, voiceover exports, and other scenarios where batch rendering is needed.

![Region Render Matrix Filler](/Assets/images/rrm_filler.png)

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Render-Region-Matrix-Filler)


### ElevenLabs SFX Generator

This script allows you to generate sounds via Eleven Labs directly from Reaper. Simply enter a prompt describing the sound you want to create - whether it’s the crackle of fire or an alarm signal on an orbital station. The script will generate the sound and insert it directly onto the timeline.

<img src="/Assets/images/elevenlabs_sfx_generator.png" alt="Global Functions preview" width="450"/>

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/ElevenLabs-SFX-Generator)


### Global startup action

<img src="/Assets/images/global_action_settings.png" alt="Global Functions preview" width="500"/>

This function has many useful perks that processed in real-time:

1. **Track working time on a project**. You can control how much time you spend on every particular project. It works automatically, when checkbox is enabled
2. **Automatically adjust grid to zoom**. When you change zoom level, grid adjusts to it. Also you can choose grid level like in Ableton (adaptive or fixed). For detailed control recommended to install 'ek_Adaptive grid settings' script
3. **Automatically limit zoom to size of project**. Max zoom level limits by the farthest item in the project.
4. **Automatically focus to MIDI editor when you click on an item**. When you single click on item, you see only one MIDI editor and focus on this particular item.
5. **Auto-Switch playback via selected track in Media Explorer**. If you use previewing in the "Play through the first selected track" mode in Media Explorer and want playback to follow the currently selected track.
6. **Automatically highlight buttons**. This option highlights toolbar buttons in real-time. This applies to scripts: 'ek_Toggle preserve pitch for selected items', 'ek_Toggle trim mode for selected trackes', 'ek_Toggle monitoring fx plugin'
7. **Toggle monitoring fx slots in exclusive mode**. If you use spectrum correction plugins (such as Realphones, Sonarworks Reference 4, SoundID Reference and etc.) on Monitoring FX when using headphones, you can always see if the plugin is enabled. For using it, add script 'ek_Toggle monitoring FX on slot 1-5' to your toolbar and this button will be highlighted automatically when the plugin on monitoring FX in particular slot is enabled.
8. **Different sample rate for recording**. This option useful for sound designers, who usually uses 48kHz and forget to increase the sampling rate before recording to get better recording quality.
9. **Dark mode theme**. If you want to turn on special dark theme in night hours, you can use this feature
10. **Additional global startup action**. If you have your own action on startup, you can specified command Id and it will be executed on startup.

For installation:
1. Install '**ek_Global startup action**' script via Extensions -> ReaPack -> Browse Packages
2. Execute script '**ek_Global startup action - settings**' in Action List and enable 'Enable global action' checkbox
3. Restart Reaper
4. Check script '**ek_Global startup action - settings**' again and enable features you need

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

### Separated actions for Media item in Mouse modifiers

This small script helps to attach 2 independent actions on media item click: on header and zone below of it. Script have 2 workflows depends on option "Draw labels above the item when media item height is more than":
- If option disabled, header label is positioned on item and header part calculates as header label height
- If option enabled, header label is positioned above the item and "header part" calculates as 1/4 of the upper part of the item

<img src="/Assets/images/separated_actions_for_media_item_preview.png" alt="Separated_actions_for_media_item_preview" />

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

### Snap items to markers or regions

This script extremely useful for wokirng with markers and videos. It snaps selected items to markers or regions started from specified number.

<img src="/Assets/images/pin_items_to_markers_or_regions.png" alt="pin_items_to_markers_or_regions" width="500"/>

It has 3 behaviours (You can see how it works shematically on pictograms in GUI): 
1. Simple - every item will be snapped to one marker, 
2. Stems - items on different tracks will be snapped to one marker in order of selection, 
3. Consider overlapped items - overlapped items will be joined to one stem and will be snapped to one marker 

You can set custom offset depends on your need: 
1. Beginning of leading item 
2. Snap offset of leading item 
3. First cue marker in leading item
4. Peak of leading item

Script gives posibility to limit markers/regions snapping. For example only 2 markers after specified.

Script requires ReaImGui, but also it has 2 useful additional scripts without GUI:
- ek_Snap items to closest markers
- ek_Snap items to closest regions

Installation:
1. Install script **ek_Snap items to markers or regions**
