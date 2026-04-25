# Scene Transition

Demonstrates smooth fade-to-black scene changes using an autoload `CanvasLayer` overlay, the `Tween` API, and `get_tree().change_scene_to_file()`.

## Purpose

Abrupt scene changes break immersion. The standard solution is a fade overlay: fade to black, switch scenes, fade back in. This demo implements that as a reusable autoload singleton — any scene can call `Transition.fade_to("res://scenes/level.tscn")` without knowing anything about the overlay or tween.

## Controls

- **Start button** (title scene): Fade to the game level
- **Back button** (level scene): Fade back to title

## How It Works

### Node Tree

```
[Autoload] Transition (CanvasLayer, layer=128)  ← transition.gd
└── Overlay (ColorRect, size=640×480, color=black, alpha=0)

scenes/
├── title.tscn    ← title.gd (has Start button)
├── level.tscn    ← level.gd (has Back button)
└── transition.tscn  (the autoload scene)
```

### `scripts/transition.gd`

```gdscript
func fade_to(path: String) -> void:
    var tw := create_tween()
    tw.tween_property(rect, "color:a", 1.0, 0.4)   # fade to black
    await tw.finished
    get_tree().change_scene_to_file(path)
    await get_tree().process_frame                    # wait for scene to init
    await get_tree().process_frame
    var tw2 := create_tween()
    tw2.tween_property(rect, "color:a", 0.0, 0.4)  # fade back in
```

The two `await get_tree().process_frame` calls ensure the new scene's `_ready()` has run before the fade-in starts, preventing a flash of the uninitialized scene.

### Why CanvasLayer at layer=128?

`CanvasLayer.layer` determines draw order. Layer 128 renders above almost everything (most UI is layer 1-10). The overlay must cover the entire screen during the transition, including any UI in the incoming scene. A high layer ensures it's never accidentally hidden behind a dialog or HUD.

### Autoload Lifetime

Autoloads persist across scene changes — they are NOT freed when `change_scene_to_file()` is called. This is what makes the overlay work: it stays alive through the transition, covering the scene swap. Without autoload, the overlay would be freed when its scene is replaced.

### Tweening Color Alpha

```gdscript
tw.tween_property(node, "color:a", target_value, duration)
```

The `"color:a"` property path targets the alpha sub-component of a `Color` property. Godot's tween system can interpolate sub-properties of built-in types (Color, Vector2, etc.) using this dot notation.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SceneTree.change_scene_to_file(path)` | Replace current scene |
| `Tween.tween_property(node, prop, val, dur)` | Animate a property over time |
| `await tween.finished` | Pause until tween completes |
| `CanvasLayer.layer` | Draw order; 128 renders above most UI |
| `[autoload]` in project.godot | Register a persistent singleton scene |
