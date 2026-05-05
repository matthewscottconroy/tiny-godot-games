# Drop Table

Weighted random loot selection: each enemy has a table of items with relative weights. Rolling the table picks one item proportionally. Kill enemies and watch observed drop rates converge on the expected probabilities.

## Purpose

Random loot needs weighted probabilities — a legendary item should be rare, coins should be common, and "nothing" should be possible. A naïve approach using `randi() % 100 < 5` for each item breaks down when you have many items with overlapping ranges. The weighted selection algorithm solves this cleanly: sum all weights, pick a random number in that range, then scan until the accumulator crosses it.

## Controls

- **Left Arrow**: Kill the Goblin
- **Up Arrow**: Kill the Orc
- **Right Arrow**: Kill the Boss
- Watch the stats panel fill in as you kill more enemies

## How It Works

### `scripts/drop_table.gd`

```gdscript
class_name DropTable
extends RefCounted

func roll() -> String:
    var total := 0.0
    for e in _entries:
        total += e["weight"]
    var r := randf() * total          # random point in [0, total)
    var acc := 0.0
    for e in _entries:
        acc += e["weight"]
        if r <= acc:
            return e["item"]          # r landed in this entry's range
    return _entries[-1]["item"]       # floating-point fallback
```

**Visual example with Goblin table:**
```
Nothing (40) | Coin (35) | Arrow (15) | Health Orb (10)
0            40          75           90               100
                  r=62 → Coin
```
A random float in `[0, 100)` is generated. If it falls in `[0, 40)` → Nothing, `[40, 75)` → Coin, etc.

**Fluent builder:**
```gdscript
var goblin := DropTable.new()
goblin.add("Nothing", 40).add("Coin", 35).add("Arrow", 15).add("Health Orb", 10)
```
`add()` returns `self`, enabling method chaining to build the table in one expression.

### `get_chances()` for visualization

```gdscript
func get_chances() -> Dictionary:
    var total := 0.0
    for e in _entries:
        total += e["weight"]
    var out := {}
    for e in _entries:
        out[e["item"]] = e["weight"] / total
    return out
```
Dividing each weight by the total gives the true probability. The demo uses this to draw the weight bars under each enemy, and the stats label compares observed vs expected rates.

### Convergence

With few kills, observed rates jump around. With many kills, they converge on the expected rates. This is the **law of large numbers** — the demo makes it visible. After ~100 kills you'll see the observed Goblin coin rate stabilize near 35%.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `randf()` | Random float in [0, 1) |
| `RefCounted` | Base class for pure-logic objects that aren't nodes |
| `Array.filter(callable)` | Filter array by predicate |
| `Dictionary.get(key, default)` | Safe dictionary access with fallback |
