extends Node2D

@onready var _cam:   Camera2D = $Camera2D
@onready var _label: Label    = $HUD/RoomLabel

func _ready() -> void:
	for room in get_tree().get_nodes_in_group("room"):
		room.player_entered.connect(_on_room_entered)

func _on_room_entered(name: String, target: Vector2) -> void:
	var tw := create_tween()
	tw.tween_property(_cam, "position", target, 0.5).set_ease(Tween.EASE_IN_OUT)
	_label.text = "Room: " + name

func _draw() -> void:
	# Full floor across the 1920-wide world
	draw_rect(Rect2(0, 442, 1920, 25), Color(0.25, 0.25, 0.25))

	# Room dividers (thin vertical lines so rooms are visible)
	draw_line(Vector2(640, 0), Vector2(640, 480), Color(0.4, 0.4, 0.44), 2.0)
	draw_line(Vector2(1280, 0), Vector2(1280, 480), Color(0.4, 0.4, 0.44), 2.0)

	# --- Room 1 platforms (x: 0–640) ---
	draw_rect(Rect2(80,  360, 120, 12), Color(0.35, 0.35, 0.38))
	draw_rect(Rect2(280, 290, 100, 12), Color(0.35, 0.35, 0.38))
	draw_rect(Rect2(480, 220, 120, 12), Color(0.35, 0.35, 0.38))

	# --- Room 2 platforms (x: 640–1280) ---
	draw_rect(Rect2(680, 360, 140, 12), Color(0.38, 0.35, 0.35))
	draw_rect(Rect2(880, 280, 100, 12), Color(0.38, 0.35, 0.35))
	draw_rect(Rect2(1080, 210, 140, 12), Color(0.38, 0.35, 0.35))

	# --- Room 3 platforms (x: 1280–1920) ---
	draw_rect(Rect2(1320, 370, 120, 12), Color(0.35, 0.38, 0.35))
	draw_rect(Rect2(1520, 300, 100, 12), Color(0.35, 0.38, 0.35))
	draw_rect(Rect2(1700, 230, 140, 12), Color(0.35, 0.38, 0.35))
