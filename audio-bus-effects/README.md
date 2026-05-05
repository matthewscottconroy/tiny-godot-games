# Audio Bus Effects

Dynamic reverb, echo, and compression routed through AudioBus. Press Space to play a tone; use arrow keys to switch buses. Demonstrates the bus architecture none of the other audio demos touch.

## Purpose

Godot's AudioBus system lets you route audio through effect chains — like a hardware mixing board. This demo creates four buses at runtime (Dry, Reverb, Echo, Compressed) and shows how the same sound source sounds completely different when routed through each one.

## Controls

- **Space**: Play tone on current bus
- **Left / Right arrows or Enter**: Switch bus

## Buses

| Bus | Effect | Description |
|-----|--------|-------------|
| Dry | None | Direct signal |
| Reverb | AudioEffectReverb | Large room simulation |
| Echo | AudioEffectDelay (×2) | Tap 1 at 300ms, tap 2 at 600ms |
| Compressed | AudioEffectCompressor | Threshold −24dB, ratio 6:1 |

## How It Works

### Creating buses at runtime (`scripts/main.gd`)

```gdscript
AudioServer.add_bus()
var idx := AudioServer.bus_count - 1
AudioServer.set_bus_name(idx, "Reverb")
AudioServer.set_bus_send(idx, "Master")
var rev := AudioEffectReverb.new()
rev.room_size = 0.85
rev.wet = 0.65
AudioServer.add_bus_effect(idx, rev)
```

Buses are created programmatically at `_ready()` — no project AudioBus configuration needed. `set_bus_send(idx, "Master")` routes the bus output to the Master bus (and then to speakers).

### Switching buses

```gdscript
_player.bus = BUSES[_current_bus]
```

`AudioStreamPlayer.bus` takes the bus name as a string. Changing it mid-session routes all subsequent playback through the new chain.

### Echo tap structure

```gdscript
var delay := AudioEffectDelay.new()
delay.tap1_active   = true
delay.tap1_delay_ms = 300.0
delay.tap1_level_db = -6.0
delay.tap2_active   = true
delay.tap2_delay_ms = 600.0
delay.tap2_level_db = -12.0
```

Two taps create a repeating echo that diminishes by 6dB per repeat — the standard slapback pattern.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AudioServer.add_bus()` | Create a new audio bus at runtime |
| `AudioServer.set_bus_send(idx, name)` | Route bus output to another bus |
| `AudioServer.add_bus_effect(idx, effect)` | Append effect to bus chain |
| `AudioEffectReverb / Delay / Compressor` | Built-in DSP effect resources |
| `AudioStreamPlayer.bus` | Route player output to named bus |
