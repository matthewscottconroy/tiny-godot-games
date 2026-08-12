# Rhythm Minigame

A minimal Godot 4 demo showing timed-input rhythm game mechanics: notes fall to a target zone, a judgment window scores your timing accuracy.

## Purpose

Rhythm scoring is a judgment window around a target time, and everything else follows from it. The subtleties are that timing must be measured against audio or a monotonic clock rather than frame counts, and that the window boundaries define the difficulty. This demo shows notes approaching a target line and the graded judgment that results.

## Controls

| Key | Action |
|-----|--------|
| Space | Hit — judges the nearest note |

## How It Works

### Note Spawning

A beat timer counts down `BEAT_INTERVAL = 60 / BPM` seconds. Each beat, a note spawns with 75% probability, creating musical gaps.

### Judgment

When Space is pressed, the note closest to `TARGET_Y` is evaluated:

| Distance from target | Result | Points |
|---------------------|--------|--------|
| ≤ 10 px | PERFECT | 100 + combo bonus |
| ≤ 26 px | GOOD | 50 |
| > 26 px or no note | MISS | 0, combo reset |

### Combo Multiplier

Each successful hit increments `_combo`. The perfect score formula is `100 + combo * 5`, rewarding sustained accuracy. Any miss resets combo to 0.

### Auto-Miss

Notes that fall past `TARGET_Y + GOOD_DIST * 2` without being hit are automatically counted as misses and removed.

## Key Constants

```gdscript
const BPM           := 120.0    # beats per minute
const BEAT_INTERVAL := 0.5      # seconds between beats
const FALL_SPEED    := 240.0    # px/s note fall speed
const TARGET_Y      := 400.0    # y position of the hit zone
const PERFECT_DIST  := 10.0     # pixels for PERFECT rating
const GOOD_DIST     := 26.0     # pixels for GOOD rating
```

## Files

```
rhythm-minigame/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # beat timer, note spawn, judgment, combo, _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Time.get_ticks_msec()` | A monotonic clock, not a frame count |
| `absf()` | Signed timing error against the target |
| Judgment window thresholds | Grade the error into Perfect/Good/Miss |
| `draw_line()` / `draw_circle()` | Notes and the target line |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

