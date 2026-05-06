# Dialogue Tree

A branching NPC conversation system driven by a Dictionary-based graph: nodes carry speaker text and a list of player choices, choices carry conditions that filter them based on game state and effects that mutate it when selected.

## Purpose

Dialogue systems appear in every RPG, adventure game, visual novel, and narrative-driven platformer. The fundamental problem is representing a directed graph of conversation states, with branching controlled by what the player has done in the world. This demo shows the minimal viable version: a flat Dictionary of named nodes where each choice points to another node by string key. No external dialogue editor, no binary file format — just GDScript data that is easy to read and modify.

The pattern here scales directly to production: tools like Yarn Spinner and Dialogic compile to a similar node-and-choice structure. Understanding the raw version makes those tools transparent. The condition and effect system — side-channel state flags that gate choices and mutate the world — is the mechanism that makes dialogue feel reactive to player actions rather than always presenting the same options.

## How It Works

### Node Structure

```gdscript
"sword_intro": {
    "speaker": "Old Merchant",
    "text": "Ah, the Blade of Embers! ...",
    "choices": [
        {"text": "I'll pay 5 gold.",    "condition": "gold_gte_5", "target": "buy_info"},
        {"text": "I don't have gold.",  "condition": "",           "target": "no_gold"},
        {"text": "Goodbye.",            "condition": "",           "target": "goodbye_cold"},
    ]
}
```

`target: "_close"` is the sentinel that closes the dialogue box. An empty `choices` array marks a dead-end node — pressing Space/Enter closes automatically.

### Condition Filtering

```gdscript
func _get_available_choices() -> Array:
    for choice in choices:
        var cond: String = choice.get("condition", "")
        if cond == "":
            result.append(choice)
        elif cond == "gold_gte_5":
            if _game_state.get("gold", 0) >= 5:
                result.append(choice)
        elif _game_state.get(cond, false):
            result.append(choice)
    return result
```

Condition strings are evaluated at display time, so the available choices automatically reflect the current world state. `gold_gte_5` is a special case for the numeric comparison; all other conditions are simple boolean flag lookups in `_game_state`.

### State Mutation (Effects)

```gdscript
func _apply_effect(effect_name: String) -> void:
    match effect_name:
        "spend_gold":  _game_state.gold = max(0, _game_state.gold - 5)
        "set_talked":  _game_state.talked_before = true
        "give_sword":  _game_state.has_sword = true
```

Effects fire when the player confirms a choice. They are the mechanism for linking dialogue to the wider game: spending resources, flagging events, granting items. The `talked_before` flag switches the NPC's greeting node from `"start"` to `"start_again"` on the next visit.

### Traversal

```gdscript
var chosen = choices[num_key]
var effect: String = chosen.get("effect", "")
if effect != "":
    _apply_effect(effect)
var target: String = chosen.get("target", "_close")
if target == "_close":
    _active = false
else:
    _current_node = target
queue_redraw()
```

State is just `_current_node: String`. Advancing the dialogue is a single assignment.

## Condition and Effect Design

**Conditions as strings** are simple and human-readable but require manual dispatch code. For larger projects, replace the `if/elif` chain with a callable: store `"condition": func(): return _game_state.gold >= 5` directly in the choice Dictionary — GDScript supports first-class callables.

**Effects as strings** have the same tradeoff. The `match` block stays readable up to about 10–15 effects. Beyond that, store a `Callable` in the choice Dictionary: `"effect": func(): _game_state.gold -= 5`.

**Re-entrant nodes** — `"start_again"` is a separate node for the repeat-visit greeting. The alternative is a single `"start"` node with a conditional choice that redirects, but separate nodes are easier to read and edit.

## How to Adapt This in Your Project

- **Multiple NPCs**: Give each NPC its own `_dialogue` Dictionary. The same `_current_node` / `_active` / `_get_available_choices()` logic works unchanged — just swap which Dictionary is in use when `_open_dialogue()` is called.
- **Shared game state**: Replace the local `_game_state` Dictionary with an Autoload singleton (`GameState.has_sword`, `GameState.gold`) so all NPCs and systems read the same flags.
- **Voice acting / audio**: Add an `"audio_key": String` field to each node and play the corresponding `AudioStreamPlayer` when the node is entered.
- **Localization**: Store `"text_key": "MERCHANT_SWORD_INTRO"` instead of raw text, then call `tr(node["text_key"])` when rendering to the dialogue panel.
- **Ink / Yarn import**: The Dictionary format here maps cleanly onto Yarn Spinner's node/option model. An importer just needs to populate the same structure from a `.yarn` file.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Dictionary.get(key, default)` | Safe field access with fallback |
| `InputEventKey.keycode - KEY_1` | Convert 1–4 keypresses to 0-based choice index |
| `String.split(" ")` | Word-wrap implementation for dialogue text |
| `Vector2.distance_to(other)` | Proximity check for interaction trigger |
| `queue_redraw()` | Request a `_draw()` call after state change |

## Controls

| Key / Input | Action |
|-------------|--------|
| WASD | Move the player |
| E | Open dialogue when within 100 px of the NPC |
| 1 – 4 | Select the numbered dialogue choice |
| Space / Enter | Close dialogue at a dead-end node |
| Escape | Close dialogue immediately |

## Key Constants / Data

```gdscript
const INTERACT_RANGE := 100.0   # px from player to NPC center

# Game state flags (shown in HUD):
# gold: int         — spent on information ("spend_gold" effect)
# has_sword: bool   — unlocks "show_sword" branch
# talked_before: bool — switches entry node to "start_again"

# Dialogue entry nodes: "start" (first visit), "start_again" (repeat visits)
# Terminal sentinel: target == "_close"
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Dialogue graph, condition filtering, effect application, rendering |
| `tests/test_logic.gd` | Unit tests for condition evaluation and effect side effects |
| `scenes/main.tscn` | Scene root (Node2D with script) |
| `tests/test.tscn` | Test runner scene |
