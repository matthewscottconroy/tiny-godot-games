extends Node

@onready var _subviewport: SubViewport = $PixelContainer/PixelViewport
@onready var _container: SubViewportContainer = $PixelContainer

var _pixel_mode: bool = true

func _ready() -> void:
	_apply_pixel_mode()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		_pixel_mode = !_pixel_mode
		_apply_pixel_mode()

func _apply_pixel_mode() -> void:
	if _pixel_mode:
		_subviewport.size = Vector2i(160, 120)
		_container.stretch = true
	else:
		_subviewport.size = Vector2i(640, 480)
		_container.stretch = true
