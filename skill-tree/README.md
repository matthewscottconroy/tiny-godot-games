# Skill Tree

A node-graph skill tree with prerequisite dependencies, variable point costs, hover tooltips, and animated unlock states — all driven by a flat Array of skill Dictionaries.

## Purpose

Skill trees are the long-term progression layer in RPGs, strategy games, and character builders. They give players agency over specialization, make builds feel personal, and pace power delivery across a playthrough. The core data problem is representing a directed acyclic graph (DAG) where each node can have zero or more prerequisites and an unlock cost. This demo shows the minimal version of that: a flat array indexed by integer ID, with prerequisites stored as a list of IDs to check. No graph library, no node objects — just Dictionary lookups.

The same pattern extends naturally to tech trees in 4X games, talent rows in MMOs, passive grids in ARPGs, and ability unlock progressions in platformers. Understanding the prerequisite-check and point-deduction loop is the reusable core.

## How It Works

### Skill Data Model

```gdscript
{"id": 7, "name": "Combo",
 "desc": "Combine Strength+Speed for burst.",
 "pos": Vector2(320, 220),
 "prereqs": [1, 3],        # both Strength II AND Speed I must be unlocked
 "unlocked": false,
 "cost": 2}                 # costs 2 skill points
```

All skills live in an Array. The `id` field equals the Array index, so `skills[prereq_id]` is always a direct lookup — O(1), no search needed. The unlock *rules* live in a reusable class, `SkillTree` (`scripts/skill_tree.gd`); `main.gd` owns rendering, hover hit-testing, and colors.

### Prerequisite Check (`SkillTree.can_unlock`)

```gdscript
func can_unlock(index: int) -> bool:
    var s = skills[index]
    if s.unlocked or points < s.cost:
        return false
    for prereq_id in s.prereqs:
        if not skills[prereq_id].unlocked:
            return false
    return true
```

All three conditions must pass: not already owned, enough points, and every listed prerequisite unlocked. The loop short-circuits on the first unmet prerequisite.

### Unlock Action (`SkillTree.unlock`)

```gdscript
# main.gd
if _hovered >= 0 and _tree.unlock(_hovered):
    queue_redraw()

# skill_tree.gd — atomic: re-checks, spends points, sets the flag, emits a signal
func unlock(index: int) -> bool:
    if not can_unlock(index): return false
    skills[index].unlocked = true
    points -= skills[index].cost
    skill_unlocked.emit(index)
    return true
```

`unlock()` re-validates before committing, so the caller can't spend points on an ineligible skill. Point deduction and flag-set happen atomically; the R key calls `reset()` for rollback.

### Hover Detection

Mouse position is checked against every node each `InputEventMouseMotion`:

```gdscript
var closest_dist := HOVER_RADIUS   # 32 px threshold
for i in range(_skills.size()):
    var dist := mouse_pos.distance_to(_skills[i].pos)
    if dist < closest_dist:
        closest_dist = dist
        _hovered = i
```

The nearest-within-threshold approach prevents two large adjacent nodes from both claiming hover simultaneously.

## Visual States

| Node appearance | Meaning |
|-----------------|---------|
| Bright fill, gold outline | Unlocked |
| Dark fill, pulsing blue outline | Available (prereqs met, points sufficient) |
| Dark fill, dim gray outline | Locked |
| Slightly larger radius (32 vs 28) | Hovered |

Connection lines between nodes turn gold when both endpoints are unlocked, giving a "lit path" effect that shows which branches have been activated.

The pulsing effect on available nodes uses `sin(_pulse_time)` driven by `_process`:

```gdscript
var pulse := (sin(_pulse_time) + 1.0) * 0.5   # 0.0 – 1.0
fill_color = Color(0.15, 0.15, 0.25 + pulse * 0.1)
```

## Skill Tree Graph Layout

