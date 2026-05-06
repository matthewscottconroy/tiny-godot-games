extends Control

@onready var _container: SubViewportContainer = $WarpContainer
@onready var _viewport: SubViewport = $WarpContainer/WorldViewport

var _warp_enabled: bool = true
var _warp_strength: float = 0.02
var _warp_speed: float = 2.0
var _time: float = 0.0
var _material: ShaderMaterial

func _ready() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float time = 0.0;
uniform float strength = 0.02;
uniform float speed = 2.0;
void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 20.0 + time * speed) * strength;
    uv.y += cos(uv.x * 20.0 + time * speed * 0.7) * strength;
    COLOR = texture(TEXTURE, uv);
}
"""
	_material = ShaderMaterial.new()
	_material.shader = shader
	_container.material = _material

func _process(delta: float) -> void:
	_time += delta
	_material.set_shader_parameter("time", _time)
	_material.set_shader_parameter("strength", _warp_strength if _warp_enabled else 0.0)
	_material.set_shader_parameter("speed", _warp_speed)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_warp_enabled = !_warp_enabled
			KEY_EQUAL, KEY_PLUS:
				_warp_strength = min(0.15, _warp_strength + 0.005)
			KEY_MINUS:
				_warp_strength = max(0.0, _warp_strength - 0.005)
			KEY_UP:
				_warp_speed = min(10.0, _warp_speed + 0.5)
			KEY_DOWN:
				_warp_speed = max(0.1, _warp_speed - 0.5)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Status bar at bottom
	draw_rect(Rect2(0, 454, 640, 26), Color(0, 0, 0, 0.65))
	var status := "WARP: %s   Strength: %.3f   Speed: %.1f" % [
		"ON" if _warp_enabled else "OFF",
		_warp_strength,
		_warp_speed
	]
	draw_string(font, Vector2(8, 470), status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 1.0, 1.0))

	# Controls hint
	draw_rect(Rect2(0, 430, 640, 24), Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(8, 446), "W: toggle warp   +/-: strength   Up/Down: speed",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8))

	# WARP OFF overlay indicator
	if not _warp_enabled:
		draw_rect(Rect2(240, 200, 160, 40), Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(262, 226), "WARP OFF",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.4, 0.4))
