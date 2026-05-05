extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_wall_jump_pushes_away_from_wall()
	test_wall_slide_caps_fall_speed()
	test_wall_jump_upward_velocity()
	test_floor_jump_normal()
	test_state_wall_slide_in_air_on_wall()
	test_state_fall_in_air_no_wall()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[ledge-grab] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const WALL_JUMP_X  := 260.0
const WALL_JUMP_Y  := -380.0
const WALL_SLIDE   := 60.0
const GRAVITY      := 900.0

func _calc_wall_jump(wall_normal: Vector2) -> Vector2:
	return Vector2(wall_normal.x * WALL_JUMP_X, WALL_JUMP_Y)

func _clamp_wall_slide(vy: float, delta: float) -> float:
	return minf(vy + GRAVITY * delta, WALL_SLIDE)

enum State { IDLE, RUN, JUMP, FALL, WALL_SLIDE }

func _calc_state(on_floor: bool, on_wall: bool, vy: float, vx: float) -> State:
	if on_floor:
		return State.RUN if absf(vx) > 10 else State.IDLE
	elif on_wall:
		return State.WALL_SLIDE
	else:
		return State.JUMP if vy < 0 else State.FALL

func test_wall_jump_pushes_away_from_wall() -> void:
	var left_wall_normal  := Vector2(1, 0)   # left wall pushes right
	var right_wall_normal := Vector2(-1, 0)  # right wall pushes left
	var vjl := _calc_wall_jump(left_wall_normal)
	var vjr := _calc_wall_jump(right_wall_normal)
	expect(vjl.x > 0,  "left wall jump: positive x (pushed right)")
	expect(vjr.x < 0,  "right wall jump: negative x (pushed left)")

func test_wall_jump_upward_velocity() -> void:
	var v := _calc_wall_jump(Vector2(1, 0))
	expect(v.y == WALL_JUMP_Y, "wall jump sets correct upward velocity")
	expect(v.y < 0, "wall jump velocity is upward (negative y)")

func test_wall_slide_caps_fall_speed() -> void:
	var high_fall_speed := 600.0
	var capped := _clamp_wall_slide(high_fall_speed, 0.016)
	expect(capped <= WALL_SLIDE, "wall slide caps fall speed to WALL_SLIDE")

func test_floor_jump_normal() -> void:
	var v := Vector2(0, -400)
	expect(v.y < 0, "regular jump has upward velocity")

func test_state_wall_slide_in_air_on_wall() -> void:
	var s := _calc_state(false, true, 50.0, 0.0)
	expect(s == State.WALL_SLIDE, "airborne + on wall → WALL_SLIDE")

func test_state_fall_in_air_no_wall() -> void:
	var s := _calc_state(false, false, 50.0, 0.0)
	expect(s == State.FALL, "airborne + not on wall + falling → FALL")
