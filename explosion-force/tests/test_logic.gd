extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_scene_starts_with_still_balls()
	_test_an_explosion_throws_balls_outward()
	_test_the_blast_falls_off_with_distance()
	_test_balls_outside_the_blast_are_untouched()
	_test_a_ball_on_the_epicentre_is_not_flung_to_infinity()
	_test_a_click_sets_off_an_explosion()
	_test_a_shockwave_grows_and_fades()
	_test_balls_stay_on_screen()
	_test_each_wall_turns_a_ball_around()
	_test_the_balls_come_to_rest()
	_test_r_resets_the_scene()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[explosion-force] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _one_ball_at(m: Node2D, pos: Vector2) -> Dictionary:
	m._balls = [{pos = pos, vel = Vector2.ZERO, color = Color.WHITE}]
	return m._balls[0]

func _test_the_scene_starts_with_still_balls() -> void:
	print("the scene")
	var m := _make()
	expect(m._balls.size() == m.BALL_COUNT, "a handful of balls")
	expect(m._shockwaves.is_empty(), "and no explosions yet")
	var still := true
	for ball in m._balls:
		if ball.vel != Vector2.ZERO:
			still = false
	expect(still, "all of them at rest")

func _test_an_explosion_throws_balls_outward() -> void:
	print("the blast")
	var m := _make()
	var epicentre := Vector2(320.0, 240.0)
	var right := _one_ball_at(m, epicentre + Vector2(50.0, 0.0))
	m._explode(epicentre)
	expect(right.vel.x > 0.0, "a ball to the right of the blast is pushed further right")

	var above := _make()
	var up := _one_ball_at(above, epicentre - Vector2(0.0, 50.0))
	above._explode(epicentre)
	expect(up.vel.y < 0.0, "and one above it is pushed upwards")

func _test_the_blast_falls_off_with_distance() -> void:
	print("falloff")
	var epicentre := Vector2(320.0, 240.0)
	var near := _make()
	var near_ball := _one_ball_at(near, epicentre + Vector2(20.0, 0.0))
	near._explode(epicentre)

	var far := _make()
	var far_ball := _one_ball_at(far, epicentre + Vector2(150.0, 0.0))
	far._explode(epicentre)

	expect(near_ball.vel.length() > far_ball.vel.length(),
		"a ball near the blast is thrown harder than one at the edge of it")

func _test_balls_outside_the_blast_are_untouched() -> void:
	print("out of range")
	var m := _make()
	var epicentre := Vector2(320.0, 240.0)
	var distant := _one_ball_at(m, epicentre + Vector2(m.EXPLOSION_RADIUS + 20.0, 0.0))
	m._explode(epicentre)
	expect(distant.vel == Vector2.ZERO, "a ball beyond the blast radius does not move")

func _test_a_ball_on_the_epicentre_is_not_flung_to_infinity() -> void:
	print("the epicentre")
	var m := _make()
	var epicentre := Vector2(320.0, 240.0)
	# Dividing by a zero distance would produce a NaN and lose the ball for good.
	var sitting := _one_ball_at(m, epicentre)
	m._explode(epicentre)
	expect(not is_nan(sitting.vel.x) and not is_nan(sitting.vel.y),
		"a ball exactly on the epicentre keeps a real velocity")
	expect(sitting.vel == Vector2.ZERO, "and is simply skipped")

func _test_a_click_sets_off_an_explosion() -> void:
	print("clicking")
	var m := _make()
	var ball := _one_ball_at(m, Vector2(320.0, 240.0) + Vector2(40.0, 0.0))
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = Vector2(320.0, 240.0)
	m._input(e)
	expect(ball.vel != Vector2.ZERO, "clicking explodes at the cursor")
	expect(m._shockwaves.size() == 1, "and leaves a shockwave to draw")

func _test_a_shockwave_grows_and_fades() -> void:
	print("the shockwave")
	var m := _make()
	m._explode(Vector2(320.0, 240.0))
	var wave: Dictionary = m._shockwaves[0]
	m._process(STEP)
	expect(wave.radius > 0.0, "the ring expands")
	expect(wave.alpha < 1.0, "and fades as it goes")
	# Still on the list: `wave` is a reference, so it keeps reporting its own
	# radius and alpha whether or not the demo still has it. A cleanup rule
	# inverted to drop everything immediately is invisible from the dictionary
	# and only visible from the list.
	expect(m._shockwaves.size() == 1,
		"and is still being drawn while it is visible (%d)" % m._shockwaves.size())
	expect(wave.alpha > 0.0, "because it has not faded out yet (%.2f)" % wave.alpha)

	for i in 180:
		m._process(STEP)
	expect(m._shockwaves.is_empty(), "and is cleaned up once invisible")

	# Several at once are each kept until their own time is up, rather than the
	# whole list being cleared when the first one goes.
	# A ring lasts about 1/1.8s, so ten frames apart both are still fading.
	m._explode(Vector2(100.0, 100.0))
	for i in 10:
		m._process(STEP)
	m._explode(Vector2(500.0, 300.0))
	expect(m._shockwaves.size() == 2, "two rings coexist (%d)" % m._shockwaves.size())
	for i in 10:
		m._process(STEP)
	expect(m._shockwaves.size() == 2,
		"both still visible partway through (%d)" % m._shockwaves.size())
	# The older one goes first, on its own schedule rather than with the newer.
	for i in 20:
		m._process(STEP)
	expect(m._shockwaves.size() == 1,
		"the older ring fades out first (%d)" % m._shockwaves.size())

