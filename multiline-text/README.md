# Multiline Text

Demonstrates `RichTextLabel` with BBCode markup — bold, italic, color, tables, animated effects, and realistic quest-log layouts — all driven by assigning BBCode strings to the `text` property at runtime.

## Purpose

Most game UIs need more than plain white text on a dark background. Quest logs need colored status indicators and tables. Dialogue boxes need italics for emphasis and character-name highlighting. Tutorials need monospace code-style formatting. `RichTextLabel` with `bbcode_enabled = true` handles all of this without custom rendering code — you compose a string with markup tags and assign it; the node parses and renders the result.

The BBCode approach is also data-friendly: dialogue, quest text, and item descriptions loaded from JSON or CSV files can include markup tags, which the label renders without any additional parsing code. This is how commercial games like Divinity: Original Sin and Pillars of Eternity drive their richly formatted dialogue and item descriptions from data files.

Understanding when to use BBCode vs the programmatic `push_*()` / `pop()` API is also important. BBCode is write-once-read-never (you set `text` and the node handles everything); `push_*()` / `pop()` allows conditional construction and dynamic updates without string rebuilding.

## Controls

The demo is driven entirely by its buttons - no keyboard input.

| Button | Shows |
|--------|-------|
| Basic | Plain multi-line text and wrapping |
| Colors | Per-span colour via BBCode |
| Table | Aligned columns |
| Effects | Animated `wave` / `shake` / `rainbow` tags |
| Mixed | Several techniques combined |

## How It Works

### Node Tree

```
Main (Control)             ← main.gd
├── RichTextLabel
└── Buttons (HBoxContainer)
    └── [Basic, Colors, Table, Effects, Mixed buttons]
```

Each button calls a function that sets `rich.text` to a BBCode string. `_ready()` enables BBCode and shows the basic demo by default:

```gdscript
func _ready() -> void:
    # bbcode_enabled is set in the scene inspector (or can be set here)
    $Buttons/BasicBtn.pressed.connect(_show_basic)
    $Buttons/ColorsBtn.pressed.connect(_show_colors)
    $Buttons/TableBtn.pressed.connect(_show_table)
    $Buttons/EffectsBtn.pressed.connect(_show_effects)
    $Buttons/MixedBtn.pressed.connect(_show_mixed)
    _show_basic()
```

### Basic Formatting (`_show_basic`)

```gdscript
rich.text = """[b]Bold text[/b] is wrapped in [code][b][/code] tags.
[i]Italic text[/i] uses [code][i][/code].
[b][i]Bold and italic[/i][/b] can be combined.
[u]Underline[/u] uses [code][u][/code].
[s]Strikethrough[/s] uses [code][s][/code].

[indent]Indented text uses [code][indent][/code].[/indent]
[center]Centered text uses [code][center][/code].[/center]
[right]Right-aligned with [code][right][/code].[/right]"""
```

Tags nest and combine freely. `[b][i]text[/i][/b]` renders bold-italic. Unmatched or mistyped tags are silently ignored, so test your markup — no error messages are generated.

### Colors (`_show_colors`)

```gdscript
rich.text = """[color=tomato]Red / Tomato[/color]
[color=#ff6b6b]Hex color #ff6b6b[/color]
[bgcolor=navy][color=white]  Background highlight  [/color][/bgcolor]
[fgcolor=gold]Foreground overlay[/fgcolor]"""
```

`[color=]` accepts named Godot colors (case-insensitive), hex codes (`#rrggbb` or `#rrggbbaa`), and HTML color names. `[bgcolor=]` fills the text background; `[fgcolor=]` applies a color overlay on top of the current color.

### Tables (`_show_table`)

```gdscript
rich.text = """[table=3]
[cell][b]Name[/b][/cell][cell][b]HP[/b][/cell][cell][b]ATK[/b][/cell]
[cell][color=sea_green]Goblin[/color][/cell][cell]30[/cell][cell]5[/cell]
[cell][color=cornflower_blue]Knight[/color][/cell][cell]120[/cell][cell]22[/cell]
[cell][color=tomato]Dragon[/color][/cell][cell]500[/cell][cell]80[/cell]
[/table]"""
```

`[table=N]` creates a grid with N columns. `[cell]...[/cell]` fills one cell. Cells fill left-to-right, wrapping after every N cells. Column widths auto-size to content. Tags inside cells work normally — cells can contain bold, color, effects, or even nested tables.

### Animated Effects (`_show_effects`)

```gdscript
rich.text = """[wave amp=20 freq=3 connected=1]~ Wave effect text ~[/wave]
[shake rate=20 level=4 connected=1]!!! Shake effect !!![/shake]
[tornado radius=8 freq=2 connected=1]( Tornado swirl )[/tornado]
[rainbow freq=0.5 sat=0.8 val=0.8]Rainbow colored text[/rainbow]
[pulse color=#ffffff freq=1.0 ease=-2.0]Pulsing text fades in and out[/pulse]
[hint=This tooltip appears on hover]Hover to see tooltip[/hint]"""
```

