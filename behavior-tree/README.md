# Behavior Tree

<!-- tags: component, shows-its-working -->

An enemy AI driven by a Behavior Tree: the enemy patrols, investigates noises, chases the player, and attacks — all orchestrated through composable tree nodes that return SUCCESS, FAILURE, or RUNNING each frame.

## Purpose

Behavior Trees (BTs) are the dominant AI architecture in commercial games, used in titles from Halo to The Last of Us. They solve the combinatorial explosion that plagues flat state machines: instead of managing O(n²) transitions between states, you compose a tree of reusable nodes where priority and fallback are structurally encoded. A Selector node expresses "try the most important thing first, fall back if it fails." A Sequence node expresses "do all of these in order, abort if any step fails." This makes complex AI readable, testable in isolation, and easy to extend without touching existing nodes.

BTs also handle the multi-frame nature of game AI cleanly: any node can return RUNNING to indicate an in-progress action. The tree re-ticks from the root each frame and naturally re-evaluates conditions, so if the player escapes mid-chase the CanSeePlayer condition immediately returns FAILURE, aborting the entire chase sequence and falling through to the next branch.

Choose BTs over a flat FSM when your AI has more than four or five distinct behaviors, when behaviors need to be combined in different ways for different enemy types, or when you want designers to author AI without touching code.

## How It Works

### The Node Types (`scripts/bt_nodes.gd`)

Every node implements `tick(ctx: Dictionary) -> BTNode.Status`:

```gdscript
class Sequence extends BTNode:
    var children: Array[BTNode] = []
    func tick(ctx: Dictionary) -> Status:
        for child in children:
            var s := child.tick(ctx)
            if s != Status.SUCCESS:
                return s  # abort on first non-success
        return Status.SUCCESS

class Selector extends BTNode:
    var children: Array[BTNode] = []
    func tick(ctx: Dictionary) -> Status:
        for child in children:
            var s := child.tick(ctx)
            if s != Status.FAILURE:
                return s  # succeed on first non-failure
        return Status.FAILURE

class Leaf extends BTNode:
    var _fn: Callable
    func tick(ctx: Dictionary) -> Status:
        return _fn.call(ctx)
```

**Sequence** is logical AND: returns FAILURE on the first child failure, SUCCESS only when all children succeed.  
**Selector** is logical OR: returns SUCCESS on the first child success, FAILURE only when all children fail.  
**Leaf** wraps a `Callable` — conditions return SUCCESS/FAILURE immediately; actions may return RUNNING.

### Building the Tree (`scripts/main.gd`)

```gdscript
func _build_tree() -> void:
    var can_see   = BTNode.Leaf.new("CanSeePlayer",    _can_see_player)
    var chase     = BTNode.Leaf.new("ChasePlayer",     _chase_player)
    var attack    = BTNode.Leaf.new("AttackPlayer",    _attack_player)
    var heard     = BTNode.Leaf.new("HeardNoise",      _heard_noise)
    var investigate = BTNode.Leaf.new("InvestigateNoise", _investigate_noise)
    var patrol    = BTNode.Leaf.new("Patrol",          _patrol)

    var chase_seq = BTNode.Sequence.new()
    chase_seq.children = [can_see, chase, attack]

    var investigate_seq = BTNode.Sequence.new()
    investigate_seq.children = [heard, investigate]

    var root = BTNode.Selector.new()
    root.children = [chase_seq, investigate_seq, patrol]
    _bt_root = root
```

### Ticking Each Frame

```gdscript
func _process(delta: float) -> void:
    _enemy.vel = Vector2.ZERO
    _bt_root.tick({})
    _enemy.pos += _enemy.vel * delta
```

The enemy velocity is zeroed before each tick so whichever leaf runs this frame gets full authority over movement.

### Leaf Behaviors

The chase leaf returns RUNNING while closing in and SUCCESS once adjacent:

```gdscript
func _chase_player(ctx: Dictionary) -> BTNode.Status:
    var dist := _enemy.pos.distance_to(_player_pos)
    if dist <= ATTACK_RANGE:
        return BTNode.Status.SUCCESS
    var dir := (_player_pos - _enemy.pos).normalized()
    _enemy.vel = dir * CHASE_SPEED
    _enemy.state = "chase"
    return BTNode.Status.RUNNING
```

