# Stamina System

<!-- tags: physics, ui -->

A depletable/regenerating resource that gates sprinting in a side-scrolling platformer: hold Shift to sprint at 360 px/s, stamina drains while active, and regenerates after a brief cooldown delay once you stop.

## Purpose

Stamina (also called energy, heat, or focus depending on the genre) is one of the most common resource-gating patterns in games. It appears in action-RPGs limiting dodge-roll spam, in souls-likes gating every swing, in platformers limiting dash or sprint, and in stealth games limiting breath-holding. The mechanic creates a rhythm of engagement and recovery that prevents players from holding one button forever.

This demo implements the canonical three-state pattern — drain, wait, regenerate — with a crucial detail: a post-sprint delay before regen begins. This `REGEN_DELAY` prevents the exploit of rapidly tapping Shift to get near-infinite sprint by resetting the regen timer on every sprint frame. The pattern is directly reusable for mana, rage, ki, or any resource with asymmetric gain/drain rates.

## How It Works

### Three-State Logic

```gdscript
if _sprinting:
    _stamina    = maxf(_stamina - DRAIN_RATE * delta, 0.0)
    _regen_wait = REGEN_DELAY          # reset delay on every sprint frame
else:
    _regen_wait = maxf(_regen_wait - delta, 0.0)
    if _regen_wait <= 0.0:
        _stamina = minf(_stamina + REGEN_RATE * delta, STAMINA_MAX)
```

**State 1 — Draining**: Sprinting. Stamina decreases at `DRAIN_RATE` per second; the regen delay is kept pinned at its maximum so the moment you release Shift, the countdown starts from a full delay.

**State 2 — Waiting**: Not sprinting, but `_regen_wait > 0`. Stamina sits frozen while the delay ticks down. This is the state that punishes tap-spamming — each Shift press resets the timer back to `REGEN_DELAY = 0.8` seconds.

**State 3 — Regenerating**: Not sprinting, delay expired. Stamina rises at `REGEN_RATE` per second up to `STAMINA_MAX`.

### Sprint Gate

```gdscript
var want_sprint := Input.is_key_pressed(KEY_SHIFT) and h != 0.0
_sprinting = want_sprint and _stamina > 0.0
```

`_stamina > 0.0` is the hard gate. `h != 0.0` prevents draining stamina while standing still and holding Shift — a small quality-of-life detail. When stamina hits zero, sprint cuts out mid-run; the player automatically decelerates to normal speed.

### Visual Feedback

```gdscript
_bar.value    = _stamina
_bar.modulate = Color.GREEN if _stamina > 30.0 else Color.ORANGE_RED
_label.text   = "SPRINTING" if _sprinting else ("DEPLETED" if _stamina <= 0.0 else "READY")
```

The `ProgressBar` above the player turns orange-red when stamina falls below 30 — a warning band before full depletion. The label cycles through three states to make the system state legible. The player sprite turns gold while sprinting via `_draw()`.

## Stamina Rate Tuning

The relationship between `DRAIN_RATE`, `REGEN_RATE`, and `REGEN_DELAY` determines the feel of the system:

| Constant | Value | Effect |
|----------|-------|--------|
| `DRAIN_RATE` | 38.0 /s | Full stamina lasts ~2.6 seconds of sprinting |
| `REGEN_RATE` | 18.0 /s | Empty stamina fully regens in ~5.6 seconds |
| `REGEN_DELAY` | 0.8 s | Must wait 0.8 s after stopping before regen begins |

Drain is roughly 2× regen, so a player who sprints until depletion must wait more than double the sprint duration before recovering — this is the classic "cost more than you earn" punishment for overextending. Reducing `REGEN_DELAY` to 0.0 creates a soft system (Zelda-style hearts); increasing it toward 2.0–3.0 creates a harsh system (Dark Souls-style).

## How to Adapt This in Your Project

- **Multiple actions on one pool**: Add separate drain rates per action (dodge = 25, sprint = 38, heavy attack = 50) and check the same `_stamina > action_cost` gate before each.
- **Stamina as a `CharacterStats` resource**: Move the constants and variables onto a `Resource` subclass so they persist across scenes and are accessible to UI nodes via a signal.
- **Partial regen cap**: Set `STAMINA_MAX` to `_stamina_max_current` (which starts lower) and increase it with upgrades — common in action-RPGs for "vitality" progression.
- **Audio feedback**: Play a "whoosh" sound when `_sprinting` transitions false→true; play an "exhausted" sound when `_stamina` first reaches 0.
- **UI health/stamina bars via theme**: Replace `_bar.modulate` with a `StyleBoxFlat` swap on the bar's `fill` theme override for a cleaner color change without tinting the whole bar node.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D` + `move_and_slide()` | Physics-based movement with floor detection |
| `Input.get_axis("ui_left", "ui_right")` | Horizontal input as –1 to +1 float |
| `Input.is_key_pressed(KEY_SHIFT)` | Held key check without InputMap |
| `is_on_floor()` | Jump gate — only jump from ground |
| `maxf(v - rate * delta, 0.0)` | Drain clamped at zero |
| `minf(v + rate * delta, max)` | Regen clamped at maximum |
| `ProgressBar.value` | Direct assignment drives fill percentage |
| `ProgressBar.modulate` | Color tint to show warning state |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys / A, D | Move left / right |
| Hold Shift | Sprint (consumes stamina; blocked when depleted) |
| Arrow Up (`ui_up`) | Jump (only from floor) |

## Key Constants

```gdscript
const SPEED        := 200.0   # px/s normal walk
const SPRINT_SPEED := 360.0   # px/s while sprinting
const JUMP_VEL     := -400.0  # initial upward velocity
const GRAVITY      := 900.0   # px/s^2 downward

const STAMINA_MAX  := 100.0
const DRAIN_RATE   := 38.0    # stamina/s lost while sprinting
const REGEN_RATE   := 18.0    # stamina/s gained while idle
const REGEN_DELAY  := 0.8     # seconds after sprint before regen starts
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Player physics, stamina state machine, visual feedback |
| `tests/test_logic.gd` | Unit tests for drain, regen, delay, depletion gate, and speed values |
| `scenes/main.tscn` | Scene with CharacterBody2D, ProgressBar, InfoLabel, floor platform |
| `tests/test.tscn` | Test runner scene |

## Use as a building block

**Copy:** `scripts/player.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [animated-sprite](../animated-sprite) — A sprite sheet generated entirely in code — no image files or imports.
- [area-trigger](../area-trigger) — `Area2D` invisible trigger zones firing signals on body enter/exit.
- [camera-deadzone](../camera-deadzone) — Camera stays still until the player exits a rectangular dead zone, then catches up.
- [camera-rooms](../camera-rooms) — Room-based camera transitions using `Area2D`, signals, and `Tween`.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

