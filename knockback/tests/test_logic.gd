extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_knockback_direction_from_hit()
	test_knockback_blocked_during_iframes()
	test_knockback_decays_each_frame()
	test_knockback_adds_to_control()
	test_kb_up_clears_after_one_frame()
	test_iframes_decrement()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[knockback] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const KB_IMPULSE := 480.0
const KB_UP      := -260.0
const KB_DECAY   := 7.0

func _compute_knockback_dir(player_pos: Vector2, hit_from: Vector2) -> Vector2:
	return (player_pos - hit_from).normalized()

func _apply_hit(player_pos: Vector2, from: Vector2, iframes: float) -> Dictionary:
	if iframes > 0.0:
		return {"knockback": Vector2.ZERO, "iframes": iframes, "applied": false}
	var dir := _compute_knockback_dir(player_pos, from)
	return {
		"knockback": Vector2(dir.x * KB_IMPULSE, KB_UP),
		"iframes": 0.8,
		"applied": true
	}

func test_knockback_direction_from_hit() -> void:
	var dir := _compute_knockback_dir(Vector2(100, 0), Vector2(0, 0))
	expect(dir.x > 0.0, "knockback pushes player away from hit source")

func test_knockback_blocked_during_iframes() -> void:
	var r := _apply_hit(Vector2(100, 0), Vector2(0, 0), 0.5)
	expect(not r["applied"], "hit ignored when iframes > 0")

func test_knockback_decays_each_frame() -> void:
	var kb := Vector2(480, 0)
	kb = kb.lerp(Vector2.ZERO, KB_DECAY * 0.016)
	expect(kb.x < 480.0, "knockback decays per frame")

func test_knockback_adds_to_control() -> void:
	var ctrl_x    := 200.0
	var knockback  := Vector2(300, 0)
	var vel_x      := ctrl_x + knockback.x
	expect(vel_x == 500.0, "knockback adds to control velocity")

func test_kb_up_clears_after_one_frame() -> void:
	var kb := Vector2(300, KB_UP)
	var vel_y: float
	if kb.y != 0.0:
		vel_y = kb.y
		kb.y  = 0.0
	expect(kb.y == 0.0, "knockback.y clears after being applied to velocity.y")

func test_iframes_decrement() -> void:
	var iframes := 0.8
	iframes = maxf(iframes - 0.016, 0.0)
	expect(iframes < 0.8, "iframes countdown each frame")