## Behavior Tree Theory

The tree encodes priority from left to right. At each frame the root Selector tries its first child (the chase Sequence). If `CanSeePlayer` returns FAILURE, the entire Sequence fails immediately and the Selector moves to the investigate Sequence. If no noise has been heard, that also fails, and Patrol runs as the default.

```
Selector [Root]
├── Sequence [Chase]
│   ├── CanSeePlayer   condition: distance < 160 px
│   ├── ChasePlayer    action: approach, RUNNING until adjacent
│   └── AttackPlayer   action: flash + SUCCESS if within 25 px
├── Sequence [Investigate]
│   ├── HeardNoise     condition: alert_pos != null
│   └── InvestigateNoise  action: walk to alert_pos
└── Patrol             action: oscillate between x=80 and x=200
```

**Complexity**: O(k) per tick where k is the number of nodes that must be evaluated before a result propagates — in the worst case the full tree, in the best case just the first condition. The context `Dictionary` passes shared world state into leaves without coupling them to the scene tree directly.

## How to Adapt This in Your Project

- Add a `RUNNING` resume state to your root by recording the last-running leaf and resuming from it. This avoids re-evaluating upstream conditions every frame and is the standard "reactive BT" optimization.
- Split conditions and actions into separate files. Conditions should be pure reads; actions should write only to a shared context dictionary, not directly to game objects.
- To add a new behavior (e.g., take cover), create a new Sequence with a condition leaf and an action leaf, then insert it into the root Selector at the appropriate priority position.
- The `ctx` Dictionary pattern is already present — pass health, ammo, and squad state through it so leaf callables remain decoupled.
- Avoid deeply nested Selectors inside Sequences: that makes failure semantics hard to reason about. Prefer flat Selectors at each level with Sequences for multi-step actions.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Callable` | Stores a function reference for use as a leaf node |
| `fn.call(ctx)` | Invokes the callable with a context argument |
| `draw_arc`, `draw_circle`, `draw_rect` | Immediate-mode 2D drawing in `_draw()` |
| `draw_string(ThemeDB.fallback_font, ...)` | Draw text without a Label node |
| `queue_redraw()` | Request a `_draw()` call on the next frame |
| `Input.is_key_pressed(KEY_W)` | Polling-style directional input |

## Controls

| Key | Action |
|-----|--------|
| WASD | Move the player (blue circle) |
| N | Place a noise marker at the mouse cursor |

The right panel shows the live tree: green = SUCCESS, red = FAILURE, yellow = RUNNING, gray = not evaluated this frame.

## Key Constants

```gdscript
const PATROL_MIN  := 80.0    # leftmost patrol x
const PATROL_MAX  := 200.0   # rightmost patrol x
const CHASE_SPEED := 80.0    # enemy px/s when chasing
const PATROL_SPEED := 40.0   # enemy px/s when patrolling
const INVESTIGATE_SPEED := 60.0
const PLAYER_SPEED := 120.0
const ATTACK_RANGE := 25.0   # px — triggers attack
const SIGHT_RANGE  := 160.0  # px — triggers chase
```

## Files

| File | Purpose |
|------|---------|
| `scripts/bt_nodes.gd` | `BTNode` base class with `Sequence`, `Selector`, and `Leaf` inner classes |
| `scripts/main.gd` | Enemy/player state, builds the BT, ticks it each frame, draws visualization |
| `scenes/main.tscn` | Root `Node2D` with `main.gd` attached |

## Use as a building block

**Copy:** `scripts/bt_nodes.gd` — the `BTNode` type. `scripts/main.gd` is the demo driver (it builds the scene and draws the visualisation) and is not needed.

**`BTNode` API**
- `tick(_ctx: Dictionary) -> Status`

**Notes**
- `class_name BTNode` is global to the project — rename it if you already define that type.

## Related demos

- [crafting-system](../crafting-system) — Combine two ingredients into a result via a commutative recipe dictionary.
- [dialogue-tree](../dialogue-tree) — Branching conversations with conditional choices that mutate game state.
- [experience-leveling](../experience-leveling) — XP collection and leveling on an exponential curve with stat gains.
- [inventory](../inventory) — A grid inventory: pick up, place, swap slots, and drop back to the world.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

