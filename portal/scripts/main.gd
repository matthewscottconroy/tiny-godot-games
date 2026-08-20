extends Node2D

const GRAVITY := 500.0
const BALL_R := 10.0
const PORTAL_R := 22.0
const PORTAL_ENTRY_DIST := 18.0

# The normal points into the room, away from the surface.
#
# The ceiling is here because the room needs closing: without it a ball thrown
# upward leaves over the top and never comes back, and since nothing culls a
# ball that has gone, they accumulate off screen for as long as the demo runs.
# The bounce code always had a branch for a downward-facing normal; there was
# simply no surface with one.
const SURFACES: Array = [
	{"rect": Rect2(0, 440, 640, 40),   "normal": Vector2(0, -1)},   # floor
	{"rect": Rect2(0, 0, 640, 20),     "normal": Vector2(0, 1)},    # ceiling
	{"rect": Rect2(0, 0, 20, 480),     "normal": Vector2(1, 0)},    # left wall
	{"rect": Rect2(620, 0, 20, 480),   "normal": Vector2(-1, 0)},   # right wall
	{"rect": Rect2(200, 280, 240, 20), "normal": Vector2(0, -1)},   # platform
]

var _portal_a: Dictionary = {"pos": Vector2.ZERO, "normal": Vector2(0, -1), "active": false}
var _portal_b: Dictionary = {"pos": Vector2.ZERO, "normal": Vector2(0, -1), "active": false}
var _balls: Array = []

func _ready() -> void:
	_spawn_ball()

