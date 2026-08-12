extends Node2D

# A trivial child for the ring to place. Drawn as an arrow so the `face_outward`
# rotation is visible.

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(14, 0), Vector2(-8, -8), Vector2(-8, 8),
	]), Color(0.4, 0.75, 0.95))
