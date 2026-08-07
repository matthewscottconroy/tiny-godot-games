extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_no_movement_inside_dead_zone()
	test_moves_when_player_exits_right()
	test_moves_when_player_exits_left()
	test_moves_when_player_exits_up()
	test_target_pulls_player_to_zone_edge()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[camera-deadzone] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const DEAD_W := 80.0
const DEAD_H := 40.0

func _compute_target(cam_pos: Vector2, player_pos: Vector2) -> Vector2:
	var offset := player_pos - cam_pos
	var target := cam_pos
	if offset.x > DEAD_W:   target.x = player_pos.x - DEAD_W
	elif offset.x < -DEAD_W: target.x = player_pos.x + DEAD_W
	if offset.y > DEAD_H:   target.y = player_pos.y - DEAD_H
	elif offset.y < -DEAD_H: target.y = player_pos.y + DEAD_H
	return target

func test_no_movement_inside_dead_zone() -> void:
	var cam    := Vector2(320, 240)
	var player := Vector2(360, 260)  # within DEAD_W/DEAD_H
	var target := _compute_target(cam, player)
	expect(target.is_equal_approx(cam), "camera target unchanged when player inside dead zone")

func test_moves_when_player_exits_right() -> void:
	var cam    := Vector2(320, 240)
	var player := Vector2(cam.x + DEAD_W + 20, 240)
	var target := _compute_target(cam, player)
	expect(target.x > cam.x, "camera target shifts right when player exits right edge")

func test_moves_when_player_exits_left() -> void:
	var cam    := Vector2(320, 240)
	var player := Vector2(cam.x - DEAD_W - 20, 240)
	var target := _compute_target(cam, player)
	expect(target.x < cam.x, "camera target shifts left when player exits left edge")

func test_moves_when_player_exits_up() -> void:
	var cam    := Vector2(320, 240)
	var player := Vector2(320, cam.y - DEAD_H - 20)
	var target := _compute_target(cam, player)
	expect(target.y < cam.y, "camera target shifts up when player exits top edge")

func test_target_pulls_player_to_zone_edge() -> void:
	var cam    := Vector2(0, 0)
	var player := Vector2(DEAD_W + 50, 0)
	var target := _compute_target(cam, player)
	# After target, player offset from cam = player_pos - target = DEAD_W exactly
	var new_offset := player - target
	expect(absf(new_offset.x - DEAD_W) < 0.01, "target restores player to dead zone edge")
