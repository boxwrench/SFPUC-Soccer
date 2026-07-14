# SFPUC Super Soccer

A pixel-art arcade soccer game built in **Godot 4.4+**, customized for the
SFPUC with four teams: **Water, Power, Sewer, and Hetch Hetchy Water and
Power**. Based on the MIT-licensed video course
[*Create a Soccer Game in Godot!*](https://github.com/nicolasbize/soccer-course)
by Nicolas Bize.

## Features

- **Solo tournament:** four-team bracket (two semifinals → final)
- **Two-player local:** co-op (same team) or versus
- Two-button controls (Pass + Shoot) with charged shots, headers, volleys,
  and bicycle kicks
- CPU teammates and opponents driven by steering-behavior AI, plus a diving
  goalkeeper
- Full match flow: kickoff, goals, celebrations, resets, overtime, game over

## Play it (no install)

Grab the portable Windows build from
[**Releases**](https://github.com/boxwrench/SFPUC-Soccer/releases/latest):
download the zip, unzip anywhere, double-click `SFPUC-Super-Soccer.exe`.
Everything is packed into the one exe. (SmartScreen may warn because it's
unsigned — click **More info → Run anyway**.)

## Run it from source

1. Install [Godot 4.4+](https://godotengine.org) (standard build).
2. Clone this repo and open `project.godot` in Godot, then press **F5** —
   or on Windows, double-click `Launch SFPUC Soccer.vbs` (expects
   `godot.exe` on your PATH).

To build the portable exe yourself: install the Godot export templates
(Editor → Manage Export Templates), then run
`godot --headless --export-release "Windows Desktop"` — the preset in
`export_presets.cfg` writes `dist/SFPUC-Super-Soccer.exe` with the game
data embedded.

### Controls

| Action | Player 1 | Player 2 |
|---|---|---|
| Move | Arrow keys | WASD |
| Pass | `[` | `` ` `` |
| Shoot | `]` | `1` |

Hold Shoot to charge a harder shot. Press Pass without the ball to switch
to the teammate nearest the ball.

## Make it your own

The whole point of this repo is to be easy to re-skin for your own
organization. The four things to change are rosters, team colors, team
cards, and the name — all covered step-by-step in
[**SFPUC-Soccer-Game-Guide.md**](SFPUC-Soccer-Game-Guide.md), which also
walks through building the entire game from scratch alongside the original
video course.

Quick version:

- **Rosters:** edit `assets/json/squads.json` (names, roles, speed, power,
  skin tone `0`–`2`, and optional `"presentation": "female"` per player)
- **Team colors:** edit `assets/art/palettes/teams-color-palette.png`
  (one row per team; a shader recolors the shared spritesheet at runtime)
- **Team cards/flags:** replace the PNGs mapped in `utils/flag_helper.gd`
- **Name & title art:** Project Settings → Application → Config → Name,
  plus the title texture (`assets/art/ui/mainmenu/title-sfpuc-hd-menu.png`,
  referenced in `scenes/soccer_game.tscn`)

## Attribution

Game architecture, base art, and course by
[Nicolas Bize](https://github.com/nicolasbize/soccer-course) (MIT).
SFPUC customization by boxwrench. See [LICENSE](LICENSE).
