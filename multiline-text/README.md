# Multiline Text

Demonstrates `RichTextLabel` with BBCode markup — bold, italic, colors, tables, animated effects, and mixed layouts — all set via the `text` property at runtime.

## Purpose

Most UIs need more than plain text: quest logs need colored headers, dialogue needs italics, status screens need tables. `RichTextLabel` with `bbcode_enabled = true` handles all of this with a simple markup syntax. This demo catalogs the full feature set.

## Controls

- **Basic** button: Inline formatting — bold, italic, underline, strikethrough, code, indent, alignment
- **Colors** button: Named colors, hex codes, background/foreground color spans
- **Table** button: A `[table=3]` grid with aligned cells
- **Effects** button: Animated effects — wave, shake, tornado, rainbow, pulse
- **Mixed** button: A realistic quest-log combining all features

## How It Works

### Node Tree

```
Main (Control)             ← main.gd
├── RichTextLabel
└── ButtonRow (HBoxContainer)
    └── [Basic, Colors, Table, Effects, Mixed buttons]
```

### `scripts/main.gd`

Each button sets `rich.text` to a BBCode string. `RichTextLabel.bbcode_enabled` must be `true` (set in `_ready()`). The `scroll_active` property enables scrolling when content overflows.

## BBCode Tag Reference

| Tag | Effect |
|-----|--------|
| `[b]...[/b]` | Bold |
| `[i]...[/i]` | Italic |
| `[u]...[/u]` | Underline |
| `[s]...[/s]` | Strikethrough |
| `[code]...[/code]` | Monospace font |
| `[color=red]...[/color]` | Named or hex color |
| `[bgcolor=...]...[/bgcolor]` | Background highlight |
| `[center]...[/center]` | Horizontal alignment |
| `[right]...[/right]` | Right-align text |
| `[indent]...[/indent]` | Increase indent level |
| `[table=N]...[/table]` | Grid with N columns |
| `[cell]...[/cell]` | Cell inside a table |
| `[wave]...[/wave]` | Vertical wave animation |
| `[shake]...[/shake]` | Random shake animation |
| `[rainbow]...[/rainbow]` | Cycling hue animation |

## Why BBCode Over Code?

The BBCode API is write-only: you compose a string and assign it. This is ideal for data-driven text (loaded from a JSON dialogue file, fetched from a server). For programmatic construction, the `push_*()` / `pop()` method API gives more control but is more verbose.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `RichTextLabel.bbcode_enabled` | Must be `true` to parse BBCode |
| `RichTextLabel.text` | Assign BBCode string; re-parses immediately |
| `RichTextLabel.scroll_active` | Enable/disable scroll bar |
| `RichTextLabel.push_color(c)` | Programmatic alternative to `[color]` |
| `RichTextLabel.pop()` | Closes the most recent push |
