# YAGNI Audit & Share-Prep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prune everything the shipped SFPUC Super Soccer game doesn't use (dead code/assets only, zero behavior change), publish to the new GitHub remote, and bring the README + build guide in line with the final repo.

**Architecture:** This is an audit-and-prune plan, not a feature build. Verification replaces TDD: every prune commit is gated by a headless Godot smoke check, and code prunes additionally by a user playtest. An inventory script produces an evidence-backed kill list that the user approves before any deletion.

**Tech Stack:** Godot 4.5 (`godot.exe` on PATH at `C:\Users\wests\.local\bin\godot.exe`), GDScript, Python 3.14 (audit script + encoding repair), git.

## Global Constraints

- **Zero behavior change.** Only provably-unreferenced files/config may be removed. Live-code refactors are out of scope.
- **Nothing is deleted until the user approves the audit report kill list** (end of Task 2 is a hard stop).
- **Never force-push.** If a push is rejected, stop and surface to the user.
- **Smoke check** (run after every prune commit):
  ```bash
  godot --headless --path C:/Github/soccer-course --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|ERROR|Failed|cannot"
  ```
  Expected: **no lines printed** (grep exits 1). Any hit = stop, diagnose, revert the offending deletion.
- All markdown files written as UTF-8 without BOM (PowerShell writers default to UTF-16 — use the Write tool or `-Encoding utf8`).
- Every commit message ends with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- The folder rename (`C:\Github\soccer-course` → `C:\Github\SFPUC-Soccer`) happens ONLY in Task 9, after everything else is pushed.
- User playtest checkpoints: after Task 4 (code prune) and in Task 9 (full loop). Wait for the user's report before proceeding past a checkpoint.

---

### Task 1: Baseline commits, remote swap, first push

**Files:**
- Modify: git index only (commits the existing working tree; no file edits)
- Remote: `origin` → `https://github.com/boxwrench/SFPUC-Soccer.git`, old origin → `upstream`

**Interfaces:**
- Produces: a clean working tree and a pushed `main`; every later task commits on top of this baseline.

- [x] **Step 1: Confirm the working tree contents match expectations**

```bash
git -C C:/Github/soccer-course status --short | grep -cv "^$"
```

Expected: ~123 lines. If wildly different, stop and ask the user what changed.

- [x] **Step 2: Commit the game/asset customization**

Everything except the guide and launcher (which get their own commit):

```bash
cd C:/Github/soccer-course
git add -A -- assets/ scenes/ utils/ resources/ project.godot
git commit -m "apply SFPUC customization: teams, palette, screens, rosters

Replaces the eight country teams with four SFPUC teams (Water, Power,
Sewer, Hetch Hetchy Water and Power), swaps flags for official-logo team
cards, updates the tournament to a two-semifinal bracket, and rebrands
the menus.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [x] **Step 3: Commit the guide and launcher**

```bash
git add -A -- SFPUC-Soccer-Game-Guide.md "Launch SFPUC Soccer.vbs"
git commit -m "add SFPUC build guide and desktop launcher

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [x] **Step 4: Verify nothing is left uncommitted**

```bash
git status --short
```

Expected: empty output. If files remain, add them to whichever of the two commits fits (`git commit --amend` is acceptable here since nothing is pushed yet) or make a third commit.

- [x] **Step 5: Swap remotes**

```bash
git remote rename origin upstream
git remote add origin https://github.com/boxwrench/SFPUC-Soccer.git
git remote -v
```

Expected: `origin` = boxwrench/SFPUC-Soccer.git, `upstream` = nicolasbize/soccer-course.git.

- [x] **Step 6: Push main**

```bash
git push -u origin main
```

