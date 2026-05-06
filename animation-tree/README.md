# Animation Tree

Demonstrates `AnimationTree` with `AnimationNodeStateMachine` — building a state machine in code that drives squash-and-stretch animations through idle, walk, jump, fall, and land states.

## Purpose

`AnimationPlayer` plays individual clips in isolation; `AnimationTree` routes between them based on game state, with configurable blending at transitions. This is the standard architecture for character animation in production games: a designer creates clips, and an `AnimationTree` graph determines which clip plays and how it blends into the next one.

Games like Celeste, Hollow Knight, and nearly every 3D action game use state machine-driven animation. The pattern keeps animation logic out of movement code — the physics script calls `travel("jump")` and the animation system handles the rest, including cross-fading. Without it, you would have scattered `AnimationPlayer.play()` calls throughout your physics code with no blend control.

Building the state machine in code (rather than the editor GUI) exposes exactly what the GUI stores and enables data-driven animation graphs loaded at runtime, procedurally built graphs, or graphs reconstructed from save data.

## How It Works

### Node Tree

```
Main (Node2D)                  <- main.gd (physics + state machine builder)
├── Player (Node2D)
│   ├── Visual (Node2D)        <- animation tracks target this node's scale/position
│   ├── AnimationPlayer        <- stores the five animation clips
│   └── AnimationTree          <- routes between clips via state machine
└── HUD (CanvasLayer)
    └── StateLabel
```

### Building Animations in Code

```gdscript
func _build_animations() -> void:
    var lib := AnimationLibrary.new()

    var idle := Animation.new()
    idle.length    = 1.2
    idle.loop_mode = Animation.LOOP_LINEAR
    var it := idle.add_track(Animation.TYPE_VALUE)
    idle.track_set_path(it, "Visual:scale")
    idle.track_set_interpolation_type(it, Animation.INTERPOLATION_LINEAR)
    idle.track_insert_key(it, 0.0, Vector2(1.0,  1.0))
    idle.track_insert_key(it, 0.6, Vector2(1.06, 0.94))
    idle.track_insert_key(it, 1.2, Vector2(1.0,  1.0))
    lib.add_animation("idle", idle)
    # ... (walk, jump, fall, land added similarly)
    _anim_player.add_animation_library("", lib)
```

`TYPE_VALUE` tracks animate any property by path string. `"Visual:scale"` targets the `scale` property on the child node named "Visual". The `""` library name is the default namespace — clips added here are referenced without a prefix.

### Building the State Machine in Code

```gdscript
func _build_state_machine() -> void:
    var sm := AnimationNodeStateMachine.new()

    for anim_name in ["idle", "walk", "jump", "fall", "land"]:
        var node := AnimationNodeAnimation.new()
        node.animation = anim_name
        sm.add_node(anim_name, node)

    var pairs := [
        ["idle", "walk"], ["walk", "idle"],
        ["idle", "jump"], ["walk", "jump"],
        ["jump", "fall"], ["fall", "land"],
        ["land", "idle"], ["land", "walk"]
    ]
    for pair in pairs:
        var t := AnimationNodeStateMachineTransition.new()
        t.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED
        t.xfade_time   = 0.08
        sm.add_transition(pair[0], pair[1], t)

    sm.set_start_node("idle")
    _anim_tree.tree_root = sm
    _anim_tree.anim_player = NodePath("../AnimationPlayer")
    _anim_tree.active = true
```

`ADVANCE_MODE_DISABLED` means transitions do not fire automatically — only explicit `travel()` calls trigger them. `xfade_time = 0.08` (80 ms) blends the outgoing and incoming clips so state changes don't snap.

### Requesting State Transitions

```gdscript
# Initialized one frame after _ready() to give AnimationTree time to activate
_playback = _anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback

# In response to jump input:
_playback.travel("jump")

# Polling-based transitions in _update_state():
if _on_floor and cur == "idle" and absf(_vel.x) > 10:
    _playback.travel("walk")
elif cur == "walk" and absf(_vel.x) <= 10:
    _playback.travel("idle")
```

