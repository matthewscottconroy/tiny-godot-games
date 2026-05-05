# Input Buffer

An attack input buffer: pressing the attack key slightly early during a cooldown queues the action for the next available frame. Eliminates the frustration of "I pressed it but nothing happened."

## Purpose

Many action games have cooldowns — skills, attacks, abilities. Without buffering, the player must time their press to land exactly when the cooldown expires. That's a skill floor of millisecond precision. Input buffering solves this: press slightly early, and the action fires as soon as the cooldown clears. This demo shows the minimal implementation and visualizes both timers with progress bars.

## Controls

- **Arrow keys / WASD**: Move, Up to jump
- **Space / Enter**: Attack
- Try pressing attack during the orange cooldown bar — the green buffer bar will show the queued input

## How It Works

### `scripts/player.gd`

Two timers control the system:

```gdscript
const ATTACK_COOLDOWN := 0.5   # time between attacks
const BUFFER_WINDOW   := 0.18  # how early you can press and have it queue
```

**Setting the buffer:**
```gdscript
if Input.is_action_just_pressed("ui_accept"):
    _buffer = BUFFER_WINDOW
```
Every frame the buffer decrements. A press restarts it from the full window.

**Firing when both conditions met:**
```gdscript
if _buffer > 0.0 and _cooldown == 0.0:
    _fire_attack()

func _fire_attack() -> void:
    _cooldown = ATTACK_COOLDOWN
    _buffer   = 0.0
```
The attack fires only when the cooldown has cleared AND a buffered input is waiting. `_fire_attack()` resets both: starts a new cooldown, clears the buffer so it doesn't double-fire.

### Visualization

The player character draws two small progress bars:
- **Orange bar**: fraction of cooldown remaining
- **Green bar**: fraction of buffer window remaining

Watching these while pressing attack early shows the buffer window catching the press.

## Relationship to Jump Buffer

This is the same technique as jump buffering in `platformer-controller`, applied to attacks:
- Jump buffer: press jump slightly before landing → jump fires on contact
- Attack buffer: press attack slightly before cooldown clears → attack fires on ready

The pattern is identical. The `BUFFER_WINDOW` constant controls how forgiving the system is.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_action_just_pressed(a)` | Edge-triggered: fires only on the first frame of a press |
| `maxf(a, b)` | Clamp timer to 0 without going negative |
| `Node2D._draw()` | Override to draw custom shapes — called via `queue_redraw()` |