Expected: success. If rejected (repo not empty, auth failure, repo doesn't exist), STOP and tell the user — never force-push. The user may need to create the GitHub repo first.

---

### Task 2: Reference inventory & audit report (HARD STOP at end)

**Files:**
- Create: `C:\Users\wests\AppData\Local\Temp\claude\C--Github-soccer-course\5dd272b7-4161-4fc5-8e8b-a42bb8e6589e\scratchpad\audit_refs.py` (deliberately NOT in the repo — shipping a one-off audit tool would itself violate YAGNI)
- Create: `docs/superpowers/audits/2026-07-13-dead-code-audit.md` (committed — it's the evidence record)

**Interfaces:**
- Produces: the approved kill list that Tasks 3–5 execute. Report format: one section per prune commit (`## Assets`, `## Code`, `## Settings`), each item as `- path — evidence`.

- [x] **Step 1: Write the reference-graph script**

Save as `audit_refs.py` in the scratchpad directory:

```python
"""Find files in a Godot project unreachable from project.godot roots."""
import re
from pathlib import Path

ROOT = Path("C:/Github/soccer-course")
SCAN_DIRS = ["assets", "scenes", "utils", "resources", "shaders"]
ROOT_FILES = ["game_theme.tres", "default_bus_layout.tres", "icon.svg"]
PARSEABLE = {".tscn", ".tres", ".gd", ".godot", ".gdshader", ".import", ".theme"}
RES_RE = re.compile(r'res://[^"\'\s)\]]+')
UID_RE = re.compile(r'uid://[0-9a-z]+')

def all_project_files():
    files = []
    for d in SCAN_DIRS:
        files += [p for p in (ROOT / d).rglob("*") if p.is_file()]
    files += [ROOT / f for f in ROOT_FILES if (ROOT / f).exists()]
    return files

def res_path(p: Path) -> str:
    return "res://" + p.relative_to(ROOT).as_posix()

def build_uid_map(files):
    """uid://xxx -> res:// path of the asset/scene/script that owns it."""
    uid_map = {}
    for p in files:
        if p.suffix == ".import":
            text = p.read_text(encoding="utf-8", errors="replace")
            m = re.search(r'uid="(uid://[0-9a-z]+)"', text)
            if m:  # .import's uid belongs to the asset it sits next to
                uid_map[m.group(1)] = res_path(p.with_suffix(""))
        elif p.suffix in (".tscn", ".tres"):
            head = p.read_text(encoding="utf-8", errors="replace")[:200]
            m = re.search(r'uid="(uid://[0-9a-z]+)"', head)
            if m:
                uid_map[m.group(1)] = res_path(p)
        elif p.suffix == ".uid":  # Godot 4.4+ sidecar for .gd files
            uid = p.read_text(encoding="utf-8").strip()
            uid_map[uid] = res_path(p.with_suffix(""))
    return uid_map

def refs_of(p: Path, uid_map):
    """All res:// paths referenced by file p."""
    if p.suffix not in PARSEABLE:
        return set()
    text = p.read_text(encoding="utf-8", errors="replace")
    found = set(RES_RE.findall(text))
    for uid in UID_RE.findall(text):
        if uid in uid_map:
            found.add(uid_map[uid])
    return found

def main():
    files = all_project_files()
    uid_map = build_uid_map(files)
    by_res = {res_path(p): p for p in files}

    godot_cfg = ROOT / "project.godot"
    roots = set(RES_RE.findall(godot_cfg.read_text(encoding="utf-8")))
    for uid in UID_RE.findall(godot_cfg.read_text(encoding="utf-8")):
        if uid in uid_map:
            roots.add(uid_map[uid])

    reachable, queue = set(), list(roots)
    while queue:
        r = queue.pop()
        if r in reachable or r not in by_res:
            continue
        reachable.add(r)
        # a reachable asset keeps its .import and .uid sidecars
        for side in (r + ".import", r + ".uid"):
            if side in by_res:
                reachable.add(side)
        queue.extend(refs_of(by_res[r], uid_map))

    orphans = sorted(set(by_res) - reachable)
    # sidecars are only orphaned together with their owner; hide the noise
    orphans = [o for o in orphans
               if not (o.endswith((".import", ".uid"))
                       and o.rsplit(".", 1)[0] in reachable)]
    print(f"{len(by_res)} files, {len(reachable)} reachable, {len(orphans)} orphan candidates\n")
    for o in orphans:
        print(o)

if __name__ == "__main__":
    main()
```

- [x] **Step 2: Run it and sanity-check the output**

```bash
python "C:\Users\wests\AppData\Local\Temp\claude\C--Github-soccer-course\5dd272b7-4161-4fc5-8e8b-a42bb8e6589e\scratchpad\audit_refs.py"
```

Expected: a count line plus orphan candidates. Sanity checks before trusting it:
- `res://assets/art/ui/flags/flag_water.png` (and the other 7 FlagHelper dict entries) must be **reachable** — they're loaded via `FlagHelper` const dicts, which the regex catches as string literals.
- `scenes/soccer_game.tscn` must be reachable (it's the main scene, referenced by uid from project.godot).
- If either check fails, the script has a bug — fix it before reading any further output.

- [x] **Step 3: Hunt dynamic-path false positives**

Any orphan candidate could still be loaded via a string built at runtime. Check for construction patterns:

```bash
grep -rn "res://.*%s\|res://.*\" *+\|str(\"res://" C:/Github/soccer-course/scenes C:/Github/soccer-course/utils --include="*.gd"
```

Expected: few or no hits (FlagHelper uses literal dicts). Every hit must be resolved by hand against the candidate list; anything plausibly loaded dynamically gets **removed from the kill list** with a note.

- [x] **Step 4: Audit the config surface (settings, input, physics layers)**

Each check produces evidence lines for the report:

```bash
# input actions: every p1_*/p2_* action should appear in code or scenes
for a in p1_left p1_right p1_up p1_down p1_pass p1_shoot p2_left p2_right p2_up p2_down p2_pass p2_shoot; do
  n=$(grep -rl "$a" C:/Github/soccer-course/scenes C:/Github/soccer-course/utils --include="*.gd" --include="*.tscn" | wc -l)
  echo "$a: $n files"
done

# physics layers: dump every collision_layer/mask value used in scenes,
# then decode bits by hand against the 6 named layers in project.godot
grep -rn "collision_layer\|collision_mask" C:/Github/soccer-course/scenes --include="*.tscn"

# leftover 8-team / quarterfinal logic
grep -rni "quarter\|worldcup\|QF\b" C:/Github/soccer-course/scenes C:/Github/soccer-course/utils --include="*.gd" --include="*.tscn"

# autoloads actually referenced from code
for a in DataLoader GameEvents GameManager SoundPlayer MusicPlayer; do
  echo "$a: $(grep -rl "\b$a\." C:/Github/soccer-course/scenes C:/Github/soccer-course/utils --include="*.gd" | wc -l) files"
done
```

An input action with 0 file hits, a physics layer whose bit appears in no scene, or a `quarter*` code path is a **Settings/Code kill-list candidate** — each with its zero-hit grep as evidence.

- [x] **Step 5: Write the audit report**

Create `docs/superpowers/audits/2026-07-13-dead-code-audit.md` with exactly three kill-list sections mapping to the three prune commits, plus a "Kept despite looking dead" section for dynamic-load survivors:

```markdown
# Dead-Code Audit — 2026-07-13

Method: BFS reference walk from project.godot roots (script:
audit_refs.py, session scratchpad) + dynamic-path grep + config-surface
greps. Every item lists its evidence. Items here are CANDIDATES until
user approval.

## Assets (prune commit 1)
- res://path/to/file.png — unreachable in reference walk; no dynamic-load hits
  (one line per file; .import/.uid sidecars implied)

## Code (prune commit 2)
- res://path/to/script.gd — unreachable; class_name not referenced anywhere

## Settings (prune commit 3)
- input action `x` — 0 hits in *.gd / *.tscn
- physics layer N `Name` — bit set in no collision_layer/mask in any scene

## Kept despite looking dead (do NOT delete)
- res://path — loaded dynamically via <file:line>
```

Fill every section from Steps 2–4 output. Empty sections say "none found".

- [x] **Step 6: Commit the report**

```bash
git add docs/superpowers/audits/2026-07-13-dead-code-audit.md
git commit -m "add dead-code audit report (kill list pending approval)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [x] **Step 7: HARD STOP — present the kill list to the user** ← APPROVED 2026-07-13: items 8,9,10 (title-sfpuc-hd.png, title-sfpuc-hd-transparent.png, tournament-screen.png) to be ARCHIVED not deleted; remaining 10 approved for deletion

Show the user the three kill-list sections and the "kept" section. Do not begin Task 3 until they approve (they may strike items). Record any strikes by editing the report (move to "Kept") and amending or re-committing.

---

### Task 3: Prune commit 1 — orphaned assets

**Files:**
- Delete: every file in the approved **Assets** section of `docs/superpowers/audits/2026-07-13-dead-code-audit.md`, plus each one's `.import` sidecar

**Interfaces:**
- Consumes: approved Assets kill list from Task 2.

- [x] **Step 1: Delete the approved assets (sidecars included)**

For each `res://<path>` in the approved Assets section:

```bash
cd C:/Github/soccer-course
git rm -- "<path>" "<path>.import"
```

(If a listed file has no `.import` — e.g. `.wav` files do, `.json` files don't — `git rm` just the file.)

- [x] **Step 2: Run the smoke check**

```bash
godot --headless --path C:/Github/soccer-course --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|ERROR|Failed|cannot"
```

Expected: no lines printed. Any missing-resource error names the file to restore: `git restore --staged --worktree -- <path> <path>.import`, move it to the report's "Kept" section, and re-run the check.

- [x] **Step 3: Commit**

```bash
git add -A
git commit -m "remove assets unused by the shipped game

Per docs/superpowers/audits/2026-07-13-dead-code-audit.md (Assets).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Prune commit 2 — dead code (user playtest checkpoint) — SKIPPED: audit found 0 dead code items; playtest folded into Task 9 full loop

**Files:**
- Delete: every file in the approved **Code** section of the audit report (plus `.uid` sidecars)
- Modify: any live file that contains an approved dead-code fragment (e.g. a leftover quarterfinal branch in `scenes/screens/tournament/tournament.gd`) — exact edits come from the report's evidence lines

**Interfaces:**
- Consumes: approved Code kill list from Task 2.

- [ ] **Step 1: Delete approved dead script/scene files**

```bash
cd C:/Github/soccer-course
git rm -- "<path>" "<path>.uid"   # .uid only exists for .gd files
```

- [ ] **Step 2: Remove approved dead fragments from live files**

For each fragment item in the report (file:line evidence), open the file and delete exactly the dead branch/function listed. No rewrites of surrounding code — if removing it cleanly would require restructuring live code, strike the item instead (zero-behavior-change constraint wins).

- [ ] **Step 3: Run the smoke check**

```bash
godot --headless --path C:/Github/soccer-course --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|ERROR|Failed|cannot"
```

Expected: no lines printed. Note: factories (`player_state_factory.gd`, `screen_factory.gd`, etc.) preload their classes, so a wrongly-deleted state script fails loudly right here — that's the point of checking before playtest.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "remove code unreferenced by the shipped game

Per docs/superpowers/audits/2026-07-13-dead-code-audit.md (Code).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 5: USER PLAYTEST CHECKPOINT**

Ask the user to run the game (double-click `Launch SFPUC Soccer.vbs` or F5 in the editor) and play one full solo match: menu → team select → kickoff → score a goal → finish the match. Wait for their report. Any breakage: `git revert HEAD`, re-examine the evidence for the offending item, re-prune narrower.

---

### Task 5: Prune commit 3 — settings & config — SKIPPED per plan clause: audit Settings section = none found

**Files:**
- Modify: `project.godot` (only lines named in the approved **Settings** section)

**Interfaces:**
- Consumes: approved Settings kill list from Task 2.

- [ ] **Step 1: Remove approved dead settings**

Edit `project.godot`, deleting exactly the approved entries (an unused input action's whole block, an unused `layer_N` name line). Nothing else — window/stretch/rendering settings are load-bearing per the guide's Part 1.4.

- [ ] **Step 2: Run the smoke check**

```bash
godot --headless --path C:/Github/soccer-course --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|ERROR|Failed|cannot"
```

Expected: no lines printed.

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "drop unused input actions and physics layer names

Per docs/superpowers/audits/2026-07-13-dead-code-audit.md (Settings).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

If the Settings section was empty ("none found"), skip this task entirely and note that in the final summary.

---

### Task 6: Repair the guide's mojibake

**Files:**
- Modify: `SFPUC-Soccer-Game-Guide.md` (encoding repair, whole file)
- Create: `C:\Users\wests\AppData\Local\Temp\claude\C--Github-soccer-course\5dd272b7-4161-4fc5-8e8b-a42bb8e6589e\scratchpad\fix_mojibake.py`

**Interfaces:**
- Produces: a clean-UTF-8 guide that Task 8 edits further.

- [x] **Step 1: Install ftfy and write the repair script**

```bash
pip install ftfy
```

Save as `fix_mojibake.py` in the scratchpad directory:

```python
"""Repair multi-round UTF-8/cp1252 mojibake in the build guide."""
from pathlib import Path
import ftfy

SRC = Path("C:/Github/soccer-course/SFPUC-Soccer-Game-Guide.md")
text = SRC.read_text(encoding="utf-8")

prev = None
rounds = 0
while prev != text and rounds < 10:   # damage is multi-round; iterate to fixpoint
    prev = text
    text = ftfy.fix_text(text)
    rounds += 1

SRC.write_text(text, encoding="utf-8", newline="\n")
print(f"fixed in {rounds} round(s); residual 'Ã' count: {text.count('Ã')}")
```

- [x] **Step 2: Run it and verify**

```bash
python "C:\Users\wests\AppData\Local\Temp\claude\C--Github-soccer-course\5dd272b7-4161-4fc5-8e8b-a42bb8e6589e\scratchpad\fix_mojibake.py"
grep -c "Ã" C:/Github/soccer-course/SFPUC-Soccer-Game-Guide.md
```

Expected: residual count **0**. Spot-check known lines: line 5 should read "**the checkpoint tags are your safety net.**" preceded by an em-dash, and the Part 2.2 table should show `]` → `p1_pass` with a real arrow. If ftfy leaves residue, examine the specific lines — do NOT hand-retype the whole file.

- [x] **Step 3: Fix the literal escape on the B.4 line**

The guide contains a literal `\r\n` in text (B.4, "**Window icon:** replace icon.svg.\r\n- **Typography:**"). Split it into two real list lines:

```markdown
- **Window icon:** replace icon.svg.
- **Typography:** use Franklin Gothic Book for UI labels and Minion Pro Regular for formal/tournament copy when licensing and file formats permit.
```

- [x] **Step 4: Commit**

```bash
git add SFPUC-Soccer-Game-Guide.md
git commit -m "repair guide encoding (mojibake) and literal escape

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: Rewrite the README

**Files:**
- Modify: `README.md` (full replacement of the current 3-line stub)

**Interfaces:**
- Consumes: nothing from other tasks (safe to reorder).
- Produces: the repo front door that links to `SFPUC-Soccer-Game-Guide.md`.

- [x] **Step 1: Replace README.md with this content**

```markdown
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

## Run it

1. Install [Godot 4.4+](https://godotengine.org) (standard build).
2. Clone this repo and open `project.godot` in Godot, then press **F5** —
   or on Windows, double-click `Launch SFPUC Soccer.vbs` (expects
   `godot.exe` on your PATH).

### Controls

| Action | Player 1 | Player 2 |
|---|---|---|
| Move | Arrow keys | WASD |
| Pass | `]` | `` ` `` |
| Shoot | `[` | `1` |

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

- **Rosters:** edit `assets/json/squads.json` (names, roles, speed, power)
- **Team colors:** edit `assets/art/palettes/teams-color-palette.png`
  (one row per team; a shader recolors the shared spritesheet at runtime)
- **Team cards/flags:** replace the PNGs mapped in `utils/flag_helper.gd`
- **Name & title art:** Project Settings → Application → Config → Name,
  plus the title texture in `scenes/screens/main_menu/`

## Attribution

Game architecture, base art, and course by
[Nicolas Bize](https://github.com/nicolasbize/soccer-course) (MIT).
SFPUC customization by boxwrench. See [LICENSE](LICENSE).
```

- [x] **Step 2: Verify the intra-repo links resolve**

```bash
ls C:/Github/soccer-course/SFPUC-Soccer-Game-Guide.md C:/Github/soccer-course/LICENSE C:/Github/soccer-course/assets/json/squads.json
```

Expected: all three paths exist. Also confirm the controls table against `project.godot`'s input map (p2_pass is physical keycode 96 = backtick, p2_shoot is 49 = the `1` key) — if Task 5 changed input actions, reflect that here.

- [x] **Step 3: Commit**

```bash
git add README.md
git commit -m "rewrite README as public front door

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: Sync the guide with the post-audit repo

**Files:**
- Modify: `SFPUC-Soccer-Game-Guide.md` (the "Current Repository State" section and a new divergence-notes subsection)

**Interfaces:**
- Consumes: the final audit report (what was actually pruned in Tasks 3–5).

- [ ] **Step 1: Update "Current Repository State"**

Rewrite that section (currently lines 38–51) so every claim matches the post-prune repo. Verify each bullet by checking the file it names still exists (e.g. `assets/art/ui/mainmenu/menu-backgroundSF-fitted.png`, `title-sfpuc-hd-menu.png`, the female spritesheet). Drop bullets about assets that were pruned; add a sentence noting the repo was dead-code audited on 2026-07-13 with a link to `docs/superpowers/audits/2026-07-13-dead-code-audit.md`.

- [ ] **Step 2: Add divergence notes**

Insert a subsection immediately after "Current Repository State":

```markdown
## Where This Repo Diverges From the Course

This repo is pruned to exactly what the shipped SFPUC game uses, so a few
things the videos build are intentionally absent here:

- **Country flags and 8-team assets** — replaced by the four SFPUC
  team cards; the quarterfinal round and its art are gone (4 teams need
  only semifinals → final).
- *(one bullet per additional pruned item that a course video builds —
  take these from the audit report's Code and Settings sections; skip
  pruned items no video ever mentions)*

If you're following the videos and your build has something this repo
lacks, that's expected — the course repo's checkpoint tags
(https://github.com/nicolasbize/soccer-course/tags) remain the reference
for the un-pruned version.
```

Replace the italic placeholder bullet with the real bullets before committing — the final list depends on what the user approved in Task 2.

- [ ] **Step 3: Verify no stale references remain**

For every file pruned in Tasks 3–5, grep the guide for its basename:

```bash
for f in $(git log --diff-filter=D --name-only --pretty=format: HEAD~5..HEAD | sort -u | grep -v "\.import$\|\.uid$"); do
  grep -l "$(basename $f)" C:/Github/soccer-course/SFPUC-Soccer-Game-Guide.md >/dev/null && echo "STALE: $f"
done
```

Expected: no `STALE:` lines, except where the guide *deliberately* mentions a removed file in the divergence notes.

- [ ] **Step 4: Commit**

```bash
git add SFPUC-Soccer-Game-Guide.md
git commit -m "sync guide with post-audit repo state, add divergence notes

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: Final verification, push, folder rename

**Files:**
- None modified; push + filesystem rename only.

**Interfaces:**
- Consumes: everything; this is the release gate.

- [ ] **Step 1: Final smoke check**

```bash
godot --headless --path C:/Github/soccer-course --quit-after 120 2>&1 | grep -iE "SCRIPT ERROR|ERROR|Failed|cannot"
```

Expected: no lines printed.

- [ ] **Step 2: USER FULL-LOOP PLAYTEST**

Ask the user to verify, in one sitting:
1. Main menu → **1 Player** → team select → semifinal → play to game over → bracket advances → final → tournament complete → back to menu
2. Main menu → **2 Players** → both co-op and versus start correctly (one kickoff each is enough)
3. Sound effects and music play; team colors/cards look right on every screen

Wait for their report. Any failure: fix (reverting the responsible prune commit if it's audit-caused), re-run this task from Step 1.

- [ ] **Step 3: Push everything**

```bash
git push origin main
git log --oneline origin/main -10
```

Expected: push succeeds; log shows the audit/docs commits on the remote.

- [ ] **Step 4: Rename the local folder (very last action)**

The session's working directory dies with this rename — do it only when nothing else remains. Godot and any terminal in the folder must be closed first. Give the user this command to run themselves (recommended), or run it accepting that the session can't touch the repo afterward:

```powershell
Rename-Item "C:\Github\soccer-course" "SFPUC-Soccer"
```

Then tell the user: re-open the project in Godot from the new path (`C:\Github\SFPUC-Soccer\project.godot`) and update any editor recent-projects entry. Git needs no change — the remote URL already matches the new name.
