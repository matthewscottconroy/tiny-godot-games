# Groups

Demonstrates Godot's group system: broadcasting method calls to all nodes in a named group with a single line of code.

## Purpose

When many nodes of the same type need to respond to the same event — all enemies flash when the player uses an ability, all enemies freeze when pausing, all enemies take area-of-effect damage — calling each one individually requires tracking every instance. Groups let you broadcast to all members at once, even dynamically spawned ones, without any lists or references.

## Controls

- **Flash All**: Every enemy briefly flashes white (`call_group("enemies", "flash")`)
- **Freeze / Unfreeze**: Toggle movement on all enemies simultaneously
- **Damage All (−25 HP)**: Deal 25 damage to every enemy; enemies at 0 HP are removed
- **Spawn Enemy**: Add a new enemy to the scene (it joins the group automatically)

## How It Works

### Node Tree

```
Main (Node2D)              ← main.gd  (buttons, spawning, group calls)
├── Enemies (Node2D)
│   ├── Enemy (Node2D)    ← enemy.gd  (×7 at start)
│   └── ...
├── Buttons (HBoxContainer)
└── LogLabel (Label)
```

### `scripts/enemy.gd`

```gdscript
func _ready() -> void:
    add_to_group("enemies")
    vel = Vector2(randf_range(-70, 70), randf_range(-50, 50))
```

Every enemy adds itself to the `"enemies"` group in `_ready()`. Newly spawned enemies do this too — there is no registration step in `main.gd`.

Public methods that respond to group broadcasts:
- **`flash()`** — Tweens `modulate` to bright white then back to normal
- **`freeze_toggle()`** — Inverts `frozen`; sets `modulate` to blue when frozen
- **`take_damage(amount)`** — Decrements `hp`; calls `queue_free()` at 0

`_process(delta)` moves the enemy within screen bounds, bouncing on edges. If `frozen`, it skips movement.

### `scripts/main.gd`

```gdscript
$Buttons/FlashBtn.pressed.connect(func():
    get_tree().call_group("enemies", "flash")
    _log("flash() called on all %d enemies" % get_tree().get_nodes_in_group("enemies").size()))
```

`get_tree().call_group("enemies", "flash")` calls the `flash()` method on every node in the `"enemies"` group. It is equivalent to:
```gdscript
for enemy in get_tree().get_nodes_in_group("enemies"):
    enemy.flash()
```
but more concise and handled by the engine.

Spawning:
```gdscript
func _spawn_enemy() -> void:
    var e := Node2D.new()
    e.set_script(EnemyScript)
    e.position = Vector2(randf_range(80, 560), randf_range(100, 380))
    enemies.add_child(e)
```

No manual registration — the new enemy's `_ready()` calls `add_to_group("enemies")` automatically.

## Groups Theory

### What a Group Is

A group is a named set maintained by the `SceneTree`. Any node can join any number of groups at any time. The SceneTree's `call_group()` iterates the set and calls the method on each member.

### call_group() vs Signals vs References

| Approach | When to use |
|---|---|
| `call_group(group, method)` | Broadcast to many unknown nodes of the same type |
| Signals | One source, known set of listeners; need type-safe arguments |
| Direct references (`$Enemy`) | Fixed, known targets; need return values |

Groups shine when:
- The set of recipients is dynamic (enemies are spawned and destroyed)
- The caller doesn't need to know how many recipients exist
- Return values are not needed

### call_group Ordering

`call_group` calls methods in the order nodes were added to the scene tree. `call_group_flags(SceneTree.GROUP_CALL_DEFERRED, ...)` defers all calls to the end of the frame, useful when methods might modify the scene tree (e.g. `queue_free()`).

### get_nodes_in_group()

```gdscript
get_tree().get_nodes_in_group("enemies").size()
```

Returns an `Array[Node]` of all members. After `take_damage()` kills some enemies (via `queue_free()`), the count reflects only living enemies because freed nodes automatically leave their groups.

### Automatic Removal

When a node is freed (via `queue_free()` or `free()`), Godot automatically removes it from all groups. There is no need to call `remove_from_group()` before freeing.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `add_to_group(name)` | Join a group (usually in _ready()) |
| `remove_from_group(name)` | Leave a group |
| `is_in_group(name)` | Check membership |
| `get_tree().call_group(group, method, args...)` | Broadcast method call |
| `get_tree().get_nodes_in_group(group)` | Get all members as an Array |
| `SceneTree.GROUP_CALL_DEFERRED` | Defer calls to end of frame |
