extends Node2D

@onready var player_light  : PointLight2D = $Player/PlayerLight
@onready var torch_light   : PointLight2D = $TorchLight
@onready var ambient_label : Label        = $HUD/AmbientLabel

## The blocks the lights fall on. Drawn from this list and cut out of the light
## from it too, so the shadow always matches what is on screen.
const WALLS: Array[Rect2] = [
	Rect2(40, 120, 120, 80),
	Rect2(480, 80, 100, 120),
	Rect2(220, 160, 80, 160),
]

func _ready() -> void:
	_build_occluders()
	var tex := _make_light_tex(100)
	player_light.texture = tex
	torch_light.texture  = _make_light_tex(140)

	$HUD/ToggleTorchBtn.pressed.connect(func():
		torch_light.enabled = not torch_light.enabled)
	$HUD/ColorBtn.pressed.connect(func():
		player_light.color = Color(randf(), randf(), randf()))
	$HUD/AmbientSlider.value_changed.connect(func(v: float):
		$CanvasModulate.color = Color(v, v, v * 1.1)
		ambient_label.text = "Ambient: %.0f%%" % (v * 100))

## Give every wall an occluder, so the lights throw shadows past them.
##
## A PointLight2D only casts a shadow where a LightOccluder2D blocks it, and
## only when the light has shadows switched on — without both halves the walls
## are lit as if they were paint on the floor.
func _build_occluders() -> void:
	player_light.shadow_enabled = true
	torch_light.shadow_enabled = true
	for wall in WALLS:
		var occluder := LightOccluder2D.new()
		var polygon := OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([
			wall.position,
			Vector2(wall.end.x, wall.position.y),
			wall.end,
			Vector2(wall.position.x, wall.end.y),
		])
		occluder.occluder = polygon
		add_child(occluder)

func _make_light_tex(radius: int) -> ImageTexture:
	var img := Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	for x in radius * 2:
		for y in radius * 2:
			var d := Vector2(x - radius, y - radius).length()
			var a := pow(maxf(1.0 - d / radius, 0.0), 1.8)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)

func _draw() -> void:
	for wall in WALLS:
		draw_rect(wall, Color(0.25, 0.22, 0.2))
	draw_rect(Rect2(0, 440, 640, 40), Color(0.2, 0.18, 0.15))
