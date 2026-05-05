# Moving Platforms

Sinusoidally-oscillating platforms that carry the player when stood on. Demonstrates the `constant_linear_velocity` property that communicates platform motion to the physics engine.

## Purpose

Moving platforms seem simple but have a subtle requirement: a CharacterBody2D must know how fast the floor is moving to be carried correctly. Godot's `StaticBody2D.constant_linear_velocity` does exactly this. Setting position directly without it produces a platform that slides under the player's feet instead of carrying them.

## Controls

- **Arrow keys / WASD**: Move
- **Up**: Jump

## Surfaces

| Platform | Axis | Amplitude | Period |
|----------|------|-----------|--------|
| Vertical | Y | 80 px | 2.2 s |
| Horizontal | X | 100 px | 3.0 s |
| Diagonal | (1,−1) | 55 px | 2.8 s |

## How It Works

### `scripts/moving_platform.gd`

```gdscript
func _physics_process(delta: float) -> void:
    _elapsed += delta
    var prev   := position
    var offset := axis.normalized() * sin(_elapsed * TAU / period) * amplitude
    position                 = _origin + offset
    constant_linear_velocity = (position - prev) / delta
```

`constant_linear_velocity` is computed from the actual position delta each frame rather than differentiating the sine analytically. This stays correct even if period or amplitude change at runtime.

### Why `constant_linear_velocity` matters

Without it, `move_and_slide()` sees the floor as stationary. The player stands on the platform but doesn't inherit its velocity — the platform slides away from under them. With it, the physics engine adds the platform velocity to the character when computing floor contact.

### `@export` parameters

```gdscript
@export var amplitude:  float   = 80.0
@export var period:     float   = 2.5
@export var axis:       Vector2 = Vector2(0.0, 1.0)
@export var draw_size:  Vector2 = Vector2(120.0, 14.0)
```

All three platforms share the same script — the exported properties make each platform unique without subclassing.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `StaticBody2D.constant_linear_velocity` | Communicates platform speed to riders |
| `sin(t * TAU / period)` | Oscillates between −1 and +1 over `period` seconds |
| `Vector2.normalized()` | Ensures diagonal axes produce the correct amplitude |
| `@export var axis: Vector2` | Per-instance direction without subclassing |
