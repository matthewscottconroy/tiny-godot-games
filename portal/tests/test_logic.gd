extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_with_a_ball_and_no_portals()
	_test_space_spawns_another_ball()
	_test_r_clears_everything()
	_test_a_click_puts_a_portal_on_the_nearest_surface()
	_test_the_two_mouse_buttons_place_different_portals()
	_test_a_ball_falls_and_bounces()
	_test_the_ball_stays_in_the_room()
	_test_a_ball_entering_a_portal_comes_out_the_other()
	_test_a_ball_leaving_a_portal_is_left_alone()
	_test_teleporting_keeps_the_ball_s_speed()
	_test_the_exit_velocity_follows_the_exit_portal()
	_test_one_portal_on_its_own_does_nothing()
	_test_key_releases_are_not_key_presses()
	_test_the_room_is_closed_on_every_side()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[portal] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _only_ball(m: Node2D, pos: Vector2, vel: Vector2) -> Dictionary:
	m._balls.clear()
	m._balls.append({"pos": pos, "vel": vel})
	return m._balls[0]

func _click(m: Node2D, at: Vector2, button: int, pressed: bool = true) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.position = at
	m._input(e)

func _key(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

## Place both portals directly, bypassing the mouse.
func _portals(m: Node2D, a_pos: Vector2, a_normal: Vector2, b_pos: Vector2, b_normal: Vector2) -> void:
	m._portal_a = {"pos": a_pos, "normal": a_normal, "active": true}
	m._portal_b = {"pos": b_pos, "normal": b_normal, "active": true}

func _test_it_starts_with_a_ball_and_no_portals() -> void:
	print("opening state")
	var m := _make()
	expect(m._balls.size() == 1, "one ball to start with")
	expect(m._balls[0]["pos"].y < 200.0, "dropped in from the top")
	expect(not m._portal_a["active"] and not m._portal_b["active"], "and no portals placed yet")

func _test_space_spawns_another_ball() -> void:
	print("spawning")
	var m := _make()
	_key(m, KEY_SPACE)
	expect(m._balls.size() == 2, "space drops in another ball")
	expect(m._balls[0]["pos"] != m._balls[1]["pos"], "not in exactly the same place as the first")

func _test_r_clears_everything() -> void:
	print("reset")
	var m := _make()
	_click(m, Vector2(320.0, 435.0), MOUSE_BUTTON_LEFT)
	_key(m, KEY_SPACE)
	_key(m, KEY_R)
	expect(m._balls.is_empty(), "R takes the balls away")
	expect(not m._portal_a["active"], "and the portals with them")

func _test_a_click_puts_a_portal_on_the_nearest_surface() -> void:
	print("placing portals")
	var floor_click := _make()
	_click(floor_click, Vector2(320.0, 430.0), MOUSE_BUTTON_LEFT)
	expect(floor_click._portal_a["active"], "clicking near the floor places a portal")
	expect(floor_click._portal_a["normal"] == Vector2(0, -1), "facing up out of the floor")

	var wall_click := _make()
	_click(wall_click, Vector2(25.0, 240.0), MOUSE_BUTTON_LEFT)
	expect(wall_click._portal_a["normal"] == Vector2(1, 0), "and one near the left wall faces right")

	var far_click := _make()
	_click(far_click, Vector2(330.0, 290.0), MOUSE_BUTTON_LEFT)
	expect(far_click._portal_a["active"], "a click over the middle platform lands on it")
	expect(far_click._portal_a["pos"].y < 300.0, "on its top face, not the floor far below")

func _test_the_two_mouse_buttons_place_different_portals() -> void:
	print("two portals")
	var m := _make()
	_click(m, Vector2(320.0, 430.0), MOUSE_BUTTON_LEFT)
	expect(m._portal_a["active"] and not m._portal_b["active"], "left click places the first")
	_click(m, Vector2(25.0, 240.0), MOUSE_BUTTON_RIGHT)
	expect(m._portal_b["active"], "right click places the second")
	expect(m._portal_a["pos"] != m._portal_b["pos"], "in a different place")

func _test_a_ball_falls_and_bounces() -> void:
	print("bouncing")
	var m := _make()
	var ball := _only_ball(m, Vector2(320.0, 200.0), Vector2.ZERO)
	for i in 120:
		m._process(STEP)
	expect(ball["pos"].y > 200.0, "the ball falls")
	expect(ball["pos"].y + m.BALL_R <= 441.0, "and does not sink through the floor")

	var dropped := _make()
	var fast := _only_ball(dropped, Vector2(320.0, 435.0), Vector2(0.0, 300.0))
	dropped._process(STEP)
	expect(fast["vel"].y < 0.0, "hitting the floor sends it back up")
	expect(absf(fast["vel"].y) < 300.0, "having lost most of its speed on the way")

func _test_the_ball_stays_in_the_room() -> void:
	print("the walls")
	var m := _make()
	var ball := _only_ball(m, Vector2(320.0, 400.0), Vector2(900.0, 0.0))
	var escaped := false
	for i in 300:
		m._process(STEP)
		if ball["pos"].x < 0.0 or ball["pos"].x > 640.0 or ball["pos"].y > 480.0:
			escaped = true
	expect(not escaped, "a fast ball bounces between the walls rather than passing through one")

func _test_a_ball_entering_a_portal_comes_out_the_other() -> void:
	print("teleporting")
	var m := _make()
	# Floor portal in, left-wall portal out.
	_portals(m, Vector2(320.0, 439.0), Vector2(0, -1), Vector2(21.0, 240.0), Vector2(1, 0))
	# Started just above the portal's reach: any closer to the floor and the
	# floor's own collision band bounces the ball before the portal sees it.
	var ball := _only_ball(m, Vector2(320.0, 418.0), Vector2(0.0, 200.0))
	m._process(STEP)
	expect(ball["pos"].x < 100.0, "the ball comes out at the other portal")
	expect(ball["pos"].x > 21.0, "clear of the surface it is set into")

func _test_a_ball_leaving_a_portal_is_left_alone() -> void:
	print("one-way")
	var m := _make()
	_portals(m, Vector2(320.0, 439.0), Vector2(0, -1), Vector2(21.0, 240.0), Vector2(1, 0))
	# Sitting right on the portal but travelling away from it — this is the ball
	# that has just come out, and teleporting it again would trap it in a loop.
	var ball := _only_ball(m, Vector2(320.0, 432.0), Vector2(0.0, -200.0))
	m._process(STEP)
	expect(ball["pos"].x > 300.0, "a ball moving out of a portal is not pulled back in")

func _test_teleporting_keeps_the_ball_s_speed() -> void:
	print("conservation")
	var m := _make()
	_portals(m, Vector2(320.0, 439.0), Vector2(0, -1), Vector2(21.0, 240.0), Vector2(1, 0))
	var ball := _only_ball(m, Vector2(320.0, 418.0), Vector2(0.0, 200.0))
	var before: float = ball["vel"].length()
	m._process(STEP)
	expect(absf(ball["vel"].length() - before) < 20.0,
		"a portal moves the ball without speeding it up or slowing it down")

func _test_the_exit_velocity_follows_the_exit_portal() -> void:
	print("turning the corner")
	var m := _make()
	# Straight down into a floor portal, out of a wall portal facing right.
	var out: Vector2 = m._transform_velocity(Vector2(0.0, 300.0), Vector2(0, -1), Vector2(1, 0))
	expect(out.x > 0.0, "falling into the floor comes out heading right")
	expect(absf(out.y) < 1.0, "with nothing left of the downward motion")
	expect(is_equal_approx(out.length(), 300.0), "and the same speed as it went in")

	var straight: Vector2 = m._transform_velocity(Vector2(0.0, 300.0), Vector2(0, -1), Vector2(0, -1))
	expect(straight.y < 0.0, "two floor portals send it back up")

	# A velocity arriving at an angle keeps its sideways drift, turned to match
	# how far the exit portal is rotated from the entry one. The tests above all
	# enter straight on, where the sideways part is zero and the rotation could
	# be anything at all.
	var slanted: Vector2 = m._transform_velocity(
		Vector2(100.0, 300.0), Vector2(0, -1), Vector2(1, 0))
	expect(is_equal_approx(slanted.length(), Vector2(100.0, 300.0).length()),
		"a slanted entry keeps its speed (%.1f)" % slanted.length())
	expect(slanted.x > 0.0,
		"and still leaves along the exit portal's normal (%s)" % slanted)
	expect(absf(slanted.y) > 50.0,
		"carrying its sideways drift rather than losing it (%s)" % slanted)
	# Which way the drift ends up pointing is the whole content of the rotation,
	# so it is pinned rather than merely compared with its mirror image: two
	# different mistakes here both flip it, and both leave a mirror pair intact.
	# Entering the floor drifting right and leaving a right-facing wall, the
	# drift comes out pointing up.
	expect(slanted.y < 0.0,
		"and pointing up out of a right-facing exit (%s)" % slanted)
	expect(is_equal_approx(slanted.x, 300.0) and is_equal_approx(slanted.y, -100.0),
		"exactly: the entry's 300 along the normal and 100 across it (%s)" % slanted)

	# The drift turns with the portal: entering the floor moving right and
	# leaving a right-facing wall, the drift ends up pointing up. Sent the other
	# way it points down, and the two are mirror images.
	var mirrored: Vector2 = m._transform_velocity(
		Vector2(-100.0, 300.0), Vector2(0, -1), Vector2(1, 0))
	expect(mirrored.y > 0.0,
		"drifting the other way comes out pointing down (%s)" % mirrored)
	expect(is_equal_approx(slanted.x, mirrored.x),
		"with the same speed along the normal either way (%.1f, %.1f)"
		% [slanted.x, mirrored.x])
	expect(is_equal_approx(absf(slanted.y), absf(mirrored.y)),
		"and the same amount of drift")

	# Two portals a quarter-turn apart in the other direction, so the sign of
	# the rotation matters: a sum instead of a difference turns the wrong way.
	var up_exit: Vector2 = m._transform_velocity(
		Vector2(100.0, 300.0), Vector2(0, -1), Vector2(-1, 0))
	expect(up_exit.x < 0.0, "a left-facing exit sends it left (%s)" % up_exit)
	expect(up_exit.y > 0.0,
		"with its drift turned the opposite way from the right-facing exit (%s)"
		% up_exit)

func _test_one_portal_on_its_own_does_nothing() -> void:
	print("half a pair")
	var m := _make()
	# A portal with nowhere to go must be inert. Firing it anyway would drop the
	# ball at the unplaced portal's default position, in the corner of the room.
	m._portal_a = {"pos": Vector2(320.0, 439.0), "normal": Vector2(0, -1), "active": true}
	var ball := _only_ball(m, Vector2(320.0, 418.0), Vector2(0.0, 200.0))
	m._process(STEP)
	expect(ball["pos"].x > 300.0, "a ball falling into a lone portal is not teleported")
	expect(ball["pos"].y > 418.0, "it just keeps falling")

func _test_key_releases_are_not_key_presses() -> void:
	print("key releases")
	var m := _make()
	var before: int = m._balls.size()
	var release := InputEventKey.new()
	release.keycode = KEY_SPACE
	release.pressed = false
	m._input(release)
	expect(m._balls.size() == before, "letting go of space does not spawn a second ball")

	var reset := InputEventKey.new()
	reset.keycode = KEY_R
	reset.pressed = false
	m._input(reset)
	expect(m._balls.size() == before, "and letting go of R does not clear the room")

## The room is closed: a ball thrown hard in any direction stays in it.
##
## The ceiling exists for this. Without one a ball thrown upward leaves over the
## top and never returns, and since nothing culls a departed ball they pile up
## off screen for as long as the demo runs. The bounce code always had a branch
## for a downward-facing normal — there was simply no surface with one, so it
## was unreachable.
func _test_the_room_is_closed_on_every_side() -> void:
	print("the closed room")
	var throws := [
		["up", Vector2(-900.0, 0.0)],
		["down", Vector2(900.0, 0.0)],
		["left", Vector2(0.0, -900.0)],
		["right", Vector2(0.0, 900.0)],
	]
	for throw in throws:
		var m := _make()
		var launch: Vector2 = throw[1]
		var ball := _only_ball(m, Vector2(320.0, 240.0), Vector2(launch.y, launch.x))
		var escaped := false
		for i in 400:
			m._process(STEP)
			if ball["pos"].x < 0.0 or ball["pos"].x > 640.0 \
					or ball["pos"].y < 0.0 or ball["pos"].y > 480.0:
				escaped = true
		expect_quiet(not escaped,
			"thrown %s it stays inside (%s)" % [throw[0], ball["pos"]])
	expect(_quiet_failures == 0, "a ball thrown hard in any direction stays in the room")

	# The ceiling specifically: straight up, and it comes back down having lost
	# speed to the bounce rather than passing through.
	var m2 := _make()
	var rising := _only_ball(m2, Vector2(320.0, 200.0), Vector2(0.0, -900.0))
	var highest: float = rising["pos"].y
	for i in 200:
		m2._process(STEP)
		highest = minf(highest, rising["pos"].y)
	expect(highest >= 20.0,
		"a ball fired at the ceiling stops at it (%.0f)" % highest)
	expect(rising["pos"].y > highest,
		"and comes back down (%.0f from %.0f)" % [rising["pos"].y, highest])

	# A ball already overlapping a wall but travelling away from it keeps going.
	# The velocity check is what stops a bounce being applied twice while the
	# ball is still inside the surface — reverse it and the ball is turned back
	# into the wall it is trying to leave, and sticks there.
	var m4 := _make()
	var leaving := _only_ball(m4, Vector2(28.0, 240.0), Vector2(400.0, 0.0))
	for i in 5:
		m4._process(STEP)
	expect(leaving["vel"].x > 0.0,
		"a ball leaving the left wall is not turned back into it (%.0f)" % leaving["vel"].x)
	expect(leaving["pos"].x > 28.0,
		"and travels away from it (%.0f)" % leaving["pos"].x)

	var m5 := _make()
	var arriving := _only_ball(m5, Vector2(28.0, 240.0), Vector2(-400.0, 0.0))
	for i in 5:
		m5._process(STEP)
	expect(arriving["vel"].x > 0.0,
		"while one driving into it is turned around (%.0f)" % arriving["vel"].x)

	# Portals are placed on the press, not the release. Placing on both would
	# put a portal down and then immediately move it on the way back up.
	var m6 := _make()
	_click(m6, Vector2(320.0, 439.0), MOUSE_BUTTON_RIGHT, false)
	expect(not m6._portal_b["active"],
		"releasing the right button places no portal")
	_click(m6, Vector2(320.0, 439.0), MOUSE_BUTTON_RIGHT, true)
	expect(m6._portal_b["active"], "while pressing it places one")

	# Pushed out to sit exactly against the surface, on every side.
	#
	# One step from deliberately deep inside the surface. Position is integrated
	# before the collision check, so a ball started just barely overlapping has
	# already left the region by the time the check runs — which is a way to
	# write a test that exercises nothing and passes.
	var contacts := [
		["floor", Vector2(320.0, 448.0), Vector2(0.0, 100.0), "y", 440.0, 1.0],
		["ceiling", Vector2(320.0, 12.0), Vector2(0.0, -100.0), "y", 20.0, -1.0],
		["left wall", Vector2(12.0, 240.0), Vector2(-100.0, 0.0), "x", 20.0, -1.0],
		["right wall", Vector2(628.0, 240.0), Vector2(100.0, 0.0), "x", 620.0, 1.0],
	]
	for c in contacts:
		var m7 := _make()
		var b := _only_ball(m7, c[1], c[2])
		m7._process(STEP)
		var edge: float = (b["pos"].y if c[3] == "y" else b["pos"].x) \
			+ float(c[5]) * m7.BALL_R
		expect_quiet(absf(edge - float(c[4])) < 0.01,
			"%s: the ball is placed against it (edge %.2f, surface %.0f)"
			% [c[0], edge, float(c[4])])
	expect(_quiet_failures == 0,
		"a ball inside a surface is pushed out to touch it, not to somewhere else")

	# And it is only turned around when it is heading into a surface. Reverse
	# that test and a ball leaving one is driven back into it and sticks.
	var departures := [
		["floor", Vector2(320.0, 448.0), Vector2(0.0, -100.0), "y", -1.0],
		["ceiling", Vector2(320.0, 12.0), Vector2(0.0, 100.0), "y", 1.0],
		["left wall", Vector2(12.0, 240.0), Vector2(100.0, 0.0), "x", 1.0],
		["right wall", Vector2(628.0, 240.0), Vector2(-100.0, 0.0), "x", -1.0],
	]
	for d in departures:
		var m8 := _make()
		var b := _only_ball(m8, d[1], d[2])
		m8._process(STEP)
		var moving: float = b["vel"].y if d[3] == "y" else b["vel"].x
		expect_quiet(moving * float(d[4]) > 0.0,
			"%s: a ball leaving it keeps going (%.0f)" % [d[0], moving])
	expect(_quiet_failures == 0, "a ball travelling away from a surface is left alone")

	# And a portal can be put on it, which is what makes it a surface rather
	# than a wall the demo happens to draw.
	var m3 := _make()
	m3._place_portal(m3._portal_a, Vector2(320.0, 24.0))
	expect(m3._portal_a["active"], "a portal lands on the ceiling")
	expect(m3._portal_a["normal"] == Vector2(0, 1),
		"facing down into the room (%s)" % m3._portal_a["normal"])
	# Sat just clear of the surface, on the room side — sunk into it instead,
	# the ring is drawn inside the wall and a ball entering it starts embedded.
	expect(m3._portal_a["pos"].y > 20.0,
		"and sitting just below the ceiling face rather than inside it (%.1f)"
		% m3._portal_a["pos"].y)
	expect(m3._portal_a["pos"].y < 22.0,
		"by a hair, not a gap (%.1f)" % m3._portal_a["pos"].y)

	# Clicked from inside the room, so the click projects onto the face itself
	# and the 1px offset is the only thing deciding which side of it the portal
	# lands on.
	var m9 := _make()
	m9._place_portal(m9._portal_a, Vector2(320.0, 435.0))
	expect(m9._portal_a["pos"].y < 440.0,
		"a floor portal sits just above the floor face (%.1f)" % m9._portal_a["pos"].y)
	expect(m9._portal_a["pos"].y > 438.0,
		"again by a hair (%.1f)" % m9._portal_a["pos"].y)

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("    (", label, " — failed)")
