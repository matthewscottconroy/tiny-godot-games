# Tooltip

<!-- tags: shows-its-working -->

Hover-triggered tooltips with a configurable delay, smooth alpha fade-in/fade-out, per-item accent colors, and screen-edge clamping — rendered entirely in `_draw()` with no Control nodes.

## Purpose

Tooltips are the primary way games surface complexity without cluttering the main UI. Every action RPG, strategy game, and card game relies on them: hover a spell to see its damage values, hover a unit to see its stats, hover a crafting ingredient to see what recipes use it. *Path of Exile* is almost entirely a tooltip game. *Civilization VI* explains every system through hover cards.

Getting tooltips right requires solving three problems that are easy to underestimate. First, the delay: showing a tooltip immediately on hover is jarring and noisy when the player is mousing across items quickly. A 300–500ms delay means the tooltip only appears when the player pauses with intent. Second, the fade: a tooltip that pops in and out abruptly feels cheap. A 150ms fade-in is nearly imperceptible as a delay but makes the appearance feel polished. Third, edge clamping: a tooltip that runs off the screen is a usability failure. All three are implemented here.

## How It Works

### Hover Detection

Every frame, `_process` checks distance from the mouse to each item's center:

```gdscript
var new_hovered := -1
for i in range(_items.size()):
    var item = _items[i]
    if _mouse_pos.distance_to(item["pos"]) <= item["radius"]:
        new_hovered = i
        break
```

When `new_hovered` differs from `_hovered_idx`, the hover timer and alpha are both reset to zero — even if the player moves quickly from one item to an adjacent one, the delay restarts:

```gdscript
if new_hovered != _hovered_idx:
    _hovered_idx = new_hovered
    _hover_timer = 0.0
    _tooltip_alpha = 0.0
```

### Delay and Fade

The timer only advances when hovering the same item continuously. Once it passes `HOVER_DELAY`, the alpha climbs toward 1.0 at fade-in rate. Leaving an item drops the alpha at the (faster) fade-out rate:

```gdscript
if _hover_timer >= HOVER_DELAY:
    _tooltip_alpha = min(1.0, _tooltip_alpha + delta / FADE_IN_TIME)
else:
    _tooltip_alpha = max(0.0, _tooltip_alpha - delta / FADE_OUT_TIME)
```

Fade-out is faster than fade-in (`FADE_OUT_TIME = 0.1` vs `FADE_IN_TIME = 0.15`) so the tooltip disappears crisply without lingering.

### Screen-Edge Clamping

```gdscript
func _clamp_tooltip_rect(mouse_pos: Vector2, size: Vector2) -> Vector2:
    var preferred := mouse_pos + Vector2(14.0, 14.0)
    var bounds := Rect2(4.0, 4.0, 632.0, 472.0)
    preferred.x = clamp(preferred.x, bounds.position.x, bounds.position.x + bounds.size.x - size.x)
    preferred.y = clamp(preferred.y, bounds.position.y, bounds.position.y + bounds.size.y - size.y)
    return preferred
```

The preferred position is 14px below and right of the cursor (so it doesn't cover the item). Both axes are independently clamped to keep the tooltip fully inside the safe bounds.

### Drawing the Tooltip

All tooltip rendering happens in `_draw()` gated on `_tooltip_alpha > 0.0`:

```gdscript
if _tooltip_alpha > 0.0 and _hovered_idx >= 0:
    var item = _items[_hovered_idx]
    # shadow, background, border, accent bar, title, description lines
    draw_rect(Rect2(pos, Vector2(tooltip_size.x, 3)),
            Color(item["color"].r, item["color"].g, item["color"].b, _tooltip_alpha), true)
```

The 3px accent bar at the top uses the hovered item's own color — a small detail that visually ties the tooltip to its source.

## The Tooltip Pattern

### Delay Thresholds

`HOVER_DELAY = 0.4` seconds is a standard starting point. Below 200ms feels too eager; above 600ms feels sluggish. Games that display complex tooltips (e.g. detailed item stats) often use a longer delay because the player needs to consciously hover to read. Games with simpler label tooltips can use a shorter delay.

### Alpha as a Continuous State Variable

Rather than using a boolean "visible" flag, `_tooltip_alpha` is a continuous float. This means the tooltip can be partially visible (e.g., mid-fade) even as the underlying data changes. It also avoids the timer-vs-tween coordination problem: the alpha is always correct for the current frame, regardless of how many transitions happened this frame.

### Alternatives

- **`Control.hint_tooltip` property**: built-in Godot tooltip, minimal control over styling or delay.
- **`Tween`-based approach**: cleaner animation code but requires coordinating tween cancellation when hover changes mid-fade.
- **Instanced tooltip scene**: better for complex tooltip layouts with icons, progress bars, or nested data.

## How to Adapt This in Your Project

1. Replace the hard-coded `_items` array with a data-driven structure populated from your game resources (items, spells, units).
2. Move `_clamp_tooltip_rect` to a utility autoload so any scene can reuse it.
3. Adjust `HOVER_DELAY` and fade times to match the density of your UI — denser UIs benefit from a shorter delay.
4. For variable-height tooltips, measure content before drawing: count description lines, check for optional fields, and size the background rect accordingly.
5. In a Control-based UI, set `mouse_entered` and `mouse_exited` signals on your items instead of polling distance each frame.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.distance_to(other)` | Euclidean distance between two points |
| `clamp(value, min, max)` | Constrain a float within a range |
| `Node2D._process(delta)` | Per-frame update; accumulates hover timer |
| `Node2D._draw()` | Override for immediate-mode rendering |
| `queue_redraw()` | Request a `_draw()` call next frame |
| `draw_rect()` / `draw_string()` | Drawing primitives inside `_draw()` |
| `Color.lightened(amount)` | Return a brighter version of a color |

## Controls

| Input | Action |
|-------|--------|
| Hover over an item for 0.4s | Show tooltip |
| Move cursor away | Tooltip fades out |

## Key Constants

```gdscript
const HOVER_DELAY   := 0.4    # seconds of continuous hover before tooltip appears
const FADE_IN_TIME  := 0.15   # seconds to go from alpha 0 → 1
const FADE_OUT_TIME := 0.1    # seconds to go from alpha 1 → 0 (faster than fade-in)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All logic: item data, hover detection, delay/fade, drawing |
| `scenes/main.tscn` | Single Node2D — no Control nodes |
| `tests/test_logic.gd` | Unit tests for hover timer, alpha fade, edge clamping |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [2d-lighting](../2d-lighting) — Runtime `GradientTexture2D` point lights under a global `CanvasModulate`.
- [ability-system](../ability-system) — Four hotkey abilities with independent cooldowns and a shared mana pool.
- [audio-positional](../audio-positional) — `AudioStreamPlayer2D` spatial attenuation with a synthesized tone.
- [behavior-tree](../behavior-tree) — Enemy AI driven by a composable behavior tree (patrol/investigate/chase/attack).

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

