# Lantern Keeper — Godot 4.7.2 test checklist

Run these checks in Godot 4.7.2 before submitting or exporting. This archive has been updated in source, but it has not been executed in a Godot runtime in this environment.

## Menus and navigation
- [ ] Title screen opens without parser/runtime errors.
- [ ] Begin Journey starts Region 1.
- [ ] Select Level shows Region 1 unlocked and later regions locked on a fresh save.
- [ ] Completing a region unlocks the next region; return to menu and verify selection.
- [ ] Settings opens and Back returns to the title screen.
- [ ] Escape pauses during gameplay and resumes from pause.

## Gameplay and audio
- [ ] WASD and arrow keys move the player.
- [ ] Walls block movement; player stays inside the world boundary.
- [ ] Collecting motes updates the counter and plays a collection sound.
- [ ] Touching a shadow costs one life and plays a damage sound; invulnerability prevents repeated hits.
- [ ] Activating a beacon before collecting all motes is refused.
- [ ] Activating a beacon after collecting all motes completes the region and plays a beacon sound.
- [ ] Each region starts its own ambient music.
- [ ] Sound effects and background music toggles work independently.
- [ ] Volume minus/plus changes audio loudness.

## End screens and persistence
- [ ] Pause menu has Resume, Restart Region, and Main Menu.
- [ ] Game-over screen displays elapsed time and score; Retry Region and Main Menu work.
- [ ] Victory screen displays completion time, score, best time, and best score.
- [ ] Close and reopen the game; unlocked regions and best results remain saved.
- [ ] Settings (volume and audio toggles) remain saved after restart.

## Desktop and Android
- [ ] Fullscreen toggle works on desktop; return to windowed mode.
- [ ] On Android, test joystick touch and ACT button with two fingers simultaneously.
- [ ] Confirm touch controls remain in their intended lower-screen areas on the target aspect ratio.
- [ ] Confirm buttons are tappable and text is readable on the target device.
- [ ] Export and launch a Windows build.
- [ ] Export and launch an Android APK on a physical device.

## Known testing boundary
The project source is prepared for Godot 4.7.2, but no Godot executable/device runtime was available during this edit. Android scaling, exported builds, and runtime audio behavior must be verified in the Godot editor and on the target device.


## Gameplay improvement tests
- [ ] Lantern energy decreases while playing and is restored by collecting motes.
- [ ] Reaching the beacon area activates a checkpoint; taking damage returns the player there.
- [ ] Patrol-type shadows move around their starting area.
- [ ] Pursuer-type shadows move toward the player during their chase phase.
- [ ] Interacting near the switch opens the sealed gate.
- [ ] The crate can be pushed and does not pass through walls.
- [ ] Speed power-up temporarily increases movement speed.
- [ ] Shield power-up prevents one hazard hit during its active period.
- [ ] Completion screen awards between one and three stars.


## Visual update checks
- [ ] Each region displays its own ground palette, winding path, trees, rocks, and ruins.
- [ ] Decorative objects do not block the player's route or cover important collectibles.
- [ ] Player idle animation is visible when standing still.
- [ ] Player walking animation is visible while moving in all directions.
- [ ] Damage flash/animation appears after touching a shadow.
- [ ] Mote collection produces a particle burst.
- [ ] Switch and beacon activation produce particle bursts.
- [ ] HUD energy bar and region/mote progress update correctly.
- [ ] Confirm visuals remain correctly scaled in a resized PC window and on an Android device.


## UI / difficulty additions
- [ ] Open How to Play from the main menu and verify Back to Menu works.
- [ ] Confirm Settings volume, sound, music, fullscreen, and Back controls are clickable.
- [ ] Confirm all three regions spawn the intended additional shadow wisps.
- [ ] Confirm later-region wisps pursue faster without trapping the player at spawn.
- [ ] Check UI scaling at 1280x720 and on an Android screen.


## Final polish additions
- [ ] Player model is clearly visible at normal gameplay zoom and remains above the environment.
- [ ] Wisp, Stalker, and Guardian enemy silhouettes are visually distinct.
- [ ] Wisps drift in wider, faster loops; Stalkers periodically pursue; Guardians patrol a smaller territory.
- [ ] Lantern energy reaching zero causes only one damage penalty until energy is restored.
- [ ] In Region 3, collecting all motes and opening the switch gate activates the Summit Guardian.
- [ ] Approach the Summit Guardian and press E/Space/ACT three times (with its cooldown) to calm it.
- [ ] The guardian can damage the player on contact; shields and invulnerability still work.
- [ ] The final beacon remains locked until the guardian is calmed.
- [ ] Tutorial explains the enemy types and final guardian encounter.


## Applied critical-fix and region tests
- [ ] Closed gates block the player from every approach direction; opening all required seals removes the collision.
- [ ] Crate pushing is blocked by walls, closed gates, and the moving obstacle.
- [ ] Grove pressure plate opens its gate when the crate is pushed onto it and ACT is pressed.
- [ ] Archive and Summit gates remain closed until both seals are activated.
- [ ] Checkpoint activates only when the player reaches the visible checkpoint marker; damage respawns at that marker.
- [ ] Tutorial's final instruction does not overlap Back to Menu at 1280x720.
- [ ] Archive moving obstacle moves along its route and blocks player movement without passing through the wall layout.
- [ ] Hidden memory bonus can be collected once per region and awards 300 points.
- [ ] Stalkers chase and then retreat; Guardians remain near their patrol territory.
- [ ] Summit Guardian shows a warning radius before its pulse, damages only within the pulse radius, and becomes vulnerable during recovery.
- [ ] Press ACT near the vulnerable Guardian during recovery to remove one seal; repeat for all three seals.
- [ ] Final beacon remains locked until the Guardian is calmed.
- [ ] Main menu opens the story, tutorial, settings, and credits screens.
- [ ] Story Continue starts Region 1; credits Back returns to the menu.
- [ ] Region-complete screen leads to the next region; final victory screen can open credits.

## Export and presentation checklist
- [ ] Add a Windows Desktop export preset in Godot 4.7.2 and install export templates.
- [ ] Export and launch the Windows build.
- [ ] If required, configure Android SDK/JDK, add an Android export preset, export an APK, and test on a physical device.
- [ ] Capture title screen, each region, tutorial, guardian encounter, victory, and credits screenshots.
- [ ] Record a short full-playthrough or feature demonstration after runtime testing.
