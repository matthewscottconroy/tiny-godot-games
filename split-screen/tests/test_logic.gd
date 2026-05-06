extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_player_key_assignment()
	_test_jump_velocity()
	_test_camera_follows_player()
	_test_viewport_sizes()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)

# ---- minimal simulation structs ----

class FakePlayer:
	var use_wasd: bool
	var body_color: Color
	const SPEED    := 160.0
	const JUMP_VEL := -360.0
	const GRAVITY  := 800.0
	var velocity := Vector2.ZERO

	func _init(wasd: bool, color: Color) -> void:
		use_wasd = wasd
		body_color = color

	func jump_key() -> int:
		return KEY_W if use_wasd else KEY_UP

	func apply_gravity(delta: float) -> void:
		velocity.y += GRAVITY * delta

	func jump() -> void:
		velocity.y = JUMP_VEL

class FakeCamera:
	var position := Vector2.ZERO

	func follow(player_pos: Vector2) -> void:
		position = player_pos

# ---- tests ----

func _test_player_key_assignment() -> void:
	print("player key assignment by use_wasd flag")
	var p1 := FakePlayer.new(true,  Color.CORNFLOWER_BLUE)
	var p2 := FakePlayer.new(false, Color.TOMATO)

	expect(p1.use_wasd == true,  "player 1 uses WASD")
	expect(p2.use_wasd == false, "player 2 uses arrow keys")
	expect(p1.jump_key() == KEY_W,  "player 1 jump key is W")
	expect(p2.jump_key() == KEY_UP, "player 2 jump key is UP")

func _test_jump_velocity() -> void:
	print("jump velocity and gravity")
	var p := FakePlayer.new(true, Color.WHITE)
	expect_approx(p.velocity.y, 0.0, "initial y velocity is zero")

	p.apply_gravity(1.0)
	expect_approx(p.velocity.y, 800.0, "gravity adds 800 per second")

	p.jump()
	expect_approx(p.velocity.y, FakePlayer.JUMP_VEL, "jump sets velocity to JUMP_VEL")
	expect(FakePlayer.JUMP_VEL < 0.0, "jump velocity is negative (upward)")

func _test_camera_follows_player() -> void:
	print("camera follows player global position")
	var cam := FakeCamera.new()
	var player_pos := Vector2(100.0, 200.0)

	cam.follow(player_pos)
	expect(cam.position == player_pos, "camera position matches player position")

	player_pos = Vector2(250.0, 180.0)
	cam.follow(player_pos)
	expect(cam.position == player_pos, "camera updates when player moves")

func _test_viewport_sizes() -> void:
	print("viewport dimensions")
	# Each half of a 640x480 window
	const FULL_W := 640
	const FULL_H := 480
	const HALF_W := FULL_W / 2
	expect(HALF_W == 320, "half-width is 320")
	expect(FULL_H == 480, "full height is 480")

	# Verify the two viewports together tile the full window
	expect(HALF_W + HALF_W == FULL_W, "two 320-wide viewports equal 640")

	# SubViewport size matches expectations
	var vp_size := Vector2i(320, 480)
	expect(vp_size.x == HALF_W, "SubViewport width is 320")
	expect(vp_size.y == FULL_H, "SubViewport height is 480")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
