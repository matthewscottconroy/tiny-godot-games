extends Node

# Drives the real player and hook from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_idle_on_the_ground()
	_test_gravity_and_landing()
	_test_firing_the_hook()
	_test_the_hook_flies_towards_the_click()
	_test_a_hook_that_hits_a_platform_attaches()
	_test_a_hook_that_misses_everything_is_dropped()
	_test_clicking_while_the_hook_flies_cancels_it()
	_test_the_rope_does_not_stretch()
	_test_the_swing_loses_energy()
	_test_firing_again_while_attached_re_hooks()
	_test_r_puts_the_player_back()
	_test_walls_push_the_player_out_sideways()
	_test_a_key_release_is_not_a_reset()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[grapple-hook] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _run(m: Node2D, frames: int) -> void:
	for i in frames:
		m._physics_process(STEP)

func _fire_at(m: Node2D, target: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = target
	m._input(e)

## A point on the ceiling-most platform, well above the player.
func _anchor_point(m: Node2D) -> Vector2:
	var high: Rect2 = m.LEVEL[1]
	for rect: Rect2 in m.LEVEL:
		if rect.size.x < 400.0 and rect.position.y < high.position.y:
			high = rect
	return high.position + high.size * 0.5

func _test_it_starts_idle_on_the_ground() -> void:
	print("the start")
	var m := _make()
	expect(m._gstate == m.GState.IDLE, "the hook starts stowed")
	_run(m, 120)
	expect(m._on_floor, "and the player is standing on the level")

func _test_gravity_and_landing() -> void:
	print("falling")
	var m := _make()
	m._pos = Vector2(300.0, 100.0)
	m._vel = Vector2.ZERO
	m._physics_process(STEP)
	expect(m._vel.y > 0.0, "an unhooked player falls")
	_run(m, 300)
	expect(m._on_floor, "until the ground stops them")
	expect(is_zero_approx(m._vel.y), "with the fall arrested")

func _test_firing_the_hook() -> void:
	print("firing")
	var m := _make()
	_fire_at(m, m._pos + Vector2(0.0, -200.0))
	expect(m._gstate == m.GState.FLYING, "clicking fires the hook")
	expect(m._hook_pos == m._pos, "which leaves from the player")
	expect(m._hook_vel.length() > 0.0, "travelling")

func _test_the_hook_flies_towards_the_click() -> void:
	print("aim")
	var m := _make()
	var target: Vector2 = m._pos + Vector2(200.0, -100.0)
	_fire_at(m, target)
	var aim: Vector2 = m._pos.direction_to(target)
	expect(m._hook_vel.normalized().dot(aim) > 0.99, "the hook flies at the cursor")
	expect(is_equal_approx(m._hook_vel.length(), m.HOOK_SPEED), "at the hook speed")

	var started: Vector2 = m._hook_pos
	m._physics_process(STEP)
	expect(m._hook_pos.distance_to(started) > 0.0, "and travels while it flies")

func _test_a_hook_that_hits_a_platform_attaches() -> void:
	print("attaching")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	_run(m, 120)
	expect(m._gstate == m.GState.ATTACHED, "a hook that reaches a platform bites")
	expect(m._rope_len > 0.0, "and the rope is measured from where the player was")
	var on_a_platform := false
	for rect: Rect2 in m.LEVEL:
		if rect.grow(0.001).has_point(m._hook_pos):
			on_a_platform = true
	expect(on_a_platform, "with the hook left on the platform it hit")

func _test_a_hook_that_misses_everything_is_dropped() -> void:
	print("missing")
	var m := _make()
	# Straight up from the starting position, where nothing overhangs: the level
	# is walled left and right, so the only way off the screen is the top.
	_fire_at(m, m._pos + Vector2(0.0, -400.0))
	_run(m, 240)
	expect(m._gstate != m.GState.FLYING, "a hook that leaves the screen stops flying")
	expect(m._gstate == m.GState.IDLE, "and is stowed rather than left attached to nothing")

func _test_clicking_while_the_hook_flies_cancels_it() -> void:
	print("cancelling")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	expect(m._gstate == m.GState.FLYING, "hook away")
	_fire_at(m, m._pos + Vector2(100.0, 0.0))
	expect(m._gstate == m.GState.IDLE, "a second click recalls it")

func _test_the_rope_does_not_stretch() -> void:
	print("the rope")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	_run(m, 120)
	expect(m._gstate == m.GState.ATTACHED, "attached")
	var longest := 0.0
	for i in 300:
		m._physics_process(STEP)
		longest = maxf(longest, m._pos.distance_to(m._hook_pos))
	expect(longest <= m._rope_len + 1.0,
		"swinging never stretches the rope beyond its length (%.1f vs %.1f)" % [longest, m._rope_len])

func _test_the_swing_loses_energy() -> void:
	print("damping")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	_run(m, 120)
	expect(m._gstate == m.GState.ATTACHED, "attached")
	m._vel = Vector2(400.0, 0.0)
	var early := 0.0
	for i in 60:
		m._physics_process(STEP)
		early = maxf(early, m._vel.length())
	var late := 0.0
	for i in 600:
		m._physics_process(STEP)
		late = maxf(late, m._vel.length())
	expect(late < early, "a swing winds down rather than gaining speed each pass")

func _test_firing_again_while_attached_re_hooks() -> void:
	print("re-hooking")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	_run(m, 120)
	expect(m._gstate == m.GState.ATTACHED, "attached")
	_fire_at(m, m._pos + Vector2(-200.0, -200.0))
	expect(m._gstate == m.GState.FLYING, "firing again lets go and throws a new hook")

func _test_r_puts_the_player_back() -> void:
	print("reset")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	_run(m, 200)
	var e := InputEventKey.new()
	e.keycode = KEY_R
	e.pressed = true
	m._input(e)
	expect(m._gstate == m.GState.IDLE, "R stows the hook")
	expect(m._vel == Vector2.ZERO, "stops the player")
	expect(m._pos == Vector2(300.0, 400.0), "and puts them back at the start")

## The level's left and right walls, whichever way round they are listed.
func _side_walls(m: Node2D) -> Array[Rect2]:
	var walls: Array[Rect2] = []
	for rect: Rect2 in m.LEVEL:
		if rect.size.y > rect.size.x:
			walls.append(rect)
	return walls

func _test_walls_push_the_player_out_sideways() -> void:
	print("side walls")
	var m := _make()
	var walls := _side_walls(m)
	expect(walls.size() == 2, "the level is walled on both sides")

	for wall in walls:
		var from_the_left: bool = wall.position.x > 320.0
		var player := _make()
		# Just inside the face the player would arrive at. Dead centre would be
		# a tie between the two push-out directions, which says nothing about
		# which one the resolver should pick.
		var entry: float = wall.position.x + 2.0 if from_the_left else wall.end.x - 2.0
		player._pos = Vector2(entry, 200.0)
		player._vel = Vector2(200.0 if from_the_left else -200.0, 0.0)
		player._resolve_collisions()
		if from_the_left:
			expect(player._pos.x <= wall.position.x - player.PLAYER_R + 0.001,
				"a player walking into the right wall is pushed back to its left face")
		else:
			expect(player._pos.x >= wall.position.x + wall.size.x + player.PLAYER_R - 0.001,
				"and one walking into the left wall out to its right face")
		expect(is_zero_approx(player._vel.x), "with the sideways speed stopped")

	# Moving away from a wall it is already overlapping, the player keeps their
	# speed — otherwise every brush against a wall would kill the swing.
	var leaving := _make()
	var right_wall: Rect2 = walls[0] if walls[0].position.x > 320.0 else walls[1]
	leaving._pos = Vector2(right_wall.position.x + 2.0, 200.0)
	leaving._vel = Vector2(-200.0, 0.0)
	leaving._resolve_collisions()
	expect(leaving._vel.x < 0.0, "a player already heading away from a wall keeps their speed")

func _test_a_key_release_is_not_a_reset() -> void:
	print("key releases")
	var m := _make()
	_fire_at(m, _anchor_point(m))
	_run(m, 60)
	var state: int = m._gstate
	var release := InputEventKey.new()
	release.keycode = KEY_R
	release.pressed = false
	m._input(release)
	expect(m._gstate == state, "letting go of R does not reset the run")
