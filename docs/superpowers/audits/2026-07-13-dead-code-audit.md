# Dead-Code Audit — 2026-07-13

Method: BFS reference walk from project.godot roots (script:
audit_refs.py, session scratchpad) + dynamic-path grep + config-surface
greps. Every item lists its evidence. Items here are CANDIDATES until
user approval.

The reference-walk script required one correctness fix before its output
could be trusted: it originally only resolved `res://` string literals and
`uid://` references, but this codebase uses GDScript's global `class_name`
mechanism pervasively (60+ scripts) for factory-dispatch (e.g.
`BallStateFactory`, `PlayerStateFactory`, `GameStateFactory`, `AIBehaviorFactory`
map enum values directly to bare class-name identifiers like `BallStateShot`,
never a `res://` path or `preload()`). Without resolving those identifiers to
the declaring file, the walk falsely orphaned 258/304 files, including
`flag_helper.gd` and, transitively, all 8 FlagHelper flag PNGs it loads via
`load(path)` from literal dict values — failing the brief's mandatory Step 2
sanity check. Fix: build a `class_name X -> res://...gd` map from all `.gd`
files, and treat any bare identifier match against that map (word-boundary
regex) the same as a resolved `uid://`. After the fix: 304 files, 275
reachable, 29 orphan candidates (down from 258), and both sanity checks
(FlagHelper's 8 flag paths + `scenes/soccer_game.tscn`) pass.

## Assets (prune commit 1)
- res://assets/art/brand/SFWPS-Horz-4C-white.png — unreachable in reference walk; no dynamic-load hits; zero grep hits for basename in scenes/utils/resources/project.godot (.import sidecar implied)
- res://assets/art/brand/sfpuc-soccer.ico — unreachable; project.godot `config/icon` points to `res://icon.svg`, not this file; no export_presets.cfg exists in the repo to reference it either; zero basename hits
- res://assets/art/characters/soccer-fplayer2.png — unreachable; `scenes/characters/player.tscn` loads `res://assets/art/characters/soccer-player.png` instead; zero basename hits (.import sidecar implied)
- res://assets/art/ui/1x1.png — unreachable; no dynamic-load hits; zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/menu-backgroundSF.png — unreachable; `scenes/screens/main_menu/main_menu_screen.tscn` uses `menu-backgroundSF-fitted.png` instead (superseded asset); zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/options-selected.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/options.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/title-sfpuc-hd-transparent.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/title-sfpuc-hd.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/title.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/art/ui/mainmenu/title2.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/art/ui/teamselection/tournament-screen.png — unreachable; `scenes/screens/team_selection/team_selection_screen.tscn` uses `team-selection-background.png` instead (superseded asset); zero basename hits (.import sidecar implied)
- res://assets/art/ui/teamselection/tournament-screen2.png — unreachable; zero basename hits (.import sidecar implied)
- res://assets/fonts/Daydream.ttf — unreachable; `game_theme.tres` / project.godot `theme/custom_font` only reference `Pixeled.ttf` (verified via uid `uid://yyvkod86gv2y`); zero basename hits (.import sidecar implied)
- "res://assets/fonts/Daydream 1.0 Personal License.txt" — license file for the orphaned Daydream.ttf above; no code/scene references it; zero basename hits

## Code (prune commit 2)
None found. Every `.gd` file in the project resolved as reachable after the
class_name-map fix above; no script (including every `class_name`-only
dispatched state/factory/behavior script) came up unreferenced.

## Settings (prune commit 3)
None found.
- Input actions: all 12 (`p1_left`, `p1_right`, `p1_up`, `p1_down`, `p1_pass`, `p1_shoot`, `p2_left`, `p2_right`, `p2_up`, `p2_down`, `p2_pass`, `p2_shoot`) return 1 file hit each in `*.gd`/`*.tscn` under scenes/utils — none are 0-hit.
- Physics layers: all 6 named layers in project.godot (`PitchWalls`=1, `Player`=2, `Ball`=4, `InvisibleWalls`=8, `ScoringArea`=16, `GoalKeeperHands`=32) have their bit set in at least one `collision_layer`/`collision_mask` value across `scenes/ball/ball.tscn`, `scenes/characters/player.tscn`, `scenes/goal/goal.tscn` (e.g. bit 1+6 in `collision_mask = 33`, bit 1+4 in `collision_mask = 9`) — none are unused.
- `grep -rni "quarter|worldcup|QF\b"` across scenes/utils: zero hits — no leftover 8-team/quarterfinal logic exists.
- Autoloads: all 5 (`DataLoader`: 5 files, `GameEvents`: 19 files, `GameManager`: 15 files, `SoundPlayer`: 14 files, `MusicPlayer`: 2 files) are referenced from code — none are dead.

## Kept despite looking dead (do NOT delete)
- res://default_bus_layout.tres — flagged as an orphan by the reference walk because it has no `res://` or `uid://` mention anywhere in project.godot, but this is Godot's implicit default value for the `audio/buses/default_bus_layout` project setting: Godot only writes that key into project.godot when it differs from the default, so the engine loads this file automatically from its well-known path at startup. Confirmed project.godot has no `[audio]` section and no `audio/buses/default_bus_layout` override key. Not a kill-list candidate.
