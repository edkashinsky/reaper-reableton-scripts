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

This function has many useful perks that processed in real-time

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Global-Startup-Action)


### Smart Snap

<img src="/Assets/images/smart_snap.png" alt="smart_snap" width="400"/>

This script extremely useful for wokirng with markers and videos. It snaps selected items to markers or regions started from specified number.

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Smart-Snap)


### Toggle Docker

<img src="/Assets/images/toggle_docker.png" alt="Toggle Docker" width="400"/>

This script was inspired by Ableton’s workflow. It’s very convenient to be able to hide a docker with all the windows inside it with a single click, and just as convenient to show it again with another click. That’s exactly how this script works. Simple as that!

#### [Documentation](https://github.com/edkashinsky/reaper-reableton-scripts/wiki/Toggle-Docker)


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

