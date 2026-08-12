extends Node2D

@onready var _player:      CharacterBody2D = $Player
@onready var _fps_label:   Label = $CanvasLayer/Panel/VBox/FPSLabel
@onready var _pos_label:   Label = $CanvasLayer/Panel/VBox/PosLabel
@onready var _vel_label:   Label = $CanvasLayer/Panel/VBox/VelLabel
@onready var _floor_label: Label = $CanvasLayer/Panel/VBox/FloorLabel
@onready var _state_label: Label = $CanvasLayer/Panel/VBox/StateLabel
@onready var _panel:       Control = $CanvasLayer/Panel

var _overlay_visible := true

# Toggling belongs in an event handler, not a poll: one event per physical press.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_F3 or key.keycode == KEY_QUOTELEFT:
		_overlay_visible = !_overlay_visible
		_panel.visible = _overlay_visible

func _process(_delta: float) -> void:
	if _overlay_visible:
		_fps_label.text   = "FPS:     %d"             % Engine.get_frames_per_second()
		_pos_label.text   = "Pos:     (%.0f, %.0f)"   % [_player.global_position.x, _player.global_position.y]
		_vel_label.text   = "Vel:     (%.0f, %.0f)"   % [_player.velocity.x, _player.velocity.y]
		_floor_label.text = "OnFloor: %s"             % str(_player.is_on_floor())
		_state_label.text = "State:   %s"             % _player.state

func _draw() -> void:
	draw_rect(Rect2(0, 442, 640, 25),    Color(0.30, 0.30, 0.35))
	draw_rect(Rect2(80,  300, 160, 14),  Color(0.40, 0.28, 0.16))
	draw_rect(Rect2(380, 220, 160, 14),  Color(0.40, 0.28, 0.16))