All effects animate every frame with no additional code. Parameters tune the visual:
- `[wave]`: `amp` = vertical displacement in pixels, `freq` = oscillation speed
- `[shake]`: `rate` = shake frequency, `level` = shake magnitude
- `[rainbow]`: `freq` = hue rotation speed, `sat`/`val` = HSV saturation and value
- `[pulse]`: `color` = target pulse color, `freq` = pulses per second, `ease` = easing curve

`connected=1` makes all characters in the tag move together as a unit rather than individually.

### Mixed Layout (`_show_mixed`)

The Mixed demo combines all features in a realistic quest-log:

```gdscript
rich.text = """[center][b][color=gold]⚔ Quest Log ⚔[/color][/b][/center]

[color=cornflower_blue]■[/color] [b]The Lost Amulet[/b]
[indent]Find the amulet in [color=tomato]Darkwood Forest[/color].
Progress: [color=sea_green]2[/color] / 5 fragments found.[/indent]

[wave amp=5 freq=2 connected=1]URGENT:[/wave] A dragon has been spotted.

[table=2]
[cell][b]Stat[/b][/cell][cell][b]Value[/b][/cell]
[cell]Quests completed[/cell][cell][color=sea_green]12[/color][/cell]
[cell]Quests failed[/cell][cell][color=tomato]3[/color][/cell]
[/table]"""
```

This is the pattern to copy for real game UIs — structured text with semantic colors (green = good, red = danger, gold = important), indented detail, and a summary table.

## BBCode vs push_*()/pop()

| Method | Best for |
|--------|---------|
| `rich.text = "..."` | Static or data-loaded text; simple to write |
| `push_color(c)` / `pop()` | Conditionally built text (e.g. color health bar text red when below 20%) |
| `push_table(cols)` + `push_cell()` | Tables with dynamic row counts |

The programmatic API lets you avoid string concatenation for dynamic content. For example, a health display that changes color at low HP:

```gdscript
rich.clear()
rich.push_bold()
rich.add_text("HP: ")
rich.pop()
if hp < 20:
    rich.push_color(Color.RED)
rich.add_text(str(hp))
if hp < 20:
    rich.pop()
```

## How to Adapt This in Your Project

- **Data-driven dialogue**: store dialogue lines as strings with embedded BBCode tags in JSON. Load and assign directly to `rich.text` — no parsing code needed.
- **Item tooltips**: use `[hint=...]` to add hover tooltips to item names in inventory lists.
- **Chat systems**: append formatted messages with `append_text("[color=cyan][%s][/color] %s" % [player_name, message])`. Unlike setting `text`, `append_text` adds to existing content.
- **Accessibility**: use `[lang=...]` to mark text for screen reader hints; `RichTextLabel` supports basic accessibility metadata.
- **Custom effects**: subclass `RichTextEffect` to create project-specific animated text effects (e.g. typewriter, glitch, fire color cycling).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `RichTextLabel.bbcode_enabled` | Must be `true` to parse BBCode tags |
| `RichTextLabel.text` | Set BBCode string; re-parses and renders immediately |
| `RichTextLabel.append_text(s)` | Append BBCode without clearing existing content |
| `RichTextLabel.clear()` | Remove all content |
| `RichTextLabel.scroll_active` | Enable scrollbar when content overflows |
| `RichTextLabel.push_color(c)` / `.pop()` | Programmatic color span (no string needed) |
| `RichTextLabel.push_bold()` / `.pop()` | Programmatic bold span |
| `RichTextLabel.push_table(cols)` | Programmatic table start |
| `RichTextEffect` | Base class for custom animated text effects |

## BBCode Tag Reference

| Tag | Effect |
|-----|--------|
| `[b]...[/b]` | Bold |
| `[i]...[/i]` | Italic |
| `[u]...[/u]` | Underline |
| `[s]...[/s]` | Strikethrough |
| `[code]...[/code]` | Monospace font |
| `[color=red]...[/color]` | Named or hex color |
| `[bgcolor=navy]...[/bgcolor]` | Background color |
| `[fgcolor=gold]...[/fgcolor]` | Foreground overlay |
| `[center]...[/center]` | Center-align |
| `[right]...[/right]` | Right-align |
| `[indent]...[/indent]` | Indent level |
| `[table=N]...[/table]` | N-column grid |
| `[cell]...[/cell]` | One table cell |
| `[wave amp=20 freq=3]` | Vertical wave animation |
| `[shake rate=20 level=4]` | Random shake animation |
| `[rainbow freq=0.5]` | Hue-cycling animation |
| `[pulse color=# freq=1.0]` | Fade in/out animation |
| `[hint=tooltip text]` | Hover tooltip |

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All BBCode strings and button connections |
| `scenes/main.tscn` | Control root with RichTextLabel and button bar |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