func _test_balls_stay_on_screen() -> void:
	print("the walls")
	var m := _make()
	var ball := _one_ball_at(m, Vector2(320.0, 240.0))
	ball.vel = Vector2(4000.0, -4000.0)
	var escaped := false
	for i in 300:
		m._process(STEP)
		if ball.pos.x < m.BALL_R - 0.001 or ball.pos.x > 640.0 - m.BALL_R + 0.001 \
				or ball.pos.y < m.BALL_R - 0.001 or ball.pos.y > 480.0 - m.BALL_R + 0.001:
			escaped = true
	expect(not escaped, "even a ball thrown hard stays inside the window")

## Each wall stops a ball, and only the wall it is heading for.
##
## "It stayed inside the window" is satisfied by a clamp inverted to pin every
## ball against one edge for good — the ball is certainly still inside. What the
## demo promises is a ball that reaches a wall, stops at it, and comes back.
func _test_each_wall_turns_a_ball_around() -> void:
	print("each wall")
	var walls := [
		["left", Vector2(-2000.0, 0.0), "x", 0.0, 1.0],
		["right", Vector2(2000.0, 0.0), "x", 640.0, -1.0],
		["top", Vector2(0.0, -2000.0), "y", 0.0, 1.0],
		["bottom", Vector2(0.0, 2000.0), "y", 480.0, -1.0],
	]
	for w in walls:
		var m := _make()
		var ball := _one_ball_at(m, Vector2(320.0, 240.0))
		ball.vel = w[1]
		var axis: String = w[2]
		var away: float = float(w[4])
		var face: float = float(w[3]) + away * m.BALL_R

		# Closest approach over the flight, not the position at the end: the
		# ball bounces and travels back, so where it finishes says nothing.
		var nearest := 1e9
		var crossed := false
		var turned := false
		for i in 30:
			m._process(STEP)
			var at: float = ball.pos.x if axis == "x" else ball.pos.y
			nearest = minf(nearest, absf(at - face))
			if (at - face) * away < -0.01:
				crossed = true
			var moving: float = ball.vel.x if axis == "x" else ball.vel.y
			if moving * away > 0.0:
				turned = true
		expect_quiet(nearest < 3.0,
			"%s: the ball reaches it (%.1f px short)" % [w[0], nearest])
		expect_quiet(not crossed, "%s: and never passes through it" % w[0])
		expect_quiet(turned, "%s: coming back the other way" % w[0])
	expect(_quiet_failures == 0, "every wall stops a ball and turns it round")

	# A ball nowhere near a wall is left where it is. A comparison the wrong way
	# round clamps it to an edge it never reached.
	var open := _make()
	var free := _one_ball_at(open, Vector2(320.0, 240.0))
	free.vel = Vector2(30.0, 0.0)
	open._process(STEP)
	expect(free.pos.x > 320.0 and free.pos.x < 340.0,
		"a ball in open space just moves (%.1f)" % free.pos.x)
	expect(free.pos.y > 240.0 and free.pos.y < 260.0,
		"falling as it goes (%.1f)" % free.pos.y)
	expect(free.vel.x > 0.0, "keeping the direction it had (%.0f)" % free.vel.x)

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("    (", label, " — failed)")

func _test_the_balls_come_to_rest() -> void:
	print("settling")
	var m := _make()
	m._explode(Vector2(320.0, 240.0))
	for i in 900:
		m._process(STEP)
	var fastest := 0.0
	for ball in m._balls:
		fastest = maxf(fastest, ball.vel.length())
	expect(fastest < 200.0, "the debris slows down and settles rather than bouncing forever")

func _test_r_resets_the_scene() -> void:
	print("reset")
	var m := _make()
	m._explode(Vector2(320.0, 240.0))
	for i in 60:
		m._process(STEP)
	var e := InputEventKey.new()
	e.keycode = KEY_R
	e.pressed = true
	m._input(e)
	expect(m._balls.size() == m.BALL_COUNT, "R lays the balls out again")
	expect(m._shockwaves.is_empty(), "and clears the shockwaves")
	var still := true
	for ball in m._balls:
		if ball.vel != Vector2.ZERO:
			still = false
	expect(still, "all of them stopped")
