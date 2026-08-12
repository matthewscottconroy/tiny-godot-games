extends Node

# Pure GDScript tests — no scene tree dependencies.

var _pass := 0
var _fail := 0
var _results: Array = []

func _ready() -> void:
	_test_velocity_transform_same_normal()
	_test_velocity_transform_opposite()
	_test_portal_entry_detection()
	_test_portal_no_entry_moving_away()
	_test_surface_projection()
	_report()

# --------------- helpers ---------------

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _transform_velocity(vel: Vector2, from_normal: Vector2, to_normal: Vector2) -> Vector2:
	var along := vel.dot(-from_normal)
	var perp_vec := vel - (-from_normal) * vel.dot(-from_normal)
	var angle_a := (-from_normal).angle()
	var angle_b := to_normal.angle()
	var rotation := angle_b - angle_a
	var perp_rotated := perp_vec.rotated(rotation)
	return to_normal * along + perp_rotated

func _ball_enters_portal(ball_pos: Vector2, ball_vel: Vector2, portal_pos: Vector2, portal_normal: Vector2) -> bool:
	var dist := ball_pos.distance_to(portal_pos)
	if dist > 18.0:
		return false
	var toward := ball_vel.dot(-portal_normal)
	return toward > 0.0

const SURFACES: Array = [
	{"rect": Rect2(0, 440, 640, 40),   "normal": Vector2(0, -1)},
	{"rect": Rect2(0, 0, 20, 480),     "normal": Vector2(1, 0)},
	{"rect": Rect2(620, 0, 20, 480),   "normal": Vector2(-1, 0)},
	{"rect": Rect2(200, 280, 240, 20), "normal": Vector2(0, -1)},
]

func _place_portal_normal(click_pos: Vector2) -> Vector2:
	var best_dist := INF
	var best_normal := Vector2(0, -1)
	for surf in SURFACES:
		var r: Rect2 = surf["rect"]
		var proj := Vector2(
			clamp(click_pos.x, r.position.x, r.position.x + r.size.x),
			clamp(click_pos.y, r.position.y, r.position.y + r.size.y)
		)
		var d := click_pos.distance_to(proj)
		if d < best_dist:
			best_dist = d
			best_normal = surf["normal"]
	return best_normal

# --------------- tests ---------------

func _test_velocity_transform_same_normal() -> void:
	# Both portals face the same direction (both floor, normal up)
	var vel := Vector2(100.0, 200.0)   # falling into a floor portal
	var from_n := Vector2(0, -1)
	var to_n := Vector2(0, -1)
	var result := _transform_velocity(vel, from_n, to_n)
	# Two portals facing the same way turn the ball around: it goes into the
	# floor and comes back out of the floor, so the velocity is reversed.
	expect(result.distance_to(-vel) < 0.01, "Same normal: velocity is reversed")

func _test_velocity_transform_opposite() -> void:
	# Portal A on floor (normal = up = Vector2(0,-1))
	# Portal B on ceiling (normal = down = Vector2(0,1))
	var vel := Vector2(50.0, 300.0)  # falling downward into the floor portal
	var from_n := Vector2(0, -1)
	var to_n := Vector2(0, 1)
	var result := _transform_velocity(vel, from_n, to_n)
	# The along component (into floor portal = downward into floor) should exit upward from ceiling
	# from_normal = up, so -from_normal = down. vel.dot(down) = 300 (positive, entering)
	# Result should have positive y component (moving down from ceiling) and x should be negated
	expect(result.y > 0.0, "Opposite portals: y component exits downward from ceiling")

func _test_portal_entry_detection() -> void:
	# Ball within 18px, moving toward portal (floor portal, normal up = Vector2(0,-1))
	var portal_pos := Vector2(320.0, 440.0)
	var portal_normal := Vector2(0.0, -1.0)
	var ball_pos := Vector2(320.0, 430.0)  # 10px above portal, within range
	var ball_vel := Vector2(0.0, 200.0)    # moving downward = toward floor = into portal
	expect(_ball_enters_portal(ball_pos, ball_vel, portal_pos, portal_normal), "Ball within range moving toward portal: enters")

func _test_portal_no_entry_moving_away() -> void:
	# Ball within 18px but moving away from portal
	var portal_pos := Vector2(320.0, 440.0)
	var portal_normal := Vector2(0.0, -1.0)
	var ball_pos := Vector2(320.0, 430.0)
	var ball_vel := Vector2(0.0, -200.0)   # moving upward = away from floor
	expect(not _ball_enters_portal(ball_pos, ball_vel, portal_pos, portal_normal), "Ball moving away from portal: does not enter")

func _test_surface_projection() -> void:
	# Click near the floor (y ~455) → nearest surface should be the floor with normal (0,-1)
	var click := Vector2(300.0, 455.0)
	var normal := _place_portal_normal(click)
	expect(normal == Vector2(0, -1), "Click near floor: portal placed on floor surface")

# --------------- report ---------------

func _report() -> void:
	var summary := "[portal] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
