# Footstep Audio

Surface-sensitive footstep sounds: the player emits a `stepped(surface)` signal on a timer while walking. Main responds by generating a procedural tone tuned to the current surface (stone, grass, wood, water, metal).

## Purpose

Footstep audio adds life to movement — the hollow clunk of wood, the soft rustle of grass, the metallic ring of armor on metal. This demo shows the pattern: Area2D zones set the current surface type, a step timer fires a signal at walking pace, and the audio handler generates an appropriate sound. No audio files needed — `AudioStreamWAV` with procedurally generated waveforms is used, matching the approach in `audio-demo`.

## Controls

- **Arrow keys / WASD**: Walk, Up to jump
- Walk from the left (stone default) into each colored zone to hear the surface change

## Surfaces

| Zone | Freq | Wave | Character |
|------|------|------|-----------|
| Stone (default) | 380 Hz | square | Sharp tap |
| Grass | 160 Hz | sweep | Soft rustle |
| Wood | 260 Hz | sine | Hollow thump |
| Water | 200 Hz | sine | Splashy |
| Metal | 600 Hz | square | Ringing clank |

## How It Works

### `scripts/player.gd`

```gdscript
signal stepped(surface: String)

const STEP_INTERVAL := 0.34  # seconds between steps

func _physics_process(delta: float) -> void:
    # ... movement ...
    if is_on_floor() and absf(velocity.x) > 20.0:
        _step_timer -= delta
        if _step_timer <= 0.0:
            _step_timer = STEP_INTERVAL
            stepped.emit(_current_surface)
    else:
        _step_timer = 0.0
```

The timer only counts down while `is_on_floor()` and moving. When stationary or airborne, `_step_timer` resets to 0 so the first step after landing doesn't fire early.

### `scripts/main.gd` — zone detection

```gdscript
for zone in $SurfaceZones.get_children():
    zone.body_entered.connect(func(b) -> void:
        if b == _player:
            _player.set_surface(zone.surface_name)
    )
    zone.body_exited.connect(func(b) -> void:
        if b == _player:
            _player.set_surface("stone")  # reset to default
    )
```

Each `SurfaceZone` (Area2D with `surface_name` export) covers a section of the floor. The player's surface updates on `body_entered` and resets on `body_exited`.

### Procedural tone generation

```gdscript
func _make_tone(freq: float, duration: float, wave: String) -> AudioStreamWAV:
    for i in samples:
        var t  := float(i) / SAMPLE_RATE
        var raw: float
        match wave:
            "sine":   raw = sin(TAU * freq * t)
            "square": raw = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
            "sweep":  raw = sin(TAU * lerpf(freq * 0.6, freq * 1.6, float(i) / samples) * t)
        var envelope := 1.0 - pow(float(i) / samples, 0.4)
        var sample   := clampi(int(raw * 24000 * envelope), -32768, 32767)
```

The envelope `1.0 - pow(t, 0.4)` provides a sharp attack and gradual decay — more natural than a linear ramp. The sweep wave frequency-sweeps over time, mimicking a rustle or splash.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `signal stepped(surface)` | Typed signal carrying the surface name |
| `Area2D.body_entered/exited` | Detect when CharacterBody2D enters/leaves a zone |
| `AudioStreamWAV` | Raw PCM audio stream — generated in code |
| `AudioStreamWAV.FORMAT_16_BITS` | 16-bit signed PCM format |
| `AudioStreamPlayer.play()` | Start playback from the beginning |
