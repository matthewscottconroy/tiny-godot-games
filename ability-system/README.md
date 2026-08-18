# Ability System

<!-- tags: shows-its-working -->

Four hotkey-bound abilities (Fireball, Shield, Dash, Heal), each with an independent cooldown timer and a mana cost, backed by a shared mana pool that regenerates over time.

## Purpose

Ability systems are the central mechanic of action-RPGs, MOBAs, fighting games, and many platformers. The key engineering challenges are: preventing spam (cooldowns), limiting resource usage (mana/energy costs), giving clear feedback on state (ready vs. on cooldown vs. not enough mana), and keeping the ability data table-driven so adding a fifth ability doesn't require restructuring code.

This demo uses a single Array of ability Dictionaries so the activation, cooldown-tick, and rendering code all operate on the same loop — no switch statements, no per-ability functions. The pattern scales to 20 abilities just as cleanly as four.

## How It Works

### Ability Data Model

```gdscript
var _abilities: Array = [
    {"name": "Fireball", "key": KEY_Q, "cooldown": 2.0, "cost": 20,
     "color": Color.TOMATO, "timer": 0.0, "effect_timer": 0.0},
    {"name": "Shield",   "key": KEY_W, "cooldown": 5.0, "cost": 35,
     "color": Color.CORNFLOWER_BLUE, "timer": 0.0, "effect_timer": 0.0},
    # ...
]
```

`timer` is the remaining cooldown in seconds; `effect_timer` drives the visual burst ring. Both count down toward zero in `_process`.

### Activation Gate

```gdscript
func _try_use_ability(i: int) -> void:
    var ability: Dictionary = _abilities[i]
    if ability["timer"] > 0.0:
        _add_log("%s is on cooldown!" % ability["name"])
        return
    if _mana < ability["cost"]:
        _add_log("Not enough mana for %s!" % ability["name"])
        return
    _mana -= float(ability["cost"])
    ability["timer"] = ability["cooldown"]
    ability["effect_timer"] = 0.6
    _add_log("%s activated!" % ability["name"])
```

Two guards in sequence: cooldown check first, then mana check. Ordering matters for the log message — the player learns the right reason for failure.

### Cooldown and Mana Tick

```gdscript
func _process(delta: float) -> void:
    _mana = minf(MAX_MANA, _mana + MANA_REGEN * delta)
    for ability in _abilities:
        ability["timer"]       = maxf(0.0, ability["timer"]       - delta)
        ability["effect_timer"] = maxf(0.0, ability["effect_timer"] - delta)
```

`maxf(0.0, timer - delta)` clamps the timer at zero so it never goes negative. Mana regenerates at `MANA_REGEN = 8.0` mana/second and caps at `MAX_MANA = 100`.

### Cooldown Arc Visualization

The circular arc in each ability box sweeps from the top (`-PI/2`) through `TAU * (remaining / total)` radians. A full red arc means the ability just fired; an empty arc (or "RDY" text) means it's ready:

```gdscript
var sweep := TAU * (ability["timer"] / ability["cooldown"])
draw_arc(center, 18, -PI / 2, -PI / 2 + sweep, 32,
         Color(0.8, 0.2, 0.2), 14.0)
```

The thick `line_width` of 14 creates the filled-sector appearance without needing a polygon.

## Cooldown and Resource Design

**Independent cooldowns** — each ability has its own timer, so using Fireball doesn't delay Shield. This is standard for most action games. The alternative, a single global GCD (Global Cooldown) shared by all abilities, is used in MMOs to pace button-mashing.

**Shared mana pool** — all abilities draw from one resource, so a player who dumps everything on Heal may not have mana for Fireball. This creates interesting priority decisions. Games with distinct resource types per ability (heat for guns, focus for melee) use the same Dictionary pattern but add a `resource_type` field.

**Regen rate vs. cost balance** — at 8 mana/second, a depleted pool refills in 12.5 seconds. The cheapest ability (Dash at 15) is affordable after 2 seconds of idle. Raising `MANA_REGEN` reduces downtime; raising costs pushes the player toward more conservative play.

## How to Adapt This in Your Project

- **Add abilities at runtime**: `_abilities.append({...})` is all that's needed; all loops process the full array automatically.
- **Connect to InputMap**: Replace `ke.keycode == _abilities[i]["key"]` with `InputMap` action names stored in the Dictionary for rebindable controls.
- **Passive / toggle abilities**: Add a `"active": bool` field. Toggle abilities flip `active` on use and apply their effect each frame while `active` is true, still subject to mana drain.
- **Ability upgrades**: Store the base stats in the Dictionary and add `"level": int`. Scale `cooldown` and `cost` from `level` in `_try_use_ability`.
- **Multiple resource types**: Add a `"resource": "stamina"` field and route the drain through a dictionary of resource pools.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `InputEventKey.keycode` | Compare against `KEY_Q` etc. for hotkey detection |
| `InputEventKey.echo` | Filter out held-key repeats (only trigger on first press) |
| `minf(MAX_MANA, mana + regen * delta)` | Regen clamped at maximum |
| `maxf(0.0, timer - delta)` | Countdown clamped at zero |
| `draw_arc(center, r, from, to, pts, color, width)` | Cooldown sweep arc |

## Controls

| Key | Ability | Mana Cost | Cooldown |
|-----|---------|-----------|----------|
| Q | Fireball | 20 | 2.0 s |
| W | Shield | 35 | 5.0 s |
| E | Dash | 15 | 3.0 s |
| R | Heal | 40 | 8.0 s |

## Key Constants

```gdscript
const MANA_REGEN := 8.0    # mana per second
const MAX_MANA   := 100.0

# Per-ability fields: name, key, cooldown (s), cost, color, timer, effect_timer
# effect_timer: 0.6 s burst ring duration after activation
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Ability data, activation logic, mana regen, rendering |
| `tests/test_logic.gd` | Unit tests for cooldown gate, mana deduction, regen cap |
| `scenes/main.tscn` | Scene root (Node2D with script) |
| `tests/test.tscn` | Test runner scene |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [2d-lighting](../2d-lighting) — Runtime `GradientTexture2D` point lights under a global `CanvasModulate`.
- [audio-positional](../audio-positional) — `AudioStreamPlayer2D` spatial attenuation with a synthesized tone.
- [behavior-tree](../behavior-tree) — Enemy AI driven by a composable behavior tree (patrol/investigate/chase/attack).
- [bezier-path](../bezier-path) — Interactive cubic Bézier editor with an animated dot and tangent arrow.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

