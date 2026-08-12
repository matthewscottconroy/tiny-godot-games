extends CharacterBody2D

const VISION_RANGE := 320.0

var _can_see  := false
var _player: CharacterBody2D

@onready var _label: Label = $StateLabel

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	_check_los()
	queue_redraw()
	_label.text = "ALERT!" if _can_see else "patrol"
	_label.modulate = Color.ORANGE_RED if _can_see else Color(1, 1, 1, 0.5)

func _check_los() -> void:
	if not _player:
		_can_see = false
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist > VISION_RANGE:
		_can_see = false
		return
	_can_see = _has_los(global_position, _player.global_position)

func _has_los(from: Vector2, to: Vector2) -> bool:
	# collision_mask = 2 → only walls (layer 2) can block the ray.
	return LineOfSight.is_clear(
		get_world_2d().direct_space_state, from, to, 2,
		[self.get_rid(), _player.get_rid()])

func _draw() -> void:
	var body_col := Color.TOMATO if _can_see else Color.CORAL
	draw_circle(Vector2.ZERO, 16, body_col)
	draw_arc(Vector2.ZERO, 16, 0, TAU, 24, body_col.lightened(0.4), 2.0)

	if not _can_see and _player:
		# Draw vision cone toward player
		var dir := (_player.global_position - global_position).normalized()
		for i in 18:
			var a := lerpf(-0.55, 0.55, float(i) / 17.0)
			var ray_end := dir.rotated(a) * VISION_RANGE
			draw_line(Vector2.ZERO, ray_end, Color(1.0, 0.9, 0.0, 0.04))
		# Draw range circle
		draw_arc(Vector2.ZERO, VISION_RANGE, 0, TAU, 48, Color(1, 1, 0, 0.06), 1.0)

	if _can_see and _player:
		var to_player := _player.global_position - global_position
		draw_line(Vector2.ZERO, to_player, Color(1, 0.2, 0.2, 0.6), 2.0)
