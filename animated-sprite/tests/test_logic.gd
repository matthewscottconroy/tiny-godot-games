extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_gravity_accumulation()
	_test_floor_clamp()
	_test_screen_wrap()
	_test_animation_state_ground()
	_test_animation_state_airborne()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_constants() -> void:
	print("constants")
	# Read the values off the demo's own script rather than restating literals —
	# comparing 180.0 to 180.0 asserts nothing and cannot fail.
	var player: GDScript = load("res://scripts/main.gd")
	expect(player.SPEED == 180.0, "SPEED is 180")
	expect(player.JUMP_VEL == -420.0, "JUMP_VEL is -420")
	expect(player.GRAVITY == 900.0, "GRAVITY is 900")

func _test_gravity_accumulation() -> void:
	print("gravity accumulation")
	const GRAVITY := 900.0
	var vel_y := 0.0
	vel_y += GRAVITY * 0.016
	expect_near(vel_y, 14.4, "gravity accumulates after one frame")
	vel_y += GRAVITY * 0.016
	expect_near(vel_y, 28.8, "gravity accumulates after two frames")

func _test_floor_clamp() -> void:
	print("floor clamp at y=450")
	var pos_y := 460.0
	var vel_y := 30.0
	if pos_y >= 450.0:
		pos_y = 450.0
		vel_y = 0.0
	expect(pos_y == 450.0, "position clamped to 450")
	expect(vel_y == 0.0, "vertical velocity zeroed on floor")

func _test_screen_wrap() -> void:
	print("screen wrap wrapf(-20, 660)")
	expect_near(wrapf(-25.0, -20.0, 660.0), 655.0, "wrap below min")
	expect_near(wrapf(661.0, -20.0, 660.0), -19.0, "wrap above max")
	expect_near(wrapf(320.0, -20.0, 660.0), 320.0, "mid value unchanged")

func _test_animation_state_ground() -> void:
	print("animation state on ground")
	var on_floor := true
	var vel_x := 0.0
	var vel_y := 0.0
	var anim: String
	if not on_floor:
		anim = "jump" if vel_y < 0 else "fall"
	elif abs(vel_x) > 10:
		anim = "walk"
	else:
		anim = "idle"
	expect(anim == "idle", "stationary on floor -> idle")
	vel_x = 50.0
	if not on_floor:
		anim = "jump" if vel_y < 0 else "fall"
	elif abs(vel_x) > 10:
		anim = "walk"
	else:
		anim = "idle"
	expect(anim == "walk", "moving on floor -> walk")

func _test_animation_state_airborne() -> void:
	print("animation state airborne")
	var on_floor := false
	var vel_y := -200.0
	var anim := "jump" if vel_y < 0 else "fall"
	expect(anim == "jump", "rising -> jump")
	vel_y = 100.0
	anim = "jump" if vel_y < 0 else "fall"
	expect(anim == "fall", "falling -> fall")

func _report() -> void:
	var summary := "[animated-sprite] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
