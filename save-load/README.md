# Save / Load

Demonstrates persistent game state: writing structured data to a JSON file in the user's data directory and reading it back across sessions.

## Purpose

Save systems are one of the most important non-gameplay features in any project. This demo covers the complete round-trip: collecting data, serializing it to JSON, writing to `user://`, reading back, parsing, and populating UI fields. It also shows input validation, a timestamp, and displaying the raw JSON — giving a complete picture of what is stored.

## Controls

- **Name / Score fields**: Type player name and score
- **+10 button**: Increment score
- **Save button**: Write data to `user://save.json`
- **Load button**: Read back and populate fields
- The raw JSON is shown below after loading

## How It Works

### Node Tree

```
Main (Control)           ← main.gd  (form + status; delegates I/O)
├── Fields (VBoxContainer)
│   ├── NameRow (HBoxContainer) → NameInput (LineEdit)
│   ├── ScoreRow (HBoxContainer) → ScoreInput (LineEdit), IncrBtn
│   └── SaveBtn, LoadBtn
├── StatusLabel (Label)
└── LoadDisplay (Label)
```

The file I/O lives in a reusable class, `SaveSystem` (`scripts/save_system.gd`),
so it can drop into any project. `main.gd` is only the demo form: it builds the
data dictionary, calls the system, and shows status.

### `scripts/save_system.gd`  (`class_name SaveSystem`)

**Save:**
```gdscript
func save(data: Dictionary) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
```

`JSON.stringify(data, "\t")` serializes the dictionary to a human-readable JSON string with tab indentation. `FileAccess.open(path, FileAccess.WRITE)` creates or truncates the file, `store_string()` writes it, and **`file.close()` flushes the buffer to disk** — omitting it risks data loss.

**Load:**
```gdscript
func load() -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(text)
    return parsed if parsed is Dictionary else {}
```

`JSON.parse_string()` returns `null` on failure or a `Variant` on success. Returning `{}` for both "missing" and "malformed" keeps the API simple; the caller uses `has_save()` first to tell those cases apart.

### `scripts/main.gd`

The driver builds the payload and reports status, validating input on the way in:
```gdscript
func _on_save() -> void:
    _save.save({
        "player_name": name_input.text,
        "score":       int(score_input.text) if score_input.text.is_valid_int() else 0,
        "timestamp":   Time.get_datetime_string_from_system(),
    })
```

`is_valid_int()` guards the conversion — without it, `int("abc")` would silently return 0. On load it calls `_save.has_save()` (no file) then checks `data.is_empty()` (bad file) before filling the form.

## Save System Theory

### user:// Path

`user://` maps to a platform-specific writable directory:
- **Windows**: `%APPDATA%\Godot\app_userdata\<project_name>\`
- **macOS**: `~/Library/Application Support/Godot/<project_name>/`
- **Linux**: `~/.local/share/godot/app_userdata/<project_name>/`

`res://` (the project directory) is read-only in exported builds. All runtime writes must use `user://` or an absolute path.

### JSON as a Save Format

**Advantages:**
- Human-readable — easy to debug, edit, or inspect
- Godot's `JSON.stringify()` and `JSON.parse_string()` are built-in
- Works for nested structures, arrays, numbers, booleans

**Limitations:**
- No type preservation (integers become floats in JSON if they're very large; `Vector2` requires custom serialization)
- Plain text — no built-in encryption or compression
- Not ideal for large datasets

For production games, consider encrypting sensitive data using `FileAccess.open_encrypted_with_pass()`, or using a binary format.

### JSON Type Round-Trip

JSON has five scalar types: `null`, `boolean`, `number`, `string`, and array/object containers. Godot's JSON layer maps:
- `int` → JSON number (may lose precision for very large integers)
- `float` → JSON number
- `bool` → JSON boolean
- `String` → JSON string
- `Dictionary` → JSON object
- `Array` → JSON array

`Vector2`, `Color`, `Rect2`, and other Godot types must be converted manually (e.g. `{"x": v.x, "y": v.y}`) before saving.

### Timestamps

`Time.get_datetime_string_from_system()` returns a string like `"2025-06-15 14:32:00"`. Storing the save timestamp is useful for:
- Displaying when the game was saved to the player
- Resolving conflicts between multiple save files
- Debugging "when did this save file come from?"

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `FileAccess.open(path, mode)` | Open a file for reading or writing |
| `FileAccess.file_exists(path)` | Check existence before opening |
| `FileAccess.WRITE` / `READ` | Open mode constants |
| `file.store_string(text)` | Write text to file |
| `file.get_as_text()` | Read entire file as string |
| `file.close()` | Flush and close (required for write) |
| `JSON.stringify(data, indent)` | Serialize to JSON string |
| `JSON.parse_string(text)` | Parse JSON string to Variant |
| `String.is_valid_int()` | Validate integer string before conversion |
| `Time.get_datetime_string_from_system()` | Current timestamp as string |

## Use as a building block

**Copy:** `scripts/save_system.gd` (the `SaveSystem` class). It's a `RefCounted` with no scene or demo dependencies.

**Public API**
- `_init(save_path := "user://save.json")` — pick where the file lives.
- `has_save() -> bool`
- `save(data: Dictionary)` — writes pretty-printed JSON.
- `load() -> Dictionary` — parsed data, or `{}` if missing/invalid.

**Integrate**
1. `var saves := SaveSystem.new("user://slot1.json")` (one instance per save slot).
2. Gather your game state into a `Dictionary` and call `saves.save(state)`.
3. On load: `if saves.has_save(): apply(saves.load())`.

**Notes**
- `class_name SaveSystem` is global — rename if it collides.
- JSON stores only JSON-native types. Convert `Vector2`/custom objects to arrays/dicts before saving (e.g. `{"x": pos.x, "y": pos.y}`) and back on load.
- For tamper-resistant saves, swap `FileAccess.open` for `FileAccess.open_encrypted_with_pass()` — the rest of the class is unchanged.
