# Experience & Leveling

Click enemies to defeat them, collect XP, and watch a character level up through an exponential threshold curve — with overflow carry, stat gains per level, and a respawn loop so the enemies never run out.

## Purpose

XP-based leveling is the backbone of virtually every RPG, action-RPG, and roguelite. Its job is twofold: reward short-term actions (kill feedback) and provide long-term progression pacing (level gates). The core design challenge is choosing a threshold formula that feels satisfying — too flat and levels come too fast and lose meaning, too steep and players feel stuck. This demo implements the classic exponential curve (`BASE_XP * 1.4^(level-1)`), which spaces each level roughly 40% farther apart, keeping early levels quick and later ones weighty. It also shows the important detail of XP overflow: any excess after a level-up carries forward rather than being wasted, so gaining a large chunk of XP can chain multiple level-ups in one hit.

Genres that depend heavily on this pattern include JRPGs, action-RPGs, card-battlers, idle games, and skill-based progression systems. Even non-combat systems (crafting XP, social XP) use the same threshold logic with different gain sources.

## How It Works

The XP/level logic lives in a reusable class, `LevelSystem`
(`scripts/level_system.gd`), a plain `RefCounted`. `main.gd` handles the
enemies, input, and drawing, and calls `_leveling.gain(xp)` when an enemy dies.

### XP Threshold Formula (`LevelSystem.threshold`)

```gdscript
var base_xp := 50
var growth := 1.4

func threshold(lvl: int) -> int:
    return int(base_xp * pow(growth, lvl - 1))
```

The threshold for leveling up **from** a given level grows by a factor of 1.4 each step:

| Level | XP to next |
|-------|------------|
| 1     | 50         |
| 2     | 70         |
| 3     | 98         |
| 4     | 137        |
| 5     | 192        |

`pow(1.4, 0)` equals 1.0, so level 1 always costs exactly `base_xp`.

### Gaining XP and Level-Up Overflow (`LevelSystem.gain`)

```gdscript
func gain(amount: int) -> void:
    xp += amount
    while xp >= xp_for_next and level < max_level:
        xp -= xp_for_next            # subtract, don't reset to 0
        level += 1
        xp_for_next = threshold(level)
        leveled_up.emit(level)
    xp_gained.emit(xp, xp_for_next)
```

The `while` loop handles chained level-ups. `xp -= xp_for_next` (not `xp = 0`) preserves the overflow — gain 200 XP when you only need 98 and the remaining 102 carries into the next threshold. **Stat rewards aren't in here**: they're game-specific, so the demo connects `leveled_up` and applies `_stat_attack += 5` there. That keeps `LevelSystem` reusable across characters with different reward tables.

### Enemy Interaction

Each enemy is a plain Dictionary with `pos`, `radius`, `xp_value`, `color`, `alive`, and `_respawn_timer`. A left-click checks distance to every living enemy and kills the first one within its radius:

```gdscript
var dist: float = click_pos.distance_to(enemy["pos"])
if dist <= enemy["radius"]:
    enemy["alive"] = false
    enemy["_respawn_timer"] = 2.0
    _gain_xp(enemy["xp_value"])
    break
```

`_process` ticks respawn timers and revives enemies, ensuring the player always has targets.

### Enemy Interaction

Each enemy is a plain Dictionary with `pos`, `radius`, `xp_value`, `color`, `alive`, and `_respawn_timer`. A left-click checks distance to every living enemy and kills the first one within its radius:

```gdscript
var dist: float = click_pos.distance_to(enemy["pos"])
if dist <= enemy["radius"]:
    enemy["alive"] = false
    enemy["_respawn_timer"] = 2.0
    _gain_xp(enemy["xp_value"])
    break
```

`_process` ticks respawn timers and revives enemies, ensuring the player always has targets.

## XP Threshold Design Tradeoffs

**Exponential (`BASE * factor^level`)** — used here. Feels natural; each level takes a predictable percentage more than the last. Easy to tune with one multiplier (1.4). Downside: very long tails at high levels.

**Polynomial (`BASE * level^2`)** — used in many older RPGs. Grows faster early, slower relatively at high levels. Formula is `50 * level * level`.

