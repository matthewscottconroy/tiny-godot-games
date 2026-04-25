# State Machine

Implements a four-state Finite State Machine for a platformer character: IDLE, WALK, JUMP, and FALL — each with a distinct color — driven by physics state.

## Purpose

A state machine is one of the most important patterns in game programming. Without it, player state (idle, walking, jumping, falling) is tracked with scattered boolean flags that conflict and produce bugs. A proper FSM makes states explicit, mutually exclusive, and their transitions clear. This demo shows the minimal FSM needed for a platformer character and how to derive states from physics data.

## Controls

- **Arrow keys / WASD**: Move left and right
- **Up / W**: Jump
- Watch the character change color with each state change, and the state label update

## How It Works

### Node Tree

```
Player (CharacterBody2D)     ← player.gd
├── StateLabel (Label)
└── CollisionShape2D
```

### `scripts/player.gd`

**State enum:**
```gdscript
enum State { IDLE, WALK, JUMP, FALL }
var state := State.IDLE
```

**Per-state colors:**
```gdscript
var color := {
    State.IDLE: Color.SEA_GREEN,
    State.WALK: Color.LIME_GREEN,
    State.JUMP: Color.SKY_BLUE,
    State.FALL: Color.ORANGE,
}[state]
```

Using a dictionary keyed by state enum values is cleaner than a chain of `if/elif` statements. The expression `{...}[state]` looks up the current state's color in a single step.

**Physics loop:**
```gdscript
func _physics_process(delta: float) -> void:
    var dir := Input.get_axis("ui_left", "ui_right")
    velocity.x = dir * SPEED
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    if is_on_floor() and Input.is_action_just_pressed("ui_up"):
        velocity.y = JUMP_VEL
    move_and_slide()
    _transition()
    queue_redraw()
```

Physics runs first, then `_transition()` derives the new state from the updated physics state. This order ensures the state reflects what just happened, not a prediction of what will happen.

**`_transition()`:**
```gdscript
func _transition() -> void:
    var prev := state
    if is_on_floor():
        state = State.WALK if abs(velocity.x) > 10 else State.IDLE
    else:
        state = State.JUMP if velocity.y < 0 else State.FALL
    if state != prev:
        state_label.text = State.keys()[state]
```

The transition logic:
- **On floor**: WALK if moving horizontally, IDLE if still
- **In air**: JUMP if moving upward (velocity.y < 0 because Godot's Y axis points down), FALL if moving downward

`State.keys()[state]` returns the string name of the enum value at index `state` — e.g. `State.keys()[State.JUMP]` = `"JUMP"`. This avoids maintaining a separate name dictionary.

## State Machine Theory

### What States Give You

Without a state machine:
```gdscript
var is_jumping := false
var is_walking := false
var is_falling := false
# These can be true simultaneously — which combination means what?
```

With a state machine, the character is in exactly **one** state at any time. Every combination of conditions maps to exactly one state. This eliminates impossible flag combinations.

### Transition Derivation vs Explicit Transitions

This demo derives state from physics data (floor contact, velocity) rather than maintaining explicit transitions:
```
old_state + conditions → new_state
```

This is simpler than a traditional FSM where each state explicitly lists which transitions lead to which other states. The derived approach works well when states map cleanly onto measurable quantities.

An explicit FSM would look like:
```gdscript
match state:
    State.IDLE:
        if velocity.x > 10: state = State.WALK
        if not is_on_floor(): state = State.FALL
    State.WALK:
        if velocity.x < 10: state = State.IDLE
        # ...
```

### Running Transitions After Physics

`move_and_slide()` updates `is_on_floor()` based on the movement that just happened. If `_transition()` ran before `move_and_slide()`, it would use the previous frame's floor state — potentially causing one-frame glitches when landing or taking off.

### State.keys()[index]

`enum State { IDLE, WALK, JUMP, FALL }` assigns integer values 0, 1, 2, 3 to the names. `State.keys()` returns `["IDLE", "WALK", "JUMP", "FALL"]`. Indexing by the current state integer returns the string name — a convenient way to convert an enum to its string representation.

### Visual State Feedback

Color-coding states serves two purposes:
1. **Game feel**: Players unconsciously register state from color, adding expressiveness without UI clutter
2. **Development**: The color makes the state machine's behavior visible and debuggable

In a real game, this would typically be animation clips keyed to each state.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `enum State { ... }` | Named integer constants |
| `CharacterBody2D.is_on_floor()` | True when resting on a surface |
| `CharacterBody2D.velocity` | Current velocity vector |
| `Input.get_axis(neg, pos)` | −1 to +1 input on one axis |
| `Input.is_action_just_pressed(action)` | Edge-triggered (fires once per press) |
| `move_and_slide()` | Move with collision; updates floor state |
| `Enum.keys()` | Array of string names for enum values |
