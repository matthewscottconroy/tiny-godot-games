extends Node2D

const STRENGTHS := [0.0, 0.015, 0.04, 0.08]
const LABELS    := ["Off", "Subtle", "Moderate", "Heavy"]

var _strength_idx := 1

@onready var _mat:         ShaderMaterial = $SubViewportContainer.material
@onready var _player:      CharacterBody2D = $SubViewportContainer/SubViewport/Player
@onready var _str_label:   Label = $CanvasLayer/StrLabel

func _ready() -> void:
	_apply_strength()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right"):
		_strength_idx = (_strength_idx + 1) % STRENGTHS.size()
		_apply_strength()
	elif event.is_action_pressed("ui_left"):
		_strength_idx = (_strength_idx - 1 + STRENGTHS.size()) % STRENGTHS.size()
		_apply_strength()

func _apply_strength() -> void:
	_mat.set_shader_parameter("strength", STRENGTHS[_strength_idx])
	_str_label.text = "Distortion: %s  (Left/Right to change)" % LABELS[_strength_idx]
