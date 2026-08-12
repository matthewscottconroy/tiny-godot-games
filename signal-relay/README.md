# Signal Relay

Demonstrates Godot's signal system: a transmitter node emits a custom signal; a receiver node has a method to handle it; a third node (main) wires them together.

## Purpose

Signals are Godot's primary mechanism for decoupled communication between nodes. The key design principle: the transmitter does not know who is listening, and the receiver does not know who is sending. A third node owns the connection. This pattern prevents tight coupling between unrelated parts of a game and is foundational to clean Godot architecture.

## Controls

- **Click the Transmitter button**: Emits `message_sent` with the current timestamp
- Watch the Receiver label update with the received message

## How It Works

### Node Tree

```
Main (Control)               ← main.gd  (owns the connection)
├── Transmitter (Button)     ← transmitter.gd  (sends signal)
└── Receiver (Label)         ← receiver.gd  (receives signal)
```

### `scripts/transmitter.gd`

```gdscript
extends Button
signal message_sent(text: String)

func _ready() -> void:
    pressed.connect(_on_pressed)

func _on_pressed() -> void:
    message_sent.emit("Signal received at %d ms!" % Time.get_ticks_msec())
```

The `Transmitter` is a `Button` that declares a custom `signal message_sent(text: String)`. When the button is pressed, it emits the signal with a timestamp string. The transmitter has no reference to the receiver — it only knows about the signal it owns.

### `scripts/receiver.gd`

```gdscript
extends Label

func receive(text: String) -> void:
    self.text = text
```

The `Receiver` is a `Label` with a single method `receive()`. It has no knowledge of the `Transmitter` or the `message_sent` signal. It simply provides a public method that any caller can use.

### `scripts/main.gd`

```gdscript
extends Control

func _ready() -> void:
    $Transmitter.message_sent.connect($Receiver.receive)
```

Main wires the two together with one line. This is the **dependency inversion**: rather than Transmitter directly calling Receiver's method, Main connects them through the signal system.

## Signal Theory

### Signal Declaration

```gdscript
signal message_sent(text: String)
```

This declares a signal on the node's type. The parameter list defines what data the signal carries. In Godot 4, signals are typed — the argument types are enforced at runtime. A signal with no parameters: `signal my_signal`.

### Emission

```gdscript
message_sent.emit("hello")
```

`emit()` calls all connected callables synchronously. Every connected handler runs before `emit()` returns. If no handlers are connected, `emit()` does nothing.

### Connection

```gdscript
source.signal_name.connect(target.method_reference)
```

- `source.signal_name` — accesses the signal object on the source node
- `.connect(callable)` — registers a callable to be called when the signal fires

The callable can be:
- A method reference: `$Receiver.receive`
- A lambda: `func(text): print(text)`
- A bound method: `some_object.method_name`

### Why a Third Node Owns the Connection

If `Transmitter` connected directly in its `_ready()`:
```gdscript
message_sent.connect($"../Receiver".receive)  # Transmitter knows about Receiver
```
This couples Transmitter to Receiver — the Transmitter can only work in scenes that also contain a Receiver at that exact path.

If `Receiver` connected in its `_ready()`:
```gdscript
$"../Transmitter".message_sent.connect(receive)  # Receiver knows about Transmitter
```
This couples Receiver to Transmitter — the Receiver can only work in scenes with a Transmitter at that exact path.

`Main` owning the connection keeps both nodes independent. They can be reused in different scenes, connected to different partners, or tested in isolation.

### Signal vs Direct Method Call

| | Signal | Direct call |
|---|---|---|
| Coupling | Sender unaware of receivers | Sender holds reference |
| Multiple listeners | Yes, just connect more | Must know all targets |
| Return values | No | Yes |
| Best for | Notifications, events | Queries, commands |

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `signal name(arg: Type)` | Declare a typed signal |
| `signal_name.emit(args...)` | Fire the signal |
| `signal_name.connect(callable)` | Register a handler |
| `signal_name.disconnect(callable)` | Remove a handler |
| `signal_name.is_connected(callable)` | Check if connected |
| `Time.get_ticks_msec()` | Milliseconds since engine start |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/receiver.gd` | `receiver` behaviour |
| `scripts/transmitter.gd` | `transmitter` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/receiver.gd`, `scripts/transmitter.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/receiver.gd`**
- `receive(text: String) -> void`

**`scripts/transmitter.gd`**
- signal `message_sent(text: String)`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

