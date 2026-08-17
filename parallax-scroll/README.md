# Parallax Scroll

Demonstrates the parallax effect: multiple background layers scrolling at different speeds to simulate depth and distance.

## Purpose

Parallax scrolling is a classic technique that gives 2D games a sense of three-dimensional depth. Far objects (mountains, sky) move slowly relative to the camera; near objects (trees, ground) move fast. This depth cue — called **motion parallax** — is the same cue used by the human visual system to estimate distance in the real world. This demo implements three layers with distinct scroll speeds.

## Controls

- **Arrow keys**: Move the player left and right
- Watch the three background layers scroll at different speeds as you move

## How It Works

### Node Tree

```
Main (Node2D)
├── Background (ParallaxBackground)
│   ├── FarLayer (ParallaxLayer)       ← far_layer.gd
│   ├── MidLayer (ParallaxLayer)       ← mid_layer.gd
│   └── NearLayer (ParallaxLayer)      ← near_layer.gd
└── Player (CharacterBody2D)           ← player.gd
```

### ParallaxBackground and ParallaxLayer

`ParallaxBackground` is a container node that tracks the camera's position. Each `ParallaxLayer` child has a `motion_scale` property — a `Vector2` that controls how much the layer moves relative to the camera.

| Layer | motion_scale.x | Effect |
|---|---|---|
| FarLayer | 0.1 | Moves 10% as fast as the camera — sky/mountains |
| MidLayer | 0.4 | Moves 40% as fast — rolling hills |
| NearLayer | 0.75 | Moves 75% as fast — trees and ground |

`motion_scale = Vector2(1.0, 0.0)` would move at camera speed (no parallax). `Vector2(0.0, 0.0)` would be completely fixed (not useful for parallax).

### `scripts/far_layer.gd` — Sky + Mountains

```gdscript
func _draw() -> void:
    draw_rect(...)   # solid sky blue background
    for i in range(-1, 12):
        var x := i * 280
        draw_polygon(
            [Vector2(x, 420), Vector2(x + 140, 180), Vector2(x + 280, 420)],
            [Color(0.48, 0.52, 0.64)]
        )
```

Draws a repeating row of triangular mountain silhouettes. The range starts at `-1` to ensure mountains are visible when scrolled to the left edge.

### `scripts/mid_layer.gd` — Hills

Draws circles at y=430 with radius 110. Overlapping circles create rolling hill shapes. Because `motion_scale.x = 0.4`, these hills move noticeably slower than the near layer, reinforcing depth.

### `scripts/near_layer.gd` — Trees + Ground

Draws a ground strip and tree trunks + canopy. The near layer moves at 75% camera speed — close to the player's speed, making it feel like nearby ground-level scenery.

### `scripts/player.gd`

Standard `CharacterBody2D` with horizontal movement only. The player's `Camera2D` (or the `ParallaxBackground`'s automatic tracking of the viewport) drives the parallax scroll.

## Parallax Theory

### Motion Parallax as a Depth Cue

When you look out a moving car window, nearby objects (fence posts) appear to rush past quickly, while distant objects (mountains) barely move. The brain uses this disparity in angular velocity to estimate distance — closer objects have higher angular velocity.

The parallax scroll replicates this: each layer's `motion_scale` simulates the slower apparent motion of more distant objects.

### Tiling and Seams

For infinite scrolling, each `ParallaxLayer` should have `motion_mirroring` set — Godot repeats the layer's content seamlessly. In this demo, `_draw()` renders elements across a wide range (`range(-1, 12)`) to cover the visible window without seamless tiling.

### Camera Independence

`ParallaxBackground` reads the viewport's camera offset automatically. You do not need to pass the camera position to the layers — Godot handles this internally. When the camera is a child of the player, moving the player drives the camera, which drives the parallax background.

### Vertical Parallax

`motion_scale.y` controls vertical parallax (useful for games with vertical scrolling or pseudo-3D perspective). Setting `motion_scale.y = 0.0` locks layers vertically while allowing horizontal scroll — common for horizontal platformers where you don't want the sky to shift when the player jumps.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ParallaxBackground` | Container that reads camera position |
| `ParallaxLayer.motion_scale` | Scroll speed relative to camera (Vector2) |
| `ParallaxLayer.motion_mirroring` | Repeat size for seamless tiling |
| `draw_polygon(vertices, colors)` | Filled polygon in _draw() |
| `draw_circle(center, radius, color)` | Solid circle in _draw() |

## Files

| File | What it holds |
|------|---------------|
| `scripts/far_layer.gd` | `far layer` behaviour |
| `scripts/mid_layer.gd` | `mid layer` behaviour |
| `scripts/near_layer.gd` | `near layer` behaviour |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/far_layer.gd`, `scripts/mid_layer.gd`, `scripts/near_layer.gd`, `scripts/player.gd`.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.
- [checkpoint-system](../checkpoint-system) — One-way checkpoints that update respawn position; press R to die and respawn.
- [noise-terrain](../noise-terrain) — 1D terrain from `get_noise_1d()`, redrawing live as you tune parameters.
- [radial-menu](../radial-menu) — Hold Tab to open a six-item radial action menu.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

