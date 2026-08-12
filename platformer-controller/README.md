# Platformer Controller

A CharacterBody2D controller implementing two essential feel-quality techniques: **coyote time** and **jump buffering** — the difference between a controller that feels sluggish and one that feels tight.

## Purpose

Raw platformer input is frustrating: walk off a ledge a pixel too far and the jump doesn't fire. Press jump a frame too early before landing and nothing happens. Coyote time and jump buffering solve both problems by giving the player small forgiveness windows around their inputs. This demo shows the minimal implementation of both techniques and displays the timer state in real time so you can see exactly when the windows are open.

## Controls

- **Arrow keys**: Move left and right
- **Up / W**: Jump
- Watch the label above the player — it shows GROUNDED, COYOTE (with remaining time), AIR, and BUFFERED states

## How It Works

### Node Tree

```
Player (CharacterBody2D)     ← player.gd
└── InfoLabel (Label)
```

### `scripts/player.gd`

**Key constants:**
```gdscript
const COYOTE_TIME := 0.12   # seconds after leaving a floor where jump still works
const JUMP_BUFFER := 0.10   # seconds before landing where a queued jump will fire
```

**Coyote timer:**
```gdscript
_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)
```
Every frame: if on the floor, reset the timer to full. If in the air, count it down. This means the player can jump up to 0.12 seconds after they walk off a ledge — the window is imperceptible to the eye but eliminates the frustration of near-miss jumps.

**Jump buffer:**
```gdscript
if Input.is_action_just_pressed("ui_up"):
    _buffer = JUMP_BUFFER
_buffer = maxf(_buffer - delta, 0.0)
```
When the player presses jump, set a buffer timer. The timer counts down whether or not a jump fired. If the player is still airborne, the buffer just expires harmlessly. If they land within 0.10 seconds, the next block fires the jump.

**Jump execution:**
```gdscript
if _buffer > 0.0 and _coyote > 0.0:
    velocity.y = JUMP_VEL
    _coyote    = 0.0
    _buffer    = 0.0
```
Both timers must be active. Consuming both prevents double-jumps from stacking inputs.

## Why These Techniques Matter

Without coyote time, this sequence fails:
```
frame 1: player at ledge edge, on floor
frame 2: player steps off ledge, now in air
frame 3: player presses jump → FAILS (is_on_floor() is false)
```

With coyote time:
```
frame 3: player presses jump → SUCCESS (_coyote = 0.09 > 0)
```

Without jump buffer, this sequence fails:
```
frame 1: player in air, 3 frames from landing
frame 2: player presses jump early → FAILS (is_on_floor() is false, no action taken)
frame 4: player lands → jump never fires
```

With jump buffer:
```
frame 2: player presses jump → _buffer = 0.10
frame 4: player lands, is_on_floor() becomes true, _buffer = 0.07 > 0 → JUMP FIRES
```

The result is a controller that feels responsive rather than demanding pixel-perfect timing.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CharacterBody2D.is_on_floor()` | True after `move_and_slide()` if resting on a surface |
| `Input.is_action_just_pressed(a)` | Edge-triggered: fires only on the first frame of a press |
| `Input.get_axis(neg, pos)` | Returns −1 to +1 input for one axis |
| `maxf(a, b)` | Float max — used to clamp timers to 0 without going negative |
| `move_and_slide()` | Moves the body and updates floor/wall contact state |

## Files

| File | What it holds |
|------|---------------|
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/player.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

