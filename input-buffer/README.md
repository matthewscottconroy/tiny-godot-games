# Input Buffer

An attack input buffer that queues a press made slightly early during a cooldown and fires it the moment the cooldown clears. Two on-character progress bars show the cooldown and buffer state in real time.

## Purpose

Many action games have cooldowns — skills, attacks, dodge rolls, special abilities. Without buffering, the player must time their press to land on the exact frame the cooldown expires. That's a skill floor measured in milliseconds. Most players will miss it and feel like the game ignored their input. The resulting frustration is often reported as "unresponsive controls" even when the system is technically correct.

Input buffering solves this: press slightly early, and the action fires as soon as it becomes available. The player perceives instant response because the delay between their press and the action is less than one buffer window (180ms here). Games that feel "snappy" and "responsive" — *Devil May Cry*, *Hades*, *Street Fighter* — use input buffering extensively. This demo implements the minimal version and visualizes both timers with progress bars so you can see exactly what the buffer is doing.

## How It Works

### Two Timers

```gdscript
const ATTACK_COOLDOWN := 0.5    # time between attacks
const BUFFER_WINDOW   := 0.18   # how early a press can be queued
```

Both timers count down to zero each frame:

```gdscript
_cooldown = maxf(_cooldown - delta, 0.0)
_buffer   = maxf(_buffer   - delta, 0.0)
```

`maxf(..., 0.0)` clamps each timer at zero so they never go negative.

### Setting the Buffer

```gdscript
if Input.is_action_just_pressed("ui_accept"):
    _buffer = BUFFER_WINDOW
```

`is_action_just_pressed` fires on the frame of the press — it does not repeat. Each new press resets the buffer to the full window. If the player presses twice during a cooldown, the second press overwrites the first, which is the correct behavior: only the most recent intent matters.

### Firing the Attack

```gdscript
if _buffer > 0.0 and _cooldown == 0.0:
    _fire_attack()

func _fire_attack() -> void:
    _cooldown = ATTACK_COOLDOWN
    _buffer   = 0.0
    _flash    = 0.15
    _hits    += 1
```

The attack fires when a buffer is pending AND the cooldown has expired. `_fire_attack()` immediately starts a new cooldown and clears the buffer so it can't fire twice.

### Scenario Walkthrough

1. Cooldown is active (orange bar full). Player presses attack.
2. `_buffer = 0.18` is set. The green buffer bar appears and starts draining.
3. Cooldown reaches zero while buffer is still `> 0.0`.
4. Next physics frame: `_buffer > 0 and _cooldown == 0` → attack fires immediately.
5. Player experiences zero additional delay after the cooldown expired.

If the player presses too early (more than 180ms before cooldown clears), the buffer drains to zero before the cooldown expires, and no attack fires. This is the "missed window" — the player pressed too far ahead and must press again.

### Visualization

```gdscript
# Cooldown bar (orange) above player
var cd_ratio := _cooldown / ATTACK_COOLDOWN
draw_rect(Rect2(-22, 32, bar_w * cd_ratio, 6), Color.ORANGE_RED)

# Buffer bar (green) below cooldown bar
var buf_ratio := _buffer / BUFFER_WINDOW
draw_rect(Rect2(-22, 40, bar_w * buf_ratio, 6), Color.LIME_GREEN)
```

Both bars shrink from right to left as their timers drain. Pressing attack while the orange bar is active shows the green bar appear and chase the orange bar down — exactly what happens internally.

## The Input Buffer Pattern

### Relationship to Jump Buffering

This is structurally identical to jump buffering in `platformer-controller`:

- **Jump buffer**: press jump slightly before landing → jump fires on first frame of floor contact.
- **Attack buffer**: press attack slightly before cooldown clears → attack fires on first frame of availability.

The code is identical in structure. Only the trigger condition differs: jump checks `is_on_floor()`, attack checks `_cooldown == 0.0`. The `BUFFER_WINDOW` constant controls how forgiving the window is in both cases.

### Buffer Window Tuning

`0.18` seconds (about 11 frames at 60fps) is a typical value for action games. Shorter windows feel more demanding and reward precision. Longer windows feel more forgiving but can cause attacks to fire when the player has "moved on" and is surprised by a delayed action. The right value depends on the game's tempo and the action's cooldown duration — a buffer window longer than the cooldown itself causes every press to always fire, which defeats the purpose.

### Extending to a Queue

This implementation stores a single buffered input (the most recent press). Some games store a short sequence: if you press attack three times quickly, three attacks fire in sequence as each cooldown clears. That's a `PackedFloat64Array` of buffer timestamps instead of a single `_buffer` float. Most games only need the single-input version.

### vs. Polling Every Frame

An alternative to the buffer timer is to poll `Input.is_action_pressed()` (held) rather than `is_action_just_pressed()` (edge-triggered). This fires the attack on the first available frame when both the button is held and the cooldown is clear. The trade-off: it only works while the button is physically held. If the player taps and releases quickly, the window can expire before `is_action_pressed` returns true on the fire frame. The timer-based buffer is more reliable for fast-tap inputs.

## How to Adapt This in Your Project

1. Add `_buffer` and `_cooldown` as float variables to any ability or attack component.
2. Set `_buffer = BUFFER_WINDOW` on `is_action_just_pressed`.
3. Check `_buffer > 0.0 and _cooldown == 0.0` to fire.
4. Expose `BUFFER_WINDOW` as a tunable constant (or a designer-editable `@export` variable).
5. For combo systems, maintain a small array of buffered inputs with timestamps instead of a single float.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_just_pressed(action)` | Edge-triggered: fires exactly once per press |
| `maxf(a, b)` | Float max — used to clamp timers at zero |
| `CharacterBody2D.is_on_floor()` | Floor detection for jump buffering (same pattern) |
| `Node2D._draw()` | Override for custom shape rendering |
| `queue_redraw()` | Request a `_draw()` call next frame |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys / WASD | Move |
| Up | Jump |
| Space / Enter | Attack (bufferable) |

## Key Constants

```gdscript
const ATTACK_COOLDOWN := 0.5    # seconds between attacks
const BUFFER_WINDOW   := 0.18   # seconds a queued press stays valid
```

## Files

| File | Purpose |
|------|---------|
| `scripts/player.gd` | Buffer timer, cooldown timer, attack logic, bar drawing |
| `scenes/main.tscn` | Level with player and platforms |
| `tests/test_logic.gd` | Tests for buffer window, cooldown interaction, fire conditions |
