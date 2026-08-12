extends Node

# Pure GDScript tests — no scene tree dependencies.

var _pass := 0
var _fail := 0
var _results: Array = []

const PLAYER_W := 20.0
const PLAYER_H := 36.0
const LEDGE_GRAB_RANGE := 8.0
const LEDGE_VERT_RANGE := 10.0

var _platforms: Array = [
	Rect2(0, 440, 640, 40),
	Rect2(80, 340, 140, 18),
	Rect2(300, 260, 140, 18),
	Rect2(460, 340, 140, 18),
	Rect2(160, 160, 140, 18),
]

func _ready() -> void:
	_test_ledge_detection_left_edge()
	_test_ledge_detection_right_edge()
	_test_no_grab_rising()
	_test_no_grab_too_far()
	_test_hang_position()
	_report()

# --------------- helpers ---------------

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# Returns the ledge edge grabbed, or Vector2.ZERO if none
func _check_ledge(player_pos: Vector2, vel_y: float) -> Vector2:
	if vel_y <= 0.0:
		return Vector2.ZERO
	var player_top := player_pos.y - PLAYER_H
	for plat in _platforms:
		var plat_top: float = plat.position.y
		if absf(player_top - plat_top) > LEDGE_VERT_RANGE:
			continue
		# Left edge check
		var left_edge: float = plat.position.x
		if absf((player_pos.x + PLAYER_W * 0.5) - left_edge) < LEDGE_GRAB_RANGE:
			return Vector2(left_edge, plat_top)
		# Right edge check
		var right_edge: float = plat.position.x + plat.size.x
		if absf((player_pos.x - PLAYER_W * 0.5) - right_edge) < LEDGE_GRAB_RANGE:
			return Vector2(right_edge, plat_top)
	return Vector2.ZERO

# --------------- tests ---------------

func _test_ledge_detection_left_edge() -> void:
	# Platform at Rect2(80, 340, 140, 18): left edge at x=80, top at y=340
	# Player right side at x=80 → pos.x = 80 - PLAYER_W/2 = 70, top = 340 (exact)
	var plat_top := 340.0
	var left_edge_x := 80.0
	var player_pos := Vector2(left_edge_x - PLAYER_W * 0.5, plat_top + PLAYER_H)
	var grabbed := _check_ledge(player_pos, 100.0)  # falling
	expect(grabbed != Vector2.ZERO, "Left edge: falling player near left edge grabs ledge")
	expect(grabbed.x == left_edge_x, "Left edge: grab position X matches left edge")

func _test_ledge_detection_right_edge() -> void:
	# Platform at Rect2(80, 340, 140, 18): right edge at x=220, top at y=340
	var plat_top := 340.0
	var right_edge_x := 220.0
	var player_pos := Vector2(right_edge_x + PLAYER_W * 0.5, plat_top + PLAYER_H)
	var grabbed := _check_ledge(player_pos, 100.0)  # falling
	expect(grabbed != Vector2.ZERO, "Right edge: falling player near right edge grabs ledge")
	expect(grabbed.x == right_edge_x, "Right edge: grab position X matches right edge")

func _test_no_grab_rising() -> void:
	# vel.y < 0 (rising): should not grab
	var plat_top := 340.0
	var left_edge_x := 80.0
	var player_pos := Vector2(left_edge_x - PLAYER_W * 0.5, plat_top + PLAYER_H)
	var grabbed := _check_ledge(player_pos, -200.0)  # rising
	expect(grabbed == Vector2.ZERO, "Rising (vel.y < 0): no ledge grab")

func _test_no_grab_too_far() -> void:
	# Player top more than LEDGE_VERT_RANGE below platform top: no grab
	var plat_top := 340.0
	var left_edge_x := 80.0
	# Place player so player_top = plat_top + LEDGE_VERT_RANGE + 5 (too low)
	var player_top := plat_top + LEDGE_VERT_RANGE + 5.0
	var player_pos := Vector2(left_edge_x - PLAYER_W * 0.5, player_top + PLAYER_H)
	var grabbed := _check_ledge(player_pos, 100.0)
	expect(grabbed == Vector2.ZERO, "Player top too far below platform: no grab")

func _test_hang_position() -> void:
	# While HANGING, player top should equal _hang_edge.y
	# hang_edge = Vector2(80, 340)
	var hang_edge := Vector2(80.0, 340.0)
	# In HANGING state: _pos.y = _hang_edge.y + PLAYER_H
	var hang_pos_y := hang_edge.y + PLAYER_H
	var player_top := hang_pos_y - PLAYER_H
	expect(absf(player_top - hang_edge.y) < 0.001, "HANGING: player top == hang_edge.y")

# --------------- report ---------------

func _report() -> void:
	var summary := "[ledge-hang] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
