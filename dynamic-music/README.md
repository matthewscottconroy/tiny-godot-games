# dynamic-music

Demonstrates real-time audio synthesis and crossfading between two music "layers" using `AudioStreamGenerator` and `Tween`.

## How to Run

Open the project in Godot 4.2 and press F5 (or run `scenes/main.tscn`).

- **C** — transition to calm layer (220 Hz sine)
- **F** — transition to combat/fight layer (440 Hz + 330 Hz mix)

The crossfade takes one second.

## Key Concepts

### AudioStreamGenerator and Buffer Filling

`AudioStreamGenerator` is an `AudioStream` subtype that exposes a writable sample buffer. You attach it to an `AudioStreamPlayer`, call `play()`, then retrieve the playback object each frame:

```gdscript
var pb := _calm_player.get_stream_playback() as AudioStreamGeneratorPlayback
var n := pb.get_frames_available()
for i in n:
    pb.push_frame(Vector2(left_sample, right_sample))
```

`get_frames_available()` tells you how many stereo frames the buffer can accept without overflowing. You must call this every `_process()` frame or the buffer will starve and you will hear dropouts. Each `Vector2` is a stereo sample: `x` = left channel, `y` = right channel.

### Phase Accumulation for Pitch

To produce a sine tone at a desired frequency, accumulate a phase variable each sample:

```gdscript
_calm_phase = fmod(_calm_phase + 220.0 / MIX_RATE, 1.0)
var sample := sin(TAU * _calm_phase)
```

`fmod(..., 1.0)` keeps the phase in `[0, 1)` and prevents floating-point drift over long play times. The ratio `freq / MIX_RATE` is how many full cycles advance per sample.

### Mixing Two Frequencies

Add two sine waves and scale each so the combined amplitude does not clip:

```gdscript
var s := sin(TAU * phase1) * 0.25 + sin(TAU * phase2) * 0.25
```

Each voice contributes 0.25 amplitude; together they peak at 0.5 — well below the 1.0 clipping threshold. The two pitches (440 Hz and 330 Hz) create the harmonic tension characteristic of action/combat music.

### Crossfade via volume_db Tween

Rather than mixing samples mathematically, this demo fades between two always-playing streams by tweening `AudioStreamPlayer.volume_db`:

```gdscript
var tw := create_tween()
tw.tween_property(_calm_player, "volume_db", 0.0, 1.0)
tw.parallel().tween_property(_combat_player, "volume_db", -80.0, 1.0)
```

`tw.parallel()` ensures both tweens run simultaneously. Using `-80.0 dB` rather than `INF` or muting is important: setting a player to exactly `-80 dB` is perceptually silent (the human ear cannot detect sounds below roughly `-60 dB` in a normal listening environment), yet the player remains active and its buffer stays filled, so the transition back is instant with no click or startup delay.

### Why -80 dB Equals Silence

Decibels are a logarithmic scale: `0 dB` = full amplitude, `-6 dB` = half amplitude, `-20 dB` = one tenth amplitude. At `-80 dB` the amplitude multiplier is `10^(-80/20) = 0.0001` — one ten-thousandth of full volume, far below the noise floor of any audio output device.

## File Layout

```
dynamic-music/
  project.godot
  icon.svg
  scenes/main.tscn       — Node2D with CalmPlayer + CombatPlayer
  scripts/main.gd        — synthesis, buffer filling, crossfade logic
  tests/test_logic.gd    — pure GDScript unit tests (no scene tree needed)
  tests/test.tscn        — minimal scene to run tests
```
