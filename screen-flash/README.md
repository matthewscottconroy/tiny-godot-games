# Screen Flash

<!-- tags: physics -->

Implements full-screen color flash feedback using a `ColorRect` on a `CanvasLayer` that fades out with a Tween — triggered automatically by game events and manually by key presses.

## Purpose

Screen flash is one of the most effective low-cost game feel techniques. A brief flash of red when taking damage, white when respawning, or yellow when picking up a collectible communicates game state faster than any HUD element. It works because the brain immediately registers a full-field color change even in peripheral vision.

Games across every genre use this: shooters flash red on damage (Doom, SUPERHOT), platformers flash white on death, JRPGs use white flashes for dramatic cutscene transitions, and rhythm games flash on beat hits. The technique is almost always the same: a full-screen transparent overlay that momentarily becomes opaque and fades out.

The demo also shows how to wire the flash to actual game events using Area2D signals — not just manual key presses — so the pattern is immediately applicable to real projects.

## How It Works

### Scene Structure

```
Main (Node2D) [main.gd]
├── CanvasLayer
│   └── FlashRect (ColorRect, full viewport, mouse_filter=IGNORE)
├── Hazard (Area2D, red zone)
└── Player (CharacterBody2D) [player.gd]
```

The `FlashRect` fills the entire viewport and sits on a `CanvasLayer` so it renders above the world in screen space, unaffected by any world-space camera transforms or shaders.

### The `flash()` Function (`scripts/main.gd`)

```gdscript
func flash(color: Color, duration: float) -> void:
    _flash_rect.color = color
    var tween := create_tween()
    tween.tween_property(_flash_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
```

Two things happen atomically: the rect color is set immediately (instant full-color frame), then a tween fades the alpha to 0 over `duration` seconds. `EASE_OUT` gives the flash intensity that decays rapidly at first and then slower — this is perceptually correct because the eye adapts to brightness changes.

The property path `"color:a"` lets the tween target only the alpha channel, leaving RGB intact. This matters because if you tweened the entire `Color` toward `Color.TRANSPARENT`, you would also shift the RGB toward black.

### Event-Driven Flash

```gdscript
func _ready() -> void:
    for zone in get_tree().get_nodes_in_group("hazard"):
        zone.body_entered.connect(_on_hazard_entered.bind(zone))

func _on_hazard_entered(body: Node2D, _zone: Area2D) -> void:
    if body.is_in_group("player"):
        flash(Color(1.0, 0.1, 0.1, 0.65), 0.35)
```

The hazard zone is an `Area2D` in the "hazard" group. `_ready()` discovers all hazards and wires their `body_entered` signal. This keeps `main.gd` decoupled from the specific hazard node names — add more hazards anywhere in the scene, and they auto-connect.

### Player (`scripts/player.gd`)

```gdscript
const SPEED   := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
    if Input.is_action_just_pressed("ui_up") and is_on_floor():
        velocity.y = JUMP_VEL
    move_and_slide()
```

Standard `CharacterBody2D` platformer. The player is drawn procedurally in `_draw()` as a blue rectangle with two white eye rects — no sprite asset needed.

## Full-Screen Overlay Technique

### Why CanvasLayer?

`CanvasLayer` renders its children in screen space after the world. This has three benefits:
1. The flash ignores world-space camera zoom and offset — it always fills the screen.
2. It renders above all world content including particles and UI nodes at lower layer indices.
3. It is immune to any `SubViewport` or post-process shader applied to the world.

### Tween Override Behavior

`create_tween()` creates a new tween each call. If `flash()` is called while a previous flash is still fading, the new tween starts from the freshly set color immediately, and the old tween continues targeting alpha 0 — effectively the new flash wins on the `color` assignment and the two tweens race to zero. For a cleaner override, kill the old tween first:

```gdscript
var _flash_tween: Tween
func flash(color: Color, duration: float) -> void:
    if _flash_tween:
        _flash_tween.kill()
    _flash_rect.color = color
    _flash_tween = create_tween()
    _flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
```

### Alpha Values by Flash Type

| Flash | Alpha | Why |
|-------|-------|-----|
| Damage (red) | 0.65 | Strong but world still visible |
| Pickup (yellow) | 0.70 | Brief, bright reward |
| Transition (blue) | 0.55 | Subtle, informational |
| Respawn (white) | 0.90 | Near-opaque, dramatic |

## How to Adapt This in Your Project

- **Add to any scene**: Create a `CanvasLayer` node, add a `ColorRect` anchored full-rect, set `mouse_filter = IGNORE`, and attach a script with the `flash()` function. Connect game events to call `flash()`.
- **Multiple flash layers**: Stack two `ColorRect` nodes — one for gameplay flashes, one for UI feedback. Draw them on different `CanvasLayer.layer` values.
- **Directional hit flash**: Instead of a full-screen rect, use four `ColorRect` strips on the screen edges and brighten only the edge facing the damage source.
- **Pitfall**: If `mouse_filter` is left at `STOP` (default), the `ColorRect` blocks all mouse input to the game during and after the flash.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CanvasLayer` | Screen-space overlay layer, above world content |
| `ColorRect` | Solid color rectangle, easily sized to full viewport |
| `Tween.tween_property(node, "color:a", 0.0, t)` | Fade alpha only |
| `Tween.EASE_OUT` | Fast initial decay, natural brightness falloff |
| `Area2D.body_entered` | Signal for overlap detection |
| `get_tree().get_nodes_in_group()` | Discover all hazard nodes dynamically |

## Controls

| Key / Action | Effect |
|--------------|--------|
| Arrow keys | Move player |
| Up | Jump |
| Walk into red zone | Damage flash (red, 0.35s) |
| 1 | Damage flash (red, 0.35s) |
| 2 | Pickup flash (yellow, 0.25s) |
| 3 | Transition flash (blue, 0.40s) |
| 4 | Respawn flash (white, 0.45s) |

## Key Constants

```gdscript
# Preset flash configurations
flash(Color(1.0, 0.1, 0.1, 0.65), 0.35)  # damage
flash(Color(1.0, 0.9, 0.1, 0.70), 0.25)  # pickup
flash(Color(0.2, 0.6, 1.0, 0.55), 0.40)  # transition
flash(Color(1.0, 1.0, 1.0, 0.90), 0.45)  # respawn
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | `flash()` function, hazard signal wiring, key triggers, terrain drawing |
| `scripts/player.gd` | CharacterBody2D platformer with procedural drawing |
| `scenes/main.tscn` | Scene with player, hazard Area2D, CanvasLayer/FlashRect |
| `tests/test_logic.gd` | Unit tests for flash color, alpha targeting, and preset values |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [camera-rooms](../camera-rooms) — Room-based camera transitions using `Area2D`, signals, and `Tween`.
- [drag-drop](../drag-drop) — Mouse drag-and-drop with snap-back when dropped outside a valid target.
- [tween-juice](../tween-juice) — "Game feel" via Tween: button squish and a floating score label.
- [floating-text](../floating-text) — Self-managing damage/pickup labels that rise, fade, and free themselves.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

