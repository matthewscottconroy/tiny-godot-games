extends Node2D

const PALETTES := [
	{"name": "Original",  "body": Color(0.12, 0.56, 1.00), "armor": Color(1.00, 0.84, 0.00)},
	{"name": "Crimson",   "body": Color(0.85, 0.12, 0.12), "armor": Color(0.75, 0.75, 0.80)},
	{"name": "Forest",    "body": Color(0.15, 0.65, 0.20), "armor": Color(0.60, 0.38, 0.15)},
	{"name": "Void",      "body": Color(0.50, 0.10, 0.80), "armor": Color(0.90, 0.90, 0.95)},
	{"name": "Lava",      "body": Color(0.90, 0.40, 0.05), "armor": Color(0.20, 0.20, 0.20)},
]

var _palette_idx := 0
var _texture:    ImageTexture

@onready var _sprite:    TextureRect = $CharSprite
@onready var _mat:       ShaderMaterial = $CharSprite.material
@onready var _pal_label: Label = $CanvasLayer/PalLabel

func _ready() -> void:
	_texture = _build_texture()
	_sprite.texture = _texture
	_apply_palette()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right"):
		_palette_idx = (_palette_idx + 1) % PALETTES.size()
		_apply_palette()
	elif event.is_action_pressed("ui_left"):
		_palette_idx = (_palette_idx - 1 + PALETTES.size()) % PALETTES.size()
		_apply_palette()

func _apply_palette() -> void:
	var p: Dictionary = PALETTES[_palette_idx]
	_mat.set_shader_parameter("body_dst",  p["body"])
	_mat.set_shader_parameter("armor_dst", p["armor"])
	_pal_label.text = "Palette: %s (%d/%d)" % [p["name"], _palette_idx + 1, PALETTES.size()]

func _build_texture() -> ImageTexture:
	var img := Image.create(32, 56, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var body_c  := Color(0.12, 0.56, 1.00)
	var armor_c := Color(1.00, 0.84, 0.00)
	var skin_c  := Color(0.90, 0.75, 0.60)
	# Head
	for y in range(0, 16):
		for x in range(8, 24):
			img.set_pixel(x, y, skin_c)
	# Eyes
	for px in [10, 11, 20, 21]:
		img.set_pixel(px, 6, Color.BLACK)
	# Armor collar
	for x in range(8, 24):
		img.set_pixel(x, 16, armor_c)
		img.set_pixel(x, 17, armor_c)
	# Body
	for y in range(18, 46):
		for x in range(8, 24):
			img.set_pixel(x, y, body_c)
	# Belt
	for x in range(8, 24):
		img.set_pixel(x, 34, armor_c)
		img.set_pixel(x, 35, armor_c)
	# Legs
	for y in range(46, 56):
		for x in range(8, 16):
			img.set_pixel(x, y, body_c)
		for x in range(16, 24):
			img.set_pixel(x, y, body_c)
	return ImageTexture.create_from_image(img)
