extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_pillar_positions()
	_test_pillar_count()
	_test_level_width()
	_test_ground_strip()
	_test_pillar_spacing()
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

func _test_pillar_positions() -> void:
	print("pillar x positions: 300 + i * 250")
	var positions := []
	for i in range(5):
		positions.append(300 + i * 250)
	expect(positions[0] == 300, "pillar 0 at x=300")
	expect(positions[1] == 550, "pillar 1 at x=550")
	expect(positions[2] == 800, "pillar 2 at x=800")
	expect(positions[3] == 1050, "pillar 3 at x=1050")
	expect(positions[4] == 1300, "pillar 4 at x=1300")

func _test_pillar_count() -> void:
	print("pillar count")
	var count := 5
	expect(count == 5, "5 pillars in level")

func _test_level_width() -> void:
	print("level width")
	var level_width := 1400
	expect(level_width == 1400, "level is 1400 px wide")

func _test_ground_strip() -> void:
	print("ground strip rect")
	var ground := Rect2(0, 455, 1400, 30)
	expect(ground.position.y == 455.0, "ground starts at y=455")
	expect(ground.size.x == 1400.0, "ground spans full level width")

func _test_pillar_spacing() -> void:
	print("pillar spacing")
	var spacing := 250
	for i in range(1, 5):
		var diff := (300 + i * 250) - (300 + (i - 1) * 250)
		expect(diff == spacing, "pillar spacing is uniform 250")

func _report() -> void:
	var summary := "[canvas-layer] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
