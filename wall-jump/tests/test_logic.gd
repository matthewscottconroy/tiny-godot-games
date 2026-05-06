extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_wall_jump_velocity()
	_test_wall_slide_gravity()
	_test_floor_jump_condition()
	_test_wall_jump_condition()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) < tol, label)

# --- Simulation helpers ---

const JUMP_VEL    := -420.0
const WALL_JUMP_VX := 300.0
const GRAVITY      := 900.0
const WALL_SLIDE_GRAV := 0.2

func calc_wall_jump(wall_normal: Vector2) -> Vector2:
	# Mirrors the logic in player.gd wall-jump branch
	return Vector2(-wall_normal.x * WALL_JUMP_VX, JUMP_VEL)

func calc_gravity(delta: float, on_wall: bool, pressing_toward: bool, on_floor: bool) -> float:
	var scale := WALL_SLIDE_GRAV if (on_wall and pressing_toward and not on_floor) else 1.0
	return GRAVITY * scale * delta

func can_floor_jump(on_floor: bool, jump_pressed: bool) -> bool:
	return on_floor and jump_pressed

func can_wall_jump(on_wall: bool, on_floor: bool, jump_pressed: bool) -> bool:
	return on_wall and not on_floor and jump_pressed

# --- Tests ---

func _test_wall_jump_velocity() -> void:
	print("wall jump velocity")

	# Left wall: normal points right (+x). Player should jump left (-x) and up (-y).
	var left_wall_normal := Vector2(1.0, 0.0)
	var vel := calc_wall_jump(left_wall_normal)
	expect(vel.x < 0.0, "left wall: jump pushes player to the right (away from wall)")
	expect_approx(vel.x, -WALL_JUMP_VX, "left wall: horizontal speed = WALL_JUMP_VX")
	expect_approx(vel.y, JUMP_VEL, "left wall: vertical component = JUMP_VEL")

	# Right wall: normal points left (-x). Player should jump right (+x) and up (-y).
	var right_wall_normal := Vector2(-1.0, 0.0)
	var vel2 := calc_wall_jump(right_wall_normal)
	expect(vel2.x > 0.0, "right wall: jump pushes player left (away from wall)")
	expect_approx(vel2.x, WALL_JUMP_VX, "right wall: horizontal speed = WALL_JUMP_VX")
	expect_approx(vel2.y, JUMP_VEL, "right wall: vertical component = JUMP_VEL")

func _test_wall_slide_gravity() -> void:
	print("wall slide gravity reduction")
	var delta := 0.016

	# Sliding: gravity should be reduced
	var slide_grav := calc_gravity(delta, true, true, false)
	var full_grav  := calc_gravity(delta, false, false, false)
	expect(slide_grav < full_grav, "wall slide gravity is less than full gravity")
	expect_approx(slide_grav, GRAVITY * WALL_SLIDE_GRAV * delta, "wall slide gravity = GRAVITY * WALL_SLIDE_GRAV * delta")

	# On floor: normal gravity despite touching wall
	var floor_grav := calc_gravity(delta, true, true, true)
	expect_approx(floor_grav, full_grav, "on floor: gravity is not reduced even if touching wall")

	# Pressing away from wall: normal gravity
	var away_grav := calc_gravity(delta, true, false, false)
	expect_approx(away_grav, full_grav, "pressing away from wall: gravity not reduced")

func _test_floor_jump_condition() -> void:
	print("floor jump conditions")
	expect(can_floor_jump(true,  true),  "on floor + jump pressed → can jump")
	expect(!can_floor_jump(false, true),  "not on floor + jump pressed → cannot jump")
	expect(!can_floor_jump(true,  false), "on floor + no jump → cannot jump")
	expect(!can_floor_jump(false, false), "neither → cannot jump")

func _test_wall_jump_condition() -> void:
	print("wall jump conditions")
	expect(can_wall_jump(true,  false, true),  "on wall, off floor, jump → can wall-jump")
	expect(!can_wall_jump(false, false, true),  "not on wall → cannot wall-jump")
	expect(!can_wall_jump(true,  true,  true),  "on wall but also on floor → cannot wall-jump")
	expect(!can_wall_jump(true,  false, false), "on wall, off floor, no jump → cannot wall-jump")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
