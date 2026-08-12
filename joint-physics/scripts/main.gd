extends Node2D

# Pendulum configuration
const PEND_X := 160.0
const PEND_ANCHOR_Y := 80.0
const LINK_COUNT := 5
const LINK_SPACING := 50.0

# Spring configuration
const SPRING_CX := 480.0
const SPRING_ANCHOR_Y := 90.0
const SPRING_GAP := 90.0

var _pend_bodies: Array[Node2D] = []
var _spring_left: StaticBody2D
var _spring_right: StaticBody2D
var _spring_weight: RigidBody2D

func _ready() -> void:
	_build_pendulum()
	_build_spring()

# ---------- factory helpers ----------

func _make_rigid_circle(pos: Vector2, radius: float) -> RigidBody2D:
	var body := RigidBody2D.new()
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = radius
	col.shape = cs
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body

func _make_static_circle(pos: Vector2, radius: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = radius
	col.shape = cs
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body

func _pin(body_a: Node2D, body_b: Node2D, world_pos: Vector2) -> void:
	var joint := PinJoint2D.new()
	joint.position = world_pos
	add_child(joint)
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()

func _spring(body_a: Node2D, body_b: Node2D, stiffness: float, damping: float) -> void:
	var dist := body_a.position.distance_to(body_b.position)
	var joint := DampedSpringJoint2D.new()
	joint.position = (body_a.position + body_b.position) * 0.5
	add_child(joint)
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
	joint.length = dist
	joint.rest_length = dist * 0.80
	joint.stiffness = stiffness
	joint.damping = damping

# ---------- scene builders ----------

func _build_pendulum() -> void:
	var anchor := _make_static_circle(Vector2(PEND_X, PEND_ANCHOR_Y), 9.0)
	_pend_bodies.append(anchor)

	var prev: Node2D = anchor
	for i in LINK_COUNT:
		# Slight horizontal offset on first link to start swinging
		var offset_x := -30.0 if i == 0 else 0.0
		var link := _make_rigid_circle(
			Vector2(PEND_X + offset_x, PEND_ANCHOR_Y + (i + 1) * LINK_SPACING), 11.0
		)
		link.linear_damp = 0.2
		link.angular_damp = 0.4
		_pend_bodies.append(link)

		# Pin at the UPPER body's center (the pivot point)
		_pin(prev, link, prev.position)
		prev = link

func _build_spring() -> void:
	_spring_left = _make_static_circle(
		Vector2(SPRING_CX - SPRING_GAP, SPRING_ANCHOR_Y), 9.0
	)
	_spring_right = _make_static_circle(
		Vector2(SPRING_CX + SPRING_GAP, SPRING_ANCHOR_Y), 9.0
	)
	_spring_weight = _make_rigid_circle(Vector2(SPRING_CX, SPRING_ANCHOR_Y + 150), 18.0)
	_spring_weight.mass = 4.0
	_spring_weight.linear_damp = 0.5

	_spring(_spring_left, _spring_weight, 30.0, 2.0)
	_spring(_spring_right, _spring_weight, 30.0, 2.0)

# ---------- interaction ----------

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		var last := _pend_bodies.back() as RigidBody2D
		if last:
			last.apply_central_impulse(Vector2(220, -80))
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _spring_weight:
			_spring_weight.apply_central_impulse(Vector2(randf_range(-180, 180), -250))

# ---------- rendering ----------

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.10, 0.12, 0.18))

	# Section divider
	draw_line(Vector2(320, 44), Vector2(320, 460), Color(0.28, 0.30, 0.42), 1)

	_draw_pendulum()
	_draw_springs()

func _draw_pendulum() -> void:
	# Ceiling bar
	draw_rect(Rect2(80, 60, 160, 8), Color(0.4, 0.42, 0.5))

	for i in _pend_bodies.size():
		var body: PhysicsBody2D = _pend_bodies[i]
		if not is_instance_valid(body):
			continue
		var pos: Vector2 = body.global_position

		# Link line to previous
		if i > 0:
			var prev_pos: Vector2 = _pend_bodies[i - 1].global_position
			draw_line(prev_pos, pos, Color(0.65, 0.58, 0.42), 3)

		# Body circle
		var radius := 9.0 if i == 0 else 11.0
		var color := Color(0.48, 0.50, 0.60) if i == 0 else Color(0.85, 0.65, 0.22)
		draw_circle(pos, radius, color)
		draw_arc(pos, radius, 0, TAU, 20, color.lightened(0.3), 1.5)

	# PinJoint2D label
	_draw_label("PinJoint2D", Vector2(PEND_X, 46))

func _draw_springs() -> void:
	# Ceiling bar
	draw_rect(Rect2(SPRING_CX - SPRING_GAP - 20, 70, SPRING_GAP * 2 + 40, 8), Color(0.4, 0.42, 0.5))

	# Draw spring zigzags from each anchor to weight
	var anchors := [_spring_left, _spring_right]
	for anchor in anchors:
		if not (is_instance_valid(anchor) and is_instance_valid(_spring_weight)):
			continue
		var a: Vector2 = anchor.global_position
		var b: Vector2 = _spring_weight.global_position
		_draw_spring_line(a, b)
		# Anchor circle
		draw_circle(a, 9.0, Color(0.48, 0.50, 0.60))

	# Weight
	if is_instance_valid(_spring_weight):
		var wp: Vector2 = _spring_weight.global_position
		draw_circle(wp, 18.0, Color(0.22, 0.52, 0.90))
		draw_circle(wp, 14.0, Color(0.32, 0.62, 1.0))
		draw_arc(wp, 18.0, 0, TAU, 24, Color(0.5, 0.75, 1.0), 2.0)

	_draw_label("DampedSpringJoint2D", Vector2(SPRING_CX, 46))

func _draw_spring_line(a: Vector2, b: Vector2) -> void:
	var segs := 10
	var perp := (b - a).normalized().rotated(PI * 0.5) * 10.0
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var p0 := a.lerp(b, t0) + (perp if i % 2 == 0 else -perp)
		var p1 := a.lerp(b, t1) + (perp if (i + 1) % 2 == 0 else -perp)
		draw_line(p0, p1, Color(0.45, 0.78, 0.45), 2)

func _draw_label(text: String, pos: Vector2) -> void:
	# Approximate centering by offsetting half the estimated text width
	draw_string(ThemeDB.fallback_font, pos + Vector2(-len(text) * 4, 0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.72, 0.8))
