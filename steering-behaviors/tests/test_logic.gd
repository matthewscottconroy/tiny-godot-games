extends Node

# ── Mirrored constants ───────────────────────────────────────────────────────
const MAX_SPEED     := 140.0
const MAX_FORCE     := 200.0
const ARRIVE_RADIUS := 60.0
const FLEE_RADIUS   := 150.0
const WANDER_RADIUS := 50.0
const WANDER_DIST   := 80.0

# ── Helpers ──────────────────────────────────────────────────────────────────
var _pass := 0
var _fail := 0

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	print("")
	print("Results: %d passed, %d failed" % [_pass, _fail])

# ── Mirrored steering logic ──────────────────────────────────────────────────

func _seek_steering(pos: Vector2, vel: Vector2, target: Vector2) -> Vector2:
	var to_target := target - pos
	var dist := to_target.length()
	var speed := MAX_SPEED
	if dist < ARRIVE_RADIUS:
		speed = MAX_SPEED * (dist / ARRIVE_RADIUS)
	var desired := Vector2.ZERO
	if dist > 0.01:
		desired = to_target.normalized() * speed
	return (desired - vel).limit_length(MAX_FORCE)


func _flee_steering(pos: Vector2, vel: Vector2, target: Vector2) -> Vector2:
	var to_target := target - pos
	var dist := to_target.length()
	if dist < FLEE_RADIUS and dist > 0.01:
		var desired := -to_target.normalized() * MAX_SPEED
		return (desired - vel).limit_length(MAX_FORCE)
	else:
		return (-vel).limit_length(MAX_FORCE)


func _wander_displacement(wander_angle: float) -> Vector2:
	return Vector2(cos(wander_angle), sin(wander_angle)) * WANDER_RADIUS

# ── Tests ─────────────────────────────────────────────────────────────────────

func _test_seek_toward_target() -> void:
	# Agent at origin, target to the right, zero velocity → steering should be rightward (positive x)
	var pos    := Vector2(0, 0)
	var vel    := Vector2(0, 0)
	var target := Vector2(100, 0)
	var s := _seek_steering(pos, vel, target)
	expect(s.x > 0.0 and absf(s.y) < 1.0, "seek_toward_target: steering x > 0 and y ≈ 0")


func _test_arrive_slows() -> void:
	# Place agent just inside ARRIVE_RADIUS → desired speed < MAX_SPEED
	var pos    := Vector2(0, 0)
	var vel    := Vector2(0, 0)
	var dist   := ARRIVE_RADIUS * 0.5       # halfway inside radius
	var target := Vector2(dist, 0)
	# Desired speed should be proportional: MAX_SPEED * (dist / ARRIVE_RADIUS)
	var expected_speed := MAX_SPEED * (dist / ARRIVE_RADIUS)
	# The desired velocity magnitude equals expected_speed when vel=0
	var s := _seek_steering(pos, vel, target)
	# steering = desired - vel = desired (since vel=0); its length = expected_speed
	expect(s.length() < MAX_SPEED, "arrive_slows: desired speed inside radius < MAX_SPEED")
	expect(absf(s.length() - expected_speed) < 1.0, "arrive_slows: desired speed matches proportional value")


func _test_flee_away() -> void:
	# Agent and target nearly coincident → flee steering should be strongly away (large magnitude)
	var pos    := Vector2(100, 100)
	var vel    := Vector2(0, 0)
	var target := pos + Vector2(0.1, 0)   # tiny offset so distance > 0
	var s := _flee_steering(pos, vel, target)
	# Desired is away from target, so x component should be negative
	expect(s.x < 0.0, "flee_away: steering x < 0 (moving left, away from rightward target)")
	expect(s.length() > 0.0, "flee_away: steering force is non-zero")


func _test_flee_ignores_distant() -> void:
	# Agent far from target (beyond FLEE_RADIUS) → no flee force, just deceleration
	var pos    := Vector2(0, 0)
	var vel    := Vector2(50, 0)           # has some velocity
	var target := Vector2(FLEE_RADIUS + 50, 0)
	var s := _flee_steering(pos, vel, target)
	# Should be opposing the current velocity (deceleration), not pointing away from target
	# Deceleration force is -vel.limit_length(MAX_FORCE), which is (-50, 0)
	expect(s.x < 0.0, "flee_ignores_distant: outside FLEE_RADIUS → deceleration (opposing vel)")
	expect(s.length() <= MAX_FORCE + 0.01, "flee_ignores_distant: force clamped to MAX_FORCE")


func _test_wander_bounded() -> void:
	# The displacement from the wander circle must be exactly WANDER_RADIUS in magnitude
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var disp := _wander_displacement(angle)
		expect(absf(disp.length() - WANDER_RADIUS) < 0.01,
			"wander_bounded: angle %d → displacement magnitude == WANDER_RADIUS" % i)


# ── Entry point ───────────────────────────────────────────────────────────────

func _ready() -> void:
	print("=== Steering Behaviors Tests ===")
	_test_seek_toward_target()
	_test_arrive_slows()
	_test_flee_away()
	_test_flee_ignores_distant()
	_test_wander_bounded()
	_report()
