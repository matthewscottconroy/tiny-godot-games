extends Node2D

@onready var connected_label : Label  = $ConnectedLabel
@onready var axis_label      : Label  = $AxisLabel
@onready var button_label    : Label  = $ButtonLabel

const DEADZONE := 0.12

# Godot 4's JoyAxis/JoyButton are native enums, not Dictionaries — they have no
# find_key()/keys() to turn a value back into its name. Keep an explicit table of
# the inputs this demo reports; iterating it also fixes the display order.
const AXIS_NAMES := {
	JOY_AXIS_LEFT_X:         "JOY_AXIS_LEFT_X",
	JOY_AXIS_LEFT_Y:         "JOY_AXIS_LEFT_Y",
	JOY_AXIS_RIGHT_X:        "JOY_AXIS_RIGHT_X",
	JOY_AXIS_RIGHT_Y:        "JOY_AXIS_RIGHT_Y",
	JOY_AXIS_TRIGGER_LEFT:   "JOY_AXIS_TRIGGER_LEFT",
	JOY_AXIS_TRIGGER_RIGHT:  "JOY_AXIS_TRIGGER_RIGHT",
}

const BUTTON_NAMES := {
	JOY_BUTTON_A:              "A",
	JOY_BUTTON_B:              "B",
	JOY_BUTTON_X:              "X",
	JOY_BUTTON_Y:              "Y",
	JOY_BUTTON_BACK:           "BACK",
	JOY_BUTTON_GUIDE:          "GUIDE",
	JOY_BUTTON_START:          "START",
	JOY_BUTTON_LEFT_STICK:     "LEFT_STICK",
	JOY_BUTTON_RIGHT_STICK:    "RIGHT_STICK",
	JOY_BUTTON_LEFT_SHOULDER:  "LEFT_SHOULDER",
	JOY_BUTTON_RIGHT_SHOULDER: "RIGHT_SHOULDER",
	JOY_BUTTON_DPAD_UP:        "DPAD_UP",
	JOY_BUTTON_DPAD_DOWN:      "DPAD_DOWN",
	JOY_BUTTON_DPAD_LEFT:      "DPAD_LEFT",
	JOY_BUTTON_DPAD_RIGHT:     "DPAD_RIGHT",
}

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection)
	$VibrateBtn.pressed.connect(_vibrate)
	_refresh_devices()

func _on_joy_connection(_device: int, _connected: bool) -> void:
	_refresh_devices()

func _refresh_devices() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		connected_label.text = "No gamepad connected — plug one in"
		connected_label.modulate = Color.TOMATO
	else:
		var names := pads.map(func(id): return "#%d: %s" % [id, Input.get_joy_name(id)])
		connected_label.text = "Connected: " + ", ".join(names)
		connected_label.modulate = Color.SEA_GREEN

func _process(_delta: float) -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		axis_label.text   = ""
		button_label.text = ""
		queue_redraw()
		return

	var id  := pads[0]
	var axes := []
	for ax: JoyAxis in AXIS_NAMES:
		var val := apply_deadzone(Input.get_joy_axis(id, ax))
		axes.append("  %-20s  %.3f" % [AXIS_NAMES[ax], val])
	axis_label.text = "Axes (deadzone %.2f):\n" % DEADZONE + "\n".join(axes)

	var pressed_btns := []
	for b: JoyButton in BUTTON_NAMES:
		if Input.is_joy_button_pressed(id, b):
			pressed_btns.append(BUTTON_NAMES[b])
	button_label.text = "Buttons pressed: " + (", ".join(pressed_btns) if pressed_btns else "(none)")
	queue_redraw()

## Ignore the small readings a stick gives when nobody is touching it.
##
## Analogue sticks rarely rest at exactly zero, so without this the demo
## reports a permanent drift and anything driven by it creeps across the
## screen on its own.
func apply_deadzone(raw: float) -> float:
	return 0.0 if absf(raw) < DEADZONE else raw

func _vibrate() -> void:
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		Input.start_joy_vibration(pads[0], 0.6, 0.6, 0.5)

func _draw() -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var id := Input.get_connected_joypads()[0]
	# Left stick circle
	_draw_stick(Vector2(180, 380), id, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, "L")
	# Right stick circle
	_draw_stick(Vector2(460, 380), id, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, "R")
	# Triggers
	_draw_trigger(Vector2(80, 320), id, JOY_AXIS_TRIGGER_LEFT, "LT")
	_draw_trigger(Vector2(560, 320), id, JOY_AXIS_TRIGGER_RIGHT, "RT")

func _draw_stick(center: Vector2, id: int, ax_x: int, ax_y: int, label: String) -> void:
	draw_circle(center, 40, Color(0.2, 0.2, 0.2))
	draw_arc(center, 40, 0, TAU, 32, Color(0.5, 0.5, 0.5), 2)
	var raw := Vector2(Input.get_joy_axis(id, ax_x), Input.get_joy_axis(id, ax_y))
	var val := Vector2.ZERO if raw.length() < DEADZONE else raw
	draw_circle(center + val * 30, 10, Color.CORNFLOWER_BLUE)
	draw_string(ThemeDB.fallback_font, center + Vector2(-6, 6), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _draw_trigger(pos: Vector2, id: int, ax: int, label: String) -> void:
	var val := maxf(Input.get_joy_axis(id, ax), 0.0)
	draw_rect(Rect2(pos, Vector2(30, 60)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(pos + Vector2(0, 60 * (1.0 - val)), Vector2(30, 60 * val)), Color.GOLD)
	draw_rect(Rect2(pos, Vector2(30, 60)), Color(0.6, 0.6, 0.6), false, 2)
	draw_string(ThemeDB.fallback_font, pos + Vector2(2, -6), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
