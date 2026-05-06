extends Node2D

@onready var _joy:    Control          = $CanvasLayer/Joystick
@onready var _player: CharacterBody2D  = $Player

const ARENA := Rect2(40, 60, 560, 360)

func _ready() -> void:
	_player.joystick = _joy

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.10, 0.14))
	# Arena floor
	draw_rect(ARENA, Color(0.15, 0.17, 0.22))
	draw_rect(ARENA, Color(0.35, 0.4, 0.5), false, 2.0)
	# Grid lines for depth
	for col in 7:
		var x := ARENA.position.x + float(col + 1) * ARENA.size.x / 8.0
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y),
				Color(0.25, 0.27, 0.33), 1.0)
	for row in 5:
		var y := ARENA.position.y + float(row + 1) * ARENA.size.y / 6.0
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y),
				Color(0.25, 0.27, 0.33), 1.0)
