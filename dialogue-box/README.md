# Dialogue Box

Implements a reusable dialogue system with typewriter text reveal, speaker labels, multi-line progression, and a "skip to full text" mechanic.

## Purpose

Dialogue boxes appear in RPGs, visual novels, adventure games, and cutscenes. The core challenges are: displaying text character-by-character at a readable speed, letting the player skip the animation, advancing through multiple lines, and keeping the dialogue box reusable across many scenes. This demo addresses all four.

## Controls

- **Talk button**: Begin dialogue with the NPC elder
- **Next button** (appears during dialogue): Advance to the next line
  - If text is still typing out, pressing Next skips to the full line instantly

## How It Works

### Node Tree

```
Main (Node2D)               ← main.gd  (NPC visual, Talk button)
└── CanvasLayer
    └── DialogueBox (Control)  ← dialogue_box.gd
        └── Panel
            ├── VBox
            │   ├── SpeakerLabel (Label)
            │   └── TextLabel (Label)
            └── NextBtn (Button)
```

The dialogue box lives inside a `CanvasLayer` so it stays fixed on screen regardless of camera position.

### `scripts/dialogue_box.gd`

The reusable component. Its public API:

```gdscript
func start(lines: Array[String], speakers: Array[String] = []) -> void
signal finished
```

**State variables:**
- `_lines` / `_speakers` — The content for the current conversation.
- `_index` — Which line is currently displayed.
- `_typing` — Whether the typewriter is currently active.

**`_show_line(i)`** — Clears the text label, disables the Next button, sets `_typing = true`, then calls `_type_out.call_deferred(line)`. `call_deferred` schedules `_type_out` for the next frame so `_ready()` signals are fully resolved before typing starts.

**`_type_out(full)`** — The typewriter loop:
```gdscript
func _type_out(full: String) -> void:
    for i in full.length():
        if not _typing:       # skip triggered
            text_label.text = full
            break
        text_label.text = full.left(i + 1)
        await get_tree().create_timer(1.0 / CHARS_PER_SEC).timeout
    _typing = false
    next_btn.disabled = false
```

Each character reveals one more character of the string, then waits `1/28` seconds (≈ 35 ms). `_typing = false` from `_advance()` breaks the loop and jumps to full text.

**`_advance()`** — Called by the Next button:
- If still typing: sets `_typing = false` (loop breaks on next iteration, shows full text)
- If done typing: increments `_index` and calls `_show_line(_index + 1)`

When all lines are exhausted, the box hides and emits `finished`.

### `scripts/main.gd`

Defines the conversation as parallel arrays of lines and speaker names. Connects the Talk button to call `dialogue_box.start(LINES, SPEAKERS)`, and `dialogue_box.finished` to re-enable the Talk button.

## Design Theory

### Typewriter Effect with `await`

```gdscript
await get_tree().create_timer(delay).timeout
```

`await` suspends the current function and resumes it when the awaited signal fires — without blocking the main thread. This means the rest of the game continues running (physics, input, other nodes) while the text types out character by character.

This is a **coroutine**: a function that can pause mid-execution and resume. In Godot 4, any function using `await` becomes a coroutine.

### Skip Mechanic

The `_typing` flag is shared between the typing coroutine and the advance handler. Setting `_typing = false` from `_advance()` causes the loop's `if not _typing` check to trigger on the next iteration. Because the loop does an `await` each iteration, there is at least one frame where the check can happen. The full text is then shown synchronously before the loop exits.

### Separation of Content and Display

`dialogue_box.gd` contains zero game content — no hardcoded lines, no knowledge of the NPC. `main.gd` owns the content as plain string arrays. This separation lets the dialogue box be reused for any conversation by calling `start()` with different data.

### call_deferred

`_type_out.call_deferred(line)` instead of `_type_out(line)` ensures the function runs after the current frame's signal processing is complete. This prevents issues where `await` inside a signal handler can cause unexpected ordering.

## Files

| File | What it holds |
|------|---------------|
| `scripts/dialogue_box.gd` | A reusable typewriter dialogue box. Call start(lines, speakers); it reveals |
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

`DialogueBox` (`scripts/dialogue_box.gd`) is already a reusable UI component — a
`Control` with no game content. Copy that file and its scene subtree.

**Public API**
- `@export chars_per_sec` — typewriter speed.
- `start(lines: Array[String], speakers: Array[String] = [])` — show a conversation.
- signal `finished` — emitted when the last line closes.

**Integrate**
1. Add the `DialogueBox` scene under a `CanvasLayer`.
2. `dialogue_box.start(["Hello!", "Take this map."], ["Elder", "Elder"])`.
3. `dialogue_box.finished.connect(_re_enable_player)` — it hides itself on finish.

**Notes**
- `class_name DialogueBox` is global — rename if it collides.
- Content is pure data (string arrays), so it loads trivially from JSON or a CSV.
- For branching conversations, pair it with the [dialogue-tree](../dialogue-tree) demo's `DialogueTree` to pick which lines to show next.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `await get_tree().create_timer(t).timeout` | Pause a coroutine for `t` seconds |
| `signal finished` | Emitted when all lines are shown |
| `Callable.call_deferred(args)` | Schedule a function call for next frame |
| `String.left(n)` | First `n` characters of a string |
| `Button.disabled` | Prevent interaction |
| `CanvasLayer` | Screen-space overlay |

## Related demos

- [dialogue-tree](../dialogue-tree) — Branching conversations with conditional choices that mutate game state.
- [quest-system](../quest-system) — A multi-quest tracker with kill/collect/reach objectives and XP rewards.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

