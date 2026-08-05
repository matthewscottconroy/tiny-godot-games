extends Node2D

@onready var _rect: ColorRect = $Surface
@onready var _label: Label = $Label

func _ready() -> void:
	_label.text = "Move mouse to orbit light\nR — reset light to center"

func _process(_delta: float) -> void:
	var vp := get_viewport_rect().size
	var m := get_viewport().get_mouse_position()
	var uv := m / vp
	_rect.material.set_shader_parameter("light_uv", uv)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_rect.material.set_shader_parameter("light_uv", Vector2(0.5, 0.5))
