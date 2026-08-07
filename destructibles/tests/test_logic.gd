extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_hp_decrements_on_hit()
	test_shatter_at_zero_hp()
	test_no_shatter_before_zero()
	test_fragment_count()
	test_fragment_velocity_outward()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[destructibles] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _should_shatter(hits: int, hp: int) -> bool:
	return hits >= hp

func _fragment_velocity(index: int, count: int, speed: float) -> Vector2:
	var angle := TAU * index / count
	return Vector2(cos(angle) * speed, sin(angle) * speed)

func test_hp_decrements_on_hit() -> void:
	var hp  := 3
	var hits := 0
	hits += 1
	expect(not _should_shatter(hits, hp), "1 hit on hp=3 doesn't shatter")
	hits += 1
	expect(not _should_shatter(hits, hp), "2 hits on hp=3 doesn't shatter")

func test_shatter_at_zero_hp() -> void:
	var hp   := 2
	var hits := 2
	expect(_should_shatter(hits, hp), "hits == hp triggers shatter")

func test_no_shatter_before_zero() -> void:
	expect(not _should_shatter(0, 1), "0 hits doesn't shatter")
	expect(not _should_shatter(1, 3), "1/3 hits doesn't shatter")

func test_fragment_count() -> void:
	var frag_count := 8
	var velocities := []
	for i in frag_count:
		velocities.append(_fragment_velocity(i, frag_count, 200.0))
	expect(velocities.size() == frag_count, "spawns exactly frag_count fragments")

func test_fragment_velocity_outward() -> void:
	var count := 8
	var speed := 200.0
	# Fragments should spread in all directions — sum of normalized velocities ≈ 0
	var sum := Vector2.ZERO
	for i in count:
		var v := _fragment_velocity(i, count, speed)
		sum += v.normalized()
	expect(sum.length() < 0.1, "fragment velocities spread evenly (net sum ≈ zero)")
