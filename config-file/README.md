# Config File

<!-- tags: persistence, shows-its-working -->

A settings panel with sliders and toggles that persists to `user://settings.cfg` using Godot's built-in `ConfigFile` class, with defaults on first run, clamped validation, and auto-save on slider release.

## Purpose

Every shipped game needs persistent user preferences: volume levels, resolution/fullscreen toggle, control sensitivity, accessibility options. The settings must survive across sessions, carry reasonable defaults when no file exists, and tolerate malformed or missing values gracefully. Godot's `ConfigFile` class handles this with a minimal API: organize values into named sections, call `save()` and `load()`, and use `get_value(section, key, default)` for safe reads with automatic fallbacks.

This demo shows the complete settings round-trip — load on startup, edit via interactive controls, save on change — without any external library or manual INI parsing. The custom slider and toggle rendering demonstrates how to build settings UI purely in `_draw()`, useful when a built-in theme won't match the game's visual style.

## How It Works

### Save Format

`ConfigFile` writes a human-readable INI-style file to `user://settings.cfg`:

```ini
[audio]
master_volume=80
sfx_volume=60

[display]
fullscreen=false

[gameplay]
player_speed=150
show_fps=true
```

Sections group related settings. The file is automatically created on first save and survives reinstalls as long as it is in the `user://` directory.

### Loading with Defaults

```gdscript
func _load_settings() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(CONFIG_PATH)
    if err == OK:
        _settings["master_volume"] = int(cfg.get_value("audio",    "master_volume", DEFAULTS["master_volume"]))
        _settings["sfx_volume"]    = int(cfg.get_value("audio",    "sfx_volume",    DEFAULTS["sfx_volume"]))
        _settings["fullscreen"]    = bool(cfg.get_value("display",  "fullscreen",    DEFAULTS["fullscreen"]))
        _settings["player_speed"]  = int(cfg.get_value("gameplay", "player_speed",  DEFAULTS["player_speed"]))
        _settings["show_fps"]      = bool(cfg.get_value("gameplay", "show_fps",      DEFAULTS["show_fps"]))
    _clamp_all()
```

