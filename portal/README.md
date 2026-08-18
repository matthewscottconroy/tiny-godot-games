# Portal

<!-- tags: shows-its-working -->

A 2D portal mechanic where balls enter one portal and exit the other with velocity correctly transformed to match the destination portal's orientation. Portals snap to the nearest surface and support any combination of floor, wall, and ceiling placements.

## Purpose

Portals are the signature mechanic of Valve's *Portal* series, but the underlying velocity transform appears in many other contexts: mirrors that redirect projectiles, teleporters that preserve momentum, wormholes in space shooters, and any effect that moves an object from one coordinate frame to another while conserving speed. Implementing it requires understanding surface normals, vector decomposition, and rotation — the same math used throughout 2D physics.

The tricky part is not the teleportation itself but the velocity rotation. A ball falling straight down into a floor portal should exit a wall portal traveling horizontally, at the same speed, without any "hiccup" at the boundary. Getting this right requires decomposing the velocity into the component along the entry axis and the component perpendicular to it, then rotating the perpendicular to match the new frame.

## How It Works

### Portal Placement

Clicking near a surface projects the click position onto the closest surface rectangle and places the portal there:

```gdscript
func _place_portal(portal: Dictionary, click_pos: Vector2) -> void:
    var best_dist := INF
    for surf in SURFACES:
        var r: Rect2 = surf["rect"]
        var proj := Vector2(
            clamp(click_pos.x, r.position.x, r.position.x + r.size.x),
            clamp(click_pos.y, r.position.y, r.position.y + r.size.y)
        )
        var d := click_pos.distance_to(proj)
        if d < best_dist:
            best_dist = d
            best_surface = surf
            best_proj = proj
    portal["pos"]    = best_proj + n * 1.0
    portal["normal"] = best_surface["normal"]
    portal["active"] = true
```

Each surface carries its own outward normal (`Vector2(0, -1)` for floors pointing up, `Vector2(1, 0)` for a left wall pointing right). The portal is offset 1px outward along the normal so it sits on the surface face rather than inside it.

### Velocity Transform

This is the core of the demo. When a ball passes through a portal, its velocity is transformed from the entry portal's frame to the exit portal's frame:

```gdscript
func _transform_velocity(vel: Vector2, from_normal: Vector2, to_normal: Vector2) -> Vector2:
    var along    := vel.dot(-from_normal)
    var perp_vec := vel - (-from_normal) * vel.dot(-from_normal)
    var angle_a  := (-from_normal).angle()
    var angle_b  := to_normal.angle()
    var rotation := angle_b - angle_a
    var perp_rotated := perp_vec.rotated(rotation)
    return to_normal * along + perp_rotated
```

1. `along` is the speed component moving into the portal — the dot product with the inward normal (`-from_normal`).
2. `perp_vec` is the remaining lateral component, perpendicular to the portal's axis.
3. The rotation angle is the difference between the two portal orientations.
4. The lateral component is rotated by that angle, then recombined with the along-component on the exit normal.

### Entry Detection

```gdscript
func _check_portal_entry(ball: Dictionary, from_portal: Dictionary, to_portal: Dictionary) -> void:
    var dist   := ball["pos"].distance_to(from_portal["pos"])
    if dist > PORTAL_ENTRY_DIST:
        return
    var toward := ball["vel"].dot(-from_portal["normal"])
    if toward <= 0:
        return
    ball["pos"] = to_portal["pos"] + to_portal["normal"] * (PORTAL_ENTRY_DIST + 2.0)
    ball["vel"] = _transform_velocity(ball["vel"], from_portal["normal"], to_portal["normal"])
```

The velocity direction check (`toward > 0`) is the anti-re-teleport guard. A ball that just exited a portal is moving away from it, so `dot(-normal) <= 0`, and it won't be immediately re-teleported back.

## The Velocity Transform — Frame Decomposition

The transform preserves two invariants: speed magnitude and the relative angle between the velocity and the portal opening. A ball entering a floor portal at 45° exits the other portal at 45° relative to that portal's opening, regardless of where the second portal is placed. This is equivalent to rotating the velocity by the angle between the two portals' inward normals.

The decompose-rotate-recompose approach is necessary because `Vector2.rotated()` alone would rotate around the origin, not around the portal's own axis. By extracting the lateral component first, rotating only it, and then adding back the along-component on the new axis, the transform correctly handles all portal orientation combinations.

## How to Adapt This in Your Project

Replace the dictionary-based balls with `RigidBody2D` nodes and apply the velocity transform via `linear_velocity`. Use `Area2D` for entry detection instead of a distance check — the area gives you a `body_entered` signal. Limit portal placement to specific "portal-able" surfaces using a layer mask or a custom surface flag. Add a portal cooldown to prevent infinite teleport loops. For 3D, extend the same pattern using plane normals and `Basis` rotation matrices.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.dot(other)` | Decomposes velocity into along-normal and lateral components |
| `Vector2.rotated(angle)` | Rotates the perpendicular velocity component to the new frame |
| `Vector2.angle()` | Gets the orientation angle of a normal for rotation delta |
| `Rect2.has_point(pos)` | Tests portal/ball containment for placement snapping |
| `clamp(value, min, max)` | Projects click position onto surface rectangle bounds |

## Controls

| Input | Action |
|-------|--------|
| Left Click | Place orange portal on nearest surface |
| Right Click | Place blue portal on nearest surface |
| Space | Spawn a new ball |
| R | Clear all balls and deactivate both portals |

## Key Constants

```gdscript
const GRAVITY          := 500.0  # Downward acceleration (px/s²)
const BALL_R           := 10.0   # Ball collision radius (px)
const PORTAL_R         := 22.0   # Portal visual radius (px)
const PORTAL_ENTRY_DIST := 18.0  # Distance at which teleportation triggers (px)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Portal placement, velocity transform, entry detection, ball physics, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached; surfaces defined in-script |
| `tests/test_logic.gd` | Unit tests for velocity transform and entry detection |
| `tests/test.tscn` | Scene that runs the tests |

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

