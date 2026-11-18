# LANTERN KEEPER
## Game Design Document — Final Project

### High concept
A 2D top-down puzzle-adventure in which a lone keeper restores light to three fading regions. Players collect scattered light motes, avoid roaming shadow creatures, and awaken each region's beacon.

### Design pillars
1. **Readable at a glance:** geometric silhouettes, strong contrast, clear collectibles and hazards.
2. **Simple but meaningful loop:** explore → collect → evade → reach beacon → progress.
3. **Atmospheric progression:** each region has a distinct palette, layout, and increasing challenge.
4. **Cross-platform controls:** keyboard/mouse on PC and touch controls on Android.

### Story
The world's ancient beacons have fallen dark. Without their light, paths and memories are disappearing. The player is the last Lantern Keeper, carrying a small flame between regions. By recovering lost motes and relighting each beacon, the keeper brings the world back from the edge of endless night.

### Core gameplay loop
- Explore the region.
- Collect every light mote.
- Avoid moving shadow wisps.
- Reach the beacon.
- Press E / Space or tap ACT to awaken it.
- Complete all three regions to restore the world.

### Controls
| Action | PC | Android |
|---|---|---|
| Move | WASD / arrow keys | Hold/drag lower-left virtual stick |
| Interact | E / Space | Tap ACT at lower-right |
| Pause/resume | Esc / Pause button | Pause button |

### Player and challenge systems
- Three lantern lives per run.
- Contact with a shadow costs one life and returns the keeper to the region's starting point.
- Losing all lives ends the run.
- The beacon cannot be activated until all motes in the region are collected.
- Three regions provide increasing collectible counts and denser obstacles.

### Level progression
| Region | Theme | Motes | Design focus |
|---|---|---:|---|
| 1. The Quiet Grove | Deep teal forest | 3 | Teach movement, collection, hazards, and beacon interaction |
| 2. The Sunken Archive | Blue submerged ruins | 4 | Add more obstacles and a more demanding route |
| 3. The Last Summit | Violet mountain twilight | 5 | Final challenge with denser hazards and a longer route |

### Visual direction
Flat vector / geometric art. The world uses large color fields, angular obstacles, glowing circular motes, polygonal shadow creatures, and a simple lantern-bearing keeper. All shapes are drawn in GDScript, avoiding external asset licensing and missing-file risks.

### Audio direction
The current prototype is intentionally asset-free and does not yet include music or sound effects. For the polish pass, create or source properly licensed:
- Soft ambient loop per region.
- A short bright pickup chime.
- A muted warning sound on shadow contact.
- A warm beacon activation sound.
- A subtle menu and button sound.

### Innovation and polish opportunities
- Lantern glow as a visibility / atmosphere mechanic.
- Mobile-friendly virtual joystick and action zone.
- Three themed regions with increasing challenge.
- Add a persistent best-time record and optional no-hit medal as a future extension.
- Accessibility: clear objective text, high-contrast motes, and keyboard/touch input options.

### Target audience
Casual players who enjoy short exploration and light puzzle challenges. Intended for quick sessions and easy live-demo comprehension.

### Scope and solo-development strategy
The project prioritizes one polished core loop over many unfinished systems. Three levels reuse a stable player, collectible, hazard, and beacon framework. Geometric art is generated in code so a solo developer can adjust the look without needing an asset pipeline.

### Five-minute live demo outline
1. **0:00–0:40 — Pitch:** explain the fading world, the Lantern Keeper, and the goal.
2. **0:40–1:20 — Controls:** demonstrate movement and explain PC / Android inputs.
3. **1:20–2:20 — Core loop:** collect motes, avoid a shadow, and show the counter/lives feedback.
4. **2:20–3:20 — Beacon:** activate a beacon after collecting everything and show the next region.
5. **3:20–4:20 — Progression:** briefly show the distinct palettes and rising challenge across three regions.
6. **4:20–5:00 — Bragging rights / Q&A:** explain code-drawn vector art, cross-platform controls, and the solo scope decisions.

### Known prototype limitations
- No music or sound effects are bundled yet.
- Level layouts are fixed rather than procedural.
- Save data, settings persistence, and level select are not implemented.
- Android APK and desktop builds must be exported using the team's configured Godot installation.

## Implemented polish systems (Godot 4.7.2 update)

The current source now includes generated sound effects and region-specific ambient loops, a local ConfigFile save for unlocked regions and best results, level selection, a settings screen, fuller pause/game-over/victory flows, score and time summaries, and separate multitouch IDs for the Android movement joystick and ACT control. The settings include master volume, sound/music toggles, and a desktop fullscreen toggle. These additions are implemented in `scripts/game.gd`; refer to `TEST_CHECKLIST.md` for required manual validation.

**Validation status:** source updated, but runtime validation and physical Android testing remain outstanding because a Godot 4.7.2 executable and Android device were not available during this edit.


## Visual presentation update
The three regions use distinct procedural palettes and decorative environments. The Grove uses layered foliage and natural paths; the Archive uses cooler stone and water-toned colors; the Summit uses darker ruins and warm accents. The player has procedural idle and walking cycles, a damage flash, and shield aura. Light motes pulse, and collection/switch/beacon events emit particle bursts.

## Code organization update
Environment rendering and player drawing are now reusable scripts (`environment_art.gd` and `character_art.gd`). The main controller still coordinates gameplay and UI; further extraction of player movement, enemies, level data, and menus is recommended as a later maintenance pass.

## Final polish: enemy identities and summit guardian

Shadow encounters use three enemy identities:
- **Wisp:** drifts through a broad, fast patrol loop.
- **Stalker:** periodically pursues the player, then pauses before its next chase.
- **Guardian:** holds a smaller patrol territory and visually reads as a heavier armored shadow.

In The Last Summit, collecting all light motes and activating the region switch awakens the Summit Guardian. The player must approach it and interact three times (E, Space, or ACT) to calm it, while avoiding contact damage. The final beacon can then be activated.

The player character is drawn larger with a stronger cloak silhouette, hood/face details, animated boots, and a lantern glow. Lantern energy depletion now applies a single damage penalty per depletion event rather than repeatedly damaging the player until energy is restored.
