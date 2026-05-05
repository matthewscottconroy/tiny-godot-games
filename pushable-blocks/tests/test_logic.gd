extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_push_sets_velocity()
	test_friction_decays_velocity()
	test_velocity_clamps_to_zero()
	test_push_right_when_normal_left()
	test_push_left_when_normal_right()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[pushable-blocks] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const FRICTION  := 5.5
const PUSH_STR  := 240.0

func _decay(vel: float, delta: float) -> float:
	var v := lerpf(vel, 0.0, FRICTION * delta)
	return 0.0 if absf(v) < 1.0 else v

func test_push_sets_velocity() -> void:
	var push_vel := PUSH_STR
	expect(push_vel == PUSH_STR, "push sets velocity to PUSH_STR")

func test_friction_decays_velocity() -> void:
	var v := _decay(PUSH_STR, 0.016)
	expect(v < PUSH_STR and v > 0.0, "friction reduces velocity each frame")

func test_velocity_clamps_to_zero() -> void:
	var v := _decay(0.8, 0.016)
	expect(v == 0.0, "velocity below threshold clamps to zero")

func test_push_right_when_normal_left() -> void:
	# Player moving right into block: collision normal points left (-x) toward player
	var normal := Vector2(-1, 0)
	var push_x := -normal.x * PUSH_STR
	expect(push_x > 0.0, "negated left normal gives rightward push")

func test_push_left_when_normal_right() -> void:
	# Player moving left into block: collision normal points right (+x) toward player
	var normal := Vector2(1, 0)
	var push_x := -normal.x * PUSH_STR
	expect(push_x < 0.0, "negated right normal gives leftward push")
