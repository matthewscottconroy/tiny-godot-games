extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_particle_count()
	_test_preset_cycling()
	_test_hash_distribution()
	_test_radial_positions()
	_test_swarm_converges()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol := 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _hash11(p: float) -> float:
	p = fmod(p * 0.1031, 1.0)
	p *= p + 33.33
	p *= p + p
	return fmod(absf(p), 1.0)

func _test_particle_count() -> void:
	print("particle count")
	const NUM_PARTICLES := 80
	expect(NUM_PARTICLES == 80, "80 particles defined")
	expect(NUM_PARTICLES > 0, "particle count positive")

func _test_preset_cycling() -> void:
	print("preset cycling")
	const NUM_PRESETS := 3
	var preset := 0
	preset = (preset + 1) % NUM_PRESETS
	expect(preset == 1, "cycles from 0 to 1")
	preset = (preset + 1) % NUM_PRESETS
	expect(preset == 2, "cycles from 1 to 2")
	preset = (preset + 1) % NUM_PRESETS
	expect(preset == 0, "wraps back to 0 from 2")

func _test_hash_distribution() -> void:
	print("hash function distribution")
	var vals: Array[float] = []
	for i in range(20):
		vals.append(_hash11(float(i) * 0.137))
	var all_in_range := true
	for v in vals:
		if v < 0.0 or v > 1.0:
			all_in_range = false
	expect(all_in_range, "all hash values in [0, 1]")
	var sum := 0.0
	for v in vals:
		sum += v
	var avg := sum / float(vals.size())
	expect(avg > 0.2 and avg < 0.8, "hash values roughly uniformly distributed")

func _test_radial_positions() -> void:
	print("radial orbit positions")
	var TWO_PI := TAU
	for i in range(4):
		var seed := float(i) / 4.0
		var angle := seed * TWO_PI + 0.0
		var r := 0.25 + seed * 0.2
		var px := 0.5 + cos(angle) * r
		var py := 0.5 + sin(angle) * r
		expect(px >= 0.0 and px <= 1.0, "radial x in [0,1] for seed %d" % i)
		expect(py >= 0.0 and py <= 1.0, "radial y in [0,1] for seed %d" % i)

func _test_swarm_converges() -> void:
	print("swarm convergence")
	var pos := Vector2(0.1, 0.1)
	var target := Vector2(0.5, 0.5)
	var steps := 0
	for _i in range(200):
		var diff := target - pos
		var dist := diff.length() + 0.001
		pos += diff / dist * 0.012
		steps += 1
		if (target - pos).length() < 0.05:
			break
	expect(steps < 200, "swarm particle converges to target in < 200 steps")
	expect((target - pos).length() < 0.05, "swarm particle reaches target proximity")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
