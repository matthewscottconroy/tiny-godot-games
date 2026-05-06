# Settings Menu

A settings panel with master-volume slider, fullscreen toggle, and a player-
speed option.  **Apply** saves to disk and takes effect immediately; **Cancel**
reverts the UI; **Reset** restores built-in defaults.

## Controls

| Button | Action |
|--------|--------|
| Volume slider | Adjust master bus volume |
| Fullscreen checkbox | Toggle window mode |
| Speed spinbox | Set player movement speed (50–400) |
| Apply | Save settings + apply immediately |
| Cancel | Discard unsaved UI changes |
| Reset | Restore all defaults |

## How It Works

### ConfigFile for persistent settings

```gdscript
const CONFIG_PATH := "user://settings.cfg"

func _on_apply() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio",    "volume",     _vol_slider.value)
    cfg.set_value("display",  "fullscreen", _fs_check.button_pressed)
    cfg.set_value("gameplay", "speed",      int(_speed_spin.value))
    cfg.save(CONFIG_PATH)
```

`user://` resolves to the OS user-data directory
(`~/.local/share/godot/app_userdata/<project>/` on Linux).  `ConfigFile` is an
INI-style text format built into Godot — no JSON parsing required.

### AudioServer.set_bus_volume_db + linear_to_db

The slider exposes a linear `[0, 1]` value which is more intuitive for users.
The AudioServer expects decibels, so the conversion is:

```gdscript
AudioServer.set_bus_volume_db(0, linear_to_db(_saved_vol))
```

`linear_to_db(1.0) == 0 dB` (full volume), `linear_to_db(0.5) ≈ -6 dB`
(half perceived loudness), `linear_to_db(0.0) == -inf dB` (silence).

### DisplayServer window mode

```gdscript
if _saved_fs:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
else:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
```

This takes effect immediately on Apply.

### Apply / Cancel pattern

`_saved_*` variables mirror what is on disk.  The UI widgets hold the
"draft" values.  `_apply_to_ui()` copies saved → UI (used by both `_ready`
and `_on_cancel`).  `_on_apply()` copies UI → saved → disk.

## File Layout

```
settings-menu/
  project.godot
  icon.svg
  scripts/
    main.gd         # all settings logic, ConfigFile, AudioServer
  scenes/
    main.tscn       # Panel, VBox, slider/checkbox/spinbox, buttons
  tests/
    test_logic.gd   # linear_to_db, ConfigFile round-trip, cancel revert
    test.tscn
  README.md
```
