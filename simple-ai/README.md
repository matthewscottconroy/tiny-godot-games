# Simple AI

Demonstrates the most basic form of enemy AI: a circular enemy that always moves directly toward the player, with a "sight line" drawn between them and a distance readout.

## Purpose

Before implementing complex behaviors (FSMs, pathfinding, steering), it is worth understanding the simplest possible AI: normalize the direction to the target and move along it. This demo shows the core math, how one node gets a reference to another, and how to visualize the AI's perception with a Line2D.

## Controls

- **Arrow keys**: Move the player (blue rectangle)
- Watch the red enemy always follow; the sight line connects them

## How It Works

### Node Tree

```
Main (Node2D)               ← main.gd  (draws sight line, shows distance)
├── Player (CharacterBody2D) ← player.gd
├── Enemy (CharacterBody2D)  ← enemy.gd
└── SightLine (Line2D)
```

### `scripts/enemy.gd`

```gdscript
extends CharacterBody2D

const SPEED := 70.0

@onready var player: CharacterBody2D = $"../Player"

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var dir := (player.global_position - global_position).normalized()
    velocity = dir * SPEED
    move_and_slide()
    queue_redraw()
```

The enemy finds the player via `$"../Player"` — a relative NodePath to its sibling. `@onready` resolves this once when the node enters the scene tree.

**Chase logic:**
```
direction = (player.position - enemy.position).normalized()
velocity  = direction * SPEED
```

This is pure vector math. The direction vector points from the enemy to the player. Normalizing it gives a unit vector. Scaling by SPEED gives the velocity vector.

**`_draw()`** renders the enemy as a red circle with a "pupil" dot positioned in the direction of the player:
```gdscript
var eye_offset := (player.global_position - global_position).normalized() * 8
draw_circle(eye_offset, 5, Color.WHITE)
draw_circle(eye_offset + dir * 2, 3, Color.BLACK)
```

The eye tracks the player's direction — a simple but effective visual cue that the enemy is "looking at" the player.

### `scripts/main.gd`

Updates the `Line2D` each frame to connect the enemy and player positions:
```gdscript
sight_line.set_point_position(0, enemy.global_position)
sight_line.set_point_position(1, player.global_position)
```

Also displays the distance:
```gdscript
var dist := enemy.global_position.distance_to(player.global_position)
$DistanceLabel.text = "Distance: %.0f px" % dist
```

### `scripts/player.gd`

Standard `CharacterBody2D` with `Input.get_vector()` and `move_and_slide()`.

## AI Theory

### Direct Chase: Limitations

Direct chase (always move toward the player) is the simplest possible AI. Its weaknesses:
- **Predictable**: Players learn to dodge by running in circles
- **No pathfinding**: The enemy walks directly into walls
- **No reaction time**: Response is instantaneous — no detection range, no hesitation

For a complete AI, add a detection range (enemy only chases when close), a navigation agent (pathfind around obstacles), and behavioral states (see the patrol-ai demo).

### is_instance_valid()

```gdscript
if not is_instance_valid(player):
    return
```

If the player node is freed (e.g. game over, scene change), the `player` reference becomes invalid. Accessing properties on an invalid reference causes an error. `is_instance_valid()` safely checks whether the reference still points to a live node.

### @onready and Relative Paths

```gdscript
@onready var player: CharacterBody2D = $"../Player"
```

`@onready` evaluates the expression when the node first enters the scene tree (after all children's `_ready()` have run). `$"../Player"` navigates: `..` = parent, `Player` = sibling node. This is equivalent to `get_parent().get_node("Player")`.

Quote marks around the path are required when the path contains characters like `/` or `..`.

### Line2D for Visualization

`Line2D` draws a line between a list of points. `set_point_position(index, position)` updates an individual point without recreating the line. The line is defined in world space (global positions), so no coordinate conversion is needed.

## Files

| File | What it holds |
|------|---------------|
| `scripts/enemy.gd` | `enemy` behaviour |
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

This demo is intentionally the "**AI in two lines**" example, so there's nothing
to extract — the reusable idea *is* how short it is:

```gdscript
var dir := (player.global_position - global_position).normalized()
velocity = dir * speed
move_and_slide()
```

Drop those three lines into any `CharacterBody2D` for a homing chaser. From here:
- **Flee** instead of chase: negate the direction (`-dir`).
- **Keep distance** (ranged enemy): move toward the player when far, away when close, idle in a band between.
- **Smooth turning:** instead of snapping `velocity`, steer it — see [homing-projectile](../homing-projectile) (`lerp_angle`) or [steering-behaviors](../steering-behaviors) (`SteeringAgent`) for reusable versions.
- **Stop chasing through walls:** gate movement on [line-of-sight](../line-of-sight)'s `LineOfSight.is_clear`.

`speed` is `@export`ed for per-enemy tuning. The enemy finds the player via
`$"../Player"`; in a real project prefer an `@export var target: Node2D`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `global_position.distance_to(other)` | World-space distance |
| `(target - origin).normalized()` | Unit direction vector |
| `is_instance_valid(node)` | Check if a node reference is still live |
| `@onready var x = $"../SiblingNode"` | Sibling node reference |
| `Line2D.set_point_position(idx, pos)` | Update a line vertex |
| `move_and_slide()` | Move with collision response |

## Related demos

- [patrol-ai](../patrol-ai) — A three-state FSM: patrol waypoints, chase on detection, return when escaped.
- [status-effects](../status-effects) — Poison/burn/freeze as timed, stackable, data-driven modifiers.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

