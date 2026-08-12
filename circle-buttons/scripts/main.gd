extends Control

@onready var _display:      CircleDisplay = $VBox/CircleDisplay
@onready var _result_label: Label         = $VBox/ResultLabel
@onready var _preset_label: Label         = $VBox/PresetLabel

# Three presets demonstrating different counts, sizes, and colors.
const PRESETS: Array = [
	[
		{"label": "A", "color": Color.TOMATO,            "radius": 52.0},
		{"label": "B", "color": Color.CORNFLOWER_BLUE,   "radius": 52.0},
		{"label": "C", "color": Color.MEDIUM_SEA_GREEN,  "radius": 52.0},
	],
	[
		{"label": "1", "color": Color.GOLD,     "radius": 38.0},
		{"label": "2", "color": Color.ORCHID,   "radius": 48.0},
		{"label": "3", "color": Color.SALMON,   "radius": 32.0},
		{"label": "4", "color": Color.AQUA,     "radius": 56.0},
		{"label": "5", "color": Color.LIME,     "radius": 42.0},
	],
	[
		{"color": Color.RED,     "radius": 20.0},
		{"color": Color.ORANGE,  "radius": 20.0},
		{"color": Color.YELLOW,  "radius": 20.0},
		{"color": Color.GREEN,   "radius": 20.0},
		{"color": Color.CYAN,    "radius": 20.0},
		{"color": Color.BLUE,    "radius": 20.0},
		{"color": Color.MAGENTA, "radius": 20.0},
		{"color": Color.WHITE,   "radius": 20.0},
	],
]

var _preset_idx := 0

func _ready() -> void:
	_display.circle_clicked.connect(_on_circle_clicked)
	_load_preset(0)

# Called whenever a circle is clicked.
# index is its position in the array passed to configure(); data is a copy of its spec.
func _on_circle_clicked(index: int, data: Dictionary) -> void:
	_result_label.text = (
		"index: %d   label: \"%s\"   radius: %.0f   color: #%s" % [
			index,
			data.get("label", ""),
			data.get("radius", 0.0),
			(data.get("color", Color.WHITE) as Color).to_html(false),
		]
	)

# Key presses arrive as events. _unhandled_key_input only fires for key events the
# UI did not already consume, and each physical press delivers exactly one
# `pressed and not echo` event — the "just pressed" edge, without polling.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_RIGHT, KEY_SPACE:
			_load_preset((_preset_idx + 1) % PRESETS.size())
		KEY_LEFT:
			_load_preset((_preset_idx - 1 + PRESETS.size()) % PRESETS.size())

func _load_preset(idx: int) -> void:
	_preset_idx = idx
	# This is the external "input" call — pass any array of specs at runtime
	_display.configure(PRESETS[idx])
	_preset_label.text = "Preset %d / %d  —  %d circle(s)" % [
		idx + 1, PRESETS.size(), PRESETS[idx].size()
	]
	_result_label.text = "Click a circle…"
