# Bezier Path

An interactive cubic Bezier curve editor. Drag the four control points to reshape the curve; a yellow dot animates along it displaying the current `t` value and a tangent arrow showing instantaneous travel direction.

## Purpose

Bezier curves are the backbone of smooth motion in games and animation. Enemy patrol paths, projectile arcs, camera dolly moves, UI easing curves, procedural road generation, and particle emission profiles all rely on Bezier mathematics. Learning to implement the formula from scratch — rather than relying entirely on Godot's built-in `Curve2D` — gives you the precision to build custom tooling, debug unexpected behavior, and extend the math to higher-order variants or spline chains.

*Hollow Knight* and *Ori and the Will of the Wisps* use Bezier-based animation curves for character polish. RTS games like *Age of Empires* use them for smooth unit pathing. Visual novels use them for panel transitions. The formula appears almost everywhere smooth interpolation is needed.

This demo makes the math tangible: dragging a handle point immediately reshapes the curve because the formula is re-evaluated on every `_draw()` call. The gradient color (blue at t=0, red at t=1) and the t-value label make the parameterization visible rather than abstract.

## How It Works

### Node Tree

```
Main (Node2D)    ← main.gd (everything in one script, no children)
```

The entire demo — curve evaluation, dragging, animation — runs in a single `Node2D` with no scene children. Drawing uses `_draw()` exclusively.

### Core Data

```gdscript
var _points: PackedVector2Array = PackedVector2Array([
    Vector2(80, 380),   # P0 — start endpoint
    Vector2(160, 100),  # P1 — start handle
    Vector2(480, 100),  # P2 — end handle
    Vector2(560, 380),  # P3 — end endpoint
])
var _t:     float = 0.0
var _speed: float = 0.4   # t units per second
var _drag:  int   = -1    # index of point being dragged (-1 = none)
```

### Curve Evaluation

```gdscript
func _bezier(t: float) -> Vector2:
    var p0 := _points[0]; var p1 := _points[1]
    var p2 := _points[2]; var p3 := _points[3]
    var u := 1.0 - t
    return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3

func _bezier_tangent(t: float) -> Vector2:
    var p0 := _points[0]; var p1 := _points[1]
    var p2 := _points[2]; var p3 := _points[3]
    var u := 1.0 - t
    var tangent := 3.0 * u * u * (p1 - p0) + 6.0 * u * t * (p2 - p1) + 3.0 * t * t * (p3 - p2)
    if tangent.length() > 0.001:
        return tangent.normalized()
    return Vector2(1, 0)  # fallback for degenerate (zero-length) tangent
```

The tangent formula is the analytical derivative of B(t) with respect to t. Its direction gives the heading of any object following the curve at that parameter value.

### Animation (`_process`)

```gdscript
func _process(delta: float) -> void:
    _t = fmod(_t + _speed * delta, 1.0)
    queue_redraw()
```

`fmod` wraps `_t` back to `[0, 1)` when it exceeds 1.0, creating continuous looping without a conditional reset.

### Rendering (`_draw`)

The curve is drawn as 80 line segments — fine enough to appear smooth, coarse enough to be cheap. Each segment is colored by interpolating from `CORNFLOWER_BLUE` (t=0) to `TOMATO` (t=1) using `Color.lerp()`.

Dashed lines from P0→P1 and P3→P2 (the "tangent handles") are drawn with a custom `_draw_dashed_line()` helper that walks the line distance in alternating draw/skip segments.

## Bezier Formula

### Cubic Bezier Definition

A cubic Bezier curve is parameterized by `t ∈ [0, 1]` and four control points:

```
B(t) = (1−t)³·P0 + 3(1−t)²t·P1 + 3(1−t)t²·P2 + t³·P3
```