If `load()` returns anything other than `OK` (file doesn't exist, permission error, corrupt file), the `if` block is skipped entirely and `_settings` keeps the defaults copied from `DEFAULTS` in `_ready()`. `get_value(section, key, default)` provides a per-key fallback even when the file is partially written.

### Saving

```gdscript
func _save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio",    "master_volume", _settings["master_volume"])
    cfg.set_value("audio",    "sfx_volume",    _settings["sfx_volume"])
    cfg.set_value("display",  "fullscreen",    _settings["fullscreen"])
    cfg.set_value("gameplay", "player_speed",  _settings["player_speed"])
    cfg.set_value("gameplay", "show_fps",      _settings["show_fps"])
    cfg.save(CONFIG_PATH)
    _saved_flash = 1.5
    _dirty = false
```

A fresh `ConfigFile` is constructed each save — this is intentional. It ensures the file exactly matches the current settings dictionary; there is no risk of stale keys persisting from a previous version of the settings format.

### Slider Interaction

Mouse position on the slider track converts to a value via linear interpolation:

```gdscript
func _slider_value_from_x(rect: Rect2, mouse_x: float, min_val: int, max_val: int) -> int:
    var frac := clampf((mouse_x - rect.position.x) / rect.size.x, 0.0, 1.0)
    return int(round(min_val + frac * (max_val - min_val)))
```

`clampf` keeps the fraction in `[0, 1]` even if the mouse leaves the slider rect. `round()` snaps to integer values cleanly. Dragging is tracked via a `_dragging: String` field — set on `MOUSE_BUTTON_LEFT` press, cleared on release. The slider auto-saves when the mouse button is released.

### Toggle Interaction

```gdscript
elif _get_toggle_rect(2).has_point(mb.position):
    _settings["fullscreen"] = not bool(_settings["fullscreen"])
    _dirty = true
    queue_redraw()
```

One line flips the boolean. `_dirty` is set so the explicit Save button knows there are unsaved changes. The toggle knob slides visually based on the boolean state.

## ConfigFile vs. JSON

| | `ConfigFile` | `JSON` (via `FileAccess`) |
|---|---|---|
| Format | INI sections | Flat or nested JSON |
| Sections | Built-in | Manual nesting |
| `get_value` fallback | Yes, third argument | Manual `.get(key, default)` |
| Type preservation | Godot variants (int, bool, Vector2…) | Partial (numbers, strings, bools) |
| Human editable | Yes | Yes |
| Use case | Settings, small configs | Save files, data tables |

`ConfigFile` preserves Godot types including `Vector2`, `Color`, and `Array` natively — they are written and read back correctly without manual serialization. For save data that includes game world state, the JSON approach (see the `save-load` demo) is more portable.

## user:// Path

`user://settings.cfg` resolves to a platform-specific writable directory:

| Platform | Path |
|----------|------|
| Linux | `~/.local/share/godot/app_userdata/<ProjectName>/` |
| Windows | `%APPDATA%\Godot\app_userdata\<ProjectName>\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/<ProjectName>/` |

`res://` is read-only in exported builds. All persistent runtime data must use `user://` or an absolute path.

## How to Adapt This in Your Project

- **Apply settings immediately**: In `_save_settings()`, call `AudioServer.set_bus_volume_db(0, linear_to_db(_settings["master_volume"] / 100.0))` and `DisplayServer.window_set_mode(...)` to make settings take effect in the running session.
- **Settings categories with tabs**: Wrap the five rows in a `TabContainer` with Audio, Display, and Gameplay tabs. Each tab calls the same `_draw_slider` / `_draw_toggle` helpers.
- **Reset to defaults button**: Call `_settings = DEFAULTS.duplicate()` and then `_save_settings()`.
- **Version migration**: Add a `[meta] version=2` section and check it on load. If the version is older, map old key names to new ones before using the values.
- **Encrypted settings**: For anti-cheat sensitive values, use `ConfigFile.save_encrypted_pass(path, password)` and `load_encrypted_pass()`.

## Use as a building block

This demo is deliberately **kept as one file** rather than extracted into a
generic `Settings` class. The whole point is to show the raw `ConfigFile` API —
`get_value` / `set_value` / `save` / `load` — and hiding those calls behind a
wrapper would defeat the lesson. So reuse it by **lifting the pattern**, which is
already isolated in three named methods:

- **`DEFAULTS`** — a dictionary of every setting and its default. This is your schema.
- **`_load_settings()`** — `ConfigFile.load()` then `get_value(section, key, DEFAULTS[key])` for each key, falling back to the default when a key is absent (handles first run and added settings).
- **`_save_settings()`** — `set_value(section, key, value)` for each key, then `save()`.
- **`_clamp_all()`** — validate ranges after load so a hand-edited file can't inject bad values.

**Drop it in:** copy those four pieces, replace the demo's custom-drawn sliders
with real `HSlider` / `CheckButton` nodes wired to `_settings`, and call
`_save_settings()` on change. To *apply* settings live, see the first bullet
under *How to Adapt* above.

> `class_name` isn't used here because the reusable thing is the pattern, not a
> type. If you do want a shared `Settings` object, wrap these methods in a
> `RefCounted` and expose `get(key)` / `set(key, value)` / `save()`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ConfigFile.new()` | Create an in-memory config object |
| `cfg.set_value(section, key, value)` | Write a value to a section |
| `cfg.get_value(section, key, default)` | Read with fallback |
| `cfg.save(path)` | Persist to disk |
| `cfg.load(path)` | Load from disk; returns `OK` or error code |
| `Rect2.has_point(pos)` | Hit-test click against slider / toggle / button |
| `clampf(value, 0.0, 1.0)` | Clamp slider fraction to valid range |
| `clampi(value, min, max)` | Validate integer settings after load |

## Controls

| Input | Action |
|-------|--------|
| Click and drag slider track | Adjust volume or speed value |
| Release slider | Auto-saves settings |
| Click toggle | Flip boolean setting |
| Click Save button | Explicitly save all settings |

## Key Constants

```gdscript
const CONFIG_PATH := "user://settings.cfg"

const DEFAULTS := {
    "master_volume": 80,   # int 0–100
    "sfx_volume":    60,   # int 0–100
    "fullscreen":    false,
    "player_speed":  150,  # int 50–300
    "show_fps":      true,
}

# Sections: "audio", "display", "gameplay"
# _dirty: bool — true when unsaved changes exist
# _saved_flash: float — 1.5s timer for "Saved!" confirmation text
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Settings data, ConfigFile I/O, custom slider/toggle rendering |
| `tests/test_logic.gd` | Unit tests: defaults, clamping, toggle flip, slider math, speed range |
| `scenes/main.tscn` | Scene root (Control with script, fullscreen layout) |
| `tests/test.tscn` | Test runner scene |

## Related demos

- [accessibility-options](../accessibility-options) — Colourblind-safe palettes, reduced motion, text scaling, and shape cues.
- [settings-menu](../settings-menu) — A settings panel with volume slider, fullscreen toggle, and player color.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

