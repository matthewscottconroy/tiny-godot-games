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
	var summary := "[screen-warp] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Simulate the UV displacement from the shader in GDScript for testing.
# shader: uv.x += sin(uv.y * 20 + time * speed) * strength
#         uv.y += cos(uv.x * 20 + time * speed * 0.7) * strength
func _displace_uv(uv: Vector2, time: float, strength: float, speed: float) -> Vector2:
	var out := uv
	out.x += sin(uv.y * 20.0 + time * speed) * strength
	out.y += cos(uv.x * 20.0 + time * speed * 0.7) * strength
	return out

func _test_uv_displacement_at_origin() -> void:
	print("TEST: UV displacement at origin with time=0")
	# uv=(0,0), time=0, speed=2, strength=0.02
	# uv.x += sin(0*20 + 0*2) * 0.02 = sin(0)*0.02 = 0
	# uv.y += cos(0*20 + 0*0.7) * 0.02 = cos(0)*0.02 = 0.02
	var uv := Vector2(0.0, 0.0)
	var result := _displace_uv(uv, 0.0, 0.02, 2.0)
	expect(abs(result.x - 0.0) < 0.0001, "x displacement at (0,0) t=0 is 0 (sin(0)=0)")
	# cos(0) = 1, so y offset = 0.02
	expect(abs(result.y - 0.02) < 0.0001, "y displacement at (0,0) t=0 is +strength (cos(0)=1)")

func _test_warp_off() -> void:
	print("TEST: warp off (strength=0)")
	var uv := Vector2(0.3, 0.7)
	var result := _displace_uv(uv, 1.5, 0.0, 2.0)
	expect(abs(result.x - uv.x) < 0.0001, "strength=0 → x unchanged")
	expect(abs(result.y - uv.y) < 0.0001, "strength=0 → y unchanged")

func _test_strength_increase() -> void:
	print("TEST: double strength doubles displacement")
	# Use a UV and time where sin/cos are non-zero
	var uv := Vector2(0.5, 0.5)
	var time := 0.1
	var speed := 2.0
	var r1 := _displace_uv(uv, time, 0.02, speed)
	var r2 := _displace_uv(uv, time, 0.04, speed)
	var dx1 := r1.x - uv.x
	var dx2 := r2.x - uv.x
	# dx2 should be approximately 2x dx1
	if abs(dx1) > 0.0001:
		expect(abs(dx2 / dx1 - 2.0) < 0.01, "double strength → double x displacement")
	else:
		# sin happened to be 0 — test the y channel instead
		var dy1 := r1.y - uv.y
		var dy2 := r2.y - uv.y
		expect(abs(dy2 / dy1 - 2.0) < 0.01, "double strength → double y displacement")

func _test_time_advances() -> void:
	print("TEST: sin completes half cycle at time = PI/speed")
	var speed := 2.0
	# At uv.y=0: x displacement = sin(0 + time*speed)*strength
	# At time=PI/speed: time*speed = PI, sin(PI) ≈ 0
	var uv := Vector2(0.0, 0.0)
	var time_half := PI / speed
	var r := _displace_uv(uv, time_half, 0.02, speed)
	# sin(0 + PI) = 0, so x displacement ≈ 0
	expect(abs(r.x - 0.0) < 0.001, "sin at time=PI/speed returns near-zero (half cycle)")

func _test_speed_parameter() -> void:
	print("TEST: higher speed causes faster oscillation")
	# Compare displacement at two different speeds at the same time/UV
	# With higher speed, the argument to sin is larger, causing faster phase change
	var uv := Vector2(0.0, 0.25)
	var time := 0.3
	var strength := 0.05
	var r_slow := _displace_uv(uv, time, strength, 1.0)
	var r_fast := _displace_uv(uv, time, strength, 4.0)
	# They should differ because the sin arguments differ
	var dx_slow := r_slow.x - uv.x
	var dx_fast := r_fast.x - uv.x
	expect(abs(dx_slow - dx_fast) > 0.0001, "different speeds produce different displacements")

func _ready() -> void:
	print("=== Screen Warp Tests ===")
	_test_uv_displacement_at_origin()
	_test_warp_off()
	_test_strength_increase()
	_test_time_advances()
	_test_speed_parameter()
	_report()
