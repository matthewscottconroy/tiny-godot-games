extends Node

# Drives the real player from scripts/player.gd rather than a copy of the slide
# rules — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_not_sliding_before_anything_happens()
	_test_pressing_into_the_wall_slides()
	_test_pressing_away_does_not_slide()
	_test_no_input_does_not_slide()
	_test_floor_beats_wall()
	_test_no_wall_no_slide()
	_test_both_wall_sides()
	_test_slide_reduces_gravity()
	_test_slide_speed_is_capped()
	_test_distance_accumulates_only_while_sliding()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[wall-slide] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
# A wall on the player's right pushes left, so its normal is (-1, 0).
const WALL_ON_RIGHT := -1.0
const WALL_ON_LEFT := 1.0
const PUSH_RIGHT := 1.0
const PUSH_LEFT := -1.0

var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	add_child(p)
	return p

func _test_not_sliding_before_anything_happens() -> void:
	print("initial state")
	# A player that started life flagged as sliding would fall at slide gravity
	# on its first airborne frame, before touching any wall.
	expect(not _make().is_sliding(), "a fresh player is not sliding")

func _test_pressing_into_the_wall_slides() -> void:
	print("pressing into the wall")
	var p := _make()
	expect(p.should_slide(PUSH_RIGHT, true, false, WALL_ON_RIGHT),
		"holding toward a wall while airborne starts a slide")

func _test_pressing_away_does_not_slide() -> void:
	print("pressing away")
	var p := _make()
	expect(not p.should_slide(PUSH_LEFT, true, false, WALL_ON_RIGHT),
		"holding away from the wall does not slide — you are leaving it")

func _test_no_input_does_not_slide() -> void:
	print("no input")
	var p := _make()
	expect(not p.should_slide(0.0, true, false, WALL_ON_RIGHT),
		"merely touching a wall is not a slide; it takes intent")

func _test_floor_beats_wall() -> void:
	print("standing on the floor")
	var p := _make()
	expect(not p.should_slide(PUSH_RIGHT, true, true, WALL_ON_RIGHT),
		"standing next to a wall is not sliding down it")

func _test_no_wall_no_slide() -> void:
	print("no wall")
	var p := _make()
	expect(not p.should_slide(PUSH_RIGHT, false, false, 0.0),
		"there is nothing to slide on")

func _test_both_wall_sides() -> void:
	print("the rule is symmetric")
	var p := _make()
	expect(p.should_slide(PUSH_LEFT, true, false, WALL_ON_LEFT),
		"a wall on the left works the same way")
	expect(not p.should_slide(PUSH_RIGHT, true, false, WALL_ON_LEFT),
		"and pressing away from it still does not slide")

func _test_slide_reduces_gravity() -> void:
	print("reduced gravity")
	var falling := _make()
	var sliding := _make()
	var free_fall: float = falling.tick_vertical(0.0, STEP, false)
	var slid: float = sliding.tick_vertical(0.0, STEP, true)
	expect(slid < free_fall, "a slide accelerates more slowly than a free fall")
	expect(slid > 0.0, "but still descends — it is a slide, not a grip")

func _test_slide_speed_is_capped() -> void:
	print("terminal slide speed")
	var p := _make()
	var vy := 0.0
	for i in 300:
		vy = p.tick_vertical(vy, STEP, true)
	expect(is_equal_approx(vy, p.SLIDE_SPEED_CAP),
		"a long slide settles at SLIDE_SPEED_CAP rather than accelerating forever")

	var free := _make()
	var fall := 0.0
	for i in 300:
		fall = free.tick_vertical(fall, STEP, false)
	expect(fall > p.SLIDE_SPEED_CAP, "an ordinary fall is not capped the same way")

func _test_distance_accumulates_only_while_sliding() -> void:
	print("slide distance")
	var p := _make()
	expect(is_zero_approx(p.slide_distance()), "starts at zero")
	for i in 60:
		p.tick_vertical(50.0, STEP, true)
	var slid: float = p.slide_distance()
	expect(slid > 0.0, "sliding accumulates distance")
	for i in 60:
		p.tick_vertical(50.0, STEP, false)
	expect(is_equal_approx(p.slide_distance(), slid),
		"falling normally does not add to it")
