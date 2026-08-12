extends Node2D

# Demo driver. Shows three saves written by older versions of an imaginary game
# being upgraded to the current format, step by step.

@onready var _log_label: Label = $HUD/LogLabel
@onready var _hint_label: Label = $HUD/HintLabel

const CURRENT_VERSION := 3

var _migrator: SaveMigrator
var _sample := 0
var _lines: Array[String] = []

# Saves as they were written by each historical version of the game.
const SAMPLES := [
	{
		"label": "v0 — before anyone added a version field",
		"data": {"name": "Hero", "hp": 80, "x": 100.0, "y": 240.0, "gold": 15},
	},
	{
		"label": "v1 — position split into two floats, flat inventory",
		"data": {"version": 1, "name": "Hero", "hp": 80, "x": 100.0, "y": 240.0,
			"gold": 15, "items": ["sword", "potion", "potion"]},
	},
	{
		"label": "v2 — position packed, inventory still flat",
		"data": {"version": 2, "name": "Hero", "hp": 80, "pos": {"x": 100.0, "y": 240.0},
			"gold": 15, "items": ["sword", "potion", "potion"]},
	},
	{
		"label": "v4 — from a NEWER build than this one",
		"data": {"version": 4, "name": "Hero", "hp": 80},
	},
]

func _ready() -> void:
	_migrator = SaveMigrator.new(CURRENT_VERSION)

	# 0 -> 1: give the save a version and the inventory it never had.
	_migrator.add_step(0, func(d: Dictionary) -> Dictionary:
		d["items"] = d.get("items", [])
		return d)

	# 1 -> 2: pack the loose x/y into a single position dictionary.
	_migrator.add_step(1, func(d: Dictionary) -> Dictionary:
		d["pos"] = {"x": d.get("x", 0.0), "y": d.get("y", 0.0)}
		d.erase("x")
		d.erase("y")
		return d)

	# 2 -> 3: inventory becomes stacks instead of repeated entries.
	_migrator.add_step(2, func(d: Dictionary) -> Dictionary:
		var stacks: Dictionary = {}
		for item in d.get("items", []):
			stacks[item] = int(stacks.get(item, 0)) + 1
		d["inventory"] = stacks
		d.erase("items")
		return d)

	_show(0)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_SPACE or key.keycode == KEY_RIGHT:
		_show((_sample + 1) % SAMPLES.size())
	elif key.keycode == KEY_LEFT:
		_show((_sample - 1 + SAMPLES.size()) % SAMPLES.size())

func _show(index: int) -> void:
	_sample = index
	var sample: Dictionary = SAMPLES[index]
	var before: Dictionary = sample["data"]
	var result := _migrator.migrate(before)

	_lines = []
	_lines.append("Sample %d/%d — %s" % [index + 1, SAMPLES.size(), sample["label"]])
	_lines.append("")
	_lines.append("before:  " + _brief(before))
	_lines.append("")
	if result["ok"]:
		var applied := "none — already current" if result["steps"].is_empty() \
			else ", ".join(result["steps"])
		_lines.append("steps:   " + applied)
		_lines.append("after:   " + _brief(result["data"]))
	else:
		_lines.append("REFUSED: " + str(result["error"]))
		_lines.append("")
		_lines.append("The save is left untouched. Refusing beats writing back")
		_lines.append("something plausible over the player's data.")
	_log_label.text = "\n".join(_lines)
	_hint_label.text = "← / → / Space to cycle samples    (current format: v%d)" % CURRENT_VERSION
	queue_redraw()

func _brief(d: Dictionary) -> String:
	var keys := d.keys()
	keys.sort()
	var parts: Array[String] = []
	for k in keys:
		parts.append("%s=%s" % [k, d[k]])
	return "{" + ", ".join(parts) + "}"

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	# A version timeline with the current build marked.
	for v in 5:
		var x := 90.0 + v * 110.0
		var is_current := v == CURRENT_VERSION
		var col := Color(0.35, 0.75, 0.45) if v <= CURRENT_VERSION else Color(0.5, 0.3, 0.3)
		draw_circle(Vector2(x, 120), 14.0 if is_current else 10.0, col)
		if v < 4:
			draw_line(Vector2(x + 16, 120), Vector2(x + 94, 120), col.darkened(0.3), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(x - 8, 156), "v%d" % v,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
