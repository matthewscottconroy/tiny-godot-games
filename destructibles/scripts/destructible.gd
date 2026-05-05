extends Area2D

@export var box_color   := Color.PERU
@export var box_size    := Vector2(48, 48)
@export var frag_count  := 8
@export var frag_speed  := 200.0
@export var hp          := 2   # clicks to destroy

var _hits       := 0
var _destroyed  := false
var _flash_timer := 0.0

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_click)

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		queue_redraw()

func _draw() -> void:
	if _destroyed:
		return
	var flash := clampf(_flash_timer * 6.0, 0.0, 1.0)
	var col   := box_color.lerp(Color.WHITE, flash)
	draw_rect(Rect2(-box_size * 0.5, box_size), col)
	draw_rect(Rect2(-box_size * 0.5, box_size), col.lightened(0.3), false, 2.0)
	# Crack lines appear as HP drops
	if _hits >= 1 and hp > 1:
		var half := box_size * 0.5
		draw_line(Vector2(-half.x * 0.3, -half.y), Vector2(half.x * 0.1, 0), Color(0, 0, 0, 0.5), 2.0)
		draw_line(Vector2(half.x * 0.2, 0), Vector2(-half.x * 0.1, half.y * 0.8), Color(0, 0, 0, 0.5), 2.0)

func _on_click(_vp: Viewport, event: InputEvent, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _destroyed:
			return
		_hits       += 1
		_flash_timer = 0.12
		queue_redraw()
		if _hits >= hp:
			_shatter()

func _shatter() -> void:
	_destroyed = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in frag_count:
		var frag := RigidBody2D.new()
		frag.gravity_scale = 1.2
		frag.angular_damp  = 0.5

		var frag_size := Vector2(rng.randf_range(6, 14), rng.randf_range(6, 14))

		var poly := Polygon2D.new()
		var hw := frag_size.x * 0.5
		var hh := frag_size.y * 0.5
		poly.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh),
			Vector2(hw * 0.8, hh), Vector2(-hw * 0.8, hh)
		])
		poly.color = box_color.darkened(rng.randf_range(0.0, 0.35))
		frag.add_child(poly)

		var cshape := CollisionShape2D.new()
		var rect   := RectangleShape2D.new()
		rect.size  = frag_size
		cshape.shape = rect
		frag.add_child(cshape)

		frag.position = global_position + Vector2(
			rng.randf_range(-box_size.x * 0.4, box_size.x * 0.4),
			rng.randf_range(-box_size.y * 0.4, box_size.y * 0.4)
		)
		get_parent().add_child(frag)

		var angle := TAU * i / frag_count + rng.randf_range(-0.4, 0.4)
		frag.linear_velocity = Vector2(
			cos(angle) * frag_speed * rng.randf_range(0.5, 1.5),
			sin(angle) * frag_speed * rng.randf_range(0.5, 1.5) - 80.0
		)
		frag.angular_velocity = rng.randf_range(-8.0, 8.0)

	queue_free()
