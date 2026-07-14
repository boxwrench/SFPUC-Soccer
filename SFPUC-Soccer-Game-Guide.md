# SFPUC Super Soccer — Build Guide

A step-by-step guide to building a 2D arcade soccer game in **Godot 4.4+**, customized for the SFPUC with four teams: **Water, Power, Sewer, and Hetch Hetchy Water and Power**.

> 💡 **Beginner tip — the checkpoint tags are your safety net.** The course repo (see [Attribution & Resources](#attribution--resources) at the end) has a git tag for nearly every part below. If your project ever breaks and you can't figure out why, compare your files against the matching tag, or simply clone the tag and continue from there.

---

## What You'll Build

A pixel-art arcade soccer game ("SFPUC Super Soccer") featuring:

- **Solo mode:** a four-team tournament bracket (semifinals -> final)
- **Two-player local mode:** co-op (same team) or versus
- Two-button controls (Pass + Shoot), with charged shots, headers, volleys, and bicycle kicks
- CPU teammates and opponents driven by steering-behavior AI, plus a diving goalkeeper
- Full match flow: kickoff, goals, celebrations, resets, overtime, game over
- Menus, team selection, HUD, sound effects, and music

---

## The Teams

Use the official SFPUC/SFWPS logo unchanged for every team. The teams are differentiated only by their flag field and kit color.

| Team | Color | Approved hex | Flag and kit treatment |
|---|---|---|---|
| Water | Blue | `#007DC3` | Official logo on blue |
| Power | Yellow | `#FFB034` | Official logo on yellow |
| Sewer | Green | `#8DC63F` | Official logo on green |
| Hetch Hetchy Water and Power | Powder blue | `#7EC8E3` | Official logo on powder blue |

Tip: on the HUD, use the short label "Hetch Hetchy" or "HHWP" where space is tight — the font is tiny at 280×180 resolution.

Use **Franklin Gothic Book** for UI labels and **Minion Pro Regular** for tournament or formal copy. Reuse the original course art wherever it already fits (player sprites, pitch, goals, particles, and menu layout); create new art only for the rebrand.

The current repo already applies the SFPUC team palette and official-logo flag textures.
## Current Repository State

The active runtime assets and behavior are:

- Four teams: Water, Power, Sewer, and Hetch Hetchy Water and Power.
- A two-semifinal tournament followed by a final; the old quarterfinal art and nodes are not used.
- Official-logo team cards in both team selection and tournament brackets.
- Main-menu background: `assets/art/ui/mainmenu/menu-backgroundSF-fitted.png`.
- Tournament background: `assets/art/ui/teamselection/tournament-screen2-fitted.png`.
- Player-one and player-two control layouts use native-size, nearest-neighbor rendering for crisp text.
- Main-menu title: `assets/art/ui/mainmenu/title-sfpuc-hd-menu.png` (transparent, final display asset).
- Optional female presentation: set a player record's `presentation` value to `female`; the game uses `assets/art/characters/soccer-fplayer2-sheet.png` (6 columns x 13 rows, 192 x 416). The sheet is drawn in the exact palette source colors the `replace_color` shader matches, so female players get team colors and skin tones at runtime just like male players. The shipped rosters field half-female, half-male squads with mixed skin tones.

The matching editable raw artwork is kept as `menu-backgroundSF.png` and `soccer-fplayer2.png`. Raw editing sources for the title and tournament art live in `archive/raw-art/` (ignored by Godot via `.gdignore`, so they don't ship with the game). Intermediate conversions and superseded art are intentionally excluded from the repo.

This repo was dead-code audited on 2026-07-13 (see [`docs/superpowers/audits/2026-07-13-dead-code-audit.md`](docs/superpowers/audits/2026-07-13-dead-code-audit.md)); the audit found no dead code or dead settings, only unused assets, which were pruned or archived as noted above.

## Where This Repo Diverges From the Course

This repo is pruned to exactly what the shipped SFPUC game uses, so a few
things the videos build are intentionally absent here:

- **Country flags and 8-team assets** — replaced by the four SFPUC
  team cards; the quarterfinal round and its art are gone (4 teams need
  only semifinals → final).
- **The original `title.png` menu title art** — Part 23 builds the main
  menu with the course's title texture; this repo replaces it with the
  SFPUC title art described above (`title-sfpuc-hd-menu.png`), so
  `title.png` and `title2.png` aren't present here.
- **`Player.Role` enum order** — this repo's shipped `player.gd` leads with
  the goalie (`GOALIE=0, DEFENSE=1, MIDFIELD=2, OFFENSE=3`), not the
  `DEFENDER/MIDFIELDER/FORWARD` order the course videos build. `squads.json`'s
  `role` values follow this shipped order.
- **Player 2's shoot key** — moved off Tab to `1` (physical keycode) in this
  repo's Input Map, since Tab is unusable as a shoot key in browser exports.
- **Display settings** — this repo's `project.godot` ships with
  `viewport_width`/`viewport_height` = `1400`/`900` and Stretch Mode
  `canvas_items`, rather than Part 1.4's `280`×`180` viewport with a
  `1400`×`900` override and Stretch Mode `viewport`.
- **SubViewport texture filter** — the game world renders inside a
  `280`×`180` `SubViewport` in `scenes/soccer_game.tscn`, and this repo
  sets that node's `canvas_item_default_texture_filter` to `Nearest`.
  The project-level Nearest setting (Part 1.4 step 4) only applies to
  the root viewport — a SubViewport defaults to Linear, which blurs
  sprites at fractional camera offsets and silently breaks the
  `replace_color` shader's exact color matching (skin tones fall back
  to light while large flat kit areas still swap).

If you're following the videos and your build has something this repo
lacks, that's expected — the course repo's checkpoint tags
(https://github.com/nicolasbize/soccer-course/tags) remain the reference
for the un-pruned version.

---

# Section A: Building the Base Game

Work through these parts in order. Each part corresponds to one video in the series and roughly one checkpoint tag in the repo. **Commit to git after every part** — the commands are included.

## Part 1 — Project Setup (V01)

Video: https://www.youtube.com/watch?v=__ZAKUIjxy0

### 1.1 Install Godot and create the project

1. Download and install **Godot 4.4+** (latest stable) from https://godotengine.org.
2. In the Project Manager, click **Create**. Name it `sfpuc-soccer`. Choose a folder.
3. Set the renderer to **Compatibility** — required if you later want to publish a browser-playable version (e.g., on an internal site or itch.io).
4. Leave everything else at default and create the project.

### 1.2 Set up version control (Git + GitHub)

1. Install Git from https://git-scm.com. Beginners: use **GitHub Desktop** (GUI) instead of the command line if you prefer.
2. Create a free account at https://github.com (or use your organization's account).
3. Generate an SSH key and add it to your GitHub account (see GitHub's docs — takes about a minute).
4. On GitHub, click **New repository**. Name it `sfpuc-soccer`. Add a README, a `.gitignore` using the **Godot** template, and an MIT license.
5. Copy the SSH URL from the **Code** button, then run: `git clone <your-ssh-url>`
6. Quit Godot. Move the contents of your Godot project folder into the cloned git folder; delete the now-empty original folder.
7. Reopen Godot, click **Import**, and select the git folder.
8. Commit your starting point:
   ```
   git add -A
   git commit -m "empty godot project"
   git push origin main
   ```

### 1.3 Configure the editor for 2D work

1. Go to **Editor > Manage Editor Features**. Create a new profile named `2D`.
2. Uncheck: **3D Editor, Asset Library, History dock, Node3D**. This hides 3D clutter you won't need.

### 1.4 Configure project settings

1. Open **Project > Project Settings** and enable **Advanced Settings**.
2. **Display > Window:** Width = `280`, Height = `180` (the pixel-art resolution). Width Override = `1400`, Height Override = `900` (a 5× upscale for the actual window).
3. **Stretch Mode** = `viewport`; **Scale Mode** = `integer` (keeps pixels perfectly square).
4. **Rendering > Textures:** Default Texture Filter = `Nearest` (prevents blurry pixel art). Note: this setting only covers the root viewport — if the game later renders inside a `SubViewport` (as this repo's `scenes/soccer_game.tscn` does), set that node's **Canvas Item Default Texture Filter** to `Nearest` too, or sprites blur and the palette-swap shader's exact color matching quietly fails.

### 1.5 Import game assets

1. Download `soccer-assets.zip` from the V01 video description (or pull the `assets/` folder from the course repo).
2. Unzip and drag the `assets` folder into Godot's **FileSystem** panel. This brings in art, fonts, music, and SFX.
3. Commit: `git add -A && git commit -m "added game assets" && git push origin main`

### 1.6 Create the World scene

1. Click **2D Scene** in the Scene panel. Press `F2`, rename it `World`.
2. Press `Ctrl+S`. Create a `scenes/` folder and save as `world.tscn`.
3. Press `F5` to run; select **current scene** when prompted.

### 1.7 Build the pitch background (3 sprite layers)

1. In the World scene, press `Ctrl+A` > **Node2D**. Rename it `backgrounds`.
2. Add a child **Sprite2D** named `grass`. Texture = `pitch_background.png`. Uncheck **Centered**. Modulate = `#84CD2A` (base green).
3. Add a child **Sprite2D** named `pattern`. Texture = `pitch_pattern.png`. Uncheck Centered. Modulate = `#498B00` (darker lawnmower stripes).
4. Add a child **Sprite2D** named `lines`. Texture = `pitch_lines.png`. Uncheck Centered. Modulate = `#F0F0F0` (off-white lines).
5. Press `F5` to verify, then commit.

*Stuck? Watch from 22:30 in V01.*

### 1.8 Create the Player scene

**Why CharacterBody2D?** Players need 2D position, collision detection while moving, and fine movement control. `CharacterBody2D` has built-in move-and-slide. (The ball will instead use `AnimatableBody2D` — it needs to bounce, not slide.)

1. Scene panel **+** > New Scene > **Other Node** > `CharacterBody2D`. Rename it `player`.
2. Save to `scenes/characters/player.tscn`.
3. Add a child **Sprite2D** named `player_sprite`. Texture = `soccer_player.png`. Uncheck Centered.
   - Animation properties: **HFrames = 6, VFrames = 13** (6 columns × 13 rows in the spritesheet).
4. On the root, enable **Y Sort Enabled** (Ordering section) so overlapping players depth-sort correctly.

*Stuck? Watch from 27:45 in V01.*

## Part 2 — Basic Movement (V02)

Video: https://youtu.be/fW3VAX5n9ks

### 2.1 Set up the AnimationPlayer

1. In the player scene, add a child **AnimationPlayer** node.
2. Create a `walk` animation (looping): keyframe the `player_sprite` **frame** property starting at frame 6 (spritesheet row 2), 6 frames, ~8 FPS.
3. Create a `tackle` animation: starts at frame 30, 6 frames, looping.

### 2.2 Set up the Input Map

**Project > Project Settings > Input Map.** Add:

| Action | Player 1 | Player 2 |
|---|---|---|
| left / right / up / down | Arrow keys (`p1_left`, etc.) | WASD (`p2_left`, etc.) |
| pass | `[` → `p1_pass` | `~` → `p2_pass` |
| shoot | `]` → `p1_shoot` | `1` → `p2_shoot` |

Tip: keep pass/shoot keys far from the directional keys to avoid mid-game finger conflicts.

### 2.3 Write the player script

1. Attach a GDScript to the player root. Key variables:
   ```gdscript
   @export var speed: float = 60.0
   @onready var anim_player = %AnimationPlayer
   ```
2. In `_physics_process(delta)`:
   ```gdscript
   var input_dir = Input.get_vector("p1_left", "p1_right", "p1_up", "p1_down")
   velocity = input_dir * speed
   move_and_slide()
   if velocity.length() > 0:
       anim_player.play("walk")
   else:
       anim_player.play("idle")
   ```
3. `F5` to confirm the player moves and animates.

### 2.4 Add a ControlScheme system (human + CPU on one script)

1. Create `globals/utils.gd` and register it as an **AutoLoad** (Project Settings > AutoLoad, name `Utils`).
2. In `utils.gd`:
   ```gdscript
   enum ControlScheme { PLAYER_ONE, PLAYER_TWO, CPU }
   const ACTIONS = {
       ControlScheme.PLAYER_ONE: {"left": "p1_left", "right": "p1_right", "up": "p1_up", "down": "p1_down", "pass": "p1_pass", "shoot": "p1_shoot"},
       ControlScheme.PLAYER_TWO: {"left": "p2_left", "right": "p2_right", "up": "p2_up", "down": "p2_down", "pass": "p2_pass", "shoot": "p2_shoot"},
   }
   ```
3. Add helpers: `get_input_vector(scheme) -> Vector2`, `is_action_pressed(scheme, action) -> bool`, `is_action_just_pressed(scheme, action) -> bool`.
4. In `player.gd`: `@export var control_scheme: Utils.ControlScheme = Utils.ControlScheme.PLAYER_ONE`, and replace hardcoded input calls with the Utils helpers.
5. In the World scene, add 3 player instances: one PLAYER_ONE, one PLAYER_TWO, one CPU.

### 2.5 Sprite flipping

1. Add `var _heading: int = 1` (1 = right, -1 = left).
2. `_flip_sprites()`: if `velocity.x > 0` → heading 1, `flip_h = false`; if `< 0` → heading -1, `flip_h = true`; if `== 0` keep current heading.
3. Call it every frame in `_physics_process`.

*Stuck? Watch from 18:00 in V02.*

### 2.6 A simple inline state machine (temporary)

This is a stepping stone — Part 3 replaces it with the real architecture.

1. `enum State { MOVING, TACKLING }` and `var state := State.MOVING`.
2. `var _tackle_start: float = 0.0`.
3. In `_physics_process`: MOVING + shoot pressed + moving → switch to TACKLING and record `Time.get_ticks_msec()`. In TACKLING: play tackle animation; after 500 ms return to MOVING.
4. Test, then commit: `git commit -m "basic movement and control schemes"`.

*Stuck? Watch from 23:00 in V02.*

## Part 3 — Scalable State Machine (V03)

Video (transcript gives two conflicting links): https://youtu.be/lKZ1xGdmOoc or https://www.youtube.com/watch?v=hjLANpKMlM4

Replaces the inline state machine with one class per state. This pattern carries through the whole project.

### 3.1 Base state class — `scripts/states/base_state.gd`

```gdscript
class_name BaseState extends Node

var player: CharacterBody2D

func enter() -> void: pass
func exit() -> void: pass
func handle_input(_event: InputEvent) -> void: pass
func update(_delta: float) -> BaseState: return null
# update() returns the next state, or null to stay
```

### 3.2 Individual states

One script per state, each extending `BaseState`:

- `moving_state.gd` — directional input, walk/idle animation; returns `TacklingState` when shoot is pressed.
- `tackling_state.gd` — tackle animation, timer; returns `MovingState` after ~0.5 s.
- More states arrive in later parts: dribbling, shooting, passing, hurt, celebrating, etc.

Each state knows only its own logic and transitions. No giant if/else chains.

### 3.3 The StateMachine node — `state_machine.gd`

```gdscript
extends Node
var current_state: BaseState

func init(player: CharacterBody2D, initial_state: BaseState):
    current_state = initial_state
    current_state.enter()

func update(delta: float):
    var new_state = current_state.update(delta)
    if new_state != null:
        transition_to(new_state)

func transition_to(new_state: BaseState):
    current_state.exit()
    current_state = new_state
    current_state.enter()
```

### 3.4 Wire it into the player scene

1. Add a `StateMachine` child node to the player scene, plus a plain `Node` named `States`.
2. Under `States`, add `MovingState` and `TacklingState` children with their scripts.
3. In `player.gd` `_ready()`: `state_machine.init(self, $States/MovingState)`.
4. `F5` — behavior identical to before, but cleanly separated. Commit.

## Part 4 — The Soccer Ball (V04)

Video (conflicting links): https://youtu.be/7HCe3mBnkKE or https://www.youtube.com/watch?v=TKEGLPDgSaI

### 4.1 Ball scene

1. New Scene > Other Node > **AnimatableBody2D**. Rename `ball`. Save to `scenes/ball/ball.tscn`.
2. Add child **Sprite2D** (`ball.png`, uncheck Centered) and **CollisionShape2D** with a `CircleShape2D` matching the sprite.
3. Enable **Y Sort Enabled** on the root.

### 4.2 Ball physics — `ball.gd`

```gdscript
@export var friction: float = 0.92  # velocity multiplier per frame
var velocity: Vector2 = Vector2.ZERO

func _physics_process(delta):
    velocity *= friction
    var collision = move_and_collide(velocity * delta)
    if collision:
        velocity = velocity.bounce(collision.get_normal())

func kick(direction: Vector2, force: float):
    velocity = direction * force
```

Add the ball instance to the World scene at center pitch.

### 4.3 Ball detection on players

1. Add an **Area2D** child named `BallDetectionArea` (small CircleShape2D) to the player scene.
2. Connect `area_entered`: when the ball enters, that player "has the ball".
3. Track possession globally (variable or signal) so other players release it when someone gains possession. Commit.

## Part 5 — Dribbling (V05)

Video (conflicting links): https://youtu.be/mXBj0fNtQFc or https://www.youtube.com/watch?v=XbS7e6zM-9k

1. Create `dribbling_state.gd` extending BaseState.
2. `enter()`: set ball owner to this player; play dribble animation.
3. `update(delta)`:
   - Position the ball slightly ahead: `player.global_position + player._heading_vector * DRIBBLE_OFFSET`
   - Shoot pressed → `ShootingState`; pass pressed → `PassingState`
   - Tackled (opponent's BallDetectionArea overlaps) → lose ball, back to `MovingState`
4. In `MovingState`: when the BallDetectionArea detects the ball, return `DribblingState`.
5. Ball ownership signal in a global script: `signal ball_owner_changed(new_owner)`. Emit on pickup; other players react (defenders chase, etc.). Commit.

## Part 6 — Shooting (V06)

Video (conflicting links): https://youtu.be/q7VX8fOfOwg or https://www.youtube.com/watch?v=Kf9YnIoiMdo

### 6.1 Charged shots

Hold shoot longer = harder shot.

```gdscript
# shooting_state.gd
var charge_start: float = 0.0
const MIN_POWER = 80.0
const MAX_POWER = 300.0
const MAX_CHARGE_TIME = 1.0  # seconds
```

- `enter()`: record `charge_start`; play charge animation.
- `update()`: on shoot release, `charge_time = min(elapsed, MAX_CHARGE_TIME)`, `power = lerp(MIN_POWER, MAX_POWER, charge_time / MAX_CHARGE_TIME)`, then `ball.kick(player._heading_vector, power)` and return to MovingState.
- (A visual charge bar comes later with the UI.)

### 6.2 Goal detection

1. Add **Area2D** nodes at each goal mouth in the World scene (`GoalLeft`, `GoalRight`).
2. On `area_entered` by the ball: emit `goal_scored` with the scoring team.
3. On goal: reset players to starting positions, update the score, trigger kickoff. Commit.

## Part 7 — Passing (V07)

Video (conflicting links): https://youtu.be/3EL0KzIOj2A or https://www.youtube.com/watch?v=9aClxnuCg4Q

### 7.1 Pick the best pass target

1. Get all teammates (same team group).
2. Filter: not the passer, same side of pitch, not blocked by opponents.
3. Score candidates — favor teammates ahead of the passer with open space; pick the best.

### 7.2 Passing state

1. `passing_state.gd` with `var target: CharacterBody2D`.
2. `enter()`: compute best target, kick the ball toward them with moderate force, play pass animation.
3. No valid target → fall back to DribblingState.
4. **Pass request (control swap):** pressing pass *without* the ball switches control to the teammate nearest the ball — emit a signal the GameManager handles. Commit.

## Part 8 — Precise Trajectories (V08)

Video (conflicting links): https://youtu.be/0YvHpJHiDaA or https://www.youtube.com/watch?v=A2s_HoToGaQ

AI players predict where the ball *will be*, not where it is:

```gdscript
# ball.gd
func predict_position(steps: int) -> Vector2:
    var sim_vel = velocity
    var sim_pos = global_position
    for i in range(steps):
        sim_vel *= friction
        sim_pos += sim_vel * (1.0 / 60.0)
    return sim_pos
```

AI calls `ball.predict_position(30)` (~0.5 s ahead) and moves to that point. This makes interceptions feel natural. Commit.

## Part 9 — Camera, Goals & Pitch Boundaries (V09)

Video (conflicting links): https://youtu.be/zq5L8Y3MDWA or https://www.youtube.com/watch?v=c1tz1rjCz6o

1. **Hide the vision cone:** toggle visibility off on the player's debug CollisionPolygon2D (functionality stays).
2. **Add Camera2D** to World, rename `camera`, move to top of the scene tree.
3. **Camera limits** (Inspector > Limit): Left = 0, Top = 0, Right = 850, Bottom = 360 (matches the background size).
4. **Position smoothing:** On, Speed = 5.
5. **Camera script** (`camera.gd`) with look-ahead:
   ```gdscript
   @export var ball: Ball
   const LOOK_AHEAD_DISTANCE = 100

   func _process(_delta):
       if ball.carrier:
           position = ball.carrier.position + ball.carrier.heading * LOOK_AHEAD_DISTANCE
       else:
           position = ball.position
   ```
6. Drag the ball node into the camera's **Ball** export slot in the Inspector.
7. **Goal scene** (`goal.tscn`): Node2D root with two Sprite2D children `bottom_frame` (texture `goal-bottom`, offset `(-23, -125)`) and `top_frame` (texture `goal-top`, offset `(-23, -59)`). Centered off.
8. **Goal collision:** Area2D for ball-entry detection (the net doesn't bounce — the ball pierces through); StaticBody2D + CollisionPolygon2D for the posts, which do block the ball.
9. **Boundary walls:** Sprite2D walls left/right, each with a StaticBody2D sibling + CollisionShape2D. Set collision layers so ball and players hit walls.
10. **Y-sorting:** tweak sprite offsets (e.g., −4 px) so walls and goal posts layer correctly; enable Y-sort on parent Node2Ds.
11. **Mirror walls:** duplicate the left wall, set `scale.x = -1`.

## Part 10 — Headers (V10)

Video (conflicting links): https://youtu.be/aSFw5CQqQAE or https://www.youtube.com/watch?v=FHnebIUSXHk

The game fakes a third dimension with a `height` value.

1. **Player height tracking:** add `height: float` and `height_velocity: float`, plus:
   ```gdscript
   func process_gravity(delta):
       if height > 0:
           height_velocity -= GRAVITY * delta
           height += height_velocity
           if height <= 0: height = 0
       player_sprite.position = Vector2.UP * height
   ```
2. **Ball air properties:** `air_connect_min_height` / `air_connect_max_height` exports; `can_air_connect()` and `can_air_interact()` check the ball's height range and that it isn't carried.
3. **High passes:** `const DISTANCE_HIGH_PASS = 130` in `ball.gd`; in `pass_to()`, if distance > threshold add a vertical arc: `height_velocity = GRAVITY * distance / (1.8 * intensity)`.
4. **Header state** (`player_state_header.gd`): `BONUS_POWER = 1.3`, `HEIGHT_START = 0.1`, `HEIGHT_VELOCITY = 1.5`. On enter: play `header` animation, set player height/velocity.
5. **Trigger:** in the moving state, if `ball.can_air_interact()` and shoot just pressed and player is moving → HEADER state.
6. Add the `header` animation; ball redirects with the 1.3× power bonus. Add `HEADER` to the state enum.

## Part 11 — Volleys, Bicycle Kicks & Chest Control (V11)

Video (conflicting links): https://youtu.be/UaX4MWTU6pI or https://www.youtube.com/watch?v=NDLF-bdXQpA

1. Add `CHEST_CONTROL`, `VOLLEY_KICK`, `BICYCLE_KICK` to the state enum.
2. **Volley kick** (`BONUS_POWER = 1.5`): ball at mid-air height and player *facing* the target goal.
3. **Bicycle kick** (`BONUS_POWER = 2.0`): ball high and player facing *away* from goal.
4. **Chest control** (`DURATION_CONTROL = 500 ms`): trap a high ball and bring it down.
5. Refactor `can_air_connect(min_height, max_height)` to take parameters.
6. `Player.control_ball()`: if ball height > `BALL_CONTROL_HEIGHT_MAX` → CHEST_CONTROL.
7. Add `is_facing_target_goal()` helper (chooses volley vs bicycle) and `Goal.get_random_target_position()` for aim. Register the new states in the state factory.

## Part 12 — Team Rosters from JSON (V12)

Video (conflicting links): https://youtu.be/rQkPgRpZsUE or https://www.youtube.com/watch?v=ADKs38tE3JY

**This is the heart of the SFPUC customization** — see Section B for the full SFPUC roster file.

1. Create `assets/json/squads.json`: an array of team objects, each with a `"country"` string and a `"players"` array. Each player: `{"name", "skin" (int), "role" (int), "speed" (int), "power" (int)}`, plus an optional `"presentation": "female"`.
2. Create `resources/player_resource.gd` (extends Resource):
   ```gdscript
   @export var full_name: String
   @export var skin_color: Player.SkinColor
   @export var role: Player.Role
   @export var speed: float
   @export var power: float
   ```
3. Create `utils/data_loader.gd`: read the JSON with `FileAccess`, parse it, map entries to `PlayerResource` objects.
4. In `actors_container.gd`: `get_squad(team) -> Array[PlayerResource]` and `spawn_player()` that instantiates the player prefab and calls `player.initialize(resource)`.
5. `player.initialize(resource)`: copies speed, power, role, skin color, and name onto the node.
6. Add `Player.Role` enum (`GOALIE=0, DEFENSE=1, MIDFIELD=2, OFFENSE=3`) and `Player.SkinColor` enum.

## Part 13 — Team Colors via Shader (V13)

Video (conflicting links): https://youtu.be/eJFKLf4IQJM or https://www.youtube.com/watch?v=j3WWkdnGGgk

One spritesheet, any kit color — a palette-swap shader recolors players at runtime. **This is where Water blue / Power yellow / Sewer green / Hetch Hetchy powder blue get applied.**

1. Create `shaders/replace_color.gdshader` (`canvas_item` type):
   ```glsl
   group_uniforms Palettes;
   uniform sampler2D skin_palette;
   uniform sampler2D team_palette;
   uniform int skin_color : hint_enum("Light", "Medium", "Dark");
   uniform int team_color;
   ```
   Logic: match source pixel colors against the palette textures and swap by index.
2. Create palette PNGs: `skin_palette.png` (rows = skin tones) and `team_palette.png` (rows = team colors — one row per SFPUC team).
3. Assign a **ShaderMaterial** to `player_sprite` in `player.tscn` with `resource_local_to_scene = true`; assign both palettes as shader params.
4. In `player.gd`:
   ```gdscript
   func set_shader_properties():
       player_sprite.material.set_shader_parameter("skin_color", skin_color)
       var team_index := TEAMS.find(team)
       player_sprite.material.set_shader_parameter("team_color", team_index)
   ```
5. Call `set_shader_properties()` from `initialize()`.

## Part 14 — Steering Behaviors & AI Movement (V14)

Video: https://youtu.be/4_J_rYPteXg

CPU players chase and intercept using steering forces.

1. Create `scenes/characters/ai_behavior.gd` holding references to player and ball:
   ```gdscript
   func get_onduty_steering_force():
       return player.weight_on_duty_steering * player.position.direction_to(ball.position)

   func perform_ai_movement():
       total_steering_force += get_onduty_steering_force()
       total_steering_force = total_steering_force.limit_length(1.0)
       player.velocity = total_steering_force * player.speed
   ```
2. Player additions: `spawn_position: Vector2`, `weight_on_duty_steering: float`, `ai_behavior: AIBehavior`, and `setup_ai_behavior()`.
3. In the moving state: if `control_scheme == CPU`, call `ai_behavior.process_ai()`.
4. In `actors_container.gd`: `const DURATION_WEIGHT_CACHE = 200`; store home/away squads; `set_on_duty_weights()` sorts CPU players by distance to ball and assigns `1 - ease(float(i) / 10.0, 0.1)` — nearest players chase hardest.

## Part 15 — AI Decision Making (V15)

Video (conflicting links): https://youtu.be/JYkFR7Kw7cE or https://www.youtube.com/watch?v=3i3oWE2pWaE

1. Constants in `ai_behavior.gd`: `SHOT_DISTANCE = 150`, `SHOT_PROBABILITY = 0.3`, `SPREAD_ASSIST_FACTOR = 0.8`.
2. `get_carrier_steering_force()`: with the ball, steer toward the target goal (uses `get_bicircular_weight()`).
3. `get_assist_formation_steering()`: teammates without the ball position at `ball_carrier.position + direction * SPREAD_ASSIST_FACTOR` to open passing lanes.
4. `perform_ai_movement()`: pick force by role — carrier force / assist force / chase force.
5. `perform_ai_decisions()`: with ball + within `SHOT_DISTANCE` of goal + `randf() < SHOT_PROBABILITY` → shoot.
6. Ball tuning: `friction_air = 35.0`, `friction_ground = 250.0`.

## Part 16 — Tackling & Getting Hurt (V16)

Video (conflicting links): https://youtu.be/oI_kXJsRaTA or https://www.youtube.com/watch?v=6Vbt0alyxn4

1. Add `HURT` to the state enum. `player_state_hurt.gd`: `DURATION_HURT = 1000 ms`, plays `hurt` animation (frames 54–55), upward `height_velocity` knockback.
2. Ball `tumble()`:
   ```gdscript
   const TUMBLE_HEIGHT_VELOCITY = 3.0
   func tumble(tumble_velocity: Vector2):
       velocity = tumble_velocity
       carrier = null
       height_velocity = TUMBLE_HEIGHT_VELOCITY
       switch_state(Ball.State.FREEFORM)
   ```
3. Tackling state: enable `tackle_damage_emitter_area` on enter, disable on exit.
4. `on_tackle_player()`: if the tackled player carries the ball for the *other team*, call `ball.tumble()` and send them to HURT.
5. AI passes under pressure: add `PASS_PROBABILITY`; in `perform_ai_decisions()`, `elif has_opponents_nearby() and randf() < PASS_PROBABILITY: player.switch_state(PASSING)`. `has_opponents_nearby()` checks an opponent-detection Area2D.

## Part 17 — Goalkeeper (V17)

Video: https://www.youtube.com/watch?v=-Rh283BywIE

1. New physics layers in `project.godot`: `InvisibleWalls`, `ScoringArea`, `GoalKeeperHands`.
2. **AIBehaviorFactory** picks the right AI per role; rename `ai_behavior.gd` → `ai_behavior_field.gd`, move to `scenes/characters/ai/`.
3. `ai_behavior_goalie.gd`: movement tracks the ball's Y position; decisions trigger a **DIVING** state when the ball enters the scoring area.
4. `goal.gd` helpers: `get_top_target_position()`, `get_bottom_target_position()`, `get_scoring_area()`.
5. `player_state_diving.gd`: dive animation, knockback, → RECOVERING after 500 ms.
6. `can_carry_ball()` returns false for the GOALIE role.
7. Ball gets a `scoring_raycast` (RayCast2D) aimed along `velocity.angle()` each frame to detect shots on goal.
8. Differentiate VOLLEY_KICK vs BICYCLE_KICK by vertical velocity and air state.

## Part 18 — Pass Requests & Smarter AI (V18)

Video: https://www.youtube.com/watch?v=QVF2EtRfUAA

1. `get_pass_request()` on the player — request a pass to swap control to a nearby teammate.
2. `actors_container.gd`: connect `on_player_swap_request` to handle control swapping.
3. `BallStateData` with `DURATION_TUMBLE_LOCK` and `DURATION_PASS_LOCK` to prevent premature state flips.
4. Add a `teammate_detection_area` to each AI player for coordinated positioning.
5. New steering forces: `get_ball_proximity_steering_force()`, `get_spawn_steering_force()`.
6. AI passes only when `has_opponents_nearby()` **and** `has_teammate_in_view()`.
7. `MAX_CAPTURE_HEIGHT` prevents capturing a ball that's too high.

## Part 19 — Goal Celebrations & Game Manager (V19)

Video: https://www.youtube.com/watch?v=VyD98bithXI

1. `game_events.gd` — a global signal bus (autoload) with `team_scored`.
2. **GameManager** autoload with its own state machine: `InPlay, Scored, GameOver, Overtime, Reset`.
3. `GameStateData` shares score, teams, and time between states; `GameStateFactory` instantiates states.
4. `goal.initialize(team)` + detection logic emits `GameEvents.team_scored`.
5. `PlayerStateCelebrating` / `PlayerStateMourning`: on `team_scored`, celebrate if your team scored, mourn otherwise.
6. `actors_container.gd` passes the two competing teams to `spawn_players()` to associate teams with goals.

## Part 20 — Kickoffs & the Full Match Loop (V20)

Video: https://www.youtube.com/watch?v=GFcCGij6HUE

1. New signals: `kickoff_ready`, `kickoff_started`, `team_reset`.
2. `GameStateKickoff`: wait for Pass input, then emit `kickoff_started`.
3. `game_state_reset.gd`: emit `team_reset`, wait for all players' `kickoff_ready`, then → kickoff.
4. `PlayerStateReseting`: steer each player back to their `reset_position`; emit `kickoff_ready` on arrival. Register in the state factory.
5. Player gets `kickoff_position`, `reset_position`, and `face_towards_target_goal()`.
6. Celebrating/mourning states listen for `team_reset` → RESETING.
7. Ball: `on_team_reset()` returns to spawn; `on_kickoff_started()` plays a short forward pass.
8. World scene: add `KickOffs` Node2D spawn points at center field for both teams.
9. GameManager helpers: `player_setup`, `is_coop()`, `is_single_player()`.

## Part 21 — HUD & Game UI (V21)

Video: https://www.youtube.com/watch?v=8s28FYYr6Ek

1. `game_theme.tres`: Label font = `Pixeled.ttf`, size 5, white.
2. `scenes/ui/ui.tscn`: score labels (home/away), match clock, and **badge TextureRects** for both teams (the original uses country flags — SFPUC uses division badges).
3. `ui.gd`: listen for `score_changed` and `game_over`; update labels; show the game-over overlay.
4. Helpers: `score_helper.gd` (score string), `time_helper.gd` (MM:SS), `flag_helper.gd` (badge texture by team key).
5. New signals: `ball_possessed`, `ball_released`, `game_over`, `score_changed`.
6. GameManager: per-team score; tie/time-up/overtime/winner logic; emits `score_changed` and `game_over`.
7. `reset_control_schemes()` reassigns player/CPU roles after game over.
8. Win/loss celebrations at full time, not just per-goal. Add the UI scene to `world.tscn`.

## Part 22 — Juice & Polish (V22)

Video (conflicting links): https://youtu.be/0VcMOEIlFpk or https://www.youtube.com/watch?v=hLaYwyI5UiQ

1. **Camera shake**: `DURATION_SHAKE` / `SHAKE_INTENSITY` constants, triggered by a new `impact_received` signal.
2. **Impact pause**: on hard shots/tackles the GameManager pauses briefly (`DURATION_IMPACT_PAUSE`) and emits `impact_received`.
3. **Spark particles** (`scenes/spark/spark.tscn`, GPUParticles2D) emitted on shots.
4. **Run particles** on players when speed exceeds a threshold.
5. **Anti-swarming AI**: `get_density_around_ball_steering_force()` pushes players away when too many teammates crowd the ball (`get_proximity_teammates_count()`).
6. **Stat rebalance** in `squads.json`: cap most speeds at 75, rebalance power.
7. Random 0–0.5 s delay before celebration animations so the team doesn't move in lockstep.

## Part 23 — Menus & Sound Effects (V23)

Video (conflicting links): https://youtu.be/Yp1M7kRVyAg or https://www.youtube.com/watch?v=NhB7nXOzu-Q

1. **SoundPlayer** singleton (`scenes/audio/sound_player.gd`, autoload): `play_bounce()`, `play_hurt()`, `play_pass()`, `play_shot()`, `play_whistle()` — each plays its `.wav`.
2. Hook sounds into: wall bounces, bicycle kick, header, hurt, passing, shooting, volley states; whistle on goals.
3. **Main menu** (`scenes/screens/main_menu/`): Start and Quit buttons; Start → team selection.
4. **Team selection screen** (`scenes/screens/team_selection/`): two `FlagSelector` nodes (home/away) cycling through teams loaded via `DataLoader.get_teams()` — for SFPUC these show the four division badges.
5. Remove any hardcoded team list from `player.gd`; load dynamically from JSON.
6. Kickoff state uses `GameManager.player_setup` to assign player/CPU control per selected mode.
7. Fix: adjust the goal scoring-area position so edge shots register.

## Part 24 — Final Integration (V24)

Video: https://www.youtube.com/watch?v=dTtX-AKj8YQ • Checkpoint: https://github.com/nicolasbize/soccer-course/releases/tag/v0.2.4

1. Wire the flow: main menu → team selection → (store selections in GameManager) → `world.tscn`.
2. **Background music**: AudioStreamPlayer with a looping `.ogg`; add `play_music()` / `stop_music()` to SoundPlayer.
3. Fix the scoring-area collision size/position so edge shots always count.
4. Fix remaining AI edge cases (stuck goalkeeper, ball capture at spawn).
5. **Full loop test**: menu → team select → kickoff → play → score → celebrate → reset → kickoff → game over → back to menu.
6. **Export for Web (HTML5)**: Project > Export > Add > Web, set the export template and output path. This produces a static bundle (`index.html` + `.wasm` + `.pck`).

### Web hosting note (preferred: GitHub Pages)

Godot 4 web builds normally require two HTTP headers (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`) because the engine uses SharedArrayBuffer for threading — and GitHub Pages does not send custom headers.

**Thing to try first:** in the Web export settings (Godot 4.3+), turn **Thread Support OFF**. The build runs single-threaded, no longer needs SharedArrayBuffer or the headers, and can be hosted straight on GitHub Pages: commit the exported files to the repo (e.g. a `docs/` folder or `gh-pages` branch), enable Pages in the repo settings, done. For a small 2D game the performance cost should be negligible — watch for audio crackle as the main symptom.

If threads turn out to be needed, fall back to itch.io (handles the headers automatically) or an internal server where IT can add them. This repo already maps Player 2's shoot key to `1` rather than Tab, so no remap is needed before exporting — Tab moves focus in browsers and would otherwise be unusable there.

> The original series also covers a tournament bracket and team-selection screens in the videos listed as V20–V22 in the transcript's reference table (Tournament Screen, Team Selection, Main Menu). The transcript's detailed sections fold these into Parts 19–24 above. If you want the full bracket implementation, check out the corresponding repo tags and read the `scenes/screens/` folder.

---

# Section B: SFPUC Customization {#sfpuc-customization}

Do the base build first (or clone the finished `v0.2.4` tag), then apply these changes. They're ordered from simplest to most involved.

## B.1 Replace the rosters — `assets/json/squads.json`

Replace the country squads with SFPUC teams. Keep the same schema the DataLoader expects (rename the `"country"` key only if you also rename it in `data_loader.gd`; otherwise keep the key and just change its values):

```json
[
  {
    "country": "Water",
    "players": [
      {"name": "Flo Stopper",  "skin": 2, "role": 0, "speed": 62, "power": 110, "presentation": "female"},
      {"name": "Phil Tration", "skin": 0, "role": 1, "speed": 68, "power": 145},
      {"name": "Sandy Filter", "skin": 1, "role": 1, "speed": 64, "power": 160, "presentation": "female"},
      {"name": "Chlora Mine",  "skin": 0, "role": 2, "speed": 72, "power": 135, "presentation": "female"},
      {"name": "Walter Fall",  "skin": 2, "role": 3, "speed": 74, "power": 150},
      {"name": "Otto Zone",    "skin": 1, "role": 3, "speed": 70, "power": 155}
    ]
  },
  { "country": "Power",        "players": ["...same shape, 6 players..."] },
  { "country": "Sewer",        "players": ["...same shape..."] },
  { "country": "Hetch Hetchy Water and Power", "players": ["...same shape..."] }
]
```

`skin` is `0`/`1`/`2` (light/medium/dark), `role` is `0`–`3`
(goalie/defense/midfield/offense per the shipped enum order), and
`presentation: "female"` swaps the sprite sheet (omit it for the default
male sprite). The shipped `squads.json` fields three female and three
male players per team.

Notes:

- Use real employee names (with permission!) or fun division-themed names as above.
- `role`: 0 = goalie, 1 = defense, 2 = midfield, 3 = offense (match whatever enum order you defined in Part 12/17).
- Keep speeds ≤ 75 per the Part 22 balance pass. Give each team a slightly different flavor — e.g., Power hits harder (power), Water runs faster (speed), Sewer defends deep.

## B.2 Team colors — `team_palette.png` (Part 13 shader)

The team palette texture has one row per team. Rebuild it with four rows in the same order as the teams in `squads.json`:

| Row | Team | Kit color |
|---|---|---|
| 0 | Water | `#007DC3` blue |
| 1 | Power | `#FFB034` yellow |
| 2 | Sewer | `#8DC63F` green |
| 3 | Hetch Hetchy Water and Power | `#7EC8E3` powder blue |

Since Water and Hetch Hetchy are both blue, keep Water's kit dark and Hetch Hetchy's clearly pale so they read differently at game resolution.

Each row typically holds 2–4 shades (main kit, shadow, trim) — copy the shade-step pattern from the original palette rows so shading still reads correctly. No shader code changes needed; the `team_color` index just selects a row.

## B.3 Official-logo flags

The UI (Part 21) and team selection screen (Part 23) display a texture per team via `flag_helper.gd`.

1. Add the approved official logo source to `assets/art/brand/` and preserve it unchanged. (This repo does not include that high-res brand source — only the final in-game team cards/flags are checked in.)
2. Create four flag PNGs at the same pixel dimensions as the original flag assets (22×14 px): `flag_water.png`, `flag_power.png`, `flag_sewer.png`, and `flag_hhwp.png`.
3. Each flag uses the same official logo, centered on a solid team-color field. Do not generate substitute team marks or recolor the official logo.
4. Update `flag_helper.gd` to map team keys → the four logo flag textures.

At this small size, prepare the flags from a larger source card, crop each variant, then downscale with nearest-neighbor filtering. Use the original player sprite sheet and palette shader for kit variants; add the logo to a jersey only if it remains legible at game resolution.

## B.4 Rename the game

- **Project name:** Project Settings > Application > Config > Name → "SFPUC Super Soccer".
- **Main menu title** (Part 23's `main_menu_screen.tscn`): change the title label/texture.
- **Window icon:** replace icon.svg.
- **Typography:** use Franklin Gothic Book for UI labels and Minion Pro Regular for formal/tournament copy when licensing and file formats permit.

## B.5 Tournament mode with 4 teams

Good news: 4 teams is a *cleaner* bracket than the original (which pads to quarterfinals). Your solo tournament becomes: **two semifinals → final**.

1. In the tournament screen logic, seed the four teams into two semifinal matches (randomize or fix the matchups — Water vs Sewer and Power vs Hetch Hetchy Water and Power is thematically fun: "the pipes derby" and "the powerhouse derby").
2. Winner of each semi meets in the final.
3. If the tournament code assumes 8 teams, reduce the bracket array to 4 entries and remove the quarterfinal round; check the repo's tournament screen code (in `scenes/screens/`) at the corresponding tag.

## B.6 Optional SFPUC flavor

- Rename the pitch: modulate the `lines` sprite or add a center-circle logo sprite with an SFPUC seal (get comms approval for logo use).
- Commentary-style SFX: record coworkers shouting "Gooooal!" and drop the `.wav` into SoundPlayer.
- Stadium names per team on the HUD ("Sunset Reservoir Stadium", "Hetch Hetchy Dam Arena", "Southeast Treatment Grounds", "Moccasin Powerhouse Park").

---

# Appendix: Video Reference Table

Links reproduced from the original transcript. Where the transcript gave two different URLs for the same video, both appear in the relevant Part above; if a link doesn't work, use the repo checkpoint tags instead.

| # | Topic | Link (from transcript's table) |
|---|---|---|
| V01 | Setting up Godot | https://www.youtube.com/watch?v=__ZAKUIjxy0 |
| V02 | Basic Movement | https://youtu.be/fW3VAX5n9ks |
| V03 | Scalable State Machines | https://youtu.be/lKZ1xGdmOoc |
| V04 | Soccer Ball | https://youtu.be/7HCe3mBnkKE |
| V05 | Dribbling | https://youtu.be/mXBj0fNtQFc |
| V06 | Shooting | https://youtu.be/q7VX8fOfOwg |
| V07 | Passing | https://youtu.be/3EL0KzIOj2A |
| V08 | Precise Trajectories | https://youtu.be/0YvHpJHiDaA |
| V09 | The Pitch | https://youtu.be/zq5L8Y3MDWA |
| V10 | Headers & Volleys | https://youtu.be/aSFw5CQqQAE |
| V11 | Camera & Scrolling | https://youtu.be/UaX4MWTU6pI |
| V12 | Player Shader | https://youtu.be/rQkPgRpZsUE |
| V13 | Team & Player Stats | https://youtu.be/eJFKLf4IQJM |
| V14 | Steering Behaviors & AI | https://youtu.be/4_J_rYPteXg |
| V15 | AI Decision Making | https://youtu.be/JYkFR7Kw7cE |
| V16 | Goalkeeper | https://youtu.be/oI_kXJsRaTA |
| V17 | Tackling & Hurt States | https://youtu.be/yN3JnxhDJAw |
| V18 | Kickoff & Goal Celebration | https://youtu.be/8XfMssDr8bE |
| V19 | Match Flow & Game Over | https://youtu.be/IuCr-uemU1k |
| V20 | Tournament Screen | https://youtu.be/3v0NqiEqkCA |
| V21 | Team Selection Screen | https://youtu.be/dQqH6KNK8CM |
| V22 | Main Menu | https://youtu.be/aaOqZ7bBCuU |
| V23 | Juice & Polish | https://youtu.be/0VcMOEIlFpk |
| V24 | Sound Effects & Music | https://youtu.be/Yp1M7kRVyAg |
| V25 | Game Trailer | *(placeholder in transcript — no valid link)* |

**Note:** this table's topic order does not match the transcript's detailed sections after Part 9 (the table and body drifted by one or more videos). The Parts in this guide follow the *detailed body* of the transcript, which is internally consistent and matches the repo structure. When in doubt, trust the repo tags.

---

# Attribution & Resources {#attribution--resources}

Based on the 25-video series *"Create a Soccer Game in Godot!"* by **Nicolas Bize** (gadgaming). The source code is MIT-licensed, so SFPUC may freely modify and reuse it — retain attribution.

| Resource | Link |
|---|---|
| Course source code (MIT) | https://github.com/nicolasbize/soccer-course |
| Per-video checkpoints | https://github.com/nicolasbize/soccer-course/tags (23 tags — jump to any stage) |
| Final checkpoint | https://github.com/nicolasbize/soccer-course/releases/tag/v0.2.4 |
| Play the finished demo | https://gadgaming.itch.io/super-soccer |
