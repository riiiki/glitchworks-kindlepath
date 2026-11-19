# LANTERN KEEPER
### 2D Top-Down Puzzle-Adventure | Godot 4.7.2
# Kindlepath — Glitchworks

## Project Overview

**Lantern Keeper** is a 2D top-down puzzle-adventure game developed with the Godot Engine. The player takes the role of the last Lantern Keeper, a traveler tasked with restoring light to a world that is slowly being consumed by darkness.

Across three regions, the player explores the environment, collects scattered light motes, solves simple environmental puzzles, avoids shadow creatures, and activates ancient beacons. Each region introduces a different layout and challenge, with difficulty increasing as the player progresses.

## Project Objectives

- Develop a playable 2D adventure game using Godot and GDScript.
- Demonstrate player movement, collision handling, interaction, and game-state management.
- Apply level progression through collectibles, switches, gates, checkpoints, and beacons.
- Provide keyboard controls for PC and touch controls for Android.
- Create a consistent visual style using procedural, code-drawn 2D art.

## Story and Gameplay

The world's ancient beacons have gone dark. As their light disappears, paths and memories begin to fade. The player must travel through three regions, recover their lost light motes, overcome each region's obstacles, and restore its beacon.

**Main gameplay sequence:**

1. Explore the current region.
2. Collect the required light motes.
3. Avoid shadow enemies and environmental hazards.
4. Activate switches or solve the region's puzzle to open the way forward.
5. Reach and activate the beacon to complete the region.
6. Continue to the next region until the final encounter is completed.

## Regions

| Region | Environment | Main challenge |
|---|---|---|
| The Quiet Grove | Forest paths, foliage, and ruins | Learn the controls and use a movable crate with a pressure plate to open the gate. |
| The Sunken Archive | Submerged ruins and stone pathways | Activate two seals while navigating a moving obstacle and shadow enemies. |
| The Last Summit | Mountain ruins under a violet twilight sky | Activate two seals, then face the Summit Guardian before reaching the final beacon. |

## Main Features

- **Three playable regions** with distinct environments, palettes, and increasing challenge.
- **Exploration and collection:** gather light motes and discover optional hidden memories.
- **Environmental puzzles:** interact with switches, seals, gates, pressure plates, and movable objects.
- **Enemy encounters:** Wisps patrol the area, Stalkers periodically pursue the player, and Guardians defend smaller territories.
- **Final encounter:** the Summit Guardian uses a warning-and-recovery pattern. The player must avoid its warning pulse and interact during its recovery window.
- **Player status:** three lantern lives, lantern energy, temporary protection, and collectible power-ups.
- **Checkpoints and progression:** checkpoints support region progress, while completed regions unlock further stages.
- **Menus and game flow:** opening story, tutorial, level selection, settings, pause, game-over, region-complete, victory, and credits screens.
- **Audio:** generated sound effects and region-specific ambient tones, with volume and audio options.
- **Local save data:** stores unlocked progress, best results, and player settings.
- **Cross-platform input:** keyboard and mouse on PC, plus on-screen touch controls for Android.
## Open and run
1. Install Godot 4.7.2 (or another Godot 4.7.x stable release).
2. Extract this ZIP file.
3. Open Godot Project Manager → Import.
4. Select `project.godot` inside the extracted `glitchworks-kindlepath` folder.
5. Open the project and press F6 or F5.

## Controls

| Action | PC | Android |
|---|---|---|
| Move | W, A, S, D or Arrow Keys | Use the virtual joystick at the lower-left of the screen. |
| Interact | E or Space | Tap the ACT button. |
| Pause / Resume | Esc | Use the on-screen Pause button. |

Use the interaction control near a switch, seal, beacon, or other interactive object. Some objectives only become available after the required collectibles or puzzle steps have been completed.

## Getting Started

### Requirements

- Godot Engine **4.7.2** (or a compatible Godot 4.7.x release).
- A Windows, macOS, or Linux computer for editor-based development.
- For Android deployment: Android export templates and a configured Android SDK/JDK.

### Open the project

1. Download and extract the project ZIP.
2. Open **Godot Project Manager**.
3. Select **Import**.
4. Browse to the extracted `LanternKeeper_Godot` folder and select `project.godot`.
5. Open the imported project.
6. Press **F6** to run the current scene or **F5** to run the project from its main scene.

## Project Structure

```text
LanternKeeper_Godot/
├── project.godot                 # Project settings and input configuration
├── README.md                     # Project overview and setup instructions
├── LANTERN_KEEPER_GDD.md         # Game design document
├── TEST_CHECKLIST.md             # Manual testing checklist
├── scenes/
│   └── Main.tscn                 # Main game scene
└── scripts/
    ├── game.gd                   # Game logic, UI, input, audio, and save handling
    ├── character_art.gd          # Player character drawing and animation
    └── environment_art.gd        # Region environment drawing
```

Most gameplay systems are coordinated by `scripts/game.gd`. Character and environment rendering are separated into their own scripts to make visual changes easier to manage.

## Save Data and Privacy

The game stores progress and settings locally through Godot's `user://` data directory, using the file `lantern_keeper_save.cfg`. The project does not require an online account or network connection for its core gameplay. Removing the game's local user data resets saved progress and preferences.

## Testing and Known Limitations

The project includes `TEST_CHECKLIST.md`, which should be used to verify navigation, controls, collisions, puzzle progression, enemy behavior, saving, and the three-region game flow.

**Testing status:** the source project has been updated for Godot 4.7.2, but it has not been runtime-verified in the Godot editor or tested on a physical Android device in the environment where this archive was prepared. Please run the checklist before presenting a final executable build. In particular, verify gate and obstacle collisions, touch input, checkpoint behavior, enemy interactions, and the final guardian encounter.

The ZIP contains the editable Godot project source. It does **not** include a pre-exported Windows executable or Android APK.

## Exporting the Game

- **Windows:** In Godot, open **Project → Export**, add a **Windows Desktop** preset, install the matching export templates if prompted, and export the project.
- **Android:** Install the matching export templates, configure the Android SDK/JDK in Godot's Editor Settings, add an **Android** preset, and export an APK or AAB as required.

Always test exported builds on their intended platforms before distribution or evaluation.

## Included Documentation

- `LANTERN_KEEPER_GDD.md` — concept, story, design goals, gameplay systems, and region descriptions.
- `TEST_CHECKLIST.md` — suggested manual test cases and validation steps.

---

**Project:** Lantern Keeper  
**Engine:** Godot 4.7.2  
**Genre:** 2D Top-Down Puzzle-Adventure  
**Platforms:** PC and Android (source configured; exported builds require platform setup)
