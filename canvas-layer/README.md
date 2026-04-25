# Canvas Layer

Demonstrates how `CanvasLayer` creates a screen-space overlay that does not move with the game world — the standard approach for HUDs, minimaps, and persistent UI.

## Purpose

In any scrolling game, UI elements like health bars, score displays, and minimaps need to stay fixed on screen while the world scrolls. Putting UI nodes inside the world scene causes them to scroll with the camera. `CanvasLayer` solves this by rendering its children in a separate coordinate space that ignores the camera transform.

## Controls

- **Arrow keys / WASD**: Move the player through the wide level
- Watch the position label in the top-left — it stays fixed as the world scrolls

## How It Works

### Node Tree

```
Main (Node2D)               ← main.gd (draws world decorations)
├── Player (CharacterBody2D) ← player.gd
│   └── Camera2D
├── Ground (StaticBody2D)
└── HUD (CanvasLayer)
    └── PositionLabel (Label)
```

The world is 1400 pixels wide. The Camera2D follows the player as they scroll right.

### `scripts/main.gd`

- **`_draw()`** — Draws five grey pillars across the 1400-pixel world and a ground strip. These decorations confirm that the world is larger than the viewport.
- **`_process()`** — Each frame, reads `player.position` (world coordinates) and writes it into the `PositionLabel` inside the `HUD` CanvasLayer. Even though the HUD doesn't scroll, it can display world-space data by reading from scene nodes.

### `scripts/player.gd`

Standard top-down movement using `Input.get_vector()` and `move_and_slide()`. The `Camera2D` is a child, so it follows the player automatically.

## CanvasLayer Theory

### The Rendering Stack

Godot renders the scene tree in layers. The main 2D world is on layer 0. A `CanvasLayer` node specifies its own `layer` index (default 1 for UI). Nodes on higher layers are drawn on top of lower layers, and each layer has its own independent transform.

### Why CanvasLayer Ignores the Camera

`Camera2D` affects only the main world canvas layer (layer 0). Nodes inside a `CanvasLayer` with a different layer index are rendered with the layer's own transform, which defaults to the screen origin. The camera transform is not applied to them.

This means HUD children always appear at fixed screen positions regardless of where the camera is in the world.

### CanvasLayer.layer Property

Lower numbers render first (behind). The default layer for a CanvasLayer is 1, putting it in front of the world. Setting it to a negative number would place it behind the world (e.g. for a parallax background — though `ParallaxBackground` provides a more specialized solution for that use case).

### Reading World Data in the HUD

```gdscript
pos_label.text = "World pos: (%.0f, %.0f)" % [player.position.x, player.position.y]
```

The HUD Label is in screen space, but it displays data from `player.position`, which is in world space. This is safe because `position` is just a number — converting between world and screen only matters for drawing.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CanvasLayer` | Screen-space layer, camera-independent |
| `CanvasLayer.layer` | Draw order (higher = in front) |
| `Camera2D` | Scrolls the world canvas layer |
| `Node2D.position` | World-space position |
| `get_viewport_rect()` | Screen rectangle in world coordinates |
