extends Area2D

@export var min_dmg  := 10
@export var max_dmg  := 40
@export var body_col := Color.TOMATO

var _hp     := 100
var _max_hp := 100
var _rng    := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_max_hp = _rng.randi_range(80, 180)
	_hp     = _max_hp
	input_pickable = true
	input_event.connect(_on_click)

func _draw() -> void:
	var ratio  := float(_hp) / float(_max_hp)
	var col    := body_col.darkened(1.0 - ratio)
	draw_circle(Vector2.ZERO, 32, col)
	draw_arc(Vector2.ZERO, 32, 0, TAU, 32, body_col.lightened(0.3), 2.0)
	draw_rect(Rect2(-26, 38, 52, 7), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-26, 38, 52.0 * ratio, 7), Color.LIME_GREEN)

func _on_click(_viewport: Viewport, event: InputEvent, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var dmg := _rng.randi_range(min_dmg, max_dmg)
		_hp     = max(_hp - dmg, 0)
		var offset := Vector2(_rng.randf_range(-20, 20), -44)
		var col := Color.ORANGE_RED if dmg < 25 else Color.RED
		FloatingText.spawn(get_parent(), global_position + offset, "-%d" % dmg, col)
		if _hp == 0:
			_hp = _max_hp
			FloatingText.spawn(get_parent(), global_position + Vector2(0, -20), "REVIVED!", Color.CYAN)
		queue_redraw()
