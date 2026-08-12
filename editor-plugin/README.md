# Editor Plugin

An `EditorPlugin` that adds a dock and registers a custom node type — extending the editor itself rather than the game.

## Purpose

Every project eventually grows a repetitive editor task: placing spawn points to a pattern, validating that every level has an exit, generating geometry from a few numbers. Doing those by hand is slow and error-prone; doing them with a plugin makes them a button.

`EditorPlugin` is how Godot exposes that, and it is a smaller API than it looks — a dock is just a `Control` parked in one of the editor's slots, and a custom node type is one registration call. What actually catches people is lifecycle. Godot does not clean up after your plugin: whatever you add in `_enter_tree()` you must remove in `_exit_tree()`, or every reload leaves another copy behind. And plugins reload constantly while you are writing them, so the mistake compounds within minutes.

The other classic trap is `owner`. A node added to the edited scene without its `owner` set is invisible in the Scene dock and is not saved with the scene — it simply vanishes, and nothing tells you why.

## Controls

Enable **Ring Tools** in Project Settings → Plugins. A dock appears on the left, and `RingSpawner` becomes available in the Add Node dialog.

At runtime the demo drives the same custom node from the keyboard:

| Key | Action |
|-----|--------|
| 1 / 2 | Fewer / more points |
| 3 / 4 | Smaller / larger stride (1 is a ring, higher makes a star) |
| 5 / 6 | Smaller / larger radius |

## How It Works

**`plugin.cfg` declares the plugin.** Name, description, author, version, and the script to run. Godot resolves `script` relative to the addon folder; a typo there is a silent no-op where the plugin never loads at all.

**`_enter_tree()` adds, `_exit_tree()` removes.** The plugin adds a dock with `add_control_to_dock()` and a node type with `add_custom_type()`, and undoes both on the way out. The test suite asserts that every `add_*` in the plugin has a matching `remove_*`, because this is the failure you cannot see until you have four identical docks.

**The dock is ordinary UI.** `ring_dock.tscn` is a `VBoxContainer` with sliders and a button. Nothing about it is plugin-specific except that a plugin parks it in a dock slot.

**The dock acts through `EditorInterface`.** `get_edited_scene_root()` gives it whatever scene is currently open, so "add a node to my scene" works regardless of what that scene is — then it sets `owner`, without which the node would not be saved.

**The geometry is static and pure.** `RingSpawner.build()` walks the vertices with a stride, which draws a star polygon when the stride is greater than one, and stops when the walk revisits a vertex — that is what closes a figure like stride 2 over 6 points, which only reaches half of them.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `EditorPlugin` | Base class for editor extensions |
| `add_control_to_dock()` / `remove_control_from_docks()` | Add and remove a dock panel |
| `add_custom_type()` / `remove_custom_type()` | Register a node type in the Add Node dialog |
| `EditorInterface.get_edited_scene_root()` | The scene currently open in the editor |
| `Node.owner` | Required, or the added node is not saved with the scene |
| `ConfigFile` | Reading `plugin.cfg` — the tests validate it this way |
| `@tool` | Required on the plugin and on anything it runs in the editor |

## Files

| File | What it holds |
|------|---------------|
| `addons/ring_tools/plugin.cfg` | Plugin manifest Godot reads to list and load it |
| `addons/ring_tools/plugin.gd` | The `EditorPlugin`: symmetric setup and teardown |
| `addons/ring_tools/ring_dock.tscn` | The dock's UI |
| `addons/ring_tools/ring_dock.gd` | Dock behaviour, and adding a node to the edited scene |
| `addons/ring_tools/ring_spawner.gd` | The custom node type, with static geometry generation |
| `scripts/main.gd` | Demo driver: runtime keyboard control |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite: manifest validity, teardown symmetry, geometry |

## Use as a building block

**Copy:** the whole `addons/ring_tools/` folder into your project's `addons/`, then enable it in Project Settings → Plugins. `scripts/main.gd` is the demo driver and is not needed.

**Public API**
- `RingSpawner.build(points, radius, skip) -> PackedVector2Array` — static, pure.
- `RingSpawner.polygon() -> PackedVector2Array` — using the node's own exports.
- `@export points: int`, `radius: float`, `skip: int`

**Integrate**
1. Rename the folder, the `name` in `plugin.cfg`, and the registered type — `RingSpawner` is global once registered.
2. Keep `_enter_tree()` / `_exit_tree()` symmetric. Add a teardown line the moment you add a setup line, not afterwards.
3. Set `owner` on every node you add to the edited scene, or it will not be saved.
4. For undo support, use `get_undo_redo()` from the plugin so your tool's actions land in the editor's own undo history — see [undo-redo](../undo-redo) for the underlying API.

**Notes**
- Plugin scripts must be `@tool`, and so must anything they instantiate in the editor. Forgetting it produces a plugin that loads but does nothing.
- Editor behaviour cannot be exercised headlessly, so the suite covers what actually breaks: a malformed manifest, a missing script path, asymmetric teardown, and the geometry.
- `EditorInterface` is editor-only. Guard any call to it with `Engine.is_editor_hint()` so a runtime instance stays inert.
- See [tool-script](../tool-script) first if you have not used `@tool` before.
- No project settings beyond enabling the plugin, and no input actions, are required.