**Table-based** — hardcoded array of thresholds per level. Maximum designer control, no formula to reason about, but tedious to edit and hard to extend beyond the table.

For this demo, the 1.4 multiplier means level 10 requires `50 * 1.4^9 ≈ 965 XP`, which at ~14 XP per kill averages ~70 kills from level 1. Adjusting `BASE_XP` scales total XP needed without changing the curve shape; adjusting `1.4` changes how steeply the later levels pull away.

## Use as a building block

**Copy:** `scripts/level_system.gd` (the `LevelSystem` class). It's a `RefCounted` — pure progression math, no scene.

**Public API**
- tuning: `base_xp`, `growth`, `max_level`
- state: `level`, `xp`, `xp_for_next`
- `gain(amount)` — award XP; carries overflow across multiple level-ups.
- `threshold(lvl) -> int` — XP to advance from a given level.
- signals `xp_gained(current_xp, needed)`, `leveled_up(new_level)`.

**Integrate**
1. `var levels := LevelSystem.new()` (set `base_xp`/`growth`/`max_level` to taste).
2. On a kill/quest reward: `levels.gain(reward_xp)`.
3. `levels.leveled_up.connect(_on_level_up)` — apply *your* per-level bonuses (max HP, abilities, stat points) here; keep them out of the reusable class.
4. Read `levels.xp` / `levels.xp_for_next` to fill an XP bar.

**Notes**
- `class_name LevelSystem` is global — rename if it collides.
- Swap the curve by editing `threshold()` (polynomial, table-based) without touching `gain()`.

## How to Adapt This in Your Project

- **Connect to a character resource**: Store the `LevelSystem` on a `CharacterStats` resource so multiple systems can read `level`/`xp`.
- **Add more stat gains**: the `leveled_up` handler is the single place to apply all level-based bonuses — max health increases, new ability unlocks, enemy scaling, etc.
- **Multiple XP sources**: Any system that calls `_gain_xp(amount)` feeds the same pool. Quest rewards, exploration, and crafting can all award XP without changing the leveling logic.
- **Prestige / reset loops**: Save `_level` and `_stat_attack` to a `prestige_bonus` before resetting `_level = 1`, `_xp = 0`, then add the bonus back on top.
- **Per-skill XP pools**: Duplicate the `_xp`/`_level`/`_xp_for_next` triple for each skill (strength XP, magic XP, etc.) and call `_calc_xp_threshold` with that skill's level independently.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `pow(base, exp)` | Exponential threshold formula |
| `InputEventMouseButton.position` | Click position for hit testing |
| `Vector2.distance_to(other)` | Radial hit detection |
| `draw_rect(rect, color, filled, width)` | XP bar fill and border |
| `draw_arc(center, radius, from, to, pts, color, width)` | Enemy border ring |
| `ThemeDB.fallback_font` | Font reference without a FontFile asset |

## Controls

| Input | Action |
|-------|--------|
| Left-click enemy | Defeat it and gain its XP value |
| (automatic) | Enemies respawn after 2 seconds |

## Key Constants

```gdscript
# level_system.gd — fields (defaults)
var max_level := 10
var base_xp   := 50    # XP needed for level 1 → 2
var growth    := 1.4   # each level costs 40% more than the last

# main.gd — enemy data (pos, radius, xp_value, color); xp_value 8–20.
# _stat_attack starts at 10, gains +5 per level (applied in the leveled_up handler).
```

## Files

| File | Purpose |
|------|---------|
| `scripts/level_system.gd` | **`LevelSystem`** — reusable XP curve + level-up (`gain`/`threshold`) |
| `scripts/main.gd` | Enemy state, input, rendering; owns a `LevelSystem` |
| `tests/test_logic.gd` | Unit tests for threshold formula, overflow, and level-up chain |
| `scenes/main.tscn` | Scene root (Node2D with script attached) |
| `tests/test.tscn` | Test runner scene |

## Related demos

- [crafting-system](../crafting-system) — Combine two ingredients into a result via a commutative recipe dictionary.
- [skill-tree](../skill-tree) — A node-graph skill tree with prerequisites, costs, tooltips, and unlock states.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

