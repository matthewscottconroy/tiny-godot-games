extends Node

# Drives the real player from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_player_starts_on_the_ground()
	_test_gravity_and_landing()
	_test_jumping_from_the_ground()
	_test_walking()
	_test_falling_past_a_ledge_grabs_it()
	_test_rising_past_a_ledge_does_not()
	_test_a_ledge_out_of_reach_is_not_grabbed()
	_test_hanging_holds_the_player_still()
	_test_jumping_pulls_up_onto_the_platform()
	_test_pressing_down_lets_go()
	_test_the_player_stays_on_screen()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[ledge-hang] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _run(m: Node2D, frames: int, axis: float = 0.0) -> void:
	for i in frames:
		m.tick(STEP, axis, false, false)

## Put the player just above a platform's left corner, falling.
func _falling_past_left_corner(m: Node2D, plat: Rect2) -> void:
	m._pos = Vector2(plat.position.x - m.PLAYER_W * 0.5, plat.position.y + m.PLAYER_H)
	m._vel = Vector2(0.0, 60.0)

func _a_platform(m: Node2D) -> Rect2:
	return m._platforms[1]

func _test_the_player_starts_on_the_ground() -> void:
	print("the start")
	var m := _make()
	expect(m._state == m.PState.NORMAL, "the player starts standing, not hanging")
	expect(m._platforms.size() > 1, "with platforms to climb")

func _test_gravity_and_landing() -> void:
	print("falling")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	m._vel = Vector2.ZERO
	m.tick(STEP, 0.0, false, false)
	expect(m._vel.y > 0.0, "the player falls")
	_run(m, 300)
	expect(m._on_floor, "and lands on the ground below")
	expect(is_zero_approx(m._vel.y), "with the fall stopped")

func _test_jumping_from_the_ground() -> void:
	print("jumping")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	_run(m, 300)
	expect(m._on_floor, "standing on the floor")
	m.tick(STEP, 0.0, true, false)
	expect(m._vel.y < 0.0, "jump sends the player up")

	var airborne := _make()
	airborne._pos = Vector2(320.0, 100.0)
	airborne.tick(STEP, 0.0, true, false)
	expect(airborne._vel.y > 0.0, "but a jump in mid-air does nothing")

func _test_walking() -> void:
	print("walking")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	_run(m, 300)
	var x: float = m._pos.x
	_run(m, 30, 1.0)
	expect(m._pos.x > x, "holding right walks right")
	_run(m, 60, -1.0)
	expect(m._pos.x < x, "and left walks left")

func _test_falling_past_a_ledge_grabs_it() -> void:
	print("grabbing")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "falling past a corner catches it")
	expect(m._hang_edge.x == plat.position.x, "the corner that was passed")

func _test_rising_past_a_ledge_does_not() -> void:
	print("on the way up")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	# Same place, travelling upwards: a player who jumped past the ledge should
	# clear it rather than being yanked into a hang.
	m._vel = Vector2(0.0, -60.0)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.NORMAL, "a rising player does not grab the ledge")

func _test_a_ledge_out_of_reach_is_not_grabbed() -> void:
	print("out of reach")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m._pos.x -= m.LEDGE_GRAB_RANGE * 4.0
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.NORMAL, "a corner too far to the side is not grabbed")

	var below := _make()
	_falling_past_left_corner(below, plat)
	below._pos.y += below.LEDGE_VERT_RANGE * 4.0
	below.tick(STEP, 0.0, false, false)
	expect(below._state == below.PState.NORMAL, "and neither is one well above the player's head")

func _test_hanging_holds_the_player_still() -> void:
	print("hanging")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "hanging")
	# The grab happens at the end of a falling frame; the snap to the ledge
	# happens on the next one, so that is where the hang position settles.
	m.tick(STEP, 0.0, false, false)
	var hung_at: Vector2 = m._pos
	_run(m, 60, 1.0)
	expect(m._pos == hung_at, "gravity and the walk keys do nothing while hanging")
	expect(m._vel == Vector2.ZERO, "the player is held in place")

func _test_jumping_pulls_up_onto_the_platform() -> void:
	print("climbing up")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "hanging from the ledge")
	m.tick(STEP, 0.0, true, false)
	expect(m._state == m.PState.NORMAL, "jump lets go of the ledge")
	expect(m._vel.y < 0.0, "with an upward boost to clear it")
	expect(m._pos.y < plat.position.y + m.PLAYER_H, "and the player is lifted above the edge")

func _test_pressing_down_lets_go() -> void:
	print("dropping off")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	m.tick(STEP, 0.0, false, true)
	expect(m._state == m.PState.NORMAL, "down lets go")
	expect(m._vel.y > 0.0, "and the player drops")

func _test_the_player_stays_on_screen() -> void:
	print("the edges of the screen")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	_run(m, 600, -1.0)
	expect(m._pos.x >= m.PLAYER_W * 0.5, "walking left stops at the edge of the screen")
	_run(m, 900, 1.0)
	expect(m._pos.x <= 640.0 - m.PLAYER_W * 0.5, "and walking right at the other one")
