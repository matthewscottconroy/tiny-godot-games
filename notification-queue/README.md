# Notification Queue

A FIFO notification system: messages are queued and displayed one at a time in the top-right corner, each sliding in from off-screen, holding, then sliding out before the next one begins.

## Purpose

Games generate many simultaneous events: an enemy drops loot, you gain experience, an achievement unlocks, a quest updates. If every system fires its notification the instant it happens, you get a stack of overlapping banners or a wall of text that the player can't read. The notification queue solves this by serializing events — only one message is ever on screen, and others wait their turn.

Every commercial game with a HUD uses this pattern. *Destiny 2* queues item acquisition notifications. *Dark Souls* queues item pickup messages. Mobile games queue achievement popups. The pattern also appears in operating system notification centers and web toast libraries. The implementation is always the same: a queue, a busy flag, and a chained animation that calls itself when done.

## How It Works

### `scripts/notification_manager.gd`

The manager holds two pieces of state: the queue and the busy flag.

```gdscript
var _queue: Array[String] = []
var _busy := false

func push(msg: String) -> void:
    _queue.append(msg)
    if not _busy:
        _show_next()
```

`push()` is the public API. If the manager is idle it starts immediately; if it's already animating a notification, the new message waits in the queue. The `_busy` flag prevents `_show_next()` from being called while a tween is running.

### Tween Chain

```gdscript
func _show_next() -> void:
    if _queue.is_empty():
        _busy = false
        return

    _busy = true
    _label.text = _queue.pop_front()
    _panel.position = Vector2(HIDE_X, 20.0)

    var tw := create_tween()
    tw.tween_property(_panel, "position:x", SHOW_X, SLIDE_IN_TIME)
    tw.tween_interval(SHOW_TIME)
    tw.tween_property(_panel, "position:x", HIDE_X, SLIDE_OUT_TIME)
    tw.tween_callback(_show_next)
```

Godot 4 tweens execute sequentially by default. Chaining four steps — slide in, hold, slide out, callback — in a single tween produces the entire animation without any manual timer or state machine. The final `tween_callback(_show_next)` recurses back into the draining logic, pulling the next message from the queue when ready.

The panel starts off-screen at `HIDE_X = 660.0` (just past the right edge). Sliding to `SHOW_X = 390.0` brings it into view. Sliding back to `HIDE_X` hides it.

### `scripts/main.gd` — Dispatching Messages

```gdscript
func _process(_delta: float) -> void:
    if Input.is_key_just_pressed(KEY_1):
        _notif.push("Achievement: First Steps!")
    elif Input.is_key_just_pressed(KEY_2):
        _notif.push("Level Up! You are now level 5")
```

`main.gd` holds an `@onready` reference to the `NotifManager` node and calls `push()`. The manager handles everything else. In a real game, `push()` would be called by the systems that produce events — the combat system, the loot system, the quest system — each unaware of the others.

### Why `CanvasLayer`

`NotifManager extends CanvasLayer`, which renders its children in screen space above all world-space nodes, regardless of camera position or world z-index. This guarantees notifications are never occluded by game objects, even during cutscenes or UI-heavy screens. The `CanvasLayer` approach also means the notification panel position is in screen coordinates (`SHOW_X`, `HIDE_X`), not world coordinates, so it never drifts with the camera.

## The Queue Pattern

### FIFO Order

`_queue.append(msg)` / `_queue.pop_front()` implements a first-in, first-out queue using an array. GDScript arrays do not have a dedicated `Queue` type, but `append` + `pop_front` is idiomatic. For very high-frequency events, consider capping queue length and dropping oldest entries.

### Busy Flag vs. Recursive State

The `_busy` flag is the minimal synchronization needed for this pattern. An alternative is to check `_queue.is_empty()` in `push()` as the start condition and never set a flag — but the flag makes intent explicit and makes the logic easier to reason about when adding features like pause, skip, or priority queues.

### Priority Extensions

To support priority (e.g., combat alerts interrupting achievement popups), replace `Array[String]` with `Array[Dictionary]` where each entry has `{"msg": ..., "priority": int}`. On `push()`, insert at the sorted position and optionally cancel the current tween if the new item outranks what's currently showing.

## How to Adapt This in Your Project

1. Convert `NotifManager` to an Autoload so any script can call `Notification.push(msg)` without holding a node reference.
2. Add icon support by storing a `Texture2D` alongside the message string and rendering it inside the panel.
3. To support multiple simultaneous notifications (stacked banners), maintain an array of active panels and manage their y-positions with tweens.
4. Call `_queue.clear()` to flush pending notifications when changing scenes or entering cutscenes.
5. Add a `max_queue_size` constant and drop messages if the queue exceeds it — this prevents a backlog from appearing long after the event that triggered it.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Tween.tween_property(node, prop, val, dur)` | Animate a property over time |
| `Tween.tween_interval(sec)` | Insert a pause between tween steps |
| `Tween.tween_callback(callable)` | Call a function when reached in the sequence |
| `Array.pop_front()` | Remove and return the first element (FIFO dequeue) |
| `CanvasLayer` | Renders children in screen space above world nodes |
| `create_tween()` | Create a `Tween` owned by this node |

## Controls

| Key | Notification |
|-----|-------------|
| 1 | Achievement: First Steps! |
| 2 | Level Up! You are now level 5 |
| 3 | New item found: Iron Sword |
| 4 | Quest completed: The Lost Mine |

## Key Constants

```gdscript
const SLIDE_IN_TIME  := 0.2    # seconds to slide panel onto screen
const SHOW_TIME      := 2.0    # seconds the notification stays visible
const SLIDE_OUT_TIME := 0.15   # seconds to slide panel off screen
const SHOW_X         := 390.0  # on-screen x position of panel
const HIDE_X         := 660.0  # off-screen x position (past right edge)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/notification_manager.gd` | Queue, busy flag, tween chain, `push()` API |
| `scripts/main.gd` | Key input → `push()` calls, background drawing |
| `scenes/main.tscn` | Node2D with NotifManager (CanvasLayer) child |
| `tests/test_logic.gd` | Tests for FIFO order, busy flag, queue drain |
