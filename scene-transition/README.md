# Scene Transition

<!-- tags: none -->

Smooth fade-to-black scene changes implemented as a persistent Autoload `CanvasLayer`. Any scene calls `Transition.fade_to("res://scenes/level.tscn")` and the overlay handles the fade, the scene swap, and the fade-back-in automatically.

## Purpose

Abrupt scene changes are one of the most jarring things in an otherwise polished game. The screen cuts instantly from the title to gameplay, or from one level to the next, with no visual continuity. A fade to black gives the player a moment of transition — it signals that something is changing, hides the loading gap, and lets the new scene initialize before the player sees it.

Every commercial game uses transitions. *Stardew Valley* uses a fade for every interior/exterior transition. *Celeste* uses a heart-shaped wipe on level completion. *Hollow Knight* uses a slow fade paired with loading. The simplest effective version is a full-screen black overlay that fades in, waits for the scene change, and fades back out. That's exactly what this demo implements.

The key architectural insight is that the overlay must persist through the scene change. A node inside the scene being replaced would be freed along with the scene. An Autoload survives every `change_scene_to_file()` call, making it the natural home for transition state.

## How It Works

### Node Tree

```
[Autoload] Transition (CanvasLayer, layer=128)  ← transition.gd
└── FadeRect (ColorRect, 640×480, black, alpha=0)

scenes/
├── title.tscn   ← title.gd  (Start button → fade to level)
└── level.tscn   ← level.gd  (Back button → fade to title)
```

### `scripts/transition.gd`

```gdscript
func fade_to(path: String) -> void:
    if _transitioning:
        return
    _transitioning = true
    rect.mouse_filter = Control.MOUSE_FILTER_STOP

    var tw := create_tween()
    tw.tween_property(rect, "color:a", 1.0, 0.4)  # fade to black
    await tw.finished

    get_tree().change_scene_to_file(path)

    await get_tree().process_frame   # let new scene's _ready() run
    await get_tree().process_frame

    var tw2 := create_tween()
    tw2.tween_property(rect, "color:a", 0.0, 0.4)  # fade back in
    await tw2.finished

    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _transitioning = false
```

The `_transitioning` guard prevents overlapping calls — if the player mashes the button, only the first press takes effect. `MOUSE_FILTER_STOP` blocks all input during the transition so the player cannot interact with either scene while the overlay is opaque.

### The Two `process_frame` Awaits

After `change_scene_to_file()`, the new scene is loaded but its `_ready()` callbacks have not yet run. Without waiting, the fade-in would begin on an uninitialized scene — potentially showing a flash of wrong state. Two `process_frame` awaits give the scene time to initialize completely before the overlay starts clearing.

### `CanvasLayer.layer = 128`

Most UI lives at layer 1–10. Setting `layer = 128` ensures the fade overlay renders above everything in both the outgoing and incoming scenes, including any UI panels, HUD elements, or dialog boxes.

### Scene Scripts

Each scene has a one-line wiring in `_ready()`:

```gdscript
# title.gd
$VBox/StartBtn.pressed.connect(func():
    Transition.fade_to("res://scenes/level.tscn"))

# level.gd
$VBox/BackBtn.pressed.connect(func():
    Transition.fade_to("res://scenes/title.tscn"))
```

No scene knows about the overlay's implementation. They only call the public API.

## The Transition Autoload Pattern

### Why Autoload Survives Scene Changes

When `get_tree().change_scene_to_file()` is called, Godot frees all nodes in the current scene and loads the new one. Autoloads are registered in `project.godot` and are children of the root — they are never freed during scene changes. This makes them ideal for any state or UI that must persist across scene boundaries.

### Tweening Sub-Properties

```gdscript
tw.tween_property(rect, "color:a", 1.0, 0.4)
```

The `"color:a"` property path targets the alpha channel of the `ColorRect`'s `color` property. Godot's tween system can interpolate sub-properties of built-in types (`Color`, `Vector2`, `Rect2`) using dot notation. This is cleaner than tweening a separate alpha variable and applying it manually.

### Alternative Transition Effects

The same architecture supports any transition effect by replacing `ColorRect` with a more complex visual:

- **Iris wipe**: animate a circular mask via a shader uniform.
- **Pixelate**: animate a pixel size uniform on a pixelation shader.
- **Crossfade**: keep a `SubViewport` snapshot of the outgoing scene and blend it with the incoming scene.
- **Direction wipe**: animate a `Polygon2D` or clip rect instead of alpha.

All of these use the same `fade_to()` API — callers never need to know which effect is active.

## How to Adapt This in Your Project

1. Register `Transition` as an Autoload in `Project > Project Settings > Autoload`.
2. Set `layer = 128` on the `CanvasLayer` component so it renders above all scene UI.
3. Replace the `ColorRect` with any visual you want for the transition effect.
4. Add an optional `duration` parameter to `fade_to()` so fast scene changes can use a shorter fade.
5. Add a `TransitionFinished` signal so scenes can wait for the fade-in to complete before starting intro animations.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SceneTree.change_scene_to_file(path)` | Replace the current scene with a new one |
| `Tween.tween_property(node, prop, val, dur)` | Animate a property over time |
| `await tween.finished` | Suspend coroutine until tween completes |
| `await get_tree().process_frame` | Wait one frame for scene initialization |
| `CanvasLayer.layer` | Draw order; 128 renders above most UI |
| `Control.mouse_filter` | `MOUSE_FILTER_STOP` blocks input; `IGNORE` passes it through |
| `[autoload]` in project.godot | Register a scene or script as a persistent singleton |

## Controls

| Input | Action |
|-------|--------|
| Start button (title) | Fade to level scene |
| Back button (level) | Fade back to title scene |

## Files

| File | Purpose |
|------|---------|
| `scripts/transition.gd` | Fade-to/fade-in logic, `_transitioning` guard, mouse block |
| `scripts/title.gd` | Connects Start button to `Transition.fade_to()` |
| `scripts/level.gd` | Connects Back button to `Transition.fade_to()` |
| `scenes/title.tscn` | Title screen with Start button |
| `scenes/level.tscn` | Level screen with Back button |

## Use as a building block

**Copy:** `scripts/level.gd`, `scripts/title.gd`, `scripts/transition.gd`.

**`scripts/transition.gd`**
- `fade_to(path: String) -> void`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- `Transition` is registered as an autoload (Project Settings → Globals). Copy the autoload script and register it there under a name that does not collide with anything in your project.

## Related demos

- [localization](../localization) — `TranslationServer` string tables switched at runtime across EN/ES/FR.
- [thread-loading](../thread-loading) — `load_threaded_request()` background loading with a progress UI.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

