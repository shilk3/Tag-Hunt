# Tag Hunt

A 3D procedural-world game with a jetpack and a terrain-destruction tool.
Two planned modes:

- **Treasure Hunt** — single player, find treasures buried in the terrain. *(implemented)*
- **Tag / Tips** — multiplayer, catch and tag other players. *(not yet implemented)*

Both modes share the core traversal loop: fly with a jetpack, dig through the
world with a radius-destruction tool (leaving tunnels/caves behind), and use
a radar to find your objective.

## Status

This milestone implements a playable single-player **Treasure Hunt**:

- Bounded procedural voxel terrain (rolling hills, fully diggable/tunnelable)
- Jetpack flight (WASD + mouse look, vertical thrust with a fuel meter)
- Instant radius-removal dig tool (hold left click)
- Radar HUD showing direction, distance, and rough elevation to every buried
  treasure, plus a fuel bar and treasure counter
- Win state once all treasures are found

Tag/Tips, networking, competitive treasure hunt, art/sound pass, and an
infinite/streamed world are **not yet built** — see Roadmap below.

## Requirements

- [Godot Engine 4.3+](https://godotengine.org/download) (this project uses
  GDScript only, no C# build step required)

## Running it

1. Open Godot, choose "Import", and select `project.godot` in this folder.
2. Press `F5` (or click the Play button) to run. It starts at the main menu.

## Controls

| Action | Key |
| --- | --- |
| Move | `W A S D` |
| Look | Mouse |
| Jetpack thrust up | `Space` (consumes fuel, regenerates when not thrusting) |
| Descend | `Ctrl` |
| Dig (radius-remove terrain) | Hold `Left Mouse Button` |
| Release mouse / return to menu | `Esc` |

## Exporting a Windows build

1. In the Godot editor: **Editor → Manage Export Templates** and install the
   templates matching your engine version (one-time setup).
2. **Project → Export…** → **Add…** → **Windows Desktop**.
3. Click **Export Project**, choose a location, and Godot produces a
   standalone `.exe` that runs without the editor installed.

## Project structure

```
project.godot          Engine/project config, autoloads
scripts/
  input_setup.gd        Registers input actions in code (autoload)
  voxel_world.gd         Terrain generation, chunk meshing, digging
  player.gd               Jetpack movement, mouse look, dig tool
  treasure.gd              Single treasure pickup behavior
  treasure_manager.gd     Spawns treasures, tracks collection/win state
  hud.gd                    Fuel bar, treasure counter, radar, crosshair
  main_menu.gd              Menu button wiring
  treasure_hunt.gd          Wires world/player/treasures/HUD together
scenes/
  main_menu.tscn
  treasure_hunt.tscn
  player.tscn
  treasure.tscn
```

Terrain generation and world size are tunable via the exported properties on
the `VoxelWorld` node in `treasure_hunt.tscn` (width/height/depth, chunk
size, hill height/amplitude, noise frequency, seed).

## Roadmap / next steps

- **Tag/Tips mode**: needs networking. Godot's built-in high-level
  multiplayer API (`MultiplayerSpawner`/`MultiplayerSynchronizer` over ENet)
  is the natural fit and would reuse the same player/jetpack/dig code.
- **Competitive treasure hunt**: multiple players racing for the same
  treasure set — also needs the same networking layer, plus per-player
  scoring.
- **World streaming**: current world is a bounded grid generated fully at
  start. An infinite world would need chunk streaming based on player
  position instead of building everything up front.
- **Terrain visuals**: current terrain is blocky (cube) voxels for
  reliability; smooth terrain (marching cubes/surface nets) is a possible
  later visual upgrade.
- Sound, art pass, additional dig-tool feedback (particles/decals).
