# Subtitle System

<!-- tags: ui, signals, component -->

A caption queue for speech and non-speech audio, with durations derived from reading time and one caption on screen at a time.

## Purpose

Captions are the accessibility feature with the widest reach: they serve deaf and hard-of-hearing players, anyone playing muted, anyone playing in a noisy room, and non-native speakers. They are also the one most often bolted on late and done badly.

Two things separate a usable caption system from a broken one. The first is queuing: two lines that overlap in time must not overlap on screen, so the second waits rather than replacing the first mid-read. The second is that games have two kinds of captionable audio — speech, which needs a speaker attribution, and non-speech cues like a door opening behind you, which carry information the player would otherwise lose entirely. Conflating them produces captions that either miss half the information or read like stage directions.

Timing matters too: a fixed duration is wrong for both short and long lines, so duration comes from the text length with a floor for very short ones.

## Controls

| Key | Action |
|-----|--------|
| 1 | Speak the next line of dialogue |
| 2 | Queue all three lines at once (shows the queuing) |
| 3 | Emit a non-speech sound cue |
| C | Toggle sound cues on/off |
| S | Skip the visible caption |
| X | Clear everything |

## How It Works

**One caption at a time.** `say()` and `cue()` append to a queue. If nothing is showing, the new entry becomes current immediately; otherwise it waits. `update(delta)` ages the visible caption and promotes the next one when it expires.

**Duration comes from reading time.** `duration_for(text)` divides length by `chars_per_second` and clamps between `min_duration` and `max_duration` — so a two-word line still stays up long enough to notice, and a very long line is cut off rather than parking forever.

**Cues are a separate channel.** `cue()` marks the entry `is_cue`, which the view renders bracketed and can style differently. Because it is a separate call, a player who turns sound cues off loses only those — speech is unaffected.

**Skipping and clearing are distinct.** `skip()` cuts the visible caption short and moves to the next; `clear()` drops everything, which is what a scene change needs.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Array.pop_front()` | FIFO queue behaviour |
| `String.length()` | Reading-time estimate |
| `clampf()` | Duration floor and ceiling |
| `String.strip_edges()` | Reject blank captions |
| `signal` | `caption_shown` / `caption_hidden` / `queue_empty` for the view |
| `Label.autowrap_mode` | Wrapping long captions in the band |

## Key Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `chars_per_second` | 14.0 | Reading speed used to size durations |
| `min_duration` | 1.2 | Shortest a caption is ever shown |
| `max_duration` | 8.0 | Longest before it is cut off |

## Files

| File | What it holds |
|------|---------------|
| `scripts/subtitles.gd` | The `SubtitleQueue` component: queue, timing, formatting |
| `scripts/main.gd` | Demo driver: sample dialogue, cues, and the caption band |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/subtitles.gd` — the `SubtitleQueue` type. `scripts/main.gd` is the demo driver and is not needed.

**Public API**
- `say(text, speaker := "")` / `cue(text)` — queue speech or a non-speech cue.
- `update(delta)` — call once per frame.
- `current() -> Dictionary` / `current_text() -> String` — what to draw.
- `skip()` / `clear()` — advance, or drop everything.
- `pending() -> int`, `is_showing() -> bool`, `duration_for(text) -> float`.
- `@export chars_per_second`, `min_duration`, `max_duration`, `sound_cues`.
- signals `caption_shown(entry)`, `caption_hidden(entry)`, `queue_empty`.

**Integrate**
1. Register it as an autoload so any system can caption without wiring.
2. Call `say()` wherever dialogue plays and `cue()` wherever an important sound plays — the call belongs next to the audio, not in a separate captions file that drifts out of sync.
3. Draw `current_text()` over a solid backing band. Captions over raw art are unreadable at exactly the moments they matter.
4. Expose `sound_cues` in your options screen alongside [accessibility-options](../accessibility-options).

**Notes**
- `class_name SubtitleQueue` is global to the project — rename it if you already define that type.
- Reading speed is a preference, not a constant. Consider exposing `chars_per_second` to the player; 14 is a reasonable default, not a universal one.
- The queue holds captions, not audio. If a line's audio is skipped, call `skip()` too, or the caption will outlive the sound.
- No project settings or input actions are required.

## Related demos

- [accessibility-options](../accessibility-options) — Colourblind-safe palettes, reduced motion, text scaling, and shape cues.
- [localization](../localization) — `TranslationServer` string tables switched at runtime across EN/ES/FR.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

