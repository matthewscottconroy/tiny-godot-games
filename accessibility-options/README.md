# Accessibility Options

<!-- tags: ui, persistence, signals, component -->

Colourblind-safe palettes, reduced motion, text scaling, and shape cues — one settings node that everything else reacts to.

## Purpose

Roughly one in twelve men has some form of colour vision deficiency, and the red/green pairing most games use for "good" and "bad" is exactly the one they cannot separate. Motion sensitivity affects a smaller group far more severely: screen shake and camera kick can make a game genuinely unplayable rather than merely annoying. Small text excludes people quietly, because they just stop playing rather than filing a bug.

None of these are hard to support — the hard part is architectural. Accessibility settings cut across everything: colour affects every drawn thing, reduced motion affects every tween, text scale affects every label. If each system reads a global directly there is no signal when a setting changes; if each keeps its own copy they drift apart. This demo routes all of it through one node with one `changed` signal, and shows the four settings acting on a live scene so the difference is visible rather than described.

The most important idea here is the smallest one: **colour is never the only signal.** Shape cues pair a symbol with every colour-coded state, which is what makes the display work regardless of palette.

## Controls

| Key | Action |
|-----|--------|
| C | Cycle palette (Default → Deuteranopia → Tritanopia → High contrast) |
| M | Toggle reduced motion |
| S | Toggle shape cues |
| + / − | Text size, 1.0x to 2.0x |
| Space | Trigger a screen shake (does nothing under reduced motion) |

## How It Works

**One node owns the settings.** `AccessibilitySettings` holds four values as properties with setters, and each setter emits `changed` only when the value actually differs. Views connect once and re-read everything; nothing polls.

**Palettes are semantic, not literal.** Each palette maps the roles `positive` / `negative` / `neutral` to colours, rather than naming colours directly. Drawing code asks for `colors()["positive"]` and never mentions green, so swapping the palette needs no changes anywhere else. The alternate palettes split on axes that survive the relevant deficiency — blue/orange for deuteranopia, teal/magenta for tritanopia.

**Reduced motion goes through a helper.** Instead of scattering `if reduced_motion` checks, animation code asks `motion_duration(0.4)` and gets `0.0` back when motion is off — the end state appears immediately. The rule is that reduced motion removes *movement*, never *information*.

**Shape cues make colour redundant.** `cue_for(is_positive)` returns a symbol or an empty string. Pairing it with the colour means the state is readable without perceiving hue at all.

**Settings serialise to a plain dictionary.** `to_dict()` / `from_dict()` hand off to `ConfigFile` or JSON, and `from_dict` falls back to defaults for unknown palettes and clamps out-of-range values, so a settings file written by an older build still loads.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `var x: T: set(value):` | Property setters that emit only on a real change |
| `signal changed` | One notification for every consumer |
| `enum` + a lookup `Dictionary` | Palettes keyed by role rather than by colour name |
| `clampf()` | Keep text scale inside a usable range |
| `Label.add_theme_font_size_override()` | Apply text scale to a label at runtime |
| `Color` | Role colours, compared by distance in the tests |

## Key Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `MIN_TEXT_SCALE` | 1.0 | Never smaller than the design size |
| `MAX_TEXT_SCALE` | 2.0 | Beyond this, layouts need reflowing rather than scaling |

## Files

| File | What it holds |
|------|---------------|
| `scripts/accessibility.gd` | The `AccessibilitySettings` component: the four settings, palettes, and serialisation |
| `scripts/main.gd` | Demo driver: a scene that reacts to every setting at once |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite, including a check that each palette's two semantic colours stay far apart |

## Use as a building block

**Copy:** `scripts/accessibility.gd` — the `AccessibilitySettings` type. `scripts/main.gd` is the demo driver and is not needed.

**Public API**
- `palette: Palette`, `reduced_motion: bool`, `text_scale: float`, `shape_cues: bool` — all emit `changed` when set to a new value.
- `colors() -> Dictionary` — `positive` / `negative` / `neutral` for the current palette.
- `font_size(base: int) -> int` — base size scaled and rounded.
- `motion_duration(seconds: float) -> float` — `0.0` under reduced motion.
- `cue_for(is_positive: bool) -> String` — the shape cue, or `""`.
- `to_dict()` / `from_dict()` — persistence.
- signal `changed`.

**Integrate**
1. Register it as an autoload so every scene reads the same instance.
2. In each view, connect `changed` to a refresh function and re-read the settings there — do not cache individual values.
3. Route every decorative tween's duration through `motion_duration()`, and every semantic colour through `colors()`.
4. Persist with [settings-menu](../settings-menu)'s `ConfigFile` pattern, and load through `from_dict()` so old files stay valid.

**Notes**
- `class_name AccessibilitySettings` is global to the project — rename it if you already define that type.
- The palettes here are a starting point, not an audit. Verify your actual game art with a simulator; a palette that works for flat bars may not survive over a busy background.
- Reduced motion should never remove information. If a shake conveys "you were hit", keep a non-moving cue — a flash, or a shape change — when motion is off.
- Pairs with [input-remapping](../input-remapping), which covers the motor-accessibility side, and [subtitle-system](../subtitle-system) for audio.
- No project settings or input actions are required.

## Related demos

- [input-remapping](../input-remapping) — Runtime key rebinding via the `InputMap` singleton.
- [subtitle-system](../subtitle-system) — A caption queue for speech and non-speech audio, timed by reading speed.
- [config-file](../config-file) — A settings panel persisted to `user://settings.cfg` via `ConfigFile`.
- [settings-menu](../settings-menu) — A settings panel with volume slider, fullscreen toggle, and player color.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

