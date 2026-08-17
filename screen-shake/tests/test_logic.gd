extends Node

# Drives the real shake from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_step_count_follows_duration()
	_test_a_longer_shake_has_more_steps()
	_test_a_zero_duration_shake_only_settles()
	_test_offsets_stay_within_strength()
	_test_strength_scales_the_offsets()
	_test_shake_ends_centred()
	_test_offsets_actually_vary()
	_test_the_last_step_settles_more_slowly()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[screen-shake] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

# Left out of the tree on purpose: shake_offsets() is pure, and staying out
# means no Camera2D child is needed. Node is not RefCounted, so free() by hand.
func _make() -> Node2D:
	return _script.new()

func _test_step_count_follows_duration() -> void:
	print("step count")
	var m := _make()
	expect(m.shake_steps(0.4) == 10, "0.4s of shake is 10 steps at 0.04s each")
	expect(m.shake_steps(0.2) == 5, "and half as long is half as many")
	m.free()

func _test_a_longer_shake_has_more_steps() -> void:
	print("duration scaling")
	var m := _make()
	var short_shake: PackedVector2Array = m.shake_offsets(0.2, 12.0)
	var long_shake: PackedVector2Array = m.shake_offsets(0.8, 12.0)
	expect(long_shake.size() > short_shake.size(), "a longer shake tweens through more offsets")
	m.free()

func _test_a_zero_duration_shake_only_settles() -> void:
	print("degenerate duration")
	var m := _make()
	expect(m.shake_steps(0.0) == 0, "no duration means no shake steps")
	expect(m.shake_steps(-1.0) == 0, "and a negative duration does not go negative")
	var offsets: PackedVector2Array = m.shake_offsets(0.0, 12.0)
	expect(offsets.size() == 1, "only the return to centre remains")
	m.free()

func _test_offsets_stay_within_strength() -> void:
	print("strength bounds")
	var m := _make()
	var strength := 12.0
	var offsets: PackedVector2Array = m.shake_offsets(0.4, strength)
	var inside := true
	for o in offsets:
		if absf(o.x) > strength or absf(o.y) > strength:
			inside = false
	expect(inside, "no offset exceeds the requested strength on either axis")
	m.free()

func _test_strength_scales_the_offsets() -> void:
	print("strength scaling")
	var m := _make()
	# A weak shake should never reach as far as a strong one. Sampling a lot of
	# offsets makes the comparison stable despite the randomness.
	var weak := 0.0
	var strong := 0.0
	for i in 20:
		for o in m.shake_offsets(0.4, 2.0):
			weak = maxf(weak, absf(o.x))
		for o in m.shake_offsets(0.4, 40.0):
			strong = maxf(strong, absf(o.x))
	expect(strong > weak, "a stronger shake reaches further")
	expect(weak <= 2.0, "and a weak one stays small")
	m.free()

func _test_shake_ends_centred() -> void:
	print("settling")
	var m := _make()
	for duration in [0.0, 0.2, 0.4, 1.0]:
		var offsets: PackedVector2Array = m.shake_offsets(duration, 12.0)
		expect(offsets[offsets.size() - 1] == Vector2.ZERO,
			"a %.1fs shake ends back at centre" % duration)
	m.free()

func _test_offsets_actually_vary() -> void:
	print("randomness")
	var m := _make()
	var offsets: PackedVector2Array = m.shake_offsets(1.0, 12.0)
	var distinct := {}
	for o in offsets:
		distinct[o] = true
	expect(distinct.size() > 2, "the offsets differ from each other — that is the shake")
	m.free()

func _test_the_last_step_settles_more_slowly() -> void:
	print("step timing")
	var m := _make()
	var count := 11
	expect(is_equal_approx(m.step_duration(count - 1, count), m.SETTLE_TIME),
		"the final return to centre uses the settle timing")
	expect(is_equal_approx(m.step_duration(0, count), m.STEP_TIME),
		"the first jolt does not")
	expect(is_equal_approx(m.step_duration(count - 2, count), m.STEP_TIME),
		"nor does the one just before the end")
	expect(m.SETTLE_TIME > m.STEP_TIME, "settling is the slower of the two")
	m.free()
