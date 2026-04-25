extends Node2D

var stats : EnemyStats :
	set(value):
		stats = value
		queue_redraw()

func _draw() -> void:
	if not stats:
		return
	var r := clamp(stats.max_hp / 10.0, 12.0, 40.0)
	draw_circle(Vector2.ZERO, r, stats.color)
	draw_circle(Vector2(-r * 0.35, -r * 0.3), r * 0.18, Color.WHITE)
	draw_circle(Vector2( r * 0.35, -r * 0.3), r * 0.18, Color.WHITE)
