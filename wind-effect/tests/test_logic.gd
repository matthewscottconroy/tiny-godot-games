extends Node

var _pass := 0
var _fail := 0

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[wind-effect] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# --- Logic helpers ---

func _wind_vector(wind_angle: float, wind_strength: float) -> Vector2:
	return Vector2(cos(wind_angle), sin(wind_angle)) * wind_strength

func _particle_lifetime_alpha(lifetime: float, max_lifetime: float) -> float:
	return lifetime / max_lifetime

func _particle_offscreen(pos: Vector2) -> bool:
	return pos.x > 700.0 or pos.x < -60.0 or pos.y > 540.0 or pos.y < -60.0

func _apply_wind_to_particle(vel: Vector2, wind: Vector2, delta: float, gravity: float) -> Vector2:
	vel += wind * delta + Vector2(0.0, gravity * delta)
	vel *= 0.98
	return vel

# --- Tests ---

func _test_wind_vector() -> void:
	var wv := _wind_vector(0.0, 60.0)
	expect(abs(wv.x - 60.0) < 0.001, "wind_vector: angle=0, strength=60 → x=60")
	expect(abs(wv.y) < 0.001, "wind_vector: angle=0, strength=60 → y=0")

func _test_wind_vector_up() -> void:
	var wv := _wind_vector(-PI / 2.0, 60.0)
	expect(abs(wv.x) < 0.001, "wind_vector_up: angle=-PI/2 → x≈0")
	expect(abs(wv.y - (-60.0)) < 0.001, "wind_vector_up: angle=-PI/2, strength=60 → y=-60 (upward)")

func _test_particle_drift() -> void:
	var vel := Vector2(0.0, 0.0)
	var wind := Vector2(60.0, 0.0)
	var delta := 1.0
	var gravity := 40.0
	var new_vel := _apply_wind_to_particle(vel, wind, delta, gravity)
	# After one step: vel += (60,0)*1 + (0,40)*1 = (60,40), then *0.98 = (58.8, 39.2)
	expect(abs(new_vel.x - 58.8) < 0.01, "particle_drift: vel.x after wind+damping ≈ 58.8")
	expect(abs(new_vel.y - 39.2) < 0.01, "particle_drift: vel.y after gravity+damping ≈ 39.2")

func _test_lifetime_alpha() -> void:
	var alpha := _particle_lifetime_alpha(2.0, 4.0)
	expect(abs(alpha - 0.5) < 0.001, "lifetime_alpha: lifetime=2.0, max=4.0 → alpha=0.5")
	var full_alpha := _particle_lifetime_alpha(4.0, 4.0)
	expect(abs(full_alpha - 1.0) < 0.001, "lifetime_alpha: lifetime=max → alpha=1.0")
	var zero_alpha := _particle_lifetime_alpha(0.0, 4.0)
	expect(abs(zero_alpha) < 0.001, "lifetime_alpha: lifetime=0 → alpha=0.0")

func _test_offscreen_respawn() -> void:
	var off1 := Vector2(-70.0, -70.0)   # past the -60 margin on both axes
	expect(_particle_offscreen(off1) == true, "offscreen: pos (-70,-70) → offscreen → respawn")
	var off2 := Vector2(710.0, 240.0)
	expect(_particle_offscreen(off2) == true, "offscreen: pos (710,240) → offscreen → respawn")
	var on_screen := Vector2(320.0, 240.0)
	expect(_particle_offscreen(on_screen) == false, "offscreen: pos (320,240) → on screen → no respawn")

func _ready() -> void:
	print("=== Wind Effect Tests ===")
	_test_wind_vector()
	_test_wind_vector_up()
	_test_particle_drift()
	_test_lifetime_alpha()
	_test_offscreen_respawn()
	_report()