`travel("state")` asks the state machine to find a path to the named node and play through any connecting transitions. `get_current_node()` returns the name of the currently active state for display and transition logic.

### Squash and Stretch Values

| State | Scale (x, y) | Notes |
|-------|-------------|-------|
| idle (breathe) | 1.0 → 1.06/0.94 → 1.0 | Gentle 1.2 s loop |
| walk (bob) | position y: 0 → -5 → 0 | Two vertical bobs per 0.36 s cycle |
| jump (launch) | 1.25/0.75 → 0.85/1.18 → 1.0 | Squash on launch, stretch at apex |
| fall | 0.88/1.12 (held) | Sustained stretch downward |
| land | 1.35/0.65 → 1.0/1.0 | Impact squash settling in 0.22 s |

## AnimationTree Architecture

```
AnimationPlayer  (holds clip data: "idle", "walk", "jump", "fall", "land")
      |
AnimationTree   (routes between clips via state machine)
   tree_root = AnimationNodeStateMachine
      |- "idle"  -> AnimationNodeAnimation("idle")
      |- "walk"  -> AnimationNodeAnimation("walk")
      |- "jump"  -> AnimationNodeAnimation("jump")
      |- "fall"  -> AnimationNodeAnimation("fall")
      |- "land"  -> AnimationNodeAnimation("land")
```

`AnimationPlayer` owns the clip data. `AnimationTree` owns the routing logic. The two nodes cooperate: `AnimationTree.anim_player` points to the `AnimationPlayer`, and the `AnimationTree` reads clip durations and writes blend weights back to the player.

### travel() vs. Condition-Based Transitions

This demo uses explicit `travel()` calls from physics code. The alternative is setting `advance_mode = ADVANCE_MODE_AUTO` and assigning `advance_condition` to a boolean parameter like `anim_tree["parameters/conditions/is_walking"]`. Conditions work well for designer-tunable graphs in the editor; `travel()` is clearer when state transitions are determined entirely in code.

## How to Adapt This in Your Project

- **Add a new state**: Create an `Animation`, add it to the library, add an `AnimationNodeAnimation` to the state machine, connect transitions to and from it, and add the `travel()` call in your state logic.
- **Blend 2D movement**: Replace `AnimationNodeStateMachine` root with `AnimationNodeBlendSpace2D` for 8-directional walking — blend position = input vector, corner nodes = directional walk clips.
- **Blend tree layers**: Use `AnimationNodeBlendTree` as root with `AnimationNodeAdd2` to layer an "aim" animation on top of movement animations (upper body aims while legs walk).
- **Editor-built graph**: Build the state machine in the AnimationTree editor panel and remove `_build_state_machine()` entirely — the result is identical at runtime, just stored in the .tscn.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AnimationPlayer` | Stores animation clip data |
| `AnimationLibrary` | Named collection of Animation resources |
| `Animation.add_track(type)` | Add a VALUE, TRANSFORM, etc. track |
| `Animation.track_set_path(track, path)` | Set the target property path |
| `Animation.track_insert_key(track, time, value)` | Insert a keyframe |
| `AnimationNodeStateMachine` | State machine root node for AnimationTree |
| `AnimationNodeAnimation` | Leaf node referencing one AnimationPlayer clip |
| `AnimationNodeStateMachineTransition` | Defines blend and advance behavior |
| `AnimationTree.tree_root` | The root AnimationNode of the graph |
| `anim_tree["parameters/playback"]` | Returns AnimationNodeStateMachinePlayback |
| `playback.travel("state")` | Request transition to named state |
| `playback.get_current_node()` | Name of the currently active state |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys / WASD | Move left and right |
| Space / Up | Jump |

## Key Constants

```gdscript
const SPEED    := 180.0    # horizontal pixels per second
const GRAVITY  := 620.0    # pixels per second squared
const JUMP_VEL := -330.0   # initial jump velocity
const FLOOR_Y  := 420.0    # Y position of the floor (manual physics)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Builds animations and state machine in code, drives physics and state transitions, draws character |
| `scenes/main.tscn` | Scene tree with Player, Visual, AnimationPlayer, AnimationTree, and HUD |