Key properties:
- **B(0) = P0** and **B(1) = P3** — the curve always passes through the endpoints.
- P1 and P2 are "handles" — the curve is pulled *toward* them but does not pass through them (in general).
- The blending weights `(1−t)³`, `3(1−t)²t`, `3(1−t)t²`, `t³` always sum to 1 (they form a partition of unity). This means B(t) is always inside the convex hull of the four points.

### Tangent (First Derivative)

```
B'(t) = 3(1−t)²·(P1−P0) + 6(1−t)t·(P2−P1) + 3t²·(P3−P2)
```

Geometrically:
- At t=0: `B'(0) = 3(P1 − P0)` — the curve leaves P0 in the direction of P1.
- At t=1: `B'(1) = 3(P3 − P2)` — the curve arrives at P3 from the direction of P2.

Dividing by its own length (`.normalized()`) gives the unit tangent vector — the facing direction for an object following the path.

### Non-Uniform Speed

Advancing `t` at constant speed does not produce constant-speed movement along the curve. The relationship between t-increment and arc length is nonlinear — curves with tightly-spaced control points move slower at equal t-steps than curves with spread-out points. For constant-speed motion, use arc-length parameterization: precompute a lookup table of `distance → t` by sampling the curve, then advance by world distance rather than t-increment.

### Chaining Segments (Splines)

For longer paths, chain multiple cubic segments. For a smooth join (C1 continuity) at the junction, ensure that P2 of segment A, the shared endpoint, and P1 of segment B are collinear:
```
P3_A = P0_B          (shared point)
P1_B = P3_A + (P3_A - P2_A)   (mirror of handle across junction)
```

## How to Adapt This in Your Project

**Object following the curve:** In `_process`, compute `position = _bezier(_t)` and `rotation = _bezier_tangent(_t).angle()` to move and orient an object along the path.

**One-shot traversal with a callback:** Replace the looping `fmod` with a clamped advance and emit a signal when `_t >= 1.0`. Use this to trigger "arrival" events.

**Godot's built-in Curve2D:** For production use, `Curve2D` with a `Path2D` + `PathFollow2D` provides editor tooling and arc-length parameterization. Use this demo to understand what `Curve2D` does internally.

**Easing curves:** Evaluate a single Bezier curve in 1D (`float` output, `float` input) for custom easing. P0=(0,0), P3=(1,1), adjust P1 and P2 to control the S-curve shape. This is how CSS `cubic-bezier()` easing works.

**Projectile arc:** Spawn at P0, set P3 to the target, set P1 and P2 upward for an arc, then advance `_t` each frame. At `_t == 1.0`, trigger impact.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Node2D._draw()` | Custom 2D drawing; called after `queue_redraw()` |
| `draw_line(from, to, color, width)` | Draw a line segment in local space |
| `draw_circle(pos, radius, color)` | Draw a filled circle |
| `draw_arc(pos, radius, from_angle, to_angle, points, color, width)` | Draw a circle outline |
| `draw_string(font, pos, text, ...)` | Draw text in `_draw()` |
| `fmod(a, b)` | Floating-point modulo — wraps `t` to `[0, 1)` |
| `Color.lerp(other, t)` | Interpolate between two colors |
| `PackedVector2Array` | Efficient array of Vector2 — avoids per-element allocation |

## Controls

| Input | Action |
|-------|--------|
| Left-click + drag | Move a control point |
| `A` | Reset all points to their default positions |

## Key Constants

```gdscript
const DEFAULT_POINTS := [
    Vector2(80, 380),   # P0 — start endpoint
    Vector2(160, 100),  # P1 — start handle
    Vector2(480, 100),  # P2 — end handle
    Vector2(560, 380),  # P3 — end endpoint
]
var _speed := 0.4       # t advances this many units per second (full loop in 2.5s)
# Curve rendered as 80 line segments
# Control point click radius: 16 px
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Bezier evaluation, tangent computation, dragging, animation, all rendering |
| `tests/test_logic.gd` | Unit tests: endpoint interpolation, midpoint symmetry, tangent directions, `fmod` wrap |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

