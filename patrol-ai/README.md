# Patrol AI

Implements a three-state Finite State Machine for enemy AI: patrol along waypoints, chase the player when detected, and return to the patrol route when the player escapes.

## Purpose

Enemy AI in games requires more than "always move toward the player." A credible enemy patrols predictably when the player is absent, reacts when spotted, and gives up the chase after losing contact. These three behaviors correspond to three distinct states in a Finite State Machine (FSM). This demo shows how to implement a clean FSM with explicit transition logic and per-state behavior.

## Controls

- **Arrow keys / WASD**: Move the player
- Watch the enemy label change between PATROL, CHASE, and RETURN
- The enemy's eye always looks at its current target (waypoint or player)

## How It Works

### Node Tree

```
Main (Node2D)
├── Enemy (CharacterBody2D)    ← enemy.gd
│   └── StateLabel (Label)
├── Player (CharacterBody2D)   ← player.gd
└── Waypoints (Node2D)
    ├── WP0 (Marker2D)
    ├── WP1 (Marker2D)
    └── WP2 (Marker2D)
```

### `scripts/enemy.gd`

**State enum:**
```gdscript
enum State { PATROL, CHASE, RETURN }
```

**Constants:**
```gdscript
const DETECT_RANGE  := 180.0  # distance to start chasing
const LOSE_RANGE    := 280.0  # distance to give up chase
const PATROL_SPEED  := 80.0
const CHASE_SPEED   := 150.0
```

**`_ready()`** — Collects waypoint positions from `Marker2D` children of the `Waypoints` node into `waypoints: Array[Vector2]`.

**`_physics_process()`:**
```gdscript
func _physics_process(_delta: float) -> void:
    _transition()   # determine next state
    match state:
        State.PATROL: _patrol()
        State.CHASE:  _chase()
        State.RETURN: _return()
    queue_redraw()
```

**`_transition()`** — State machine logic:
```gdscript
func _transition() -> void:
    var dist := global_position.distance_to(player.global_position)
    match state:
        State.PATROL:
            if dist < DETECT_RANGE:
                state = State.CHASE
        State.CHASE:
            if dist > LOSE_RANGE:
                state = State.RETURN
        State.RETURN:
            if dist < DETECT_RANGE:
                state = State.CHASE
            elif global_position.distance_to(waypoints[wp_index]) < 10:
                state = State.PATROL
```

**`_patrol()`** — Moves toward `waypoints[wp_index]`. When within 10 pixels of the current waypoint, advances `wp_index` cyclically: `wp_index = (wp_index + 1) % waypoints.size()`.

**`_chase()`** — Moves directly toward `player.global_position` at chase speed.

**`_return()`** — Moves toward `waypoints[wp_index]` at patrol speed, then transitions to PATROL when close.

**`_draw()`** — The enemy's color and eye position change per state. The eye looks at the patrol waypoint in PATROL state and at the player in CHASE state — a subtle but effective visual cue.

## Finite State Machine Theory

### What an FSM Is

A Finite State Machine consists of:
- A **finite set of states** (PATROL, CHASE, RETURN)
- **Transition rules** — conditions that move from one state to another
- **Behaviors** — what to do in each state

The key constraint: the machine is in exactly one state at any time. This prevents the "undefined behavior" of mixing partial behaviors from multiple states.

### Transition Hysteresis

Notice the DETECT_RANGE (180) is smaller than LOSE_RANGE (280). This is **hysteresis** — a deliberate gap between the enter and exit conditions. Without it, if the player stood exactly at 180 pixels, the enemy would rapidly flip between PATROL and CHASE every frame ("jitter"). The wider LOSE_RANGE means the player must move significantly further away before the enemy gives up.

This is the same principle used in thermostats: a heater turns on at 68°F and off at 72°F, not at exactly 70°F.

### Separation of Transition and Behavior

`_transition()` runs first, then `match state` dispatches behavior. This order ensures each state's behavior uses the **newly resolved state** each frame. The alternative (checking transitions inside each behavior function) mixes concerns and makes the logic harder to follow.

### Waypoint Cycling

```gdscript
wp_index = (wp_index + 1) % waypoints.size()
```

Modulo arithmetic wraps the index: after the last waypoint, it returns to 0. This works for any number of waypoints without range checking.

### Visual State Feedback

Color and eye direction change per state, giving the player non-verbal information about the enemy's mode. In a real game this might be accompanied by sound (detection bark) and animations. Keeping it visual in this demo makes the state machine behavior immediately legible.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `enum State { ... }` | Named integer constants for states |
| `match state: State.X: ...` | Pattern matching (cleaner than if/elif chains) |
| `global_position.distance_to(other)` | World-space distance |
| `direction.normalized() * speed` | Velocity toward a target |
| `move_and_slide()` | Move with collision |
| `Marker2D` | Empty positioned node, useful for waypoints |
| `Array.size()` | Length for modulo cycling |