```
               [0] Strength I  (cost 1, root)
              /       |          \          \
     [5] Magic I  [1] Str II  [3] Speed I  [9] Passive
         |             |     \       |
     [6] Magic II  [2] Str III  [7] Combo*  [4] Speed II
                                    |
                               [8] Ultimate
```

Skill 7 (Combo) is the only node with two prerequisites: Strength II (id 1) AND Speed I (id 3). Skills 7 and 8 cost 2 points; all others cost 1.

## How to Adapt This in Your Project

- **Load from data file**: Replace `_build_skills()` with a JSON or CSV loader. The Dictionary structure maps directly to JSON objects; `JSON.parse_string()` returns an Array of Dictionaries.
- **Persist unlocked state**: Iterate `_skills` and save `{id: skill.id, unlocked: skill.unlocked}` pairs to your save file. On load, look up by ID and set `unlocked`.
- **Apply skill effects**: Connect `SkillTree.skill_unlocked(index)` to a `CharacterStats.apply_skill(id)` method that buffs the appropriate stats.
- **Refund / respec**: Call `SkillTree.reset(points)` to relock everything and restore points. Gate it behind a cost (gold, respec token) for balance.
- **Variable node shapes**: Add a `"shape": "circle"|"diamond"|"square"` field and branch in `_draw()` to visually distinguish skill types (active, passive, ultimate).

## Use as a building block

**Copy:** `scripts/skill_tree.gd` (the `SkillTree` class). It's a `RefCounted` — the unlock rules and point pool, with no rendering.

**Public API**
- `_init(skill_defs: Array, starting_points)` — each skill: `{id, prereqs: Array[int], unlocked, cost, ...}` (extra fields like `name`/`desc`/`pos` are yours).
- `points`, `skills`.
- `can_unlock(i) -> bool`, `unlock(i) -> bool`, `reset(points)`.
- signal `skill_unlocked(index)`.

**Integrate**
1. `var tree := SkillTree.new(skill_defs, 3)`.
2. On click: `if tree.unlock(hovered): refresh()`.
3. Render from `tree.skills`, greying out nodes where `tree.can_unlock(i)` is false; connect `skill_unlocked` to apply the bonus.

**Notes**
- `class_name SkillTree` is global — rename if it collides.
- Prereqs use array indices (`id == index`); for sparse ids, look up by id inside your defs instead.
- Layout (`pos`) and colors are presentation — keep them in your view, as this demo does.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.distance_to(other)` | Radial hover detection |
| `draw_line(from, to, color, width)` | Prerequisite connection lines |
| `draw_arc(center, r, from, to, pts, color, width)` | Node outline rings |
| `sin(_pulse_time)` | Animated pulse on available nodes |
| `Array.is_empty()` | Check for root nodes (no prerequisites) |

## Controls

| Input | Action |
|-------|--------|
| Mouse move | Hover a skill node to show tooltip |
| Left-click | Unlock hovered skill (if available) |
| R | Reset all unlocks, restore 3 skill points |
| + / = / Numpad+ | Add 1 skill point (for testing) |

## Key Constants

```gdscript
const NODE_RADIUS  := 28.0   # default draw radius
const HOVER_RADIUS := 32.0   # enlarged when hovered; also hit-test threshold

# Starting skill points
# SkillTree starts with 3 points (SkillTree.new(_skills, 3))

# Skill IDs 7 and 8 cost 2 points; all others cost 1
# prereqs: [] = root node, [0] = requires Strength I, [1,3] = requires both
```

## Files

| File | Purpose |
|------|---------|
| `scripts/skill_tree.gd` | **`SkillTree`** — reusable unlock rules + point pool (`can_unlock`/`unlock`/`reset`) |
| `scripts/main.gd` | Skill data, rendering, tooltip, hover hit-testing; owns a `SkillTree` |
| `tests/test_logic.gd` | Unit tests for unlock rules, point deduction, multi-prereq gating |
| `scenes/main.tscn` | Scene root (Node2D with script) |
| `tests/test.tscn` | Test runner scene |
