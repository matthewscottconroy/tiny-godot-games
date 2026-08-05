# L-System

A minimal Godot 4.2 demo showing Lindenmayer systems: string-rewriting rules that generate fractal geometry via turtle graphics.

## Controls

| Key | Action |
|-----|--------|
| Space | Cycle to next preset |

## Presets

| Name | Axiom | Key Rule | Result |
|------|-------|----------|--------|
| Fractal Tree | `X` | `X → F+[[X]-X]-F[-FX]+X` | Branching tree |
| Fern | `X` | `X → +F-[[X]-X]-F[-FX]+X` | Asymmetric fern frond |
| Koch Snowflake | `F--F--F` | `F → F+F--F+F` | Triangular fractal curve |

## How It Works

### String Expansion

Starting from an axiom, each character is replaced by its rule string. Characters with no rule pass through unchanged.

```gdscript
func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
    var s := axiom
    for _i in iters:
        var next := ""
        for c in s:
            next += rules.get(c, c)
        s = next
    return s
```

After `n` iterations the string length grows exponentially — tree preset at 5 iterations produces ~60,000 characters.

### Turtle Interpretation

The expanded string drives a turtle (position + heading):

| Symbol | Action |
|--------|--------|
| `F` | Move forward, draw line |
| `f` | Move forward, no draw |
| `+` | Turn left by `angle` |
| `-` | Turn right by `angle` |
| `[` | Push position and heading |
| `]` | Pop position and heading |
| `X`, `Y` | No-op (structural placeholders) |

The `[` / `]` push/pop mechanism is what creates branching structures.

## Key Parameters

```gdscript
# Fractal Tree preset
"angle": 25.0    # degrees per + or - symbol
"iters": 5       # expansion iterations
"length": 3.0    # pixels per F segment
```

## Project Structure

```
l-system/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # expansion + turtle + _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
