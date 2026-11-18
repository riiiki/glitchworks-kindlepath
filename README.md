# Kindlepath — Glitchworks

A 2D top-down puzzle-adventure prototype for PC and Android. The project draws its geometric art in GDScript and generates simple original ambient audio and sound effects in code, so it has no external asset dependencies.

## Open and run
1. Install Godot 4.7.2 (or another Godot 4.7.x stable release).
2. Extract this ZIP file.
3. Open Godot Project Manager → Import.
4. Select `project.godot` inside the extracted `glitchworks-kindlepath` folder.
5. Open the project and press F6 or F5.

## Controls
- PC: WASD or arrow keys to move; E or Space to activate a beacon; Esc to pause/resume.
- Android: use the lower-left virtual joystick to move and the lower-right ACT control to interact. The joystick and ACT button support separate simultaneous touch points.
- Mouse: click the on-screen buttons and ACT area.

## Features
- Three regions with collectibles, walls, moving shadow hazards, and beacons.
- Three lantern lives and a short post-hit invulnerability period.
- Procedurally generated collection, damage, beacon, and UI sounds.
- Distinct looping ambient tones for each region.
- Independent sound-effects and music toggles, plus master-volume controls.
- Settings menu with fullscreen toggle.
- Level selection; regions unlock as the player completes the previous region.
- Pause menu with Resume, Restart Region, and Main Menu.
- Game-over and victory screens with elapsed time and score.
- Persistent unlocked progress, best completion time, best score, volume, and audio preferences (`user://lantern_keeper_save.cfg`).
- Canvas-item stretching with aspect preservation for more consistent display scaling.

## Save data
Progress and settings are stored locally in Godot's `user://` directory. Removing the app's user data resets progress. No online account or network connection is used.

## Project structure
- `project.godot` — Godot project configuration and input actions
- `scenes/Main.tscn` — main scene
- `scripts/game.gd` — game logic, menus, generated audio, touch input, drawing, and save system
- `LANTERN_KEEPER_GDD.md` — game design document
- `TEST_CHECKLIST.md` — manual validation checklist

## Export
For PC: Project → Export → add a Windows Desktop preset.
For Android: install the Android build templates and configure the Android SDK/JDK in Editor Settings, then add an Android preset. This source project uses the GL Compatibility renderer. An APK has not been exported as part of this archive.

## Important validation note
The source has been updated for Godot 4.7.2, but this environment did not have a Godot executable or an Android device available. Please run the included `TEST_CHECKLIST.md` in Godot 4.7.2 and on the target Android device before treating the project as fully tested.


## Gameplay improvements in this build
- Lantern energy drains gradually; collecting motes restores energy.
- A checkpoint is activated as the player approaches the beacon area.
- Shadow enemies patrol, and some periodically pursue the player.
- Each region has a switch and sealed gate; interact near the switch to open it.
- Pushable crates, temporary speed boosts, and temporary protective shields are included.
- Level completion awards up to three stars based on remaining lives, energy, and time.

Controls: move with WASD/arrow keys or the Android virtual stick. Press E/Space or tap ACT to activate a nearby switch or beacon. Push crates by walking into them.


## Visual and code-structure update

This build adds procedural environment art for each region (winding paths, tree clusters, rocks, grass, flowers, and broken ruins), a procedural character idle/walk/damage presentation, glowing mote pulses, and particle bursts for collection, damage, switches, and beacon activation. The HUD now includes a clearer energy bar and region/mote progress.

Reusable rendering code is separated into:
- `scripts/environment_art.gd` — region environment rendering.
- `scripts/character_art.gd` — player character animation and drawing.
- `scripts/game.gd` — game flow, gameplay state, input, and HUD integration.

The gameplay controller still owns several systems in `game.gd`; this is a first refactoring step, not a complete component-based rewrite.


## Latest UI and difficulty update
- Added a dedicated How to Play tutorial page accessible from the main menu.
- Reworked the Settings page with a centered panel and wider, more readable controls.
- Increased shadow-wisp counts across all three regions and increased pursuit speed in later regions.
- Added clearer layered enemy silhouettes and glow effects.

Runtime note: this update has not yet been launched in the Godot editor; test the tutorial navigation, settings controls, and enemy collisions before exporting.


## Final gameplay polish
- Increased the player character's drawn size and added a stronger layered silhouette, hood/face detail, cloak folds, animated boots, and a lantern glow.
- Added three distinct enemy presentations and behaviors: drifting Wisps, periodically pursuing Stalkers, and territory-patrolling Guardians. Later regions increase pursuit pressure.
- Added a final Summit Guardian encounter: after collecting all motes and opening the gate, approach the guardian and press E/Space/ACT three times to calm it before using the beacon. The guardian can still damage the player on contact.
- Changed zero-energy handling so it applies one damage penalty per depletion event instead of repeatedly hitting the player every invulnerability cycle.
- Expanded the tutorial and manual checklist for the new enemy types and final encounter.

This is a source-level implementation. The project still requires Godot 4.7.2 runtime testing, plus Windows and Android device testing.
