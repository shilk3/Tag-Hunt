# Tag Hunt

A 3D procedural-world game with a jetpack and a terrain-destruction tool.
Two modes:

- **Treasure Hunt** — single player, find treasures buried in the terrain. *(implemented)*
- **Tag / Tips** — multiplayer, catch and tag other players over LAN. *(implemented)*

Both modes share the core traversal loop: fly with a jetpack, dig through the
world with a radius-destruction tool (leaving tunnels/caves behind), and use
a radar to find your objective.

## Status

**Treasure Hunt** (single player):

- Bounded procedural voxel terrain (rolling hills, fully diggable/tunnelable)
- Jetpack flight (WASD + mouse look, vertical thrust with a fuel meter)
- Instant radius-removal dig tool (hold left click)
- Radar HUD showing direction, distance, and rough elevation to every buried
  treasure, plus a fuel bar and treasure counter
- Win state once all treasures are found

**Tag / Tips** (multiplayer, host/join over LAN or localhost):

- Same jetpack + dig-tool core loop, now with other players visible as
  colored capsules
- Host or join by IP from the Tag/Tips menu; terrain is generated
  identically on every peer from a shared fixed seed (no map transfer needed)
- Digging by any player replicates to everyone (client digs relay through
  the host)
- One player starts "it" (shown in red); touching another player within tag
  range transfers "it" status, with a short cooldown to prevent instant
  tag-back
- Radar shows other players' direction/distance/elevation instead of
  treasures; HUD banner shows who's currently it

Competitive treasure hunt, an infinite/streamed world, and an art/sound pass
are **not yet built** — see Roadmap below.

## Requirements

- [Godot Engine 4.3+](https://godotengine.org/download) (this project uses
  GDScript only, no C# build step required)

## Running it

1. Open Godot, choose "Import", and select `project.godot` in this folder.
2. Press `F5` (or click the Play button) to run. It starts at the main menu.
3. For Tag/Tips: one player clicks "Host Game", the other(s) enter the
   host's LAN IP address and click "Join Game". To test solo on one
   machine, run two instances of the exported build and join `127.0.0.1`.

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
4. For LAN play, players on the same network can join by IP directly.
   Playing over the internet would additionally need port forwarding
   (default port `8910`) or a relay — not set up here.

## Project structure

```
project.godot          Engine/project config, autoloads
scripts/
  input_setup.gd        Registers input actions in code (autoload)
  network_manager.gd     Host/join wrapper around ENet (autoload)
  voxel_world.gd          Terrain generation, chunk meshing, digging
  player.gd                Jetpack movement, mouse look, dig tool
  radar_display.gd          Shared radar widget (used by both HUDs)
  treasure.gd                Single treasure pickup behavior
  treasure_manager.gd       Spawns treasures, tracks collection/win state
  hud.gd                      Treasure Hunt HUD (fuel, treasures, radar)
  tag_hud.gd                   Tag/Tips HUD (it-status banner, radar)
  main_menu.gd                  Menu button wiring
  tag_menu.gd                    Host/Join screen wiring
  treasure_hunt.gd                Wires world/player/treasures/HUD together
  tag_arena.gd                     Wires world/players/tag logic/HUD, dig
                                    and tag-state replication over RPC
scenes/
  main_menu.tscn
  tag_menu.tscn
  treasure_hunt.tscn
  tag_arena.tscn
  player.tscn
  treasure.tscn
```

Terrain generation and world size are tunable via the exported properties on
the `VoxelWorld` node in `treasure_hunt.tscn`/`tag_arena.tscn`
(width/height/depth, chunk size, hill height/amplitude, noise frequency,
seed). Tag mode always uses a fixed seed so every peer generates the same
terrain independently.

## Roadmap / next steps

- **Competitive treasure hunt**: multiple players racing for the same
  treasure set, reusing the Tag/Tips networking layer plus per-player
  scoring.
- **World streaming**: current world is a bounded grid generated fully at
  start. An infinite world would need chunk streaming based on player
  position instead of building everything up front.
- **Terrain visuals**: current terrain is blocky (cube) voxels for
  reliability; smooth terrain (marching cubes/surface nets) is a possible
  later visual upgrade.
- **Internet play**: currently LAN/direct-IP only; a relay or NAT
  punch-through service would be needed for players on different networks.
- Sound, art pass, additional dig-tool feedback (particles/decals),
  player names/nameplates instead of raw peer IDs.
