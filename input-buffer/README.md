# Input Buffer

An attack input buffer that queues a press made slightly early during a cooldown and fires it the moment the cooldown clears. Two on-character progress bars show the cooldown and buffer state in real time.

## Purpose

Many action games have cooldowns — skills, attacks, dodge rolls, special abilities. Without buffering, the player must time their press to land on the exact frame the cooldown expires. That's a skill floor measured in milliseconds. Most players will miss it and feel like the game ignored their input. The resulting frustration is often reported as "unresponsive controls" even when the system is technically correct.

Input buffering solves this: press slightly early, and the action fires as soon as it becomes available. The player perceives instant response because the delay between their press and the action is less than one buffer window (180ms here). Games that feel "snappy" and "responsive" — *Devil May Cry*, *Hades*, *Street Fighter* — use input buffering extensively. This demo implements the minimal version and visualizes both timers with progress bars so you can see exactly what the buffer is doing.

## How It Works

The buffer/cooldown timing lives in a reusable class, `InputBuffer`
(`scripts/input_buffer.gd`), a plain `RefCounted`. The player owns one
(`var _attack := InputBuffer.new()`) and drives it with three calls:
`press()` on input, `update(delta)` each frame, and `consume()` to check whether
a queued press may fire now. The player script keeps only movement and drawing.

### Two Timers (inside `InputBuffer`)

```gdscript
var buffer_window := 0.18   # how early a press can be queued
var cooldown_time := 0.5    # time between attacks

func update(delta: float) -> void:
    _cooldown = maxf(_cooldown - delta, 0.0)
    _buffer   = maxf(_buffer   - delta, 0.0)
```

`maxf(..., 0.0)` clamps each timer at zero so they never go negative.

### Setting the Buffer

```gdscript
# player.gd
if Input.is_action_just_pressed("ui_accept"):
    _attack.press()          # sets _buffer = buffer_window

# InputBuffer.press():
func press() -> void:
    _buffer = buffer_window
```

`is_action_just_pressed` fires on the frame of the press — it does not repeat. Each new press resets the buffer to the full window. If the player presses twice during a cooldown, the second press overwrites the first: only the most recent intent matters.

### Firing the Attack

```gdscript
# player.gd
if _attack.consume():
    _fire_attack()

# InputBuffer.consume() — true once, when a queued press may fire:
func consume() -> bool:
    if _buffer > 0.0 and _cooldown == 0.0:
        _buffer = 0.0
        _cooldown = cooldown_time     # start the next cooldown
        return true
    return false
```

`consume()` returns true when a buffer is pending AND the cooldown has expired, then immediately starts the next cooldown and clears the buffer so it can't fire twice. The player's `_fire_attack()` now only does presentation (`_flash`, `_hits += 1`).

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
draw_rect(Rect2(-22, 32, bar_w * _attack.cooldown_ratio(), 6), Color.ORANGE_RED)

# Buffer bar (green) below cooldown bar
draw_rect(Rect2(-22, 40, bar_w * _attack.buffer_ratio(), 6), Color.LIME_GREEN)
```

`InputBuffer` exposes `cooldown_ratio()` / `buffer_ratio()` (0..1) for bars and `cooldown_left()` / `buffer_left()` for the second-count labels.

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

## Use as a building block

**Copy:** `scripts/input_buffer.gd` (the `InputBuffer` class). It's a `RefCounted` — pure timing, no scene or input-map dependency (it doesn't read input itself; you tell it when a press happened).

**Public API**
- tuning: `buffer_window`, `cooldown_time`
- `press()` — queue an input.
- `update(delta)` — age the timers (call each frame).
- `consume() -> bool` — true once when a queued press may fire; starts the cooldown.
- `cooldown_left()` / `buffer_left()` (seconds) and `cooldown_ratio()` / `buffer_ratio()` (0..1) for UI.

**Integrate** (any ability, not just attacks)
1. `var _dash := InputBuffer.new()`; set `cooldown_time`/`buffer_window`.
2. `if Input.is_action_just_pressed("dash"): _dash.press()`.
3. Each frame: `_dash.update(delta)`; `if _dash.consume(): do_dash()`.

**Notes**
- `class_name InputBuffer` is global — rename if it collides.
- Structurally identical to jump buffering (see *Relationship to Jump Buffering* above) — the only difference is the readiness condition, here `cooldown_time`.
- For combo systems, keep one `InputBuffer` per action, or extend it to a small queue of timestamps.

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
# player.gd
const SPEED   := 180.0
const GRAVITY := 900.0

# input_buffer.gd (fields; defaults match this demo)
var cooldown_time := 0.5    # seconds between attacks
var buffer_window := 0.18   # seconds a queued press stays valid
```

## Files

| File | Purpose |
|------|---------|
| `scripts/input_buffer.gd` | **`InputBuffer`** — reusable buffer/cooldown timing (`press`/`update`/`consume`) |
| `scripts/player.gd` | Movement, attack presentation, bar drawing; owns an `InputBuffer` |
| `scenes/main.tscn` | Level with player and platforms |
| `tests/test_logic.gd` | Tests for buffer window, cooldown interaction, fire conditions |
