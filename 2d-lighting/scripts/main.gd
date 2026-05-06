extends Node2D

@onready var _player_light: PointLight2D = $PlayerLight
@onready var _canvas_mod: CanvasModulate = $CanvasModulate

var _player_pos: Vector2 = Vector2(320, 240)
const SPEED := 160.0
var _lights_on: bool = true

func _make_light_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = [Color.WHITE, Color(1, 1, 1, 0)]
	g.offsets = [0.0, 1.0]
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	return gt

func _ready() -> void:
	var tex := _make_light_texture()
	_player_light.texture = tex
	for child in get_children():
		if child is PointLight2D and child != _player_light:
			child.texture = tex

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_L:
				_lights_on = !_lights_on
				if _lights_on:
					_canvas_mod.color = Color(0.15, 0.15, 0.15)
				else:
					_canvas_mod.color = Color.WHITE
			KEY_EQUAL, KEY_PLUS:
				_player_light.texture_scale = _player_light.texture_scale + 0.2
			KEY_MINUS:
				_player_light.texture_scale = max(0.2, _player_light.texture_scale - 0.2)

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
	_player_pos += direction * SPEED * delta
	_player_pos.x = clamp(_player_pos.x, 0.0, 640.0)
	_player_pos.y = clamp(_player_pos.y, 0.0, 480.0)
	_player_light.position = _player_pos
	queue_redraw()

func _draw() -> void:
	# Dark floor background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.12, 0.1, 0.08))

	# Wall obstacles
	draw_rect(Rect2(60, 60, 120, 24), Color(0.4, 0.3, 0.2))
	draw_rect(Rect2(400, 80, 24, 100), Color(0.35, 0.28, 0.18))
	draw_rect(Rect2(200, 300, 80, 24), Color(0.4, 0.3, 0.2))
	draw_rect(Rect2(460, 300, 24, 80), Color(0.35, 0.28, 0.18))
	draw_rect(Rect2(100, 380, 60, 24), Color(0.4, 0.3, 0.2))
	draw_rect(Rect2(520, 60, 80, 24), Color(0.4, 0.3, 0.2))

	# Colored static objects (crates / targets)
	draw_rect(Rect2(140, 200, 28, 28), Color(0.6, 0.45, 0.2))
	draw_rect(Rect2(480, 360, 28, 28), Color(0.6, 0.45, 0.2))
	draw_circle(Vector2(540, 240), 14.0, Color(0.7, 0.2, 0.2))
	draw_circle(Vector2(100, 260), 14.0, Color(0.2, 0.6, 0.7))

	# Player circle
	draw_circle(_player_pos, 12.0, Color(1.0, 0.95, 0.8))
	draw_circle(_player_pos, 8.0, Color(1.0, 1.0, 0.7))

	# HUD text
	var font := ThemeDB.fallback_font
	var font_size := 14
	draw_string(font, Vector2(8, 470), "WASD: move   L: toggle lights   +/-: range",
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.9, 0.9, 0.8))
	draw_string(font, Vector2(8, 18), "2D Lighting Demo",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.5))
