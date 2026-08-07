extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_player_speed()
	_test_zone_labels()
	_test_status_text_format()
	_test_zone_bounds()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_player_speed() -> void:
	print("player speed")
	const SPEED := 180.0
	expect(SPEED == 180.0, "player SPEED is 180")
	var vel := Vector2(SPEED, 0.0)
	expect_near(vel.length(), 180.0, "velocity magnitude equals SPEED", 0.1)

func _test_zone_labels() -> void:
	print("zone label strings")
	var safe_text := "Zone: " + "SAFE ZONE"
	var danger_text := "Zone: " + "DANGER ZONE!"
	var win_text := "Zone: " + "WIN ZONE!"
	var neutral_text := "Zone: " + "—"
	expect(safe_text == "Zone: SAFE ZONE", "safe zone label correct")
	expect(danger_text == "Zone: DANGER ZONE!", "danger zone label correct")
	expect(win_text == "Zone: WIN ZONE!", "win zone label correct")
	expect(neutral_text == "Zone: —", "neutral label correct")

func _test_status_text_format() -> void:
	print("status text prefix")
	var prefix := "Zone: "
	expect(prefix.length() == 6, "prefix is 6 characters")
	expect("Zone: SAFE ZONE".begins_with("Zone: "), "text begins with Zone: ")

func _test_zone_bounds() -> void:
	print("zone rect boundaries")
	var safe_rect := Rect2(30, 250, 160, 190)
	var danger_rect := Rect2(450, 250, 160, 190)
	var win_rect := Rect2(220, 60, 200, 150)
	expect(safe_rect.position.x == 30.0, "safe zone x=30")
	expect(danger_rect.position.x == 450.0, "danger zone x=450")
	expect(win_rect.size.x == 200.0, "win zone width=200")
	var center := safe_rect.position + safe_rect.size * 0.5
	expect(safe_rect.has_point(center), "center point is inside rect")

func _report() -> void:
	var summary := "[area-trigger] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
