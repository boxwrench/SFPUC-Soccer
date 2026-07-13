# YAGNI Audit & Share-Prep — SFPUC Super Soccer

**Date:** 2026-07-13
**Status:** Approved

## Goal

Prepare the repo for public sharing as an easy-to-replicate example: prune
everything the shipped game doesn't use (dead code/assets only — zero behavior
change), then bring the README and build guide in line with the final repo.

## Context

- The repo is a customized fork of Nicolas Bize's Godot 4 soccer course
  (MIT), rebranded as **SFPUC Super Soccer**: 4 teams (Water, Power, Sewer,
  Hetch Hetchy Water and Power), a two-semifinal tournament, ~2,150 lines of
  GDScript.
- The entire SFPUC customization (~123 files: rosters, palette, screens,
  deleted country flags, `SFPUC-Soccer-Game-Guide.md`, VBS launcher) is
  uncommitted in the working tree.
- Replication audience is **both** course-followers and clone-and-customize
  users: the repo gets pruned to what the shipped game needs; the guide stays
  course-followable, with divergence notes where the repo differs from the
  videos.
- `SFPUC-Soccer-Game-Guide.md` is double-encoded UTF-8 (mojibake on every
  em-dash/arrow) and must be repaired before sharing.
- No known gameplay bugs. The audit's job is to not introduce any.

## Decisions

| Question | Decision |
|---|---|
| YAGNI baseline | Final shipped game (guide keeps course-parity via divergence notes) |
| Pruning aggressiveness | Dead code only — provably unused; no live-code refactors |
| Baseline handling | Commit + push customization first, audit on top |
| New remote | `https://github.com/boxwrench/SFPUC-Soccer.git` as `origin`; old origin renamed `upstream` |
| Folder rename | `C:\Github\soccer-course` → `C:\Github\SFPUC-Soccer`, **last step only** (session cwd) |
| Verification | Claude: headless Godot parse/load checks; user: playtest at checkpoints |
| Audit style | Inventory first — full kill list with evidence, user approves before any deletion |

## Phases

### Phase 0 — Baseline commit & new remote

1. Commit the working tree in logical groups: game/asset customization, then
   guide + launcher.
2. Rename current `origin` to `upstream`; add
   `https://github.com/boxwrench/SFPUC-Soccer.git` as `origin`; push `main`.
3. Folder rename is deferred to Phase 4.

### Phase 1 — Inventory & audit report

Build a reference graph from `project.godot` roots (main scene, autoloads,
input map, physics layers) walking every `.tscn`/`.gd`/`.tres`/`.gdshader`
reference. **String-built resource paths are first-class**: patterns like
`flag_helper.gd`'s `"flag-%s.png" % team` make load-bearing assets look
orphaned; every dynamic `load()`/`preload()` site must be resolved against
the actual team keys before an asset is declared dead.

Audit targets:

- Orphaned assets (png/wav/ogg/ttf) and their `.import` files
- Unreferenced scripts, scenes, resources, shaders
- Leftover 8-team/quarterfinal logic in tournament code
- Unused input actions, physics layers, autoloads, project settings
- Unused exports/functions only where provably unreferenced

Deliverable: an audit report (kill list, one line of evidence per item).
**Nothing is deleted until the user approves the list.**

### Phase 2 — Prune in grouped commits

Three commits, in order: (1) orphaned assets, (2) dead code, (3)
settings/config. After each commit, run a headless Godot parse/load check.
After the code commit, the user playtests. Any breakage is reverted at
single-commit granularity.

### Phase 3 — Documentation

1. **Mojibake repair:** fix the guide's double-encoded UTF-8 programmatically
   (round-trip decode), not by hand-editing.
2. **README rewrite:** what the game is, how to run it, how to customize it
   for another org, attribution to the MIT-licensed course.
3. **Guide update:** sync "Current Repository State" with the post-audit
   repo; add divergence notes wherever the repo now differs from the course
   videos.

### Phase 4 — Final verification & handoff

1. Full-loop playtest by user: menu → team select → match → tournament →
   game over (solo and 2-player modes).
2. Final push.
3. Rename the local folder to `SFPUC-Soccer` (manual or scripted; the Claude
   session working directory becomes stale at this point by design).

## Error handling

- A pruned item that breaks parse/load or playtest: revert its commit,
  re-examine the reference evidence, re-prune narrower.
- Push rejected (remote not empty / auth): stop and surface to user; never
  force-push.
- Godot CLI unavailable for headless checks: locate the editor binary first;
  if none, fall back to user-run editor checks before each playtest.

## Out of scope

- Live-code simplification or restructuring (factories, state machines stay)
- Bug fixes beyond anything the audit itself breaks
- Web export / hosting (guide already documents it as a future option)
