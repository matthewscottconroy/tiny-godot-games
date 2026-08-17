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

const PIXEL_SHRINK := 4

func _apply_pixel_mode() -> void:
	# A SubViewportContainer with stretch enabled owns its viewport's size:
	# assigning to _subviewport.size is refused, with a warning, and both modes
	# rendered at full resolution. stretch_shrink is the supported control —
	# render at 1/N and scale the result back up, which is the chunky look.
	_container.stretch = true
	_container.stretch_shrink = PIXEL_SHRINK if _pixel_mode else 1
