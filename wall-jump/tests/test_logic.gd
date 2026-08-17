extends Node

# Drives the real player from scripts/player.gd. Writing this suite found a bug
# the inline copy had hidden since the demo was written: the wall jump launched
# INTO the wall — see below and docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_wall_jump_launches_away_from_the_wall()
	_test_wall_jump_is_symmetric()
	_test_wall_jump_goes_up()
	_test_sliding_requires_pressing_into_the_wall()
	_test_sliding_requires_being_airborne()
	_test_sliding_reduces_gravity()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[wall-jump] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Verified against the engine: a body pressed against a wall on its RIGHT
# reports get_wall_normal() == (-1, 0). The normal points away from the wall.
const WALL_ON_RIGHT := -1.0
const WALL_ON_LEFT := 1.0
const PUSH_RIGHT := 1.0
const PUSH_LEFT := -1.0

var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	add_child(p)
	return p

func _test_wall_jump_launches_away_from_the_wall() -> void:
	print("the launch direction")
	# This is the assertion that caught the bug. The demo negated the normal, so
	# jumping off a wall on your right threw you further right — back into it.
	var p := _make()
	var v: Vector2 = p.wall_jump_velocity(WALL_ON_RIGHT)
	expect(v.x < 0.0, "a wall on the right launches you LEFT, away from it")

func _test_wall_jump_is_symmetric() -> void:
	print("both sides")
	var p := _make()
	var right: Vector2 = p.wall_jump_velocity(WALL_ON_RIGHT)
	var left: Vector2 = p.wall_jump_velocity(WALL_ON_LEFT)
	expect(left.x > 0.0, "a wall on the left launches you RIGHT")
	expect(is_equal_approx(left.x, -right.x), "the two are mirror images")
	expect(is_equal_approx(absf(left.x), p.WALL_JUMP_VX), "at the configured speed")

func _test_wall_jump_goes_up() -> void:
	print("the vertical component")
	var p := _make()
	expect(p.wall_jump_velocity(WALL_ON_RIGHT).y == p.JUMP_VEL,
		"a wall jump rises by exactly JUMP_VEL")

func _test_sliding_requires_pressing_into_the_wall() -> void:
	print("slide intent")
	var p := _make()
	expect(p.is_wall_sliding(PUSH_RIGHT, true, false, WALL_ON_RIGHT),
		"holding toward the wall slides")
	expect(not p.is_wall_sliding(PUSH_LEFT, true, false, WALL_ON_RIGHT),
		"holding away from it does not")
	expect(not p.is_wall_sliding(0.0, true, false, WALL_ON_RIGHT),
		"neither does touching it with no input")

func _test_sliding_requires_being_airborne() -> void:
	print("floor beats wall")
	var p := _make()
	expect(not p.is_wall_sliding(PUSH_RIGHT, true, true, WALL_ON_RIGHT),
		"standing next to a wall is not sliding down it")
	expect(not p.is_wall_sliding(PUSH_RIGHT, false, false, 0.0),
		"and with no wall there is nothing to slide on")

func _test_sliding_reduces_gravity() -> void:
	print("reduced gravity")
	var p := _make()
	expect(p.gravity_scale(true) < p.gravity_scale(false),
		"a slide falls more slowly than a free fall")
	expect(p.gravity_scale(true) > 0.0, "but still falls")
	expect(is_equal_approx(p.gravity_scale(false), 1.0), "normal fall is unscaled")
