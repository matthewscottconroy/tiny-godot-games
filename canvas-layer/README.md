# Canvas Layer

Demonstrates how `CanvasLayer` creates a screen-space overlay that does not move with the game world — the standard approach for HUDs, minimaps, and persistent UI.

## Purpose

In any scrolling game, UI elements like health bars, score displays, and minimaps need to stay fixed on screen while the world scrolls beneath them. Placing UI nodes directly in the world scene causes them to scroll with the camera, making them useless as heads-up displays. `CanvasLayer` solves this by rendering its children in a completely separate coordinate space that ignores the camera transform.

Every 2D game with scrolling uses this pattern. Platformers like Hollow Knight keep health and soul meters locked to the top of the screen regardless of where the player is. Open-world games keep minimaps in a corner that never moves. Without `CanvasLayer`, the only alternative would be to offset every UI element by the camera position each frame — a maintenance nightmare.

This demo pairs a 1400-pixel wide scrolling world with a fixed HUD that displays the player's current world position, proving the HUD reads live world data while staying visually anchored to the screen.

## How It Works

### Node Tree

```
Main (Node2D)                <- main.gd (draws world decorations)
├── Player (CharacterBody2D) <- player.gd
│   └── Camera2D
├── Ground (StaticBody2D)
└── HUD (CanvasLayer)
    └── PositionLabel (Label)
```

The world is 1400 pixels wide. The Camera2D is a child of Player and follows it automatically. The HUD is at `layer = 1` (above the world layer 0) and never moves.

### Updating the HUD from World Data

```gdscript
# scripts/main.gd
func _process(_delta: float) -> void:
    pos_label.text = "World pos: (%.0f, %.0f)" % [player.position.x, player.position.y]
```

The Label is in screen space, but it reads `player.position` — a world-space number. This is always safe: `position` is just a `Vector2` value. Coordinate space only matters when you need to draw or place things visually, not when reading data.

### Player Movement

```gdscript
# scripts/player.gd
const SPEED := 200.0

func _physics_process(_delta: float) -> void:
    velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
    move_and_slide()
```

Standard 4-directional movement. The Camera2D child node follows the player's transform automatically — no camera code required.

### World Decorations

```gdscript
# scripts/main.gd
func _draw() -> void:
    for i in range(5):
        var x := 300 + i * 250
        draw_rect(Rect2(x - 20, 240, 40, 220), Color.DIM_GRAY)   # pillar shaft
        draw_rect(Rect2(x - 30, 235, 60, 15),  Color.GRAY)       # pillar cap
    draw_rect(Rect2(0, 455, 1400, 30), Color(0.2, 0.15, 0.1))    # ground
```

Five pillars spaced across the 1400-pixel world confirm that the level is wider than the viewport and that the camera is actually scrolling.

## CanvasLayer Theory

### The Rendering Stack

Godot renders the scene tree in canvas layers. The main 2D world lives on layer 0. A `CanvasLayer` node specifies its own `layer` integer (default 1 for UI). Each layer has an independent transform; higher-numbered layers render on top of lower ones.

`Camera2D` affects only layer 0 — it applies a viewport offset that makes the world appear to scroll. Nodes inside a `CanvasLayer` on any other layer use that layer's own transform, which defaults to the screen origin. The camera offset is never applied to them.

### Layer Ordering

| Layer value | Use case |
|-------------|----------|
| Negative (e.g. -1) | Background / parallax behind world |
| 0 | Main game world |
| 1 (default CanvasLayer) | HUD, score, health |
| 2+ | Pause overlays, modal dialogs, tooltips |

For parallax backgrounds, `ParallaxBackground` is a more specialized alternative that automatically scales the scroll offset, but the underlying mechanism is the same `CanvasLayer` system.

## How to Adapt This in Your Project

- **Health bar**: Add a `ProgressBar` or `TextureProgressBar` inside the `CanvasLayer`. Write its `value` from `player.hp` each `_process` frame, exactly like the position label here.
- **Minimap**: Add a `SubViewportContainer` inside the `CanvasLayer` with a top-down camera positioned above the player. The SubViewport renders the world; the Container displays it as a fixed screen element.
- **Fade-in on scene load**: Animate `CanvasLayer` child `ColorRect` alpha from 1 to 0 in `_ready()` for a screen-fade entrance.
- **Multiple HUD layers**: Use `layer = 1` for the main HUD and `layer = 10` for pause/death screens so they always render above all game UI.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CanvasLayer` | Screen-space render layer, camera-independent |
| `CanvasLayer.layer` | Draw order integer (higher = in front) |
| `Camera2D` | Scrolls the world canvas (layer 0 only) |
| `Input.get_vector(neg_x, pos_x, neg_y, pos_y)` | 4-directional normalized input vector |
| `CharacterBody2D.move_and_slide()` | Move with collision response |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys / WASD | Move the player through the wide level |

## Key Constants

```gdscript
# scripts/player.gd
const SPEED := 200.0   # pixels per second
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Reads player position, updates HUD label, draws world decorations |
| `scripts/player.gd` | 4-directional movement with Camera2D follow |
| `scenes/main.tscn` | Scene tree: world, player, ground, HUD CanvasLayer |
