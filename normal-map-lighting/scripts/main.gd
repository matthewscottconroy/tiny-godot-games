extends Node2D

@onready var _rect: ColorRect = $Surface
@onready var _label: Label = $Label

func _ready() -> void:
	_label.text = "Move mouse to orbit light\nR — reset light to center"

func _process(_delta: float) -> void:
	aim_light(get_viewport().get_mouse_position())

## Point the light at a spot on screen, in the shader's own 0..1 coordinates.
##
## The shader works in UV space, so the cursor has to be divided by the
## viewport size — handing it raw pixels puts the light hundreds of units off
## the surface, where it lights nothing.
func aim_light(screen_pos: Vector2) -> void:
	var size := get_viewport_rect().size
	if not is_aimable(size):
		return
	_rect.material.set_shader_parameter("light_uv", screen_pos / size)

## Is there a viewport to divide by?
##
## Either dimension being zero is enough to refuse: the aim divides by both, so
## a window one pixel wide still divides by zero on the other axis and puts the
## light at infinity. Separated from aim_light() because a window cannot
## actually be resized to zero — Godot clamps it — so the guard is unreachable
## from the outside and can only be asked directly.
static func is_aimable(size: Vector2) -> bool:
	return size.x > 0.0 and size.y > 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_rect.material.set_shader_parameter("light_uv", Vector2(0.5, 0.5))
