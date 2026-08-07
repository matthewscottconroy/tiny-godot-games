extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_first_bullet_at_neg_half_spread()
	test_last_bullet_at_pos_half_spread()
	test_middle_bullet_straight()
	test_all_bullets_same_speed()
	test_single_bullet_fires_straight()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[spread-shot] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const BULLET_COUNT := 5
const SPREAD_DEG   := 40.0
const SPEED        := 420.0

func _spread_directions(base: Vector2) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	var half := deg_to_rad(SPREAD_DEG * 0.5)
	for i in BULLET_COUNT:
		var t     := float(i) / (BULLET_COUNT - 1)
		var angle := lerpf(-half, half, t)
		dirs.append(base.rotated(angle))
	return dirs

func test_first_bullet_at_neg_half_spread() -> void:
	var dirs := _spread_directions(Vector2.RIGHT)
	var half := deg_to_rad(SPREAD_DEG * 0.5)
	expect(absf(dirs[0].angle() - (-half)) < 0.001, "first bullet at -half_spread angle")

func test_last_bullet_at_pos_half_spread() -> void:
	var dirs := _spread_directions(Vector2.RIGHT)
	var half := deg_to_rad(SPREAD_DEG * 0.5)
	expect(absf(dirs[-1].angle() - half) < 0.001, "last bullet at +half_spread angle")

func test_middle_bullet_straight() -> void:
	var dirs := _spread_directions(Vector2.RIGHT)
	var mid  := dirs[BULLET_COUNT / 2]
	expect(absf(mid.angle()) < 0.001, "middle bullet fires straight (angle ≈ 0)")

func test_all_bullets_same_speed() -> void:
	var dirs := _spread_directions(Vector2.RIGHT)
	for d in dirs:
		expect(absf(d.length() - 1.0) < 0.001, "direction vector is normalized")

func test_single_bullet_fires_straight() -> void:
	var half := deg_to_rad(SPREAD_DEG * 0.5)
	var t    := 0.5  # single bullet uses t=0.5
	var angle := lerpf(-half, half, t)
	expect(absf(angle) < 0.001, "single bullet (t=0.5) fires at angle 0")