func _spawn_ball() -> void:
	_balls.append({
		"pos": Vector2(320.0 + randf_range(-40.0, 40.0), 80.0),
		"vel": Vector2(randf_range(-60.0, 60.0), 0.0),
	})

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_place_portal(_portal_a, event.position)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_place_portal(_portal_b, event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_spawn_ball()
		elif event.keycode == KEY_R:
			_balls.clear()
			_portal_a["active"] = false
			_portal_b["active"] = false

func _place_portal(portal: Dictionary, click_pos: Vector2) -> void:
	var best_dist := INF
	var best_surface: Dictionary = {}
	var best_proj := Vector2.ZERO
	for surf in SURFACES:
		var r: Rect2 = surf["rect"]
		# Project click_pos onto the surface rect
		var proj := Vector2(
			clamp(click_pos.x, r.position.x, r.position.x + r.size.x),
			clamp(click_pos.y, r.position.y, r.position.y + r.size.y)
		)
		var d := click_pos.distance_to(proj)
		if d < best_dist:
			best_dist = d
			best_surface = surf
			best_proj = proj
	if best_surface.is_empty():
		return
	# Place portal on the surface face, offset outward by 1px
	var n: Vector2 = best_surface["normal"]
	portal["pos"] = best_proj + n * 1.0
	portal["normal"] = n
	portal["active"] = true

func _transform_velocity(vel: Vector2, from_normal: Vector2, to_normal: Vector2) -> Vector2:
	# Rotate velocity from portal_a's frame to portal_b's frame.
	# The convention: velocity entering portal_a (moving against from_normal)
	# exits portal_b moving along to_normal.
	# Decompose vel into component along from_normal and perpendicular.
	var along := vel.dot(-from_normal)   # positive = entering
	var perp_vec := vel - (-from_normal) * vel.dot(-from_normal)
	# The exit velocity: exits along to_normal with same speed component,
	# and perpendicular component rotated to match the portal orientation change.
	var angle_a := (-from_normal).angle()
	var angle_b := to_normal.angle()
	var rotation := angle_b - angle_a
	var perp_rotated := perp_vec.rotated(rotation)
	return to_normal * along + perp_rotated

func _process(delta: float) -> void:
	for ball in _balls:
		# Gravity
		ball["vel"] = ball["vel"] + Vector2(0, GRAVITY * delta)
		ball["pos"] = ball["pos"] + ball["vel"] * delta

		# Surface collisions
		for surf in SURFACES:
			var r: Rect2 = surf["rect"]
			var n: Vector2 = surf["normal"]
			# Expand rect by BALL_R for sphere collision
			var expanded := Rect2(r.position - Vector2(BALL_R, BALL_R), r.size + Vector2(BALL_R * 2, BALL_R * 2))
			if expanded.has_point(ball["pos"]):
				# Push out along normal direction
				var contact_plane_dist := 0.0
				if n == Vector2(0, -1):  # floor-like: normal points up
					contact_plane_dist = r.position.y - (ball["pos"].y + BALL_R)
					if contact_plane_dist < 0:
						ball["pos"] = ball["pos"] + Vector2(0, contact_plane_dist)
						if ball["vel"].y > 0:
							ball["vel"].y *= -0.4
				elif n == Vector2(0, 1):  # ceiling
					contact_plane_dist = (r.position.y + r.size.y) - (ball["pos"].y - BALL_R)
					if contact_plane_dist > 0:
						ball["pos"] = ball["pos"] + Vector2(0, contact_plane_dist)
						if ball["vel"].y < 0:
							ball["vel"].y *= -0.4
				elif n == Vector2(1, 0):  # left wall normal points right
					contact_plane_dist = (r.position.x + r.size.x) - (ball["pos"].x - BALL_R)
					if contact_plane_dist > 0:
						ball["pos"] = ball["pos"] + Vector2(contact_plane_dist, 0)
						if ball["vel"].x < 0:
							ball["vel"].x *= -0.4
				elif n == Vector2(-1, 0):  # right wall normal points left
					contact_plane_dist = r.position.x - (ball["pos"].x + BALL_R)
					if contact_plane_dist < 0:
						ball["pos"] = ball["pos"] + Vector2(contact_plane_dist, 0)
						if ball["vel"].x > 0:
							ball["vel"].x *= -0.4

		# Portal teleportation
		if _portal_a["active"] and _portal_b["active"]:
			_check_portal_entry(ball, _portal_a, _portal_b)
			_check_portal_entry(ball, _portal_b, _portal_a)

	queue_redraw()

func _check_portal_entry(ball: Dictionary, from_portal: Dictionary, to_portal: Dictionary) -> void:
	var dist: float = ball["pos"].distance_to(from_portal["pos"])
	if dist > PORTAL_ENTRY_DIST:
		return
	# Check ball is moving toward portal (into the surface)
	var toward: float = ball["vel"].dot(-from_portal["normal"])
	if toward <= 0:
		return
	# Teleport
	ball["pos"] = to_portal["pos"] + to_portal["normal"] * (PORTAL_ENTRY_DIST + 2.0)
	ball["vel"] = _transform_velocity(ball["vel"], from_portal["normal"], to_portal["normal"])

func _draw() -> void:
	# Draw surfaces
	for surf in SURFACES:
		var r: Rect2 = surf["rect"]
		draw_rect(r, Color(0.35, 0.32, 0.28))
		draw_rect(r, Color(0.5, 0.47, 0.43), false, 1.5)

	# Draw portals
	if _portal_a["active"]:
		_draw_portal(_portal_a["pos"], _portal_a["normal"], Color(1.0, 0.5, 0.0))
	if _portal_b["active"]:
		_draw_portal(_portal_b["pos"], _portal_b["normal"], Color(0.2, 0.5, 1.0))

	# Draw balls
	for ball in _balls:
		draw_circle(ball["pos"], BALL_R, Color(0.9, 0.85, 0.75))
		draw_arc(ball["pos"], BALL_R, 0, TAU, 24, Color(0.5, 0.45, 0.4), 1.5)

	# UI
	draw_string(ThemeDB.fallback_font, Vector2(320, 30), "Portal", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(320, 468), "LClick: orange portal  RClick: blue portal  Space: spawn ball  R: reset", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.8, 0.8, 0.8))

func _draw_portal(pos: Vector2, normal: Vector2, color: Color) -> void:
	var angle := normal.angle() + PI / 2.0
	# Draw an arc as the portal opening
	draw_arc(pos, PORTAL_R, angle, angle + PI, 32, color, 6.0)
	draw_arc(pos, PORTAL_R, angle, angle + PI, 32, color.lightened(0.4), 2.0)
	# Inner glow
	draw_arc(pos, PORTAL_R * 0.6, angle, angle + PI, 24, color.lightened(0.3), 3.0)
	# Normal arrow showing exit direction
	var arrow_end := pos + normal * 24.0
	draw_line(pos, arrow_end, color.lightened(0.3), 2.0)
	var perp := Vector2(-normal.y, normal.x)
	draw_line(arrow_end, arrow_end - normal * 6.0 + perp * 4.0, color.lightened(0.3), 2.0)
	draw_line(arrow_end, arrow_end - normal * 6.0 - perp * 4.0, color.lightened(0.3), 2.0)
