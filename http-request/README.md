# HTTP Request

A UI demo showing how to fetch data from a public JSON API using Godot 4's `HTTPRequest` node. Fetches a todo item from [JSONPlaceholder](https://jsonplaceholder.typicode.com) and displays the parsed result.

## Purpose

Leaderboards, version checks, and remote configuration all come down to one node and one signal. The parts worth knowing are the ones that bite: `HTTPRequest` is asynchronous, the response body arrives as a `PackedByteArray` you have to decode with `get_string_from_utf8()`, and `JSON.parse()` returns an error code rather than raising. This demo does a real request against a public API and handles each of those.

## Controls

| Input        | Action                    |
|--------------|---------------------------|
| Fetch JSON   | Send the HTTP GET request |

Requires an active internet connection.

## How It Works

### HTTPRequest Node

`HTTPRequest` is a built-in Godot node that wraps HTTP/HTTPS communication. Add it to the scene (it has no visual representation) and call:

```gdscript
var err := $HTTPRequest.request("https://example.com/api/data")
```

The call is **non-blocking** — it returns immediately and fires the `request_completed` signal when done.

### request_completed Signal

```gdscript
func _on_response(
        result: int,           # HTTPRequest.RESULT_* constant
        code: int,             # HTTP status code (200, 404, etc.)
        _headers: PackedStringArray,
        body: PackedByteArray  # raw response bytes
) -> void:
```

Always check both `result` and `code`:

| Check | Meaning |
|---|---|
| `result != HTTPRequest.RESULT_SUCCESS` | Network-level failure (no connection, timeout, etc.) |
| `code != 200` | Server responded but with a non-OK HTTP status |

### JSON Parsing

```gdscript
var json := JSON.new()
var err := json.parse(body.get_string_from_utf8())
if err != OK:
    # parse failed — json.get_error_line() gives the offending line
    return
var data: Dictionary = json.get_data()
```

`JSON.new()` is stateful: call `parse()` first, then `get_data()`. Always check `err` before trusting `get_data()`.

### Error Handling Strategy

This demo handles three distinct failure layers:

1. **Request failed to start** — `_http.request()` returned non-OK (bad URL format, no HTTPRequest node, etc.)
2. **Network error** — `result != RESULT_SUCCESS` in the callback (timeout, DNS failure, etc.)
3. **HTTP error** — `code != 200` (404 Not Found, 500 Server Error, etc.)
4. **Parse error** — `json.parse()` returned non-OK (malformed JSON body)

Separating these four layers makes debugging much easier than a single catch-all error handler.

### Disabling the Button During Fetch

```gdscript
func _fetch() -> void:
    _fetch_btn.disabled = true   # prevent double-click
    ...

func _on_response(...) -> void:
    _fetch_btn.disabled = false  # always re-enable, even on error
```

The button is re-enabled in all code paths of `_on_response`, including early returns on error.

## Running Tests

Open `tests/test.tscn` as the main scene and run. Tests use a hardcoded sample JSON string — no network connection is required.

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `HTTPRequest.request()` | Start an asynchronous GET |
| `HTTPRequest.request_completed` | Signal carrying result, code, headers, and body |
| `PackedByteArray.get_string_from_utf8()` | Decode the raw body |
| `JSON.parse()` / `get_error_line()` | Parse with an error code rather than an exception |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

