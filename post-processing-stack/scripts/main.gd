extends Node2D

var _time := 0.0
var _vignette := true
var _chroma := true
var _grade := true

@onready var _overlay: ColorRect = $PostProcess
@onready var _label: Label = $Label

func _ready() -> void:
	_update_label()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.06, 0.06, 0.10))

	# Animated circles
	for i in range(12):
		var angle := _time * (0.4 + i * 0.07) + i * TAU / 12.0
		var r := 120.0 + sin(_time * 0.6 + i) * 40.0
		var cx := 320.0 + cos(angle) * r
		var cy := 240.0 + sin(angle) * r * 0.6
		var hue := fmod(float(i) / 12.0 + _time * 0.1, 1.0)
		draw_circle(Vector2(cx, cy), 18.0 + sin(_time + i) * 4.0,
			Color.from_hsv(hue, 0.7, 0.9))

	# Grid lines
	for x in range(0, 641, 80):
		draw_line(Vector2(x, 0), Vector2(x, 480), Color(1, 1, 1, 0.06), 1.0)
	for y in range(0, 481, 60):
		draw_line(Vector2(0, y), Vector2(640, y), Color(1, 1, 1, 0.06), 1.0)

	# Moving rect
	var rx := 280.0 + sin(_time * 0.5) * 200.0
	draw_rect(Rect2(rx, 200, 80, 80), Color(0.9, 0.8, 0.3, 0.7), false, 2.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_vignette = not _vignette
				_overlay.material.set_shader_parameter("vignette_on", _vignette)
			KEY_2:
				_chroma = not _chroma
				_overlay.material.set_shader_parameter("chromatic_on", _chroma)
			KEY_3:
				_grade = not _grade
				_overlay.material.set_shader_parameter("grade_on", _grade)
		_update_label()

func _update_label() -> void:
	_label.text = "[1] Vignette: %s   [2] Chromatic: %s   [3] Color Grade: %s" % [
		"ON" if _vignette else "OFF",
		"ON" if _chroma else "OFF",
		"ON" if _grade else "OFF"
	]
