# 2D Lighting

Dynamic 2D point lights built from runtime-generated `GradientTexture2D` falloff textures, controlled globally by `CanvasModulate`, with an interactive player-attached light you can move and resize.

## Purpose

Lighting transforms the mood of a 2D game more than almost any other technique. A dark dungeon lit only by a torch the player carries, a cave where enemy campfires cast colored halos, a night scene where a streetlamp illuminates rain — all of these use the same mechanism: `PointLight2D` multiplied against a dark global ambient set by `CanvasModulate`.

Godot's 2D light system is additive by default: lights add brightness to whatever `CanvasModulate` allows through. This demo shows the complete setup — procedurally created light textures so no image assets are needed, a moveable player light, static colored ambient lights, and a toggle to see the contrast between lit and fully bright modes.

## How It Works

### Runtime Light Texture (`scripts/main.gd`)

```gdscript
func _make_light_texture() -> GradientTexture2D:
    var g := Gradient.new()
    g.colors = [Color.WHITE, Color(1, 1, 1, 0)]
    g.offsets = [0.0, 1.0]
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.width = 256
    gt.height = 256
    gt.fill = GradientTexture2D.FILL_RADIAL
    return gt
```

A `GradientTexture2D` with `FILL_RADIAL` produces a 256×256 texture that is opaque white at the center and transparent at the edges. When used as a `PointLight2D.texture`, Godot multiplies this falloff shape against the lit pixels — bright at the center, fading to zero at the radius. The same texture is reused for all lights, including the player light and the three static lights.

### CanvasModulate for Ambient Darkness

```gdscript
if _lights_on:
    _canvas_mod.color = Color(0.15, 0.15, 0.15)  # dark ambient
else:
    _canvas_mod.color = Color.WHITE                # full brightness
```

`CanvasModulate` multiplies every pixel in the 2D canvas by its color. At `(0.15, 0.15, 0.15)` the world is rendered at 15% base brightness — nearly black. `PointLight2D` nodes add brightness on top, creating pools of light. Setting it to white disables the effect completely and restores normal rendering.

### Player Light Tracking

```gdscript
func _process(delta: float) -> void:
    # ... WASD movement into _player_pos ...
    _player_light.position = _player_pos
    queue_redraw()
```

`_player_pos` is updated by WASD input each frame and assigned directly to `_player_light.position`. Because `_player_light` is a child of `Main`, its position is in the same coordinate space as `_player_pos`.

### Dynamic Range Control

```gdscript
KEY_EQUAL, KEY_PLUS:
    _player_light.texture_scale = _player_light.texture_scale + 0.2
KEY_MINUS:
    _player_light.texture_scale = max(0.2, _player_light.texture_scale - 0.2)
```

`PointLight2D.texture_scale` scales the light texture relative to its default size. A scale of 1.0 uses the texture as-is; 2.0 doubles the light radius; 0.2 creates a tight, dim close-range light.

## 2D Lighting Theory

### Additive Light Model

Godot's default 2D light blend mode is additive: the light color is added to the ambient-modulated pixel color. With ambient at 0.15 and a white light at energy 1.0, a lit pixel gets up to 1.15 (clamped to 1.0 in display). Colored lights (red, blue, green) add only their own channel.

The scene's three static lights each use default white energy, but the light texture's gradient ensures smooth falloff:

```
pixel_brightness = ambient * base_color + Σ(light_energy * light_falloff)
```

### Normal Maps (not in this demo)

`PointLight2D` can also interact with normal maps assigned to `Sprite2D` or `Polygon2D` nodes, simulating 3D surface lighting on flat 2D assets. This demo uses `_draw()` geometry which does not support normal maps, but replacing the rects/circles with sprites would enable it.

### Scene Structure

```
Main (Node2D) [main.gd]
├── CanvasModulate       ← global ambient multiplier
├── PlayerLight (PointLight2D)   ← follows WASD player
├── RedLight (PointLight2D)      ← static, warm red tint
├── BlueLight (PointLight2D)     ← static, cool blue
└── GreenLight (PointLight2D)    ← static, deep green
```

## How to Adapt This in Your Project

- **Player torch**: Parent a `PointLight2D` to the player node. Its position follows automatically. Adjust `energy` and `texture_scale` based on "fuel" remaining for a survival game mechanic.
- **Flickering light**: Tween or animate `energy` with a small sine wave: `energy = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.15`.
- **Shadows**: Add `LightOccluder2D` nodes to walls. They block light in the additive model and create hard-edged shadows.
- **Color atmosphere**: Tint `CanvasModulate` to `Color(0.05, 0.05, 0.15)` for a blue night, `Color(0.3, 0.15, 0.05)` for a fire-lit dungeon.
- **Pitfall**: `PointLight2D` requires a texture. Without one, no light is cast. The runtime `GradientTexture2D` approach in this demo means zero external asset dependencies.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PointLight2D` | Casts additive 2D light using a falloff texture |
| `PointLight2D.texture_scale` | Multiplies the light radius |
| `PointLight2D.energy` | Brightness multiplier |
| `CanvasModulate` | Multiplies the entire canvas by a color (ambient control) |
| `GradientTexture2D` | Procedural texture from a Gradient |
| `GradientTexture2D.FILL_RADIAL` | Circular gradient fill mode |

## Controls

| Key | Action |
|-----|--------|
| W / A / S / D | Move player (and player light) |
| L | Toggle lights on/off (CanvasModulate) |
| + / = | Increase player light radius |
| - | Decrease player light radius (min 0.2) |

## Key Constants

```gdscript
const SPEED := 160.0                      # player movement speed
_canvas_mod.color = Color(0.15, 0.15, 0.15)  # darkness level (0.0 = black, 1.0 = full bright)
gt.width = 256; gt.height = 256           # light texture resolution
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Light texture creation, player movement, toggle logic, all drawing |
| `scenes/main.tscn` | CanvasModulate, four PointLight2D nodes, world geometry |
| `tests/test.tscn` | Tests for light setup and texture generation |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

