extends Node2D

# Actions to remap (must exist in the default InputMap)
const ACTIONS := ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept"]
const DEFAULTS := {
	"ui_left":   KEY_LEFT,
	"ui_right":  KEY_RIGHT,
	"ui_up":     KEY_UP,
	"ui_down":   KEY_DOWN,
	"ui_accept": KEY_SPACE,
}

var _listening_for : String = ""
var _rows          : Dictionary = {}
var _player_pos    := Vector2(320, 430)

@onready var container : VBoxContainer = $BindingContainer

func _ready() -> void:
	$ResetBtn.pressed.connect(_reset_all)
	for action in ACTIONS:
		_build_row(action)
	_refresh_all()

func _build_row(action: String) -> void:
	var row := HBoxContainer.new()
	row.theme_override_constants = {"separation": 12}

	var name_lbl := Label.new()
	name_lbl.custom_minimum_size = Vector2(120, 0)
	name_lbl.text = action
	name_lbl.add_theme_font_size_override("font_size", 15)

	var key_btn := Button.new()
	key_btn.custom_minimum_size = Vector2(200, 0)
	key_btn.pressed.connect(func(): _start_listen(action))

	row.add_child(name_lbl)
	row.add_child(key_btn)
	container.add_child(row)
	_rows[action] = key_btn

func _start_listen(action: String) -> void:
	_listening_for = action
	_rows[action].text = "[ press a key… ]"
	_rows[action].modulate = Color.GOLD

func _unhandled_input(event: InputEvent) -> void:
	if _listening_for.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_remap(_listening_for, event.keycode)
		_listening_for = ""

func _remap(action: String, keycode: Key) -> void:
	InputMap.action_erase_events(action)
	var ev        := InputEventKey.new()
	ev.keycode     = keycode
	InputMap.action_add_event(action, ev)
	_refresh_all()

func _reset_all() -> void:
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		var ev    := InputEventKey.new()
		ev.keycode = DEFAULTS[action]
		InputMap.action_add_event(action, ev)
	_listening_for = ""
	_refresh_all()

func _refresh_all() -> void:
	for action in ACTIONS:
		if action == _listening_for:
			continue
		var events := InputMap.action_get_events(action)
		var names  := events.map(func(e): return e.as_text() if e is InputEventKey else str(e))
		_rows[action].text     = ", ".join(names)
		_rows[action].modulate = Color.WHITE

func _process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_player_pos += dir * 120 * delta
	_player_pos  = _player_pos.clamp(Vector2(20, 400), Vector2(620, 470))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(_player_pos - Vector2(16, 16), Vector2(32, 32)), Color.CORNFLOWER_BLUE)
	draw_string(ThemeDB.fallback_font, Vector2(8, 478),
		"ui_accept = %s" % (InputMap.action_get_events("ui_accept").map(
			func(e): return e.as_text())),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.5))
