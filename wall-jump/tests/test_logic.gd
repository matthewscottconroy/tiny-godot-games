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
	_test_a_wall_jump_needs_a_wall_and_no_floor()
	_test_the_facing_holds_when_the_key_is_released()
	_test_horizontal_speed_is_driven_then_eased()
	await _test_the_player_stays_down_untouched()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## A wall jump needs all three conditions, and the floor jump wins in a corner.
func _test_a_wall_jump_needs_a_wall_and_no_floor() -> void:
	print("when a wall jump fires")
	var Player := load("res://scripts/player.gd")

	expect(Player.can_wall_jump(true, true, false),
		"pressed, on a wall, airborne — that is a wall jump")
	expect(not Player.can_wall_jump(false, true, false),
		"without a press, nothing happens")
	expect(not Player.can_wall_jump(true, false, false),
		"in mid-air with no wall, there is nothing to jump off")
	expect(not Player.can_wall_jump(true, true, true),
		"and in a corner touching both, the floor jump is the one that fires — "
		+ "a wall jump from the ground flings the player off a wall they were "
		+ "only leaning on")
	expect(not Player.can_wall_jump(true, false, true),
		"standing on the floor with no wall is an ordinary jump")

## The facing survives a released key.
func _test_the_facing_holds_when_the_key_is_released() -> void:
	print("facing")
	var Player := load("res://scripts/player.gd")
	expect(Player.facing_for(1.0, -1.0) == 1.0, "pushing right faces right")
	expect(Player.facing_for(-1.0, 1.0) == -1.0, "pushing left faces left")
	expect(Player.facing_for(0.0, -1.0) == -1.0,
		"releasing leaves it facing the way it was going")
	expect(Player.facing_for(0.0, 1.0) == 1.0, "in either direction")

## Held keys drive; released keys coast to a stop.
func _test_horizontal_speed_is_driven_then_eased() -> void:
	print("horizontal movement")
	var Player := load("res://scripts/player.gd")

	expect(Player.horizontal_velocity(1.0, 0.0) == Player.SPEED,
		"pushing right drives at full speed (%.0f)" % Player.horizontal_velocity(1.0, 0.0))
	expect(Player.horizontal_velocity(-1.0, 0.0) == -Player.SPEED,
		"and pushing left, the other way")

	# A held key overrides whatever the body was doing, so a wall jump's
	# sideways launch can be steered out of.
	expect(Player.horizontal_velocity(1.0, -400.0) == Player.SPEED,
		"a held key overrides the current speed (%.0f)"
		% Player.horizontal_velocity(1.0, -400.0))

	# Released, it eases toward zero rather than snapping — and does not
	# overshoot past it.
	var eased: float = Player.horizontal_velocity(0.0, 50.0)
	expect(eased >= 0.0 and eased < 50.0,
		"releasing eases toward a stop without overshooting (%.0f)" % eased)
	expect(Player.horizontal_velocity(0.0, 0.0) == 0.0,
		"and standing still stays still")
	var from_left: float = Player.horizontal_velocity(0.0, -50.0)
	expect(from_left <= 0.0 and from_left > -50.0,
		"easing works from the other direction too (%.0f)" % from_left)

## Nothing pressed, nothing happens.
func _test_the_player_stays_down_untouched() -> void:
	print("standing still")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	var player: CharacterBody2D = scene.find_child("Player", true, false)
	expect(player != null, "the scene has a player")
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with no key pressed (rose %.1f px)" % (resting - highest))
	scene.queue_free()

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
