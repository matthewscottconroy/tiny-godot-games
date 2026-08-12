extends Node2D

@onready var _flash_rect: ColorRect = $CanvasLayer/FlashRect

func _ready() -> void:
	_flash_rect.color = Color.TRANSPARENT
	for zone in get_tree().get_nodes_in_group("hazard"):
		zone.body_entered.connect(_on_hazard_entered.bind(zone))

func _on_hazard_entered(body: Node2D, _zone: Area2D) -> void:
	if body.is_in_group("player"):
		flash(Color(1.0, 0.1, 0.1, 0.65), 0.35)

# One event per physical press (echo filtered), so each key triggers one flash.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: flash(Color(1.0, 0.1, 0.1, 0.65), 0.35)   # damage — red
		KEY_2: flash(Color(1.0, 0.9, 0.1, 0.70), 0.25)   # pickup — yellow
		KEY_3: flash(Color(0.2, 0.6, 1.0, 0.55), 0.40)   # transition — blue
		KEY_4: flash(Color(1.0, 1.0, 1.0, 0.90), 0.45)   # respawn — white

func flash(color: Color, duration: float) -> void:
	_flash_rect.color = color
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	# Floor
	draw_rect(Rect2(0, 442, 640, 25), Color(0.30, 0.30, 0.35))
	# Platforms
	draw_rect(Rect2(100, 340, 140, 12), Color(0.40, 0.28, 0.16))
	draw_rect(Rect2(400, 260, 140, 12), Color(0.40, 0.28, 0.16))
	# Hazard zone — red tinted box
	draw_rect(Rect2(270, 390, 100, 52), Color(1.0, 0.25, 0.25, 0.3))
	draw_rect(Rect2(270, 390, 100, 52), Color(1.0, 0.25, 0.25, 0.9), false, 2.0)
